import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import 'home_controller.dart';
import 'widgets/category_pill.dart';
import 'widgets/channel_card.dart';
import 'widgets/epg_preview_bar.dart';
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
              isAuthenticated: controller.isAuthenticated,
              onAuthAction: controller.onProfileTapped,
            ),
          ),

          // Main TV Content Area
          Expanded(
            child: Obx(() {
              // If user selected Movies or Shows (future sources)
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
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
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.unfocusedBorder),
                    ),
                    child: Obx(
                      () => Text(
                        '${controller.filteredChannels.length} CHANNELS',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Current Clock
              Text(
                currentTime,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Category Pills Carousel
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
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

          const SizedBox(height: 20),

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
                        'No channels found in this category',
                        style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 1.35,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
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

          const SizedBox(height: 16),

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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.prismGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(child: Icon(icon, size: 40, color: Colors.white)),
            ),
            const SizedBox(height: 24),
            Text(
              '$title Hub Ready',
              style: const TextStyle(
                fontSize: 24,
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

