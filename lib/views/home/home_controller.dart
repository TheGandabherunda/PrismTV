import 'package:get/get.dart';
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

  @override
  void onInit() {
    super.onInit();
    selectedCategory = categories.first.obs;
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

  bool get isAuthenticated => _authRepo.isAuthenticated;

  void openAuthScreen() {
    Get.toNamed(AppRoutes.auth);
  }

  void logout() async {
    await _authRepo.logout();
    Get.offAllNamed(AppRoutes.auth);
  }
}

