import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../services/app_update_service.dart';

/// Floating In-App Update & Download Toast Overlay
/// Appears at the bottom of the screen across all platforms without navigating away.
class UpdateToastOverlay extends StatelessWidget {
  const UpdateToastOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final updateService = Get.find<AppUpdateService>();

    return Obx(() {
      final isDownloading = updateService.isDownloading.value;
      final updateAvailable = updateService.updateAvailable.value;
      final isDismissed = updateService.toastDismissed.value;
      final showInfo = updateService.showInfoToast.value;
      final showPermission = updateService.showPermissionToast.value;

      final bool isVisible = isDownloading ||
          (updateAvailable && !isDismissed) ||
          showInfo ||
          showPermission;

      if (!isVisible) {
        return const SizedBox.shrink();
      }

      return Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Material(
                type: MaterialType.transparency,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xF5141624),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1.0,
                    ),
                  ),
                  child: _buildContent(context, updateService),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildContent(BuildContext context, AppUpdateService updateService) {
    if (updateService.isDownloading.value) {
      return _buildDownloadingView(updateService);
    }

    if (updateService.showPermissionToast.value) {
      return _buildPermissionView(updateService);
    }

    if (updateService.showInfoToast.value) {
      return _buildInfoView(updateService);
    }

    if (updateService.updateAvailable.value && !updateService.toastDismissed.value) {
      return _buildUpdateAvailableView(updateService);
    }

    return const SizedBox.shrink();
  }

  /// 1. Downloading with live progress bar and MB stats
  Widget _buildDownloadingView(AppUpdateService updateService) {
    final progress = updateService.downloadProgress.value;
    final percent = (progress * 100).toInt().clamp(0, 100);
    final status = updateService.downloadStatus.value;
    final isDone = progress >= 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDone
                    ? const Color(0x3322C55E)
                    : AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isDone
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF22C55E),
                        size: 20,
                      )
                    : const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isDone
                            ? 'Download Complete'
                            : 'Downloading PrismTV v${updateService.latestVersion.value}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        isDone ? 'Installing...' : '$percent%',
                        style: TextStyle(
                          color: isDone ? const Color(0xFF22C55E) : AppColors.secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status.isNotEmpty ? status : 'Preparing installation package...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress > 0.0 ? progress : null,
            minHeight: 5,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  /// 2. New Update Available with in-app Download action
  Widget _buildUpdateAvailableView(AppUpdateService updateService) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.system_update_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'Update Available',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'v${updateService.latestVersion.value}',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'In-app update ready to install without losing data.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 11.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Action: Download & Install (TV Remote focusable)
        Focus(
          child: Builder(
            builder: (ctx) {
              final hasFocus = Focus.of(ctx).hasFocus;
              return InkWell(
                onTap: updateService.downloadAndInstall,
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasFocus ? Colors.white : Colors.transparent,
                      width: hasFocus ? 2.0 : 1.0,
                    ),
                    boxShadow: hasFocus
                        ? const [
                            BoxShadow(
                              color: AppColors.primaryGlow,
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: const Text(
                    'Update',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 6),
        // Dismiss button (TV Remote focusable)
        Focus(
          child: Builder(
            builder: (ctx) {
              final hasFocus = Focus.of(ctx).hasFocus;
              return InkWell(
                onTap: updateService.dismissToast,
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasFocus ? Colors.white : Colors.transparent,
                      width: hasFocus ? 2.0 : 1.0,
                    ),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: hasFocus ? Colors.white : Colors.white.withValues(alpha: 0.5),
                    size: 18,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 3. Brief informative toast (e.g. Up to date)
  Widget _buildInfoView(AppUpdateService updateService) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF22C55E),
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            updateService.infoToastMessage.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        InkWell(
          onTap: () => updateService.showInfoToast.value = false,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.close_rounded,
              color: Colors.white.withValues(alpha: 0.5),
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  /// 4. Permission required to install APKs
  Widget _buildPermissionView(AppUpdateService updateService) {
    return Row(
      children: [
        const Icon(
          Icons.security_rounded,
          color: AppColors.secondary,
          size: 20,
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Permission Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Enable "Install unknown apps" for PrismTV to update directly.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Focus(
          child: Builder(
            builder: (ctx) {
              final hasFocus = Focus.of(ctx).hasFocus;
              return InkWell(
                onTap: updateService.openUnknownSourcesSettings,
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.25),
                    border: Border.all(
                      color: hasFocus ? Colors.white : AppColors.secondary.withValues(alpha: 0.5),
                      width: hasFocus ? 2.0 : 1.0,
                    ),
                    boxShadow: hasFocus
                        ? const [
                            BoxShadow(
                              color: AppColors.secondaryGlow,
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Settings',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 4),
        Focus(
          child: Builder(
            builder: (ctx) {
              final hasFocus = Focus.of(ctx).hasFocus;
              return InkWell(
                onTap: () => updateService.showPermissionToast.value = false,
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasFocus ? Colors.white : Colors.transparent,
                      width: hasFocus ? 2.0 : 1.0,
                    ),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: hasFocus ? Colors.white : Colors.white.withValues(alpha: 0.5),
                    size: 18,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
