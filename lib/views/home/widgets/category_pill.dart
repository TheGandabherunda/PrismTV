import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/category_model.dart';

class CategoryPill extends StatefulWidget {
  final CategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryPill({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<CategoryPill> createState() => _CategoryPillState();
}

class _CategoryPillState extends State<CategoryPill> {
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: active ? AppColors.activeTabGradient : null,
                color: active
                    ? null
                    : (highlighted ? AppColors.surfaceHover : AppColors.surfaceCard),
                borderRadius: BorderRadius.circular(22),
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
                  Icon(
                    widget.category.icon,
                    size: 16,
                    color: active
                        ? Colors.white
                        : (highlighted ? AppColors.primary : AppColors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.category.title,
                    style: TextStyle(
                      fontSize: 13,
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
