import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pub_semver/pub_semver.dart';

class UpdateManifest {
  final String version;
  final String packageUrl;
  final String sha256;
  final String releaseNotes;
  final bool isMandatory;

  UpdateManifest({
    required this.version,
    required this.packageUrl,
    required this.sha256,
    required this.releaseNotes,
    this.isMandatory = false,
  });

  factory UpdateManifest.fromJson(Map<String, dynamic> json) {
    return UpdateManifest(
      version: json['version'] as String,
      packageUrl: json['package_url'] as String,
      sha256: json['sha256'] as String,
      releaseNotes: (json['release_notes'] ?? 'Bug fixes and performance improvements.').toString(),
      isMandatory: (json['mandatory'] ?? json['is_mandatory'] ?? false) as bool,
    );
  }
}

class UpdateService {
  UpdateService({
    required this.manifestUrl,
    this.updaterRelativePath = 'updater.exe',
  });

  final String manifestUrl;
  final String updaterRelativePath;

  Future<UpdateManifest?> checkForUpdate() async {
    // Only check for desktop updates on Windows
    if (kIsWeb || !Platform.isWindows) return null;

    final uri = Uri.parse(manifestUrl);
    if (uri.scheme != 'https') {
      throw Exception('HTTPS update URL required.');
    }

    final response = await http.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Update check failed: HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final info = await PackageInfo.fromPlatform();
    
    // Normalize versions to semantic versioning
    final currentClean = info.version.split('+')[0];
    final latestClean = (data['version'] as String).replaceAll('v', '').split('+')[0];
    
    final current = Version.parse(currentClean);
    final latest = Version.parse(latestClean);

    if (latest <= current) return null;

    final packageUri = Uri.parse(data['package_url'] as String);
    if (packageUri.scheme != 'https') {
      throw Exception('Package URL must use HTTPS.');
    }

    final hash = (data['sha256'] as String).trim();
    if (!RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(hash)) {
      throw Exception('Invalid SHA-256 value in update manifest.');
    }

    return UpdateManifest.fromJson(data);
  }

  Future<File> downloadPackage(
    UpdateManifest manifest, {
    void Function(double progress)? onProgress,
  }) async {
    final uri = Uri.parse(manifest.packageUrl);
    final request = http.Request('GET', uri);
    final response = await http.Client().send(request).timeout(const Duration(minutes: 10));

    if (response.statusCode != 200) {
      throw Exception('Package download failed with status ${response.statusCode}');
    }

    final temp = await getTemporaryDirectory();
    final file = File('${temp.path}${Platform.pathSeparator}app-update.zip');
    if (await file.exists()) {
      await file.delete();
    }

    final totalBytes = response.contentLength ?? 0;
    var receivedBytes = 0;
    final sink = file.openWrite();

    await for (final chunk in response.stream) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0 && onProgress != null) {
        onProgress(receivedBytes / totalBytes);
      }
    }
    await sink.flush();
    await sink.close();

    // Verify SHA-256 integrity
    final digest = await sha256.bind(file.openRead()).first;
    final expected = manifest.sha256.toLowerCase();

    if (digest.toString().toLowerCase() != expected) {
      await file.delete();
      throw Exception('SHA-256 integrity check failed. Expected: $expected, Got: $digest');
    }

    return file;
  }

  Future<void> startUpdater(File packageFile) async {
    final app = File(Platform.resolvedExecutable);
    
    // Resolve updater.exe next to SirfBill.exe
    final updater = File('${app.parent.path}${Platform.pathSeparator}$updaterRelativePath');

    if (!await updater.exists()) {
      // If updater.exe does not exist, run package directly if it is an installer EXE
      if (packageFile.path.endsWith('.exe')) {
        await Process.start(packageFile.path, [], mode: ProcessStartMode.detached);
        exit(0);
      }
      throw Exception('Updater executable not found at ${updater.path}');
    }

    await Process.start(
      updater.path,
      [
        '--wait-pid', '$pid',
        '--install-dir', app.parent.path,
        '--package', packageFile.path,
        '--restart-exe', app.path,
      ],
      mode: ProcessStartMode.detached,
    );

    exit(0);
  }
}
