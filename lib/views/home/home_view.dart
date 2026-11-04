import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/widgets/prism_triangle_logo.dart';
import 'home_controller.dart';
import 'widgets/category_pill.dart';
import 'widgets/channel_card.dart';
import 'widgets/epg_preview_bar.dart';
import 'widgets/language_pill.dart';
import 'widgets/tv_sidebar.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Collapsible Left TV Remote Sidebar
          Obx(
            () => TvSidebar(
              selectedIndex: controller.selectedSidebarIndex.value,
              onSelect: controller.selectSidebar,
              isAuthenticated: controller.isAuthenticated.value,
              onAuthAction: controller.onProfileTapped,
            ),
          ),

          // Main TV Content Area
          Expanded(
            child: Obx(() {
              if (controller.selectedSidebarIndex.value == 1) {
                return _buildFutureSourceView('Movies', Icons.movie_creation_rounded);
              }
              if (controller.selectedSidebarIndex.value == 2) {
                return _buildFutureSourceView('TV Series & Shows', Icons.tv_rounded);
              }

              return _buildLiveTvView();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTvView() {
    final currentTime = DateFormat('hh:mm a').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.tvMarginHorizontal / 2,
        AppDimens.tvMarginVertical,
        AppDimens.tvMarginHorizontal,
        AppDimens.tvMarginVertical,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Navigation / Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Brand & Channel Count
              Row(
                children: [
                  const PrismTriangleLogo(size: 26, hasGlow: true),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (bounds) => AppColors.prismGradient.createShader(bounds),
                    child: const Text(
                      'PRISM TV',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.unfocusedBorder),
                    ),
                    child: Obx(() {
                      final count = controller.filteredChannels.length;
                      final lang = controller.selectedLanguage.value;
                      final label = lang.id == 'all'
                          ? '$count CHANNELS'
                          : '$count ${lang.title.toUpperCase()}';
                      return Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.primaryLight,
                        ),
                      );
                    }),
                  ),
                ],
              ),

              // Search Bar & Clock
              Row(
                children: [
                  // Fast Instant Search Box
                  Container(
                    width: 220,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.unfocusedBorder),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controller.searchController,
                            onChanged: controller.onSearchChanged,
                            style: const TextStyle(fontSize: 13, color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Search channel...',
                              hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        Obx(
                          () => controller.searchQuery.value.isNotEmpty
                              ? GestureDetector(
                                  onTap: controller.clearSearch,
                                  child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Current Clock
                  Text(
                    currentTime,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Filter Row 1: Languages (All, Kannada, English, Hindi, Tamil, Telugu, etc.)
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.languages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final lang = controller.languages[index];
                return Obx(
                  () => LanguagePill(
                    language: lang,
                    isSelected: controller.selectedLanguage.value.id == lang.id,
                    onTap: () => controller.selectLanguage(lang),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Filter Row 2: Categories / Genres (All, Favorites, Entertainment, Movies, etc.)
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = controller.categories[index];
                return Obx(
                  () => CategoryPill(
                    category: cat,
                    isSelected: controller.selectedCategory.value.id == cat.id,
                    onTap: () => controller.selectCategory(cat),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Channels Grid
          Expanded(
            child: Obx(() {
              if (controller.isLoadingChannels.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (controller.filteredChannels.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tv_off_rounded, size: 54, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      const Text(
                        'No channels found matching the selected filters',
                        style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.primaryLight),
                        label: const Text(
                          'Reset All Filters',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.unfocusedBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: () {
                          controller.clearSearch();
                          controller.selectLanguage(controller.languages.first);
                          controller.selectCategory(controller.categories.first);
                        },
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 1.35,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: controller.filteredChannels.length,
                itemBuilder: (context, index) {
                  final channel = controller.filteredChannels[index];
                  return ChannelCard(
                    channel: channel,
                    onTap: () => controller.playChannel(channel),
                    onFocusChange: (focused) {
                      if (focused) {
                        controller.onChannelFocused(channel);
                      }
                    },
                    onFavoriteToggle: () => controller.toggleFavorite(channel),
                  );
                },
              );
            }),
          ),

          const SizedBox(height: 12),

          // Bottom EPG Preview Bar
          Obx(
            () => EpgPreviewBar(
              channel: controller.focusedChannel.value,
              program: controller.currentProgram.value,
              isLoading: controller.isLoadingEpg.value,
              onWatchTap: () {
                if (controller.focusedChannel.value != null) {
                  controller.playChannel(controller.focusedChannel.value!);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFutureSourceView(String title, IconData icon) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.unfocusedBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: AppColors.prismGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.primaryGlow,
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(child: Icon(icon, size: 38, color: Colors.white)),
            ),
            const SizedBox(height: 22),
            Text(
              '$title Hub Ready',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'PrismTV’s decoupled source architecture is ready. When you add your $title provider API or The Kannada Talkies archive, it seamlessly populates here without UI changes.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
