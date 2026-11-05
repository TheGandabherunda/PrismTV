import 'dart:convert';
import 'dart:io' show Directory, File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Over-The-Air In-App GitHub Releases Update Service
/// Enables automated update detection, release notes inspection,
/// and in-place direct APK upgrades without uninstalling or data loss.
class AppUpdateService extends GetxService {
  static const String currentVersion = '1.0.0';
  static const String repoOwner = 'TheGandabherunda';
  static const String repoName = 'PrismTV';
  static const String channelName = 'org.thegandabherunda.prismtv/app_updater';

  static const MethodChannel _platformChannel = MethodChannel(channelName);

  final RxBool isChecking = false.obs;
  final RxBool updateAvailable = false.obs;
  final RxString latestVersion = ''.obs;
  final RxString releaseNotes = ''.obs;
  final RxString releaseUrl = ''.obs;
  final RxString apkDownloadUrl = ''.obs;
  final RxBool isDownloading = false.obs;
  final RxDouble downloadProgress = 0.0.obs;
  final RxString downloadStatus = ''.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Silent unobtrusive background update check shortly after app startup
    Future.delayed(const Duration(seconds: 4), () {
      checkForUpdates(isManual: false);
    });
  }

  /// Parses semver string like "v1.0.2" or "1.0.2" into comparable integer list
  List<int> _parseVersion(String ver) {
    final cleaned = ver.replaceAll(RegExp(r'^[vV]'), '').split('-').first.trim();
    return cleaned.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  }

  /// Compares two semver strings: returns true if remote is strictly greater than local
  bool isNewerVersion(String local, String remote) {
    final l = _parseVersion(local);
    final r = _parseVersion(remote);

    final maxLen = l.length > r.length ? l.length : r.length;
    for (int i = 0; i < maxLen; i++) {
      final lPart = i < l.length ? l[i] : 0;
      final rPart = i < r.length ? r[i] : 0;
      if (rPart > lPart) return true;
      if (rPart < lPart) return false;
    }
    return false;
  }

  /// Queries GitHub Releases API for the latest published tag
  Future<void> checkForUpdates({bool isManual = false}) async {
    if (isChecking.value) return;

    try {
      isChecking.value = true;
      errorMessage.value = '';

      final url = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'PrismTV-AppUpdateService',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final tagName = (data['tag_name'] as String? ?? '').trim();
        final body = (data['body'] as String? ?? '').trim();
        final htmlUrl = (data['html_url'] as String? ?? 'https://github.com/$repoOwner/$repoName/releases').trim();
        final assets = (data['assets'] as List<dynamic>? ?? []);

        latestVersion.value = tagName.replaceAll(RegExp(r'^[vV]'), '');
        releaseNotes.value = body.isNotEmpty ? body : 'General improvements, stability, and streaming optimizations.';
        releaseUrl.value = htmlUrl;

        // Find APK asset
        String foundApkUrl = '';
        for (final asset in assets) {
          if (asset is Map<String, dynamic>) {
            final name = (asset['name'] as String? ?? '').toLowerCase();
            final download = (asset['browser_download_url'] as String? ?? '');
            if (name.endsWith('.apk')) {
              // Prefer universal or release apk
              if (name.contains('universal') || name.contains('arm64') || name.contains('release')) {
                foundApkUrl = download;
                break;
              } else if (foundApkUrl.isEmpty) {
                foundApkUrl = download;
              }
            }
          }
        }

        apkDownloadUrl.value = foundApkUrl.isNotEmpty ? foundApkUrl : htmlUrl;

        final hasNewer = isNewerVersion(currentVersion, tagName);
        updateAvailable.value = hasNewer;

        if (isManual) {
          if (hasNewer) {
            Get.snackbar(
              'Update Available',
              'PrismTV v${latestVersion.value} is ready for installation.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xEE161824),
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
          } else {
            Get.snackbar(
              'Up to Date',
              'You are running the latest version of PrismTV (v$currentVersion).',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xEE161824),
              colorText: Colors.white,
              duration: const Duration(seconds: 4),
            );
          }
        }
      } else if (response.statusCode == 404) {
        // No release published on GitHub yet
        updateAvailable.value = false;
        latestVersion.value = currentVersion;
        if (isManual) {
          Get.snackbar(
            'PrismTV v$currentVersion',
            'No newer release found on GitHub.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xEE161824),
            colorText: Colors.white,
          );
        }
      } else {
        errorMessage.value = 'GitHub API status: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage.value = e.toString();
      if (isManual) {
        Get.snackbar(
          'Update Check Failed',
          'Could not connect to GitHub. Please check your internet connection.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xEE161824),
          colorText: Colors.white,
        );
      }
    } finally {
      isChecking.value = false;
    }
  }

  /// Downloads the APK in the background with a progress bar and invokes in-place native installation
  Future<void> downloadAndInstall() async {
    if (isDownloading.value) return;

    final targetUrl = apkDownloadUrl.value.isNotEmpty ? apkDownloadUrl.value : releaseUrl.value;
    if (targetUrl.isEmpty) {
      Get.snackbar('Error', 'Download URL is not available.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // On Web or Desktop: open browser download URL directly
    if (kIsWeb || !defaultTargetPlatform.toString().toLowerCase().contains('android')) {
      final uri = Uri.parse(targetUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    // On Android: Stream APK download directly to local cache and trigger native Package Installer
    try {
      isDownloading.value = true;
      downloadProgress.value = 0.0;
      downloadStatus.value = 'Starting download...';

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(targetUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Download failed with status: ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      final tempDir = Directory.systemTemp;
      final apkFile = File('${tempDir.path}/PrismTV_v${latestVersion.value}.apk');

      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      final sink = apkFile.openWrite();
      int received = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          final progress = received / contentLength;
          downloadProgress.value = progress;
          final mbReceived = (received / (1024 * 1024)).toStringAsFixed(1);
          final mbTotal = (contentLength / (1024 * 1024)).toStringAsFixed(1);
          downloadStatus.value = '$mbReceived MB / $mbTotal MB (${(progress * 100).toInt()}%)';
        } else {
          final mbReceived = (received / (1024 * 1024)).toStringAsFixed(1);
          downloadStatus.value = '$mbReceived MB downloaded';
        }
      }

      await sink.flush();
      await sink.close();

      downloadStatus.value = 'Verifying and installing...';

      // Invoke native Android Package Installer via MethodChannel
      try {
        final result = await _platformChannel.invokeMethod('installApk', {
          'filePath': apkFile.path,
        });
        if (result == true) {
          downloadStatus.value = 'Installer opened';
        }
      } on PlatformException catch (e) {
        // Fallback: open via external application
        final uri = Uri.parse(targetUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          errorMessage.value = 'Failed to launch installer: ${e.message}';
        }
      }
    } catch (e) {
      errorMessage.value = 'Download error: $e';
      Get.snackbar(
        'Update Error',
        'Could not complete in-app download. Opening GitHub releases...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xEE161824),
        colorText: Colors.white,
      );
      final uri = Uri.parse(targetUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } finally {
      isDownloading.value = false;
    }
  }
}
