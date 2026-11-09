import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../config/api_client.dart';

Dio _getUpdaterDio() {
  final dio = Dio();
  if (!kIsWeb) {
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );
  }
  return dio;
}

class AppUpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool isMandatory;

  AppUpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    this.isMandatory = false,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      latestVersion: json['latest_version'] ?? json['version'] ?? '1.0.0',
      downloadUrl: json['download_url'] ?? json['url'] ?? '',
      releaseNotes: json['release_notes'] ?? json['notes'] ?? 'General improvements and bug fixes.',
      isMandatory: json['is_mandatory'] ?? json['mandatory'] ?? false,
    );
  }
}

class WindowsAutoUpdater {
  static const String githubRepo = 'sayar2121/SirfBill_Restraunt';

  static Future<AppUpdateInfo?> checkForUpdate() async {
    // Updates and .exe installer downloads are only applicable for Windows desktop
    if (kIsWeb || !Platform.isWindows) {
      return null;
    }

    try {
      // 1. Direct GitHub Releases check (with short 5-second timeout)
      try {
        final ghResponse = await _getUpdaterDio().get(
          'https://api.github.com/repos/$githubRepo/releases/latest',
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'SirfBill-Updater',
            },
          ),
        );

        if (ghResponse.statusCode == 200 && ghResponse.data != null) {
          final data = ghResponse.data;
          final tagName = (data['tag_name'] ?? '').toString().replaceAll('v', '').trim();
          final body = (data['body'] ?? 'New release available.').toString();

          final assets = data['assets'] as List? ?? [];
          String downloadUrl = '';
          // Prefer app-update.zip for silent in-app delta update via updater.exe, fallback to Setup.exe
          for (var asset in assets) {
            final name = (asset['name'] ?? '').toString().toLowerCase();
            if (name == 'app-update.zip') {
              downloadUrl = asset['browser_download_url'] ?? '';
              break;
            }
          }
          if (downloadUrl.isEmpty) {
            for (var asset in assets) {
              final name = (asset['name'] ?? '').toString().toLowerCase();
              if (name.endsWith('.exe') && name.contains('setup')) {
                downloadUrl = asset['browser_download_url'] ?? '';
                break;
              }
            }
          }
          if (downloadUrl.isEmpty) {
            for (var asset in assets) {
              final name = (asset['name'] ?? '').toString().toLowerCase();
              if (name.endsWith('.exe')) {
                downloadUrl = asset['browser_download_url'] ?? '';
                break;
              }
            }
          }

          if (downloadUrl.isNotEmpty && tagName.isNotEmpty) {
            final packageInfo = await PackageInfo.fromPlatform();
            debugPrint('[AutoUpdater] Current version: ${packageInfo.version}, Latest GitHub: $tagName');
            if (_isNewerVersion(packageInfo.version, tagName)) {
              return AppUpdateInfo(
                latestVersion: tagName,
                downloadUrl: downloadUrl,
                releaseNotes: body,
              );
            }
            return null; // Already up-to-date
          }
        }
      } catch (e) {
        debugPrint('[AutoUpdater] GitHub release check error: $e');
      }

      // 2. Secondary check via GitHub release manifest.json
      try {
        final manifestResponse = await _getUpdaterDio().get(
          'https://github.com/$githubRepo/releases/latest/download/manifest.json',
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
            headers: {'User-Agent': 'SirfBill-Updater'},
          ),
        );
        if (manifestResponse.statusCode == 200 && manifestResponse.data != null) {
          final mData = manifestResponse.data is Map<String, dynamic>
              ? manifestResponse.data as Map<String, dynamic>
              : (manifestResponse.data is String ? jsonDecode(manifestResponse.data as String) as Map<String, dynamic> : <String, dynamic>{});
          final v = (mData['version'] ?? '').toString().trim();
          final pkgUrl = (mData['package_url'] ?? '').toString();
          final notes = (mData['release_notes'] ?? 'General improvements and bug fixes.').toString();
          if (v.isNotEmpty && pkgUrl.isNotEmpty) {
            final packageInfo = await PackageInfo.fromPlatform();
            if (_isNewerVersion(packageInfo.version, v)) {
              return AppUpdateInfo(
                latestVersion: v,
                downloadUrl: pkgUrl,
                releaseNotes: notes,
              );
            }
            return null; // Already up-to-date
          }
        }
      } catch (e) {
        debugPrint('[AutoUpdater] GitHub manifest.json check error: $e');
      }

      // 3. Fallback Backend API endpoint check (/api/app-version)
      try {
        final response = await ApiClient().dio.get(
          '/api/app-version',
          options: Options(
            sendTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 3),
          ),
        );
        if (response.statusCode == 200 && response.data != null) {
          final data = Map<String, dynamic>.from(response.data);
          final updateInfo = AppUpdateInfo.fromJson(data);
          final packageInfo = await PackageInfo.fromPlatform();
          if (_isNewerVersion(packageInfo.version, updateInfo.latestVersion)) {
            return updateInfo;
          }
          return null;
        }
      } catch (e) {
        debugPrint('[AutoUpdater] Backend app-version check skipped: $e');
      }
    } catch (e) {
      debugPrint('[AutoUpdater] Update check failed: $e');
    }
    return null;
  }

  static bool _isNewerVersion(String current, String latest) {
    try {
      final cParts = current.split('+')[0].split('.').map(int.parse).toList();
      final lParts = latest.split('+')[0].split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final c = i < cParts.length ? cParts[i] : 0;
        final l = i < lParts.length ? lParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (_) {}
    return false;
  }

  static bool _isDialogShowing = false;

  /// Checks for updates and displays the dialog.
  /// If [showFeedbackWhenLatest] is true (e.g. when triggered manually by user click),
  /// a snackbar or alert will notify the user if their app is already up to date or if check failed.
  static Future<void> checkAndShowUpdateIfAvailable(
    BuildContext context, {
    bool showFeedbackWhenLatest = false,
  }) async {
    try {
      if (_isDialogShowing) return;
      final updateInfo = await checkForUpdate();
      if (!context.mounted) return;

      if (updateInfo != null && !_isDialogShowing) {
        await showUpdateDialog(context, updateInfo);
      } else if (showFeedbackWhenLatest) {
        final info = await PackageInfo.fromPlatform();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text('App is up to date (v${info.version})'),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Auto-update check encountered error: $e');
      if (showFeedbackWhenLatest && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not check for updates: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  static Future<void> showUpdateDialog(BuildContext context, AppUpdateInfo info) async {
    if (_isDialogShowing) return;
    _isDialogShowing = true;
    try {
      return await showDialog<void>(
        context: context,
        barrierDismissible: !info.isMandatory,
        builder: (ctx) => _UpdateDialog(info: info),
      );
    } finally {
      _isDialogShowing = false;
    }
  }
}

class _UpdateDialog extends StatefulWidget {
  final AppUpdateInfo info;
  const _UpdateDialog({required this.info});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';

  Future<void> _startDownloadAndInstall() async {
    if (widget.info.downloadUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download URL is empty!')),
      );
      return;
    }

    // On Windows desktop, download the installer and launch it
    if (!kIsWeb && Platform.isWindows) {
      setState(() {
        _isDownloading = true;
        _progress = 0.0;
        _statusText = 'Downloading update installer...';
      });

      try {
        final tempDir = await getTemporaryDirectory();
        final isZip = widget.info.downloadUrl.toLowerCase().endsWith('.zip');
        final fileExtension = isZip ? 'zip' : 'exe';
        final filePath = '${tempDir.path}\\app-update.$fileExtension';

        // Delete any existing partial download
        final existingFile = File(filePath);
        if (await existingFile.exists()) {
          try {
            await existingFile.delete();
          } catch (_) {}
        }

        debugPrint('[AutoUpdater] Downloading from ${widget.info.downloadUrl} to $filePath');

        bool downloadSucceeded = false;

        try {
          await _getUpdaterDio().download(
            widget.info.downloadUrl,
            filePath,
            options: Options(
              followRedirects: true,
              maxRedirects: 8,
            ),
            onReceiveProgress: (received, total) {
              if (total > 0) {
                if (mounted) {
                  setState(() {
                    _progress = received / total;
                    _statusText = 'Downloading: ${(_progress * 100).toStringAsFixed(0)}%';
                  });
                }
              } else {
                if (mounted) {
                  setState(() {
                    _statusText = 'Downloading (${(received / (1024 * 1024)).toStringAsFixed(1)} MB)...';
                  });
                }
              }
            },
          );

          final checkFile = File(filePath);
          if (await checkFile.exists() && await checkFile.length() > 1000) {
            downloadSucceeded = true;
          }
        } catch (dioError) {
          debugPrint('[AutoUpdater] Dio download error: $dioError. Attempting fallback via curl.exe...');
        }

        // Fallback: Use system curl.exe (with -k to bypass invalid SSL certificates on Windows)
        if (!downloadSucceeded) {
          if (mounted) {
            setState(() {
              _statusText = 'Downloading via system curl...';
            });
          }
          final curlProcess = await Process.run('curl.exe', [
            '-k', // Insecure / ignore missing local CA certificates
            '-L', // Follow redirects (GitHub -> AWS S3)
            '-f', // Fail on HTTP errors
            '--retry', '3',
            '-o', filePath,
            widget.info.downloadUrl,
          ]);

          final checkFile = File(filePath);
          if (curlProcess.exitCode == 0 && await checkFile.exists() && await checkFile.length() > 1000) {
            downloadSucceeded = true;
            debugPrint('[AutoUpdater] Download succeeded via curl.exe (${await checkFile.length()} bytes)');
          } else {
            throw Exception('Download failed via network and curl fallback: ${curlProcess.stderr}');
          }
        }

        if (mounted) {
          setState(() {
            _statusText = 'Launching installer...';
          });
        }

        final downloadedFile = File(filePath);
        if (!await downloadedFile.exists() || await downloadedFile.length() < 1000) {
          throw Exception('Downloaded file is invalid or incomplete (${await downloadedFile.length()} bytes)');
        }

        final app = File(Platform.resolvedExecutable);

        if (isZip) {
          final sep = Platform.pathSeparator;
          final updaterFile = File('${app.parent.path}${sep}updater.exe');
          final updaterExists = await updaterFile.exists();
          debugPrint('[AutoUpdater] updater.exe path: ${updaterFile.path}, exists: $updaterExists');

          if (updaterExists) {
            debugPrint('[AutoUpdater] Launching updater.exe with package: $filePath');
            await Process.start(
              updaterFile.path,
              [
                '--wait-pid', '$pid',
                '--install-dir', app.parent.path,
                '--package', filePath,
                '--restart-exe', app.path,
              ],
              mode: ProcessStartMode.detached,
            );
            await Future.delayed(const Duration(milliseconds: 500));
            exit(0);
          } else {
            // updater.exe is missing — cannot silently update. Open releases page.
            debugPrint('[AutoUpdater] updater.exe NOT found at ${updaterFile.path}. Opening releases page.');
            if (mounted) {
              setState(() {
                _isDownloading = false;
                _statusText = 'Opening browser for manual download...';
              });
            }
            final releaseUri = Uri.parse('https://github.com/sayar2121/SirfBill_Restraunt/releases/latest');
            if (await canLaunchUrl(releaseUri)) {
              await launchUrl(releaseUri, mode: LaunchMode.externalApplication);
            }
            return;
          }
        }

        // For .exe installers: create a batch script launcher
        final sep = Platform.pathSeparator;
        final launcherBat = File('${tempDir.path}${sep}launch_setup.bat');
        final batContent = '''
@echo off
timeout /t 2 /nobreak >nul
start "" "$filePath" /VERYSILENT /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /NORESTART
exit
''';
        await launcherBat.writeAsString(batContent);
        debugPrint('[AutoUpdater] Created launcher script: ${launcherBat.path}');

        await Process.start(
          'cmd.exe',
          ['/c', launcherBat.path],
          mode: ProcessStartMode.detached,
        );

        await Future.delayed(const Duration(milliseconds: 500));
        exit(0);
      } catch (e) {
        debugPrint('[AutoUpdater] Download or execution failed: $e');
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _statusText = 'Update failed: $e';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Update failed: $e'),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: 'Download Manually',
                textColor: Colors.white,
                onPressed: () async {
                  final uri = Uri.parse('https://github.com/sayar2121/SirfBill_Restraunt/releases/latest');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ),
          );
        }
      }
    } else {
      // Fallback: open download URL in browser
      final uri = Uri.parse(widget.info.downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF166534);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final parsedItems = _parseReleaseNotes(widget.info.releaseNotes);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    Color(0xFF15803D),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'What\'s New',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'v${widget.info.latestVersion}',
                                style: const TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'A fresh update is ready to supercharge your billing.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.info.isMandatory && !_isDownloading)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Dismiss',
                    ),
                ],
              ),
            ),

            // Content Area
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Highlights header
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Release Highlights',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Feature / Highlights cards
                    ...parsedItems.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(item.icon, color: item.color, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item.category,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: item.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  if (item.description.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.description,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    if (_isDownloading) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _statusText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                Text(
                                  '${(_progress * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: _progress > 0 ? _progress : null,
                                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer / Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _isDownloading
                    ? [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Applying update, please wait...',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ]
                    : [
                        if (!widget.info.isMandatory)
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Maybe Later', style: TextStyle(color: Colors.grey)),
                          ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.download_done_rounded, size: 18),
                          label: const Text('Update & Restart Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                          onPressed: _startDownloadAndInstall,
                        ),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_ReleaseHighlight> _parseReleaseNotes(String rawNotes) {
    if (rawNotes.isEmpty || rawNotes.contains('compare/')) {
      return [
        _ReleaseHighlight(
          category: 'PERFORMANCE & CACHING',
          title: 'Debounced Image Loading & Persistent Cache',
          description: 'Throttled 10-concurrency image queue with RAM & disk caching for instant, stutter-free POS Menu & Billing.',
          icon: Icons.speed_rounded,
          color: const Color(0xFF10B981),
        ),
        _ReleaseHighlight(
          category: 'POS LAYOUT',
          title: 'Fixed Top & Bottom Billing Controls',
          description: 'Fixed header with horizontal table carousel, customer bar, and anchored bottom financial summary for smooth cart scrolling.',
          icon: Icons.table_restaurant_rounded,
          color: const Color(0xFF2563EB),
        ),
        _ReleaseHighlight(
          category: 'SCROLLING & ACCESSIBILITY',
          title: 'Full Horizontal & Vertical Scrollbars',
          description: 'Interactive visible scrollbars added across food items, categories, and order lists for effortless mouse & touch control.',
          icon: Icons.swap_horiz_rounded,
          color: const Color(0xFF7C3AED),
        ),
        _ReleaseHighlight(
          category: 'CODEBASE OPTIMIZATION',
          title: 'Streamlined Codebase & Dead Code Purge',
          description: 'Removed legacy medical/lab files and replaced verbose network image builders with lightweight cached providers.',
          icon: Icons.cleaning_services_rounded,
          color: const Color(0xFFEA580C),
        ),
      ];
    }

    final lines = rawNotes.split('\n');
    final List<_ReleaseHighlight> items = [];

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      
      String text = trimmed.replaceAll(RegExp(r'^[\*\-\•]\s*'), '').trim();
      if (text.isEmpty) continue;

      IconData icon = Icons.check_circle_outline_rounded;
      Color color = const Color(0xFF166534);
      String category = 'IMPROVEMENT';

      final lower = text.toLowerCase();
      if (lower.contains('fix') || lower.contains('bug') || lower.contains('resolve')) {
        icon = Icons.bug_report_outlined;
        color = const Color(0xFFDC2626);
        category = 'BUG FIX';
      } else if (lower.contains('feat') || lower.contains('new') || lower.contains('add')) {
        icon = Icons.new_releases_outlined;
        color = const Color(0xFF2563EB);
        category = 'NEW FEATURE';
      } else if (lower.contains('speed') || lower.contains('fast') || lower.contains('perf')) {
        icon = Icons.speed_rounded;
        color = const Color(0xFFD97706);
        category = 'PERFORMANCE';
      }

      items.add(
        _ReleaseHighlight(
          category: category,
          title: text,
          description: '',
          icon: icon,
          color: color,
        ),
      );
    }

    if (items.isEmpty) {
      return [
        _ReleaseHighlight(
          category: 'ENHANCEMENT',
          title: 'General performance improvements and stability fixes',
          description: 'Contains key optimizations for daily operations.',
          icon: Icons.check_circle_outline_rounded,
          color: const Color(0xFF166534),
        )
      ];
    }

    return items;
  }
}

class _ReleaseHighlight {
  final String category;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _ReleaseHighlight({
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

