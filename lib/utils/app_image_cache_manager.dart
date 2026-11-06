import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// ImageLoaderQueue enforces concurrency throttling (debounced loading):
/// At most 10 network requests execute simultaneously to prevent network congestion
/// and avoid memory spikes on Windows desktop / mobile.
class AppImageCacheManager {
  static final AppImageCacheManager instance = AppImageCacheManager._internal();

  AppImageCacheManager._internal();

  // In-memory decoded / raw byte cache: fast access without disk I/O
  final Map<String, Uint8List> _memoryCache = {};
  final Set<String> _failedUrls = {};

  // Maximum active concurrent downloads
  static const int maxConcurrentLoads = 10;
  int _activeLoads = 0;

  // Queue of pending requests
  final List<_ImageLoadRequest> _queue = [];

  // Directory for persistent disk caching on desktop / mobile
  Directory? _cacheDir;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      if (!kIsWeb) {
        final temp = await getTemporaryDirectory();
        _cacheDir = Directory('${temp.path}${Platform.pathSeparator}sirfbill_img_cache');
        if (!await _cacheDir!.exists()) {
          await _cacheDir!.create(recursive: true);
        }
      }
    } catch (e) {
      debugPrint('[AppImageCacheManager] Disk cache init warning: $e');
    } finally {
      _initialized = true;
    }
  }

  String _hashUrl(String url) {
    return md5.convert(utf8.encode(url)).toString();
  }

  File? _getDiskFile(String url) {
    if (_cacheDir == null) return null;
    final hash = _hashUrl(url);
    return File('${_cacheDir!.path}${Platform.pathSeparator}$hash.cache');
  }

  /// Get cached bytes synchronously if present in RAM
  Uint8List? getFromMemory(String url) => _memoryCache[url];

  /// Enqueue and download image with concurrency limited to 10
  Future<Uint8List?> loadImage(String url) async {
    if (url.isEmpty) return null;
    if (_failedUrls.contains(url)) return null;

    // 1. RAM Cache check
    if (_memoryCache.containsKey(url)) {
      return _memoryCache[url];
    }

    await init();

    // 2. Disk Cache check
    final diskFile = _getDiskFile(url);
    if (diskFile != null && await diskFile.exists()) {
      try {
        final bytes = await diskFile.readAsBytes();
        if (bytes.isNotEmpty) {
          _memoryCache[url] = bytes;
          return bytes;
        }
      } catch (_) {}
    }

    // 3. Queue up for throttled concurrent download (max 10 at a time)
    final completer = Completer<Uint8List?>();
    _queue.add(_ImageLoadRequest(url: url, completer: completer));
    _processNext();
    return completer.future;
  }

  void _processNext() {
    if (_activeLoads >= maxConcurrentLoads || _queue.isEmpty) {
      return;
    }

    final request = _queue.removeAt(0);
    _activeLoads++;

    _download(request.url).then((bytes) {
      if (bytes != null && bytes.isNotEmpty) {
        _memoryCache[request.url] = bytes;
        // Save to disk asynchronously
        final diskFile = _getDiskFile(request.url);
        if (diskFile != null) {
          // ignore: body_might_complete_normally_catch_error
          diskFile.writeAsBytes(bytes).catchError((_) {});
        }
        request.completer.complete(bytes);
      } else {
        _failedUrls.add(request.url);
        request.completer.complete(null);
      }
    }).catchError((e) {
      _failedUrls.add(request.url);
      request.completer.complete(null);
    }).whenComplete(() {
      _activeLoads--;
      _processNext();
    });
  }

  Future<Uint8List?> _download(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return null;

      // 1. First attempt with a quick 4-second timeout
      try {
        final response = await http.get(
          uri,
          headers: {
            'User-Agent': 'SirfBillRestaurant/1.0 (https://naiyo24.com; contact@naiyo24.com)',
            'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
          },
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          return response.bodyBytes;
        }
      } catch (_) {
        // Silently proceed to fallback if primary attempt fails or times out
      }

      // 2. If the URL was routed through backend image-proxy and failed/timed out,
      // fallback directly to the original target URL so images still load even if the proxy hangs
      if (url.contains('/api/restaurant/menu/image-proxy') && url.contains('url=')) {
        try {
          final queryParam = uri.queryParameters['url'];
          if (queryParam != null && queryParam.isNotEmpty) {
            final targetUri = Uri.tryParse(queryParam);
            if (targetUri != null) {
              final directResp = await http.get(
                targetUri,
                headers: {
                  'User-Agent': 'SirfBillRestaurant/1.0 (https://naiyo24.com; contact@naiyo24.com)',
                  'Accept': 'image/*,*/*',
                },
              ).timeout(const Duration(seconds: 4));

              if (directResp.statusCode == 200 && directResp.bodyBytes.isNotEmpty) {
                return directResp.bodyBytes;
              }
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  /// Batch warm-up helper (e.g. at POS / Menu Management startup)
  void precacheBatch(List<String> urls) {
    for (final url in urls) {
      if (url.isNotEmpty && !_memoryCache.containsKey(url)) {
        loadImage(url);
      }
    }
  }

  void clearMemoryCache() {
    _memoryCache.clear();
    _failedUrls.clear();
  }
}

class _ImageLoadRequest {
  final String url;
  final Completer<Uint8List?> completer;

  _ImageLoadRequest({required this.url, required this.completer});
}

/// Custom ImageProvider backed by AppImageCacheManager with memory & disk cache
class AppCachedNetworkImageProvider extends ImageProvider<AppCachedNetworkImageProvider> {
  final String url;
  final double scale;

  const AppCachedNetworkImageProvider(this.url, {this.scale = 1.0});

  @override
  Future<AppCachedNetworkImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<AppCachedNetworkImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(AppCachedNetworkImageProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<AppCachedNetworkImageProvider>('Image key', key),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    AppCachedNetworkImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    final bytes = await AppImageCacheManager.instance.loadImage(key.url);
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Failed to load image from ${key.url}');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is AppCachedNetworkImageProvider && other.url == url && other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() => '$runtimeType("$url", scale: $scale)';
}


/// Reusable Widget that loads cached network images with 10-concurrency throttling,
/// memory caching, disk caching, smooth frame loading, and error fallback.
class CachedAppImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final int? cacheWidth;
  final int? cacheHeight;
  final Widget Function(BuildContext context, bool isDark)? errorBuilder;

  const CachedAppImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.cacheWidth = 340,
    this.cacheHeight = 240,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) {
      return errorBuilder?.call(context, isDark) ?? _defaultFallback(isDark);
    }

    // On Flutter Web, use standard Image.network to let the browser handle caching,
    // rendering, and CORS / canvas rendering natively without manual XHR/http bytes fetch.
    if (kIsWeb) {
      return Image.network(
        trimmedUrl,
        fit: fit,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return Container(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorBuilder?.call(context, isDark) ?? _defaultFallback(isDark);
        },
      );
    }

    final provider = ResizeImage(
      AppCachedNetworkImageProvider(trimmedUrl),
      width: cacheWidth,
      height: cacheHeight,
    );

    return Image(
      image: provider,
      fit: fit,
      filterQuality: FilterQuality.low,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return Container(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorBuilder?.call(context, isDark) ?? _defaultFallback(isDark);
      },
    );
  }

  Widget _defaultFallback(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 30,
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}
