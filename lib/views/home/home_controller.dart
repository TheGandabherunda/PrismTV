import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/storage/hive_service.dart';
import '../../data/models/category_model.dart';
import '../../data/models/channel_model.dart';
import '../../data/models/epg_program_model.dart';
import '../../data/models/language_model.dart';
import '../../data/models/quality_option.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/channel_repository.dart';
import '../../routes/app_routes.dart';
import '../player/widgets/resolution_dialog.dart';

class HomeController extends GetxController {
  final ChannelRepository _channelRepo = Get.find<ChannelRepository>();
  final AuthRepository _authRepo = Get.find<AuthRepository>();

  final RxList<ChannelModel> allChannels = <ChannelModel>[].obs;
  final RxList<ChannelModel> filteredChannels = <ChannelModel>[].obs;

  final List<LanguageModel> languages = LanguageModel.defaultLanguages;
  late final Rx<LanguageModel> selectedLanguage;

  final List<CategoryModel> categories = CategoryModel.defaultCategories;
  late final Rx<CategoryModel> selectedCategory;

  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  final RxInt selectedSidebarIndex = 0.obs;
  final Rxn<ChannelModel> focusedChannel = Rxn<ChannelModel>();
  final Rxn<EpgProgramModel> currentProgram = Rxn<EpgProgramModel>();

  final RxBool isLoadingChannels = true.obs;
  final RxBool isLoadingEpg = false.obs;
  final RxBool isAuthenticated = false.obs;

  // Stream Resolution Settings (defaults to Auto)
  final Rx<QualityOption> defaultQuality = QualityOption.defaultOptions.first.obs;

  @override
  void onInit() {
    super.onInit();
    selectedLanguage = languages.first.obs; // Defaults to All Languages
    selectedCategory = categories.first.obs; // Defaults to All Channels
    defaultQuality.value = HiveService.getPreferredQualityOption();
    isAuthenticated.value = _authRepo.isAuthenticated;

    if (!isAuthenticated.value) {
      Future.microtask(() => Get.offAllNamed(AppRoutes.auth));
      return;
    }
    loadChannels();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
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

  void selectLanguage(LanguageModel language) {
    selectedLanguage.value = language;
    _filterChannels();
    if (filteredChannels.isNotEmpty) {
      onChannelFocused(filteredChannels.first);
    } else {
      focusedChannel.value = null;
      currentProgram.value = null;
    }
  }

  void selectCategory(CategoryModel category) {
    selectedCategory.value = category;
    _filterChannels();
    if (filteredChannels.isNotEmpty) {
      onChannelFocused(filteredChannels.first);
    } else {
      focusedChannel.value = null;
      currentProgram.value = null;
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    _filterChannels();
    if (filteredChannels.isNotEmpty) {
      onChannelFocused(filteredChannels.first);
    } else {
      focusedChannel.value = null;
      currentProgram.value = null;
    }
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
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
    final lang = selectedLanguage.value;
    final cat = selectedCategory.value;
    final query = searchQuery.value.trim().toLowerCase();

    final filtered = allChannels.where((c) {
      // 1. Language Filter
      final bool matchesLang;
      if (lang.id == 'all' || lang.jioLanguageId == null) {
        matchesLang = true;
      } else {
        matchesLang = c.languageId == lang.jioLanguageId;
      }

      // 2. Category Filter
      final bool matchesCat;
      if (cat.id == 'all') {
        matchesCat = true;
      } else if (cat.id == 'favorites') {
        matchesCat = c.isFavorite;
      } else if (cat.jioCategoryId != null) {
        matchesCat = c.categoryId == cat.jioCategoryId;
      } else {
        matchesCat = true;
      }

      // 3. Search Filter
      final bool matchesSearch;
      if (query.isEmpty) {
        matchesSearch = true;
      } else {
        final nameMatches = c.channelName.toLowerCase().contains(query);
        final idMatches = c.channelId.toString().contains(query);
        final langMatches = c.languageName.toLowerCase().contains(query);
        final catMatches = c.categoryName.toLowerCase().contains(query);
        matchesSearch = nameMatches || idMatches || langMatches || catMatches;
      }

      return matchesLang && matchesCat && matchesSearch;
    }).toList();

    filteredChannels.assignAll(filtered);
  }

  Future<void> onChannelFocused(ChannelModel channel) async {
    focusedChannel.value = channel;
    isLoadingEpg.value = true;
    try {
      final epg = await _channelRepo.getEpg(channel.channelId);
      if (epg.isNotEmpty) {
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
    _filterChannels();
  }

  Future<void> setDefaultQuality(QualityOption option) async {
    defaultQuality.value = option;
    await HiveService.setPreferredQualityOption(option);
  }

  void showDefaultQualityPicker() {
    Get.dialog(
      ResolutionDialog(
        currentOption: defaultQuality.value,
        onSelect: (opt) => setDefaultQuality(opt),
        title: 'DEFAULT STREAM RESOLUTION',
        subtitle: 'New streams will default to this resolution',
      ),
      barrierColor: const Color(0x99000000),
    );
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
        'preferredQuality': defaultQuality.value,
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
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.unfocusedBorder),
          ),
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
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.unfocusedBorder),
                ),
                child: Column(
                  children: [
                    _infoRow('Subscriber ID', session?.crmid.isNotEmpty == true ? session!.crmid : 'Active'),
                    const Divider(color: AppColors.unfocusedBorder, height: 16),
                    _infoRow('Service Tier', 'PrismTV Live Streaming'),
                    const Divider(color: AppColors.unfocusedBorder, height: 16),
                    _infoRow('Device Target', 'PrismTV Smart TV / Web'),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Default Quality Setting Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.unfocusedBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.prismGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(Icons.tune_rounded, size: 20, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Default Resolution',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Auto-selected on playback',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    // Clickable Quality Selector Pill
                    Focus(
                      child: Builder(
                        builder: (ctx) {
                          final hasFocus = Focus.of(ctx).hasFocus;
                          return InkWell(
                            onTap: () => showDefaultQualityPicker(),
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: hasFocus ? AppColors.focusedBackground : AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: hasFocus ? AppColors.primary : AppColors.unfocusedBorder,
                                  width: hasFocus ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Obx(
                                    () => Text(
                                      defaultQuality.value.label.split(' ')[0], // e.g. "Auto" or "1080p"
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: hasFocus ? Colors.white : AppColors.primaryLight,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.primaryLight),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
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
                        backgroundColor: AppColors.liveRed,
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
