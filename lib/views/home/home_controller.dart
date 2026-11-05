import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/ambient_color_service.dart';
import '../../core/storage/hive_service.dart';
import '../../data/models/auth_session.dart';
import '../../data/models/category_model.dart';
import '../../data/models/channel_model.dart';
import '../../data/models/epg_program_model.dart';
import '../../data/models/language_model.dart';
import '../../data/models/quality_option.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/channel_repository.dart';
import '../../routes/app_routes.dart';
import '../player/player_controller.dart';
import '../player/widgets/resolution_dialog.dart';
import 'widgets/account_dialog.dart';
import 'widgets/settings_dialog.dart';

class HomeController extends GetxController {
  final ChannelRepository _channelRepo = Get.find<ChannelRepository>();
  final AuthRepository _authRepo = Get.find<AuthRepository>();

  final RxList<ChannelModel> allChannels = <ChannelModel>[].obs;
  final RxList<ChannelModel> filteredChannels = <ChannelModel>[].obs;

  final List<LanguageModel> languages = LanguageModel.defaultLanguages;
  final Rx<LanguageModel> selectedLanguage = LanguageModel.defaultLanguages.first.obs;
  final RxSet<String> selectedLanguageIds = <String>{'all'}.obs;

  final List<CategoryModel> categories = CategoryModel.defaultCategories;
  final Rx<CategoryModel> selectedCategory = CategoryModel.defaultCategories.first.obs;
  final RxSet<String> selectedCategoryIds = <String>{'all'}.obs;

  // Ordered list of categorized channel sections for category-wise splitting
  final RxList<MapEntry<CategoryModel, List<ChannelModel>>> categorizedSections =
      <MapEntry<CategoryModel, List<ChannelModel>>>[].obs;

  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  final Rxn<ChannelModel> focusedChannel = Rxn<ChannelModel>();
  final Rxn<EpgProgramModel> currentProgram = Rxn<EpgProgramModel>();
  final Rx<AmbientPalette> ambientPalette = AmbientPalette.defaultPalette.obs;
  Timer? _unfocusTimer;

  String? get activeArtworkUrl {
    final poster = currentProgram.value?.posterUrl;
    if (poster != null && poster.trim().isNotEmpty) return poster;
    return focusedChannel.value?.fullLogoUrl;
  }

  final RxBool isLoadingChannels = true.obs;
  final RxBool isLoadingEpg = false.obs;
  final RxBool isAuthenticated = false.obs;

  // Stream Resolution Settings (defaults to Auto)
  final Rx<QualityOption> defaultQuality = QualityOption.defaultOptions.first.obs;

  @override
  void onInit() {
    super.onInit();
    selectedLanguage.value = languages.first; // Defaults to All Languages
    selectedCategory.value = categories.first; // Defaults to All Channels
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
    _unfocusTimer?.cancel();
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadChannels() async {
    isLoadingChannels.value = true;
    try {
      final list = await _channelRepo.getChannels();
      allChannels.assignAll(list);
      HiveService.saveCachedChannels(list);
      _filterChannels();
    } catch (_) {}
    isLoadingChannels.value = false;
  }

  void selectLanguage(LanguageModel language) {
    toggleLanguage(language.id);
  }

  void toggleLanguage(String id) {
    if (id == 'all') {
      selectedLanguageIds.assignAll(['all']);
    } else {
      selectedLanguageIds.remove('all');
      if (selectedLanguageIds.contains(id)) {
        selectedLanguageIds.remove(id);
        if (selectedLanguageIds.isEmpty) {
          selectedLanguageIds.add('all');
        }
      } else {
        selectedLanguageIds.add(id);
      }
    }
    final firstId = selectedLanguageIds.first;
    selectedLanguage.value = languages.firstWhereOrNull((l) => l.id == firstId) ?? languages.first;
    _filterChannels();
    _refreshFocusedChannel();
  }

  void resetLanguageFilter() {
    selectedLanguageIds.assignAll(['all']);
    selectedLanguage.value = languages.first;
    _filterChannels();
    _refreshFocusedChannel();
  }

  void selectCategory(CategoryModel category) {
    toggleCategory(category.id);
  }

  void toggleCategory(String id) {
    if (id == 'all') {
      selectedCategoryIds.assignAll(['all']);
    } else {
      selectedCategoryIds.remove('all');
      if (selectedCategoryIds.contains(id)) {
        selectedCategoryIds.remove(id);
        if (selectedCategoryIds.isEmpty) {
          selectedCategoryIds.add('all');
        }
      } else {
        selectedCategoryIds.add(id);
      }
    }
    final firstId = selectedCategoryIds.first;
    selectedCategory.value = categories.firstWhereOrNull((c) => c.id == firstId) ?? categories.first;
    _filterChannels();
    _refreshFocusedChannel();
  }

  void resetCategoryFilter() {
    selectedCategoryIds.assignAll(['all']);
    selectedCategory.value = categories.first;
    _filterChannels();
    _refreshFocusedChannel();
  }

  void resetAllFilters() {
    selectedLanguageIds.assignAll(['all']);
    selectedCategoryIds.assignAll(['all']);
    selectedLanguage.value = languages.first;
    selectedCategory.value = categories.first;
    searchController.clear();
    searchQuery.value = '';
    _filterChannels();
    _refreshFocusedChannel();
  }

  void _refreshFocusedChannel() {
    if (focusedChannel.value != null && !filteredChannels.contains(focusedChannel.value)) {
      focusedChannel.value = null;
      currentProgram.value = null;
      ambientPalette.value = AmbientPalette.defaultPalette;
    }
  }

  String get languageDropdownLabel {
    if (selectedLanguageIds.contains('all') || selectedLanguageIds.isEmpty) {
      return 'All Languages';
    }
    if (selectedLanguageIds.length == 1) {
      final lang = languages.firstWhereOrNull((l) => l.id == selectedLanguageIds.first);
      return lang?.title ?? '1 Language';
    }
    return '${selectedLanguageIds.length} Languages';
  }

  String get categoryDropdownLabel {
    if (selectedCategoryIds.contains('all') || selectedCategoryIds.isEmpty) {
      return 'All Categories';
    }
    if (selectedCategoryIds.length == 1) {
      final cat = categories.firstWhereOrNull((c) => c.id == selectedCategoryIds.first);
      return cat?.title ?? '1 Category';
    }
    return '${selectedCategoryIds.length} Categories';
  }

  int get activeFilterCount {
    int count = 0;
    if (!selectedLanguageIds.contains('all') && selectedLanguageIds.isNotEmpty) {
      count += selectedLanguageIds.length;
    }
    if (!selectedCategoryIds.contains('all') && selectedCategoryIds.isNotEmpty) {
      count += selectedCategoryIds.length;
    }
    return count;
  }

  bool get hasActiveFilters => activeFilterCount > 0;

  void onSearchChanged(String query) {
    searchQuery.value = query;
    _filterChannels();
    _refreshFocusedChannel();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    _filterChannels();
    _refreshFocusedChannel();
  }

  void _filterChannels() {
    final query = searchQuery.value.trim().toLowerCase();
    final isAllLangs = selectedLanguageIds.contains('all') || selectedLanguageIds.isEmpty;
    final isAllCats = selectedCategoryIds.contains('all') || selectedCategoryIds.isEmpty;

    // Resolve matching language IDs
    final selectedJioLangIds = <int>{};
    if (!isAllLangs) {
      for (final id in selectedLanguageIds) {
        final lang = languages.firstWhereOrNull((l) => l.id == id);
        if (lang?.jioLanguageId != null) {
          selectedJioLangIds.add(lang!.jioLanguageId!);
        }
      }
    }

    // 1. Filter all channels by language and search query
    final channelsMatchingLangAndSearch = allChannels.where((c) {
      final matchesLang = isAllLangs || selectedJioLangIds.contains(c.languageId);
      if (!matchesLang) return false;

      if (query.isEmpty) return true;
      final nameMatches = c.channelName.toLowerCase().contains(query);
      final idMatches = c.channelId.toString().contains(query);
      final langMatches = c.languageName.toLowerCase().contains(query);
      final catMatches = c.categoryName.toLowerCase().contains(query);
      return nameMatches || idMatches || langMatches || catMatches;
    }).toList();

    // 2. Build categorizedSections for category-wise splitting
    final sections = <MapEntry<CategoryModel, List<ChannelModel>>>[];

    for (final cat in categories) {
      if (cat.id == 'all') continue;
      if (!isAllCats && !selectedCategoryIds.contains(cat.id)) continue;

      final catChannels = channelsMatchingLangAndSearch.where((c) {
        if (cat.id == 'favorites') {
          return c.isFavorite;
        }
        if (cat.jioCategoryId != null) {
          return c.categoryId == cat.jioCategoryId;
        }
        return c.categoryName.toLowerCase() == cat.title.toLowerCase();
      }).toList();

      if (catChannels.isNotEmpty) {
        sections.add(MapEntry(cat, catChannels));
      }
    }

    categorizedSections.assignAll(sections);

    // 3. Flat filtered list (for fallback or count)
    if (isAllCats) {
      filteredChannels.assignAll(channelsMatchingLangAndSearch);
    } else {
      final flat = <ChannelModel>[];
      for (final entry in sections) {
        flat.addAll(entry.value);
      }
      filteredChannels.assignAll(flat);
    }
  }

  Future<void> onChannelFocused(ChannelModel channel) async {
    _unfocusTimer?.cancel();
    if (focusedChannel.value?.channelId == channel.channelId) return;

    focusedChannel.value = channel;
    isLoadingEpg.value = true;

    // 1. Instant response: check if event/channel palette is already cached, else start with category seed
    final cached = AmbientColorService.getCached(channel.channelName);
    ambientPalette.value = cached ?? AmbientColorService.getSeedPalette(
      channel.channelName,
      channel.categoryName,
    );

    try {
      final epg = await _channelRepo.getEpg(channel.channelId);
      if (focusedChannel.value?.channelId == channel.channelId) {
        final prog = epg.nowPlayingOrUpcoming;
        currentProgram.value = prog;

        // 2. Extract rich dynamic ambient palette directly from event photo artwork
        final poster = prog?.posterUrl;
        final targetImg = (poster != null && poster.trim().isNotEmpty)
            ? poster
            : channel.fullLogoUrl;

        final pal = await AmbientColorService.extractPalette(
          targetImg,
          fallbackLogoUrl: channel.fullLogoUrl,
          categoryName: channel.categoryName,
          channelName: channel.channelName,
        );

        if (focusedChannel.value?.channelId == channel.channelId) {
          ambientPalette.value = pal;
        }
      }
    } catch (_) {
      if (focusedChannel.value?.channelId == channel.channelId) {
        currentProgram.value = null;
      }
    } finally {
      if (focusedChannel.value?.channelId == channel.channelId) {
        isLoadingEpg.value = false;
      }
    }
  }

  void onChannelUnfocused(ChannelModel channel) {
    if (focusedChannel.value?.channelId == channel.channelId) {
      _unfocusTimer?.cancel();
      // Snappy 40ms debounce: bridges card gaps seamlessly, but returns to default immediately when exiting shelf
      _unfocusTimer = Timer(const Duration(milliseconds: 40), () {
        if (focusedChannel.value?.channelId == channel.channelId) {
          focusedChannel.value = null;
          currentProgram.value = null;
          ambientPalette.value = AmbientPalette.defaultPalette;
        }
      });
    }
  }

  Future<void> toggleFavorite(ChannelModel channel) async {
    await _channelRepo.toggleFavorite(channel);
    allChannels.refresh();
    _filterChannels();
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
    final pc = Get.find<PlayerController>();
    pc.isMinimized.value = false;
    pc.channelList = filteredChannels.toList();
    pc.switchChannel(channel);
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

  AuthSession? get currentSession => _authRepo.getCurrentSession();

  void openSettingsDialog() {
    Get.dialog(
      SettingsDialog(controller: this),
      barrierColor: Colors.black.withValues(alpha: 0.65),
    );
  }

  void _showAccountDialog() {
    Get.dialog(
      AccountDialog(controller: this),
      barrierColor: Colors.black.withValues(alpha: 0.65),
    );
  }

  void setDefaultQuality(QualityOption opt) {
    defaultQuality.value = opt;
    HiveService.setPreferredQualityOption(opt);
    if (Get.isRegistered<PlayerController>()) {
      final pc = Get.find<PlayerController>();
      pc.selectedQualityOption.value = opt;
      pc.selectedQuality.value = opt.id == 'auto' ? 'Auto' : '${opt.targetHeight}p';
    }
  }

  void logout() async {
    await _authRepo.logout();
    isAuthenticated.value = false;
    Get.offAllNamed(AppRoutes.auth);
  }
}
