import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/category_model.dart';
import '../../data/models/channel_model.dart';
import '../../data/models/epg_program_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/channel_repository.dart';
import '../../routes/app_routes.dart';

class HomeController extends GetxController {
  final ChannelRepository _channelRepo = Get.find<ChannelRepository>();
  final AuthRepository _authRepo = Get.find<AuthRepository>();

  final RxList<ChannelModel> allChannels = <ChannelModel>[].obs;
  final RxList<ChannelModel> filteredChannels = <ChannelModel>[].obs;

  final List<CategoryModel> categories = CategoryModel.defaultCategories;
  late final Rx<CategoryModel> selectedCategory;

  final RxInt selectedSidebarIndex = 0.obs;
  final Rxn<ChannelModel> focusedChannel = Rxn<ChannelModel>();
  final Rxn<EpgProgramModel> currentProgram = Rxn<EpgProgramModel>();

  final RxBool isLoadingChannels = true.obs;
  final RxBool isLoadingEpg = false.obs;
  final RxBool isAuthenticated = false.obs;

  @override
  void onInit() {
    super.onInit();
    selectedCategory = categories.first.obs;
    isAuthenticated.value = _authRepo.isAuthenticated;
    if (!isAuthenticated.value) {
      Future.microtask(() => Get.offAllNamed(AppRoutes.auth));
      return;
    }
    loadChannels();
  }

  Future<void> loadChannels() async {
    isLoadingChannels.value = true;
    try {
      final list = await _channelRepo.getChannels();
      allChannels.assignAll(list);
      _filterChannels();

      if (filteredChannels.isNotEmpty) {
        onChannelFocused(filteredChannels.first);
      }
    } catch (_) {}
    isLoadingChannels.value = false;
  }

  void selectCategory(CategoryModel category) {
    selectedCategory.value = category;
    _filterChannels();
    if (filteredChannels.isNotEmpty) {
      onChannelFocused(filteredChannels.first);
    }
  }

  void selectSidebar(int index) {
    selectedSidebarIndex.value = index;
    if (index == 3) {
      // Favorites tab
      selectCategory(categories.firstWhere((c) => c.id == 'favorites'));
    } else if (index == 0) {
      // Live TV tab
      selectCategory(categories.first);
    }
  }

  void _filterChannels() {
    final cat = selectedCategory.value;
    if (cat.id == 'all') {
      filteredChannels.assignAll(allChannels);
    } else if (cat.id == 'favorites') {
      filteredChannels.assignAll(allChannels.where((c) => c.isFavorite));
    } else if (cat.jioLanguageId != null) {
      filteredChannels.assignAll(allChannels.where((c) => c.languageId == cat.jioLanguageId));
    } else if (cat.jioCategoryId != null) {
      filteredChannels.assignAll(allChannels.where((c) => c.categoryId == cat.jioCategoryId));
    } else {
      filteredChannels.assignAll(allChannels);
    }
  }

  Future<void> onChannelFocused(ChannelModel channel) async {
    focusedChannel.value = channel;
    isLoadingEpg.value = true;
    try {
      final epg = await _channelRepo.getEpg(channel.channelId);
      if (epg.isNotEmpty) {
        // Find current live program or fallback to first
        currentProgram.value = epg.firstWhere(
          (p) => p.isNowPlaying,
          orElse: () => epg.first,
        );
      } else {
        currentProgram.value = null;
      }
    } catch (_) {
      currentProgram.value = null;
    }
    isLoadingEpg.value = false;
  }

  Future<void> toggleFavorite(ChannelModel channel) async {
    await _channelRepo.toggleFavorite(channel);
    allChannels.refresh();
    filteredChannels.refresh();
  }

  void playChannel(ChannelModel channel) {
    if (!_authRepo.isAuthenticated) {
      Get.toNamed(AppRoutes.auth);
      return;
    }
    Get.toNamed(
      AppRoutes.player,
      arguments: {
        'channel': channel,
        'channelList': filteredChannels.toList(),
      },
    );
  }

  void onProfileTapped() {
    isAuthenticated.value = _authRepo.isAuthenticated;
    if (isAuthenticated.value) {
      _showAccountDialog();
    } else {
      Get.toNamed(AppRoutes.auth);
    }
  }

  void _showAccountDialog() {
    final session = _authRepo.getCurrentSession();

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  gradient: AppColors.prismGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, size: 36, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'PrismTV Profile',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                session?.mobileNumber ?? 'Connected User',
                style: const TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.unfocusedBorder),
                ),
                child: Column(
                  children: [
                    _infoRow('Subscriber ID', session?.crmid.isNotEmpty == true ? session!.crmid : 'Active'),
                    const Divider(color: AppColors.unfocusedBorder, height: 16),
                    _infoRow('Service Tier', 'PrismTV Live Streaming'),
                    const Divider(color: AppColors.unfocusedBorder, height: 16),
                    _infoRow('Device Target', 'PrismTV Smart TV'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.unfocusedBorder),
                      ),
                      onPressed: () => Get.back(),
                      child: const Text('Back', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Get.back();
                        logout();
                      },
                      child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }

  void logout() async {
    await _authRepo.logout();
    isAuthenticated.value = false;
    Get.offAllNamed(AppRoutes.auth);
  }
}

