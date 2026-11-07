import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/app_update_service.dart';
import '../../../core/storage/hive_service.dart';
import '../../../data/models/quality_option.dart';
import '../home_controller.dart';

class SettingsDialog extends StatefulWidget {
  final HomeController controller;

  const SettingsDialog({super.key, required this.controller});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  int _activeTabIndex = 0;
  late final TextEditingController _serverController;

  @override
  void initState() {
    super.initState();
    _serverController = TextEditingController(text: HiveService.getCustomProxyUrl() ?? '');
  }

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 16 : 24,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            width: isMobile ? double.infinity : 780,
            height: isMobile ? MediaQuery.of(context).size.height * 0.88 : 590,
            decoration: BoxDecoration(
              color: const Color(0xF210121C),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.70),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              children: [
                // 1. Header Bar: Icon, Title, and Close Button
                _buildHeader(),

                // 2. Navigation Tabs Bar (Remote D-Pad Navigable)
                _buildTabsBar(isMobile),

                const Divider(height: 1, color: Color(0x1FFFFFFF)),

                // 3. Tab Content Body
                Expanded(
                  child: IndexedStack(
                    index: _activeTabIndex,
                    children: [
                      _buildCategoriesTab(isMobile),
                      _buildLanguagesTab(isMobile),
                      _buildResolutionTab(),
                      _buildStreamServerTab(),
                      _buildRemoteGuideTab(),
                      _buildUpdatesTab(isMobile),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF7B60), Color(0xFFA839C7)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.settings_rounded, size: 20, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings & Preferences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Filters, streaming quality, server endpoint & remote controls guide',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.select ||
                    event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.space ||
                    event.logicalKey == LogicalKeyboardKey.gameButtonA ||
                    event.logicalKey == LogicalKeyboardKey.gameButtonSelect ||
                    event.logicalKey == LogicalKeyboardKey.accept) {
                  Get.back();
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: Builder(
              builder: (ctx) {
                final hasFocus = Focus.of(ctx).hasFocus;
                return IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: hasFocus ? Colors.white : Colors.white70,
                  ),
                  onPressed: () => Get.back(),
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsBar(bool isMobile) {
    final tabs = [
      {'title': 'Categories', 'icon': Icons.category_rounded},
      {'title': 'Languages', 'icon': Icons.translate_rounded},
      {'title': 'Resolution', 'icon': Icons.hd_rounded},
      {'title': 'Stream Server', 'icon': Icons.dns_rounded},
      {'title': 'Remote & Keys', 'icon': Icons.settings_remote_rounded},
      {'title': 'Updates', 'icon': Icons.system_update_rounded},
    ];

    Widget buildTabItem(int index) {
      final isSelected = _activeTabIndex == index;
      final tab = tabs[index];

      return Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space) {
              setState(() => _activeTabIndex = index);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Builder(
          builder: (ctx) {
            final hasFocus = Focus.of(ctx).hasFocus;
            return InkWell(
              onTap: () => setState(() => _activeTabIndex = index),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 6,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.12)
                      : (hasFocus ? Colors.white.withValues(alpha: 0.08) : Colors.transparent),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasFocus
                        ? Colors.white
                        : (isSelected
                            ? AppColors.primaryLight.withValues(alpha: 0.5)
                            : Colors.transparent),
                    width: hasFocus || isSelected ? 1.4 : 1.0,
                  ),
                  boxShadow: hasFocus
                      ? [
                          BoxShadow(
                            color: AppColors.primaryGlow.withValues(alpha: 0.35),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 15,
                      color: isSelected || hasFocus ? Colors.white : Colors.white54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab['title'] as String,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected || hasFocus ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected || hasFocus ? Colors.white : Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    if (isMobile) {
      return Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(tabs.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: buildTabItem(index),
              );
            }),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(tabs.length, (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: buildTabItem(index),
            ),
          );
        }),
      ),
    );
  }

  // ==========================================
  // TAB 1: CATEGORIES
  // ==========================================
  Widget _buildCategoriesTab(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() {
                final count = widget.controller.selectedCategoryIds.contains('all')
                    ? 'All Selected'
                    : '${widget.controller.selectedCategoryIds.length} Selected';
                return Text(
                  'Select Categories ($count)',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                );
              }),
              Focus(
                child: Builder(
                  builder: (ctx) {
                    final hasFocus = Focus.of(ctx).hasFocus;
                    return TextButton.icon(
                      onPressed: widget.controller.resetCategoryFilter,
                      icon: const Icon(Icons.refresh_rounded, size: 15, color: AppColors.primaryLight),
                      style: TextButton.styleFrom(
                        backgroundColor: hasFocus ? Colors.white.withValues(alpha: 0.10) : null,
                      ),
                      label: const Text(
                        'Select All',
                        style: TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              final selectedIds = widget.controller.selectedCategoryIds;
              final isAll = selectedIds.contains('all');

              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 2 : 3,
                  mainAxisExtent: 48,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: widget.controller.categories.length,
                itemBuilder: (context, index) {
                  final cat = widget.controller.categories[index];
                  final isSelected = isAll ? (cat.id == 'all') : selectedIds.contains(cat.id);

                  return _FilterPillCard(
                    title: cat.title,
                    icon: cat.icon,
                    isSelected: isSelected,
                    onTap: () => widget.controller.toggleCategory(cat.id),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: LANGUAGES
  // ==========================================
  Widget _buildLanguagesTab(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() {
                final count = widget.controller.selectedLanguageIds.contains('all')
                    ? 'All Selected'
                    : '${widget.controller.selectedLanguageIds.length} Selected';
                return Text(
                  'Select Languages ($count)',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                );
              }),
              Focus(
                child: Builder(
                  builder: (ctx) {
                    final hasFocus = Focus.of(ctx).hasFocus;
                    return TextButton.icon(
                      onPressed: widget.controller.resetLanguageFilter,
                      icon: const Icon(Icons.refresh_rounded, size: 15, color: AppColors.primaryLight),
                      style: TextButton.styleFrom(
                        backgroundColor: hasFocus ? Colors.white.withValues(alpha: 0.10) : null,
                      ),
                      label: const Text(
                        'Select All',
                        style: TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              final selectedIds = widget.controller.selectedLanguageIds;
              final isAll = selectedIds.contains('all');

              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 2 : 3,
                  mainAxisExtent: 48,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: widget.controller.languages.length,
                itemBuilder: (context, index) {
                  final lang = widget.controller.languages[index];
                  final isSelected = isAll ? (lang.id == 'all') : selectedIds.contains(lang.id);

                  return _FilterPillCard(
                    title: lang.title,
                    icon: Icons.language_rounded,
                    isSelected: isSelected,
                    onTap: () => widget.controller.toggleLanguage(lang.id),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: RESOLUTION
  // ==========================================
  Widget _buildResolutionTab() {
    final options = QualityOption.defaultOptions;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Default Stream Quality Preference',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Automatically applied when channels and live broadcasts start playing.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final opt = options[index];
                return Obx(() {
                  final isSelected = widget.controller.defaultQuality.value.id == opt.id;

                  return Focus(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.select ||
                            event.logicalKey == LogicalKeyboardKey.enter ||
                            event.logicalKey == LogicalKeyboardKey.space) {
                          widget.controller.setDefaultQuality(opt);
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Builder(
                      builder: (ctx) {
                        final hasFocus = Focus.of(ctx).hasFocus;
                        return InkWell(
                          onTap: () => widget.controller.setDefaultQuality(opt),
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0x28A839C7)
                                  : (hasFocus ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.04)),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: hasFocus
                                    ? Colors.white
                                    : (isSelected
                                        ? AppColors.primaryLight
                                        : Colors.white.withValues(alpha: 0.10)),
                                width: hasFocus || isSelected ? 1.5 : 1.0,
                              ),
                              boxShadow: hasFocus
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primaryGlow.withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: isSelected ? AppColors.prismGradient : null,
                                    color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    opt.badge,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected ? Colors.white : Colors.white70,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    opt.label,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: isSelected || hasFocus ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected || hasFocus ? Colors.white : Colors.white70,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded, color: AppColors.primaryLight, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: STREAM SERVER
  // ==========================================
  Widget _buildStreamServerTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stream Server Endpoint',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Set custom streaming proxy server IP / URL (useful for Smart TVs and remote hosts). Leave blank for default localhost:3000.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT SERVER HOST',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        HiveService.getCustomProxyUrl() ?? 'Default (Local Host http://localhost:3000)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _serverController,
            style: const TextStyle(color: Colors.white, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'http://192.168.1.xxx:3000',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              filled: true,
              fillColor: const Color(0x40161824),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Focus(
                child: Builder(
                  builder: (ctx) {
                    final hasFocus = Focus.of(ctx).hasFocus;
                    return OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        side: BorderSide(color: hasFocus ? Colors.white : Colors.white.withValues(alpha: 0.15)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: hasFocus ? Colors.white.withValues(alpha: 0.10) : null,
                      ),
                      onPressed: () async {
                        _serverController.clear();
                        await HiveService.setCustomProxyUrl(null);
                        setState(() {});
                        widget.controller.loadChannels();
                        Get.snackbar(
                          'Server Reset',
                          'Reset to default stream proxy.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: const Color(0xEE161824),
                          colorText: Colors.white,
                        );
                      },
                      child: const Text('Reset to Default', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    );
                  },
                ),
              ),
              const Spacer(),
              Focus(
                child: Builder(
                  builder: (ctx) {
                    final hasFocus = Focus.of(ctx).hasFocus;
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: hasFocus ? const BorderSide(color: Colors.white, width: 1.5) : null,
                      ),
                      onPressed: () async {
                        final val = _serverController.text.trim();
                        await HiveService.setCustomProxyUrl(val.isEmpty ? null : val);
                        setState(() {});
                        widget.controller.loadChannels();
                        Get.snackbar(
                          'Server Updated',
                          'Stream server endpoint updated successfully.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: const Color(0xEE161824),
                          colorText: Colors.white,
                        );
                      },
                      child: const Text('Save & Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 5: REMOTE & KEYBOARD GUIDE
  // ==========================================
  Widget _buildRemoteGuideTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x28A839C7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryLight.withValues(alpha: 0.35),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.settings_remote_rounded, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Universal TV Remote & Keyboard Controls',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'PrismTV is built from the ground up for Smart TVs, Android TV, and Web. Every button, menu, card, and player control is 100% accessible via D-Pad and shortcuts.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 1: Live Player Controls
          const _GuideSectionHeader(
            title: 'Live TV Player Controls',
            icon: Icons.play_circle_fill_rounded,
          ),
          const SizedBox(height: 10),
          const _GuideKeyRow(keys: ['Down Arrow', 'Key C'], action: 'Open Categorized Channel Tray (browse while watching)'),
          const _GuideKeyRow(keys: ['Up Arrow'], action: 'Show Program Info & Player Header'),
          const _GuideKeyRow(keys: ['Left / Right', 'CH +/-'], action: 'Previous / Next Channel (with live feedback toast)'),
          const _GuideKeyRow(keys: ['OK / Enter', 'Space'], action: 'Toggle Play / Pause & Show Controls'),
          const _GuideKeyRow(keys: ['0 - 9'], action: 'Direct Channel Number Dialing (e.g. 1 0 4)'),
          const _GuideKeyRow(keys: ['Key Q'], action: 'Open Stream Quality Dialog (1080p, 720p, etc.)'),
          const _GuideKeyRow(keys: ['Key A'], action: 'Open Multi-Audio Language Selector'),
          const _GuideKeyRow(keys: ['Key M'], action: 'Toggle Mute / Unmute Audio'),
          const _GuideKeyRow(keys: ['Key F'], action: 'Toggle Fullscreen Mode'),
          const _GuideKeyRow(keys: ['Back', 'Escape'], action: 'Close Menus / Overlays or Exit to Home'),

          const SizedBox(height: 24),

          // Section 2: Home Screen Navigation
          const _GuideSectionHeader(
            title: 'Home Screen Navigation',
            icon: Icons.home_rounded,
          ),
          const SizedBox(height: 10),
          const _GuideKeyRow(keys: ['D-Pad / Arrows'], action: 'Navigate Channel Cards & Category Shelves'),
          const _GuideKeyRow(keys: ['OK / Enter'], action: 'Play Selected Channel'),
          const _GuideKeyRow(keys: ['Key /', 'Tab'], action: 'Focus Instant Search Bar'),
          const _GuideKeyRow(keys: ['Key S'], action: 'Open App Settings Modal'),
          const _GuideKeyRow(keys: ['Key P'], action: 'Open Account & Profile'),
          const _GuideKeyRow(keys: ['Escape'], action: 'Clear Search Query / Reset Active Filter'),

          const SizedBox(height: 24),

          // Section 3: Dialogs & Overlays
          const _GuideSectionHeader(
            title: 'Dialogs & Filter Menus',
            icon: Icons.tune_rounded,
          ),
          const SizedBox(height: 10),
          const _GuideKeyRow(keys: ['D-Pad / Arrows'], action: 'Move Focus Across Tabs & Options'),
          const _GuideKeyRow(keys: ['OK / Enter / Space'], action: 'Toggle Filter, Category, or Option'),
          const _GuideKeyRow(keys: ['Back / Escape'], action: 'Close Dialog & Return to Previous Screen'),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 6: SOFTWARE UPDATES & GITHUB RELEASES
  // ==========================================
  Widget _buildUpdatesTab(bool isMobile) {
    final updateService = Get.find<AppUpdateService>();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 16 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Status Banner Card
          Obx(() {
            final hasUpdate = updateService.updateAvailable.value;
            final isChecking = updateService.isChecking.value;
            final isDownloading = updateService.isDownloading.value;
            final progress = updateService.downloadProgress.value;
            final latest = updateService.latestVersion.value;

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: hasUpdate ? const Color(0x28A839C7) : const Color(0x1A22C55E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: hasUpdate
                      ? AppColors.primaryLight.withValues(alpha: 0.45)
                      : const Color(0x4D22C55E),
                  width: 1.2,
                ),
                boxShadow: hasUpdate
                    ? [
                        BoxShadow(
                          color: AppColors.primaryGlow.withValues(alpha: 0.25),
                          blurRadius: 18,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: hasUpdate ? AppColors.primary : const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Icon(
                            hasUpdate ? Icons.system_update_rounded : Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasUpdate
                                  ? 'New Update Available: v$latest'
                                  : 'PrismTV is Up to Date',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasUpdate
                                  ? 'An in-place direct OTA update is ready to install without losing your settings.'
                                  : 'Current Version: v${updateService.currentVersion.value} • Connected to GitHub',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Download Progress Bar
                  if (isDownloading) ...[
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress > 0.0 ? progress : null,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          updateService.downloadStatus.value,
                          style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Action Buttons Row
                  Row(
                    children: [
                      if (hasUpdate && !isDownloading)
                        Focus(
                          child: Builder(
                            builder: (ctx) {
                              final hasFocus = Focus.of(ctx).hasFocus;
                              return ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  side: hasFocus ? const BorderSide(color: Colors.white, width: 1.5) : null,
                                ),
                                onPressed: updateService.downloadAndInstall,
                                icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                                label: const Text(
                                  'Download & Install Update',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              );
                            },
                          ),
                        ),

                      if (!hasUpdate || isDownloading) ...[
                        Focus(
                          child: Builder(
                            builder: (ctx) {
                              final hasFocus = Focus.of(ctx).hasFocus;
                              return OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  side: BorderSide(color: hasFocus ? Colors.white : Colors.white.withValues(alpha: 0.20)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  backgroundColor: hasFocus ? Colors.white.withValues(alpha: 0.10) : null,
                                ),
                                onPressed: isChecking ? null : () => updateService.checkForUpdates(isManual: true),
                                icon: isChecking
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                                      )
                                    : const Icon(Icons.refresh_rounded, size: 16, color: Colors.white70),
                                label: Text(
                                  isChecking ? 'Checking GitHub...' : 'Check for Updates',
                                  style: const TextStyle(color: Colors.white, fontSize: 12.5),
                                ),
                              );
                            },
                          ),
                        ),
                        if (!isDownloading) ...[
                          const SizedBox(width: 8),
                          Focus(
                            child: Builder(
                              builder: (ctx) {
                                final hasFocus = Focus.of(ctx).hasFocus;
                                return OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    side: BorderSide(color: hasFocus ? Colors.white : Colors.white.withValues(alpha: 0.20)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    backgroundColor: hasFocus ? Colors.white.withValues(alpha: 0.10) : null,
                                  ),
                                  onPressed: updateService.downloadAndInstall,
                                  icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white70),
                                  label: const Text(
                                    'Download & Reinstall',
                                    style: TextStyle(color: Colors.white, fontSize: 12.5),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],

                      const Spacer(),

                      // GitHub Release Link
                      Focus(
                        child: Builder(
                          builder: (ctx) {
                            final hasFocus = Focus.of(ctx).hasFocus;
                            return TextButton.icon(
                              style: TextButton.styleFrom(
                                backgroundColor: hasFocus ? Colors.white.withValues(alpha: 0.10) : null,
                              ),
                              onPressed: () async {
                                final uri = Uri.parse('https://github.com/TheGandabherunda/PrismTV/releases');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.primaryLight),
                              label: const Text(
                                'View on GitHub',
                                style: TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // 2. Release Notes / Changelog
          const _GuideSectionHeader(
            title: 'Changelog & What\'s New',
            icon: Icons.article_rounded,
          ),
          const SizedBox(height: 10),

          Obx(() {
            final notes = updateService.releaseNotes.value;
            final isChecking = updateService.isChecking.value;

            if (isChecking) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70)),
                    SizedBox(width: 12),
                    Text('Fetching latest release notes from GitHub...', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              );
            }

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Text(
                notes.isNotEmpty
                    ? notes
                    : 'PrismTV v1.0.1 update featuring 1080p DASH universal streaming, mobile gesture controls, and automated multi-platform release packages.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // 3. Seamless OTA Update Guide
          const _GuideSectionHeader(
            title: 'In-Place Direct OTA Upgrade Info',
            icon: Icons.info_outline_rounded,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x18161824),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UpdateInfoPoint(
                  icon: Icons.security_rounded,
                  text: 'No Data Loss: Login session, favorites, and proxy configurations are completely preserved during updates.',
                ),
                SizedBox(height: 8),
                _UpdateInfoPoint(
                  icon: Icons.tv_rounded,
                  text: 'Smart TV & Android Friendly: Remote D-Pad clickable; prompts Android OS native installer directly.',
                ),
                SizedBox(height: 8),
                _UpdateInfoPoint(
                  icon: Icons.cloud_download_rounded,
                  text: 'Direct from GitHub: Downloads verified official release artifacts from TheGandabherunda/PrismTV.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateInfoPoint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _UpdateInfoPoint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primaryLight),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _GuideSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _GuideSectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryLight),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _GuideKeyRow extends StatelessWidget {
  final List<String> keys;
  final String action;

  const _GuideKeyRow({required this.keys, required this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Wrap(
            spacing: 6,
            children: keys.map((k) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x38FFFFFF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.20),
                  width: 1.0,
                ),
              ),
              child: Text(
                k,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )).toList(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              action,
              style: const TextStyle(
                fontSize: 12.5,
                color: Colors.white70,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPillCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPillCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (ctx) {
          final hasFocus = Focus.of(ctx).hasFocus;
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0x2EA839C7)
                    : (hasFocus ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasFocus
                      ? Colors.white
                      : (isSelected
                          ? AppColors.primaryLight.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.09)),
                  width: hasFocus || isSelected ? 1.5 : 1.0,
                ),
                boxShadow: hasFocus
                    ? [
                        BoxShadow(
                          color: AppColors.primaryGlow.withValues(alpha: 0.40),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected || hasFocus ? AppColors.primaryLight : Colors.white54,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected || hasFocus ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected || hasFocus ? Colors.white : Colors.white70,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_rounded, size: 16, color: AppColors.primaryLight),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
