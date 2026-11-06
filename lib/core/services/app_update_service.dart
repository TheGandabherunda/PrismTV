import 'dart:convert';
import 'dart:io' show Directory, File;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Over-The-Air In-App GitHub Releases Update Service
/// Enables automated update detection, release notes inspection,
/// and in-place direct APK upgrades without uninstalling or data loss.
class AppUpdateService extends GetxService with WidgetsBindingObserver {
  static const String repoOwner = 'TheGandabherunda';
  static const String repoName = 'PrismTV';
  static const String channelName = 'org.thegandabherunda.prismtv/app_updater';

  static const MethodChannel _platformChannel = MethodChannel(channelName);

  /// App Version State (Dynamically populated from native package manager)
  final RxString currentVersion = '1.0.2'.obs;
  String deviceAbi = 'arm64-v8a';

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

  /// Custom Toast / Overlay UI State
  final RxBool toastDismissed = false.obs;
  final RxBool showInfoToast = false.obs;
  final RxString infoToastMessage = ''.obs;
  final RxBool showPermissionToast = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initNativeInfo();
    // Silent unobtrusive background update check shortly after app startup
    Future.delayed(const Duration(seconds: 4), () {
      checkForUpdates(isManual: false);
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionOnResume();
    }
  }

  Future<void> _checkPermissionOnResume() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (showPermissionToast.value) {
        try {
          final canInstall = await _platformChannel.invokeMethod<bool>('canInstallUnknownApps') ?? true;
          if (canInstall) {
            showPermissionToast.value = false;
            _showBottomInfoToast('Permission granted! Tap Update to continue.');
          }
        } catch (_) {}
      }
    }
  }

  /// Queries native Android package manager for the real compiled version and device ABI
  Future<void> _initNativeInfo() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final ver = await _platformChannel.invokeMethod<String>('getAppVersion');
        if (ver != null && ver.trim().isNotEmpty) {
          final clean = ver.split('+').first.trim();
          currentVersion.value = clean;
          debugPrint('[AppUpdateService] Initialized native app version: $clean');
        }
      } catch (e) {
        debugPrint('[AppUpdateService] Could not retrieve native app version: $e');
      }

      try {
        final abi = await _platformChannel.invokeMethod<String>('getDeviceAbi');
        if (abi != null && abi.trim().isNotEmpty) {
          deviceAbi = abi.trim();
          debugPrint('[AppUpdateService] Detected device architecture: $deviceAbi');
        }
      } catch (e) {
        debugPrint('[AppUpdateService] Could not retrieve device ABI: $e');
      }
    }
  }

  /// Dismisses the update banner/toast for the current app session
  void dismissToast() {
    toastDismissed.value = true;
  }

  /// Opens Android Settings directly to the "Install Unknown Apps" permission toggle for PrismTV
  Future<void> openUnknownSourcesSettings() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        showPermissionToast.value = false;
        await _platformChannel.invokeMethod('openUnknownSourcesSettings');
      } catch (e) {
        debugPrint('[AppUpdateService] openUnknownSourcesSettings error: $e');
      }
    }
  }

  /// Parses semver string like "v1.0.2", "1.0.1+2", or "1.0.2-beta" into comparable integer list
  List<int> _parseVersion(String ver) {
    final cleaned = ver
        .replaceAll(RegExp(r'^[vV]'), '')
        .split('-').first
        .split('+').first
        .trim();
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

  /// Displays an informative bottom toast that auto-dismisses after [seconds]
  void _showBottomInfoToast(String message, {int seconds = 4}) {
    infoToastMessage.value = message;
    showInfoToast.value = true;
    Future.delayed(Duration(seconds: seconds), () {
      if (infoToastMessage.value == message) {
        showInfoToast.value = false;
      }
    });
  }

  /// Queries GitHub Releases API for the latest published tag
  Future<void> checkForUpdates({bool isManual = false}) async {
    if (isChecking.value) return;

    try {
      isChecking.value = true;
      errorMessage.value = '';

      // Make sure we have latest local version from native before comparing
      await _initNativeInfo();

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

        // Smart asset resolution based on device ABI
        String bestMatchUrl = '';
        String universalUrl = '';
        String anyApkUrl = '';

        for (final asset in assets) {
          if (asset is Map<String, dynamic>) {
            final name = (asset['name'] as String? ?? '').toLowerCase();
            final download = (asset['browser_download_url'] as String? ?? '');
            if (name.endsWith('.apk')) {
              if (deviceAbi.contains('arm64') && name.contains('arm64')) {
                bestMatchUrl = download;
              } else if ((deviceAbi.contains('armeabi') || deviceAbi.contains('v7a')) && name.contains('armeabi')) {
                bestMatchUrl = download;
              } else if (deviceAbi.contains('x86_64') && name.contains('x86_64')) {
                bestMatchUrl = download;
              }

              if (name.contains('universal')) {
                universalUrl = download;
              }
              if (anyApkUrl.isEmpty) {
                anyApkUrl = download;
              }
            }
          }
        }

        if (bestMatchUrl.isNotEmpty) {
          apkDownloadUrl.value = bestMatchUrl;
        } else if (universalUrl.isNotEmpty) {
          apkDownloadUrl.value = universalUrl;
        } else if (anyApkUrl.isNotEmpty) {
          apkDownloadUrl.value = anyApkUrl;
        } else {
          apkDownloadUrl.value = htmlUrl;
        }

        final hasNewer = isNewerVersion(currentVersion.value, tagName);
        updateAvailable.value = hasNewer;

        if (hasNewer) {
          // Un-dismiss toast so the notification pill appears cleanly at bottom
          toastDismissed.value = false;
        } else if (isManual) {
          _showBottomInfoToast('PrismTV is up to date (v${currentVersion.value})');
        }
      } else if (response.statusCode == 404) {
        updateAvailable.value = false;
        latestVersion.value = currentVersion.value;
        if (isManual) {
          _showBottomInfoToast('PrismTV is up to date (v${currentVersion.value})');
        }
      } else {
        errorMessage.value = 'GitHub API status: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage.value = e.toString();
      if (isManual) {
        _showBottomInfoToast('Could not check for updates. Check internet connection.');
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
      _showBottomInfoToast('Download URL is not available.');
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

    // On Android: verify "Install unknown apps" permission before starting download
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      bool canInstall = true;
      try {
        canInstall = await _platformChannel.invokeMethod<bool>('canInstallUnknownApps') ?? true;
      } catch (_) {}

      if (!canInstall) {
        showPermissionToast.value = true;
        _showBottomInfoToast('Please enable "Install unknown apps" for PrismTV to install updates.');
        await openUnknownSourcesSettings();
        return;
      }
    }

    // On Android: Stream APK download directly to app cache and trigger native Package Installer
    try {
      isDownloading.value = true;
      downloadProgress.value = 0.0;
      downloadStatus.value = 'Connecting to download server...';
      showPermissionToast.value = false;
      showInfoToast.value = false;

      // Query native cache directory configured in file_paths.xml (<cache-path name="cache" path="." />)
      String cachePath = '';
      try {
        final nativeCache = await _platformChannel.invokeMethod<String>('getCacheDir');
        if (nativeCache != null && nativeCache.isNotEmpty) {
          cachePath = nativeCache;
        }
      } catch (_) {}

      final baseDir = cachePath.isNotEmpty ? Directory(cachePath) : Directory.systemTemp;
      if (!await baseDir.exists()) {
        await baseDir.create(recursive: true);
      }

      final verName = latestVersion.value.isNotEmpty ? latestVersion.value : 'update';
      final apkFile = File('${baseDir.path}/PrismTV_$verName.apk');

      if (await apkFile.exists()) {
        try {
          await apkFile.delete();
        } catch (_) {}
      }

      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(targetUrl));
        request.headers['User-Agent'] = 'PrismTV-AppUpdateService';
        final response = await client.send(request);

        if (response.statusCode != 200) {
          throw Exception('Download failed with status: ${response.statusCode}');
        }

        final contentLength = response.contentLength ?? 0;
        final sink = apkFile.openWrite();
        int received = 0;

        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (contentLength > 0) {
            final progress = (received / contentLength).clamp(0.0, 1.0);
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
      } finally {
        client.close();
      }

      downloadProgress.value = 1.0;
      downloadStatus.value = 'Download complete. Launching installer...';

      // Small delay to let the UI reflect 100% completion before opening native installer sheet
      await Future.delayed(const Duration(milliseconds: 500));

      // Invoke native Android Package Installer via MethodChannel
      try {
        final result = await _platformChannel.invokeMethod('installApk', {
          'filePath': apkFile.path,
        });
        if (result == true) {
          downloadStatus.value = 'Package installer opened';
        }
      } on PlatformException catch (e) {
        if (e.code == 'PERMISSION_REQUIRED') {
          showPermissionToast.value = true;
          downloadStatus.value = 'Permission required to install unknown apps';
        } else {
          errorMessage.value = 'Installer error: ${e.message}';
          _showBottomInfoToast('Installer error: ${e.message}');
        }
      }
    } catch (e) {
      errorMessage.value = 'Download error: $e';
      _showBottomInfoToast('Could not complete in-app download: $e');
    } finally {
      isDownloading.value = false;
    }
  }
}
