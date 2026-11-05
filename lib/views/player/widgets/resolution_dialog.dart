import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/quality_option.dart';

class ResolutionDialog extends StatelessWidget {
  final QualityOption currentOption;
  final List<QualityOption>? availableOptions;
  final ValueChanged<QualityOption> onSelect;
  final String title;
  final String subtitle;

  const ResolutionDialog({
    super.key,
    required this.currentOption,
    this.availableOptions,
    required this.onSelect,
    this.title = 'STREAM RESOLUTION',
    this.subtitle = 'Select preferred playback video quality',
  });

  @override
  Widget build(BuildContext context) {
    final options = (availableOptions != null && availableOptions!.isNotEmpty)
        ? availableOptions!
        : QualityOption.defaultOptions;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.unfocusedBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0xCC000000),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: AppColors.prismGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Get.back(),
                ),
              ],
            ),

            const SizedBox(height: 18),
            Container(height: 1, color: AppColors.unfocusedBorder),
            const SizedBox(height: 14),

            // Resolution Options List (Dynamic from stream representations)
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: options.map((opt) {
                      final isSelected = opt.id == currentOption.id ||
                          (opt.targetHeight > 0 && opt.targetHeight == currentOption.targetHeight) ||
                          (opt.id == 'auto' && currentOption.id == 'auto');

                      return _QualityOptionTile(
                        option: opt,
                        isSelected: isSelected,
                        onTap: () {
                          onSelect(opt);
                          Get.back();
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _QualityOptionTile extends StatefulWidget {
  final QualityOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _QualityOptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_QualityOptionTile> createState() => _QualityOptionTileState();
}

class _QualityOptionTileState extends State<_QualityOptionTile> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = _isFocused || _isHovered;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Focus(
        autofocus: widget.isSelected,
        onFocusChange: (f) => setState(() => _isFocused = f),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: highlighted ? 1.02 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: highlighted
                      ? AppColors.focusedBackground
                      : (widget.isSelected ? AppColors.primaryGlow : AppColors.surfaceCard),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: highlighted
                        ? AppColors.primary
                        : (widget.isSelected ? AppColors.primaryLight : AppColors.unfocusedBorder),
                    width: highlighted || widget.isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: highlighted
                      ? const [
                          BoxShadow(
                            color: AppColors.primaryGlow,
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    // Quality Icon
                    Icon(
                      widget.option.targetHeight >= 720
                          ? Icons.hd_rounded
                          : (widget.option.id == 'auto'
                              ? Icons.auto_awesome_rounded
                              : Icons.sd_rounded),
                      size: 20,
                      color: widget.isSelected
                          ? AppColors.primaryLight
                          : (highlighted ? Colors.white : AppColors.textSecondary),
                    ),
                    const SizedBox(width: 14),

                    // Label
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.option.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: widget.isSelected || highlighted
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: widget.isSelected || highlighted
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.option.badge,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Selection Indicator
                    if (widget.isSelected)
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          gradient: AppColors.activeTabGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.check_rounded, size: 14, color: Colors.white),
                        ),
                      )
                    else if (highlighted)
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.primaryLight,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
