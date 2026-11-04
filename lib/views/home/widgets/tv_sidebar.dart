import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

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
      width: 72,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          right: BorderSide(color: AppColors.unfocusedBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Mini Logo
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppColors.prismGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.stream_rounded, size: 24, color: Colors.white),
            ),
          ),
          const SizedBox(height: 36),

          // Nav Items
          ...List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = selectedIndex == index;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Focus(
                child: Builder(
                  builder: (ctx) {
                    final hasFocus = Focus.of(ctx).hasFocus;
                    return InkWell(
                      onTap: () => onSelect(index),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: hasFocus
                              ? AppColors.focusedBackground
                              : (isSelected ? AppColors.primaryGlow : Colors.transparent),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: hasFocus
                                ? AppColors.primary
                                : (isSelected ? AppColors.primary : Colors.transparent),
                            width: hasFocus ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            item.icon,
                            color: hasFocus || isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 24,
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
            padding: const EdgeInsets.only(bottom: 24),
            child: Focus(
              child: Builder(
                builder: (ctx) {
                  final hasFocus = Focus.of(ctx).hasFocus;
                  return InkWell(
                    onTap: onAuthAction,
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: hasFocus ? AppColors.focusedBackground : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: hasFocus ? AppColors.primary : Colors.transparent,
                          width: hasFocus ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          isAuthenticated ? Icons.account_circle_rounded : Icons.login_rounded,
                          color: isAuthenticated ? AppColors.primary : AppColors.textSecondary,
                          size: 26,
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

