import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/prism_triangle_logo.dart';

class TvSidebarItem {
  final IconData icon;
  final String title;

  const TvSidebarItem({required this.icon, required this.title});
}

class TvSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool isAuthenticated;
  final VoidCallback onAuthAction;

  const TvSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.isAuthenticated,
    required this.onAuthAction,
  });

  static const List<TvSidebarItem> items = [
    TvSidebarItem(icon: Icons.live_tv_rounded, title: 'Live TV'),
    TvSidebarItem(icon: Icons.movie_outlined, title: 'Movies'),
    TvSidebarItem(icon: Icons.tv_rounded, title: 'Series'),
    TvSidebarItem(icon: Icons.favorite_border_rounded, title: 'Favorites'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.unfocusedBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Mini Brand Triangle Logo
          const PrismTriangleLogo(size: 30, hasGlow: true),
          const SizedBox(height: 32),

          // Nav Items
          ...List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = selectedIndex == index;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Focus(
                child: Builder(
                  builder: (ctx) {
                    final hasFocus = Focus.of(ctx).hasFocus;
                    return InkWell(
                      onTap: () => onSelect(index),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppColors.activeTabGradient : null,
                          color: hasFocus
                              ? AppColors.focusedBackground
                              : (isSelected ? null : Colors.transparent),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasFocus
                                ? AppColors.primary
                                : (isSelected ? Colors.transparent : Colors.transparent),
                            width: hasFocus ? 2 : 1,
                          ),
                          boxShadow: (isSelected || hasFocus)
                              ? const [
                                  BoxShadow(
                                    color: AppColors.primaryGlow,
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Icon(
                            item.icon,
                            color: isSelected
                                ? Colors.white
                                : (hasFocus ? AppColors.primaryLight : AppColors.textSecondary),
                            size: 22,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }),

          const Spacer(),

          // Auth / Settings Button
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Focus(
              child: Builder(
                builder: (ctx) {
                  final hasFocus = Focus.of(ctx).hasFocus;
                  return InkWell(
                    onTap: onAuthAction,
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: hasFocus ? AppColors.focusedBackground : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasFocus ? AppColors.primary : Colors.transparent,
                          width: hasFocus ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          isAuthenticated ? Icons.account_circle_rounded : Icons.login_rounded,
                          color: isAuthenticated ? AppColors.primaryLight : AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
