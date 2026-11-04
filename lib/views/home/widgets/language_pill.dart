import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/language_model.dart';

class LanguagePill extends StatefulWidget {
  final LanguageModel language;
  final bool isSelected;
  final VoidCallback onTap;

  const LanguagePill({
    super.key,
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<LanguagePill> createState() => _LanguagePillState();
}

class _LanguagePillState extends State<LanguagePill> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected;
    final highlighted = _isFocused || _isHovered;

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: highlighted ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: active ? AppColors.activeTabGradient : null,
                color: active
                    ? null
                    : (highlighted ? AppColors.surfaceHover : AppColors.surfaceCard),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? Colors.transparent
                      : (highlighted ? AppColors.primary : AppColors.unfocusedBorder),
                  width: active || highlighted ? 1.5 : 1.0,
                ),
                boxShadow: (active || highlighted)
                    ? [
                        BoxShadow(
                          color: active ? AppColors.secondaryGlow : AppColors.primaryGlow,
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Native script badge
                  if (widget.language.id != 'all') ...[
                    Text(
                      widget.language.nativeTitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: active ? Colors.white : AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: active ? Colors.white70 : AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.language.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.bold : FontWeight.w600,
                      color: active
                          ? Colors.white
                          : (highlighted ? Colors.white : AppColors.textSecondary),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
