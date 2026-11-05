import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/ambient_color_service.dart';
import '../../core/widgets/prism_triangle_logo.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../data/models/category_model.dart';
import '../../data/models/channel_model.dart';
import '../../data/models/epg_program_model.dart';
import 'home_controller.dart';
import 'widgets/channel_card.dart';
import '../player/widgets/floating_miniplayer.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Root Multi-Color Ambient Dynamic Atmosphere Layer (Across homescreen)
          Positioned.fill(
            child: Obx(() {
              final palette = controller.ambientPalette.value;
              return _AmbientAtmosphereMesh(
                palette: palette,
              );
            }),
          ),

          // 2. Main TV Live UI (No rail, full-screen width with top header, shelves & right event column)
          Positioned.fill(
            child: _buildLiveTvView(context),
          ),

          // Floating Miniplayer (pinned to bottom-right)
          const FloatingMiniplayer(),
        ],
      ),
    );
  }

  Widget _buildLiveTvView(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Stack(
      children: [
        // 1. Main TV Content Area: Left Shelves + Right Event Info Column
        // The shelves list scrolls underneath the Apple-like progressive blur header!
        Positioned.fill(
          child: isMobile
              ? _buildShelvesList(isMobile: true)
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Scrollable Shelves Layer
                    Expanded(
                      child: _buildShelvesList(isMobile: false),
                    ),

                    // Right Side Column: Shows Hovered/Selected Channel & Current Event Info
                    Obx(() {
                      final channel = controller.focusedChannel.value;
                      final program = controller.currentProgram.value;
                      final isLoading = controller.isLoadingEpg.value;
                      final palette = controller.ambientPalette.value;

                      return Padding(
                        padding: const EdgeInsets.only(top: 130),
                        child: _EpgDetailSideColumn(
                          channel: channel,
                          program: program,
                          isLoading: isLoading,
                          ambientPalette: palette,
                        ),
                      );
                    }),
                  ],
                ),
        ),

        // 2. Pure Optical Progressive Blur Header pinned at top (Zero Tint, Pure Optical Glass)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _ApplePureProgressiveBlurHeader(
            height: isMobile ? 80.0 : 115.0,
            child: _buildTopHeader(context),
          ),
        ),
      ],
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile) {
      return Obx(() {
        if (controller.isMobileSearchOpen.value) {
          // Mobile Search Expanded Bar
          return Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                  onPressed: controller.closeMobileSearch,
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x38161824),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, size: 18, color: AppColors.primaryLight),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controller.searchController,
                            onChanged: controller.onSearchChanged,
                            autofocus: true,
                            style: const TextStyle(color: Colors.white, fontSize: 13.5),
                            cursorColor: AppColors.primaryLight,
                            decoration: InputDecoration(
                              hintText: 'Search channel, language...',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.40),
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        if (controller.searchQuery.value.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                            onPressed: controller.clearSearch,
                            splashRadius: 16,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _CinejoyFilterButton(controller: controller, isMobile: true),
              ],
            ),
          );
        }

        // Mobile Standard Header
        return Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Left: Logo & Brand
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  PrismTriangleLogo(size: 28, hasGlow: true),
                  SizedBox(width: 8),
                  Text(
                    'PrismTV',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Right: Search Button, Filter Button, Settings, Profile
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Colors.white, size: 21),
                onPressed: controller.openMobileSearch,
                splashRadius: 20,
                tooltip: 'Search',
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              const SizedBox(width: 4),
              _CinejoyFilterButton(controller: controller, isMobile: true),
              const SizedBox(width: 4),
              _HeaderSettingsButton(onTap: controller.openSettingsDialog),
              const SizedBox(width: 4),
              Obx(() => _HeaderAccountButton(
                isAuthenticated: controller.isAuthenticated.value,
                onTap: controller.onProfileTapped,
              )),
            ],
          ),
        );
      });
    }

    // Desktop Header (100% UNCHANGED!)
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          // Top Left: App Icon & Brand Logo (No LIVE chip)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              PrismTriangleLogo(size: 32, hasGlow: true),
              SizedBox(width: 12),
              Text(
                'PrismTV',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Center: Search & Filter Capsule
          _CinejoyHeaderCapsule(controller: controller),

          const Spacer(),

          // Top Right: Settings Button & Account Button (Icon button only, no phone number)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Settings Icon Button
              _HeaderSettingsButton(
                onTap: controller.openSettingsDialog,
              ),

              const SizedBox(width: 12),

              // Account Icon Button
              Obx(() => _HeaderAccountButton(
                isAuthenticated: controller.isAuthenticated.value,
                onTap: controller.onProfileTapped,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShelvesList({bool isMobile = false}) {
    return Obx(() {
      if (controller.isLoadingChannels.value) {
        return Shimmer(
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              top: isMobile ? 100 : 136,
              bottom: isMobile ? 32 : 48,
            ),
            children: const [
              SkeletonShelf(),
              SkeletonShelf(),
            ],
          ),
        );
      }

      final sections = controller.categorizedSections;

      if (sections.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.only(top: isMobile ? 100 : 140),
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
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.unfocusedBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  onPressed: controller.resetAllFilters,
                  child: const Text(
                    'Reset All Filters',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          top: isMobile ? 100 : 136,
          bottom: isMobile ? 32 : 48,
        ),
        itemCount: sections.length + 1,
        itemBuilder: (context, index) {
          if (index == sections.length) {
            return _HomeScreenFooter(isMobile: isMobile);
          }
          final entry = sections[index];
          return _CategoryShelf(
            category: entry.key,
            channels: entry.value,
            controller: controller,
            isMobile: isMobile,
          );
        },
      );
    });
  }
}

/// Extreme Bottom Home Screen Footer
/// Shows PrismTV icon, brand title, version badge, thank you note, and official GitHub repository link.
class _HomeScreenFooter extends StatefulWidget {
  final bool isMobile;
  const _HomeScreenFooter({this.isMobile = false});

  @override
  State<_HomeScreenFooter> createState() => _HomeScreenFooterState();
}

class _HomeScreenFooterState extends State<_HomeScreenFooter> {
  bool _isRepoHovered = false;

  Future<void> _openRepo() async {
    final uri = Uri.parse('https://github.com/TheGandabherunda/PrismTV');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 16 : 28,
        vertical: widget.isMobile ? 24 : 40,
      ),
      margin: EdgeInsets.only(
        top: widget.isMobile ? 10 : 20,
        bottom: widget.isMobile ? 20 : 36,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Subtle Divider
            Container(
              width: 140,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),

            // App Icon and Brand Name
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                PrismTriangleLogo(size: 26, hasGlow: true),
                SizedBox(width: 10),
                Text(
                  'PrismTV',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // App Version Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 1.0,
                ),
              ),
              child: const Text(
                'v1.0.0',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Thanks for using note
            const Text(
              'Thanks for using PrismTV! 🍿',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 6),

            // If any issues are there
            const Text(
              'If you encounter any issues or have feedback, please raise an issue in our repository:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),

            // GitHub Repo Interactive Pill
            MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _isRepoHovered = true),
              onExit: (_) => setState(() => _isRepoHovered = false),
              child: GestureDetector(
                onTap: _openRepo,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: _isRepoHovered
                        ? const Color(0x33FFFFFF)
                        : const Color(0x18FFFFFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isRepoHovered
                          ? AppColors.primaryLight.withValues(alpha: 0.65)
                          : Colors.white.withValues(alpha: 0.16),
                      width: 1.0,
                    ),
                    boxShadow: _isRepoHovered
                        ? [
                            BoxShadow(
                              color: AppColors.primaryGlow.withValues(alpha: 0.35),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.code_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'github.com/TheGandabherunda/PrismTV',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isRepoHovered ? Colors.white : Colors.white.withValues(alpha: 0.90),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 13,
                        color: _isRepoHovered ? AppColors.primaryLight : Colors.white54,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pure Optical Progressive Blur Floating Header (Edge-to-Edge Full Width)
/// Generous 115px height: Search bar (y=14 to 62) is deeply covered from behind with optical blur,
/// followed by 53px of smooth, luxurious falloff down to imperceptible 0.08 sigma at 115px.
/// ZERO COLOR, ZERO TINT, PURE OPTICAL DIFFUSION.
class _ApplePureProgressiveBlurHeader extends StatelessWidget {
  final Widget child;
  final double height;

  const _ApplePureProgressiveBlurHeader({
    required this.child,
    this.height = 115.0,
  });

  @override
  Widget build(BuildContext context) {
    final scale = height / 115.0;

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Optical slices: ZERO TINT, ZERO COLOR scrim, PURE optical glass diffusion
          IgnorePointer(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _OpticalBlurSlice(height: 115 * scale, sigma: 0.08),
                _OpticalBlurSlice(height: 105 * scale, sigma: 0.35),
                _OpticalBlurSlice(height: 95 * scale, sigma: 0.85),
                _OpticalBlurSlice(height: 85 * scale, sigma: 1.60),
                _OpticalBlurSlice(height: 75 * scale, sigma: 2.60),
                _OpticalBlurSlice(height: 68 * scale, sigma: 3.80),
                _OpticalBlurSlice(height: 60 * scale, sigma: 5.20),
                _OpticalBlurSlice(height: 52 * scale, sigma: 6.80),
                _OpticalBlurSlice(height: 44 * scale, sigma: 8.20),
                _OpticalBlurSlice(height: 36 * scale, sigma: 9.50),
                _OpticalBlurSlice(height: 28 * scale, sigma: 10.50),
                _OpticalBlurSlice(height: 20 * scale, sigma: 11.00),
                _OpticalBlurSlice(height: 12 * scale, sigma: 11.00),
              ],
            ),
          ),

          // Header Content (Brand Logo, Search Capsule, Settings & Profile)
          child,
        ],
      ),
    );
  }
}

/// Pure optical backdrop slice: ZERO COLOR, ZERO TINT, PURE OPTICAL DIFFUSION
class _OpticalBlurSlice extends StatelessWidget {
  final double height;
  final double sigma;

  const _OpticalBlurSlice({required this.height, required this.sigma});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height,
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Settings Icon Button with Subtle Glow and Glass Finish
class _HeaderSettingsButton extends StatefulWidget {
  final VoidCallback onTap;

  const _HeaderSettingsButton({required this.onTap});

  @override
  State<_HeaderSettingsButton> createState() => _HeaderSettingsButtonState();
}

class _HeaderSettingsButtonState extends State<_HeaderSettingsButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Settings & Preferences',
      child: Focus(
        child: Builder(
          builder: (ctx) {
            final hasFocus = Focus.of(ctx).hasFocus;
            return MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: widget.onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _isHovered || hasFocus
                        ? const Color(0x40A839C7)
                        : const Color(0x2E161824),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isHovered || hasFocus
                          ? AppColors.primaryLight.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.16),
                      width: 1.0,
                    ),
                    boxShadow: _isHovered || hasFocus
                        ? const [
                            BoxShadow(
                              color: AppColors.primaryGlow,
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.settings_rounded,
                      size: 21,
                      color: _isHovered || hasFocus ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Account Icon Button on Top Right (Identical 42x42 container, profile icon with sunset-violet gradient)
class _HeaderAccountButton extends StatefulWidget {
  final bool isAuthenticated;
  final VoidCallback onTap;

  const _HeaderAccountButton({
    required this.isAuthenticated,
    required this.onTap,
  });

  @override
  State<_HeaderAccountButton> createState() => _HeaderAccountButtonState();
}

class _HeaderAccountButtonState extends State<_HeaderAccountButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.isAuthenticated ? 'Account Profile' : 'Sign In',
      child: Focus(
        child: Builder(
          builder: (ctx) {
            final hasFocus = Focus.of(ctx).hasFocus;
            return MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: widget.onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _isHovered || hasFocus
                        ? const Color(0x40A839C7)
                        : const Color(0x2E161824),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isHovered || hasFocus
                          ? AppColors.primaryLight.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.16),
                      width: 1.0,
                    ),
                    boxShadow: _isHovered || hasFocus
                        ? const [
                            BoxShadow(
                              color: AppColors.primaryGlow,
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFF7B60), Color(0xFFA839C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Icon(
                          widget.isAuthenticated ? Icons.person_rounded : Icons.login_rounded,
                          size: 21,
                          color: Colors.white,
                        ),
                      ),
                      if (widget.isAuthenticated)
                        Positioned(
                          right: 7,
                          top: 7,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00E676),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x8800E676),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Unified Floating Glass Navigation Capsule (Cinejoy Style)
/// Houses both the Search Box and Filter Button in a single frosted glass pill
class _CinejoyHeaderCapsule extends StatefulWidget {
  final HomeController controller;

  const _CinejoyHeaderCapsule({required this.controller});

  @override
  State<_CinejoyHeaderCapsule> createState() => _CinejoyHeaderCapsuleState();
}

class _CinejoyHeaderCapsuleState extends State<_CinejoyHeaderCapsule> {
  late final FocusNode _focusNode;
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _isFocused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 48,
            constraints: const BoxConstraints(maxWidth: 540),
            decoration: BoxDecoration(
              color: _isFocused
                  ? const Color(0x451A1D2B)
                  : (_isHovered ? const Color(0x38161824) : const Color(0x28161824)),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isFocused
                    ? AppColors.primaryLight.withValues(alpha: 0.90)
                    : (_isHovered
                        ? Colors.white.withValues(alpha: 0.32)
                        : Colors.white.withValues(alpha: 0.16)),
                width: _isFocused ? 1.5 : 1.0,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: AppColors.primaryGlow.withValues(alpha: 0.40),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.40),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.30),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                AnimatedCrossFade(
                  firstChild: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: _isFocused
                        ? AppColors.primaryLight
                        : (_isHovered
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.white.withValues(alpha: 0.55)),
                  ),
                  secondChild: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.primaryLight,
                  ),
                  crossFadeState: _isFocused ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 180),
                ),
                const SizedBox(width: 12),

                // Search Text Field
                Expanded(
                  child: TextField(
                    focusNode: _focusNode,
                    controller: widget.controller.searchController,
                    onChanged: widget.controller.onSearchChanged,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                    ),
                    cursorColor: AppColors.primaryLight,
                    decoration: InputDecoration(
                      hintText: 'Search channel, language, genre...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: _isFocused ? 0.48 : 0.36),
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                Obx(() {
                  if (widget.controller.searchQuery.value.isNotEmpty) {
                    return IconButton(
                      icon: const Icon(Icons.close_rounded, size: 17, color: Colors.white70),
                      onPressed: widget.controller.clearSearch,
                      splashRadius: 16,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    );
                  }
                  return const SizedBox.shrink();
                }),

                // Divider between Search and Filters
                Container(
                  width: 1,
                  height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: Colors.white.withValues(alpha: 0.15),
                ),

                // Cinejoy Cascading Filter Dropdown Button
                _CinejoyFilterButton(controller: widget.controller),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _FilterSubMenu { none, category, language }

/// Cinejoy Unified Filter Button with Cascading Side Dropdown
class _CinejoyFilterButton extends StatefulWidget {
  final HomeController controller;
  final bool isMobile;

  const _CinejoyFilterButton({
    required this.controller,
    this.isMobile = false,
  });

  @override
  State<_CinejoyFilterButton> createState() => _CinejoyFilterButtonState();
}

class _CinejoyFilterButtonState extends State<_CinejoyFilterButton> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  bool _isHovered = false;
  _FilterSubMenu _activeSubMenu = _FilterSubMenu.category;

  void _openMobileFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MobileFilterSheet(controller: widget.controller),
    );
  }

  void _toggle() {
    if (widget.isMobile) {
      _openMobileFilterSheet();
      return;
    }
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    _close();
    _activeSubMenu = _FilterSubMenu.category;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setOverlayState) {
            return Stack(
              children: [
                // Outside click detector
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _close,
                    child: const ColoredBox(color: Colors.transparent),
                  ),
                ),

                // Cascading Dropdown Container (Main Menu on Left, Secondary Drawer on Right)
                Positioned(
                  child: CompositedTransformFollower(
                    link: _layerLink,
                    showWhenUnlinked: false,
                    targetAnchor: Alignment.bottomLeft,
                    followerAnchor: Alignment.topLeft,
                    offset: const Offset(-20, 10),
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Main Filter Options Menu
                          _buildMainMenu(setOverlayState),

                          // 2. Secondary Drawer (Category or Language List) opens to the RIGHT
                          if (_activeSubMenu != _FilterSubMenu.none) ...[
                            const SizedBox(width: 8),
                            _buildSideFlyout(setOverlayState),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    if (mounted) setState(() => _isOpen = true);
  }

  void _close() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  /// Main Menu: Shows Category, Language, and Reset (Pure Text, NO icons)
  Widget _buildMainMenu(void Function(void Function()) setOverlayState) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xF210121C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Obx(() {
              final catLabel = widget.controller.categoryDropdownLabel;
              final langLabel = widget.controller.languageDropdownLabel;
              final hasActive = widget.controller.hasActiveFilters;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Category Option
                  _buildMainMenuItem(
                    title: 'Category',
                    subtitle: catLabel,
                    isSelected: _activeSubMenu == _FilterSubMenu.category,
                    onTap: () {
                      setOverlayState(() => _activeSubMenu = _FilterSubMenu.category);
                    },
                  ),

                  const SizedBox(height: 2),

                  // Language Option
                  _buildMainMenuItem(
                    title: 'Language',
                    subtitle: langLabel,
                    isSelected: _activeSubMenu == _FilterSubMenu.language,
                    onTap: () {
                      setOverlayState(() => _activeSubMenu = _FilterSubMenu.language);
                    },
                  ),

                  if (hasActive) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Divider(
                        color: Colors.white.withValues(alpha: 0.08),
                        height: 1,
                      ),
                    ),

                    // Reset All Filters
                    InkWell(
                      onTap: () {
                        widget.controller.resetAllFilters();
                        setOverlayState(() {});
                      },
                      hoverColor: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Text(
                          'Reset Filters',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildMainMenuItem({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return _FilterMenuTile(
      title: title,
      subtitle: subtitle,
      isSelected: isSelected,
      onTap: onTap,
    );
  }

  /// Side Flyout: Shows Category List or Language List (Pure Text, NO icons)
  Widget _buildSideFlyout(void Function(void Function()) setOverlayState) {
    final isCategory = _activeSubMenu == _FilterSubMenu.category;

    return Container(
      width: 270,
      constraints: const BoxConstraints(maxHeight: 380),
      decoration: BoxDecoration(
        color: const Color(0xF210121C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Flyout Header: Title + Reset link
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
                child: Row(
                  children: [
                    Text(
                      isCategory ? 'Categories' : 'Languages',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        if (isCategory) {
                          widget.controller.resetCategoryFilter();
                        } else {
                          widget.controller.resetLanguageFilter();
                        }
                        setOverlayState(() {});
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: Text(
                          'Reset',
                          style: TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),

              // Scrollable Options List
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                  physics: const BouncingScrollPhysics(),
                  child: Obx(() {
                    if (isCategory) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.controller.categories.map((cat) {
                          final count = cat.id == 'all'
                              ? widget.controller.allChannels.length
                              : widget.controller.allChannels
                                  .where((c) => cat.jioCategoryId != null && c.categoryId == cat.jioCategoryId)
                                  .length;
                          final isSelected = widget.controller.selectedCategoryIds.contains(cat.id);

                          return _buildFilterItemRow(
                            title: cat.title,
                            count: count,
                            isSelected: isSelected,
                            onTap: () {
                              widget.controller.toggleCategory(cat.id);
                              setOverlayState(() {});
                            },
                          );
                        }).toList(),
                      );
                    } else {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.controller.languages.map((lang) {
                          final count = lang.id == 'all'
                              ? widget.controller.allChannels.length
                              : widget.controller.allChannels
                                  .where((c) => lang.jioLanguageId != null && c.languageId == lang.jioLanguageId)
                                  .length;
                          final isSelected = widget.controller.selectedLanguageIds.contains(lang.id);

                          return _buildFilterItemRow(
                            title: lang.title,
                            count: count,
                            isSelected: isSelected,
                            onTap: () {
                              widget.controller.toggleLanguage(lang.id);
                              setOverlayState(() {});
                            },
                          );
                        }).toList(),
                      );
                    }
                  }),
                ),
              ),

              Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),

              // Footer: Done Button
              Padding(
                padding: const EdgeInsets.all(10),
                child: InkWell(
                  onTap: _close,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppColors.prismGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pure Text List Item Row with Selection Indicator & Dynamic Hover Effect
  Widget _buildFilterItemRow({
    required String title,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return _FilterSubMenuTile(
      title: title,
      count: count,
      isSelected: isSelected,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMobile) {
      return Obx(() {
        final hasActive = widget.controller.hasActiveFilters;

        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.tune_rounded, color: Colors.white, size: 21),
              if (hasActive)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: _openMobileFilterSheet,
          splashRadius: 20,
          tooltip: 'Filters',
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        );
      });
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: Obx(() {
        final hasActive = widget.controller.hasActiveFilters;
        final count = widget.controller.activeFilterCount;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: hasActive || _isOpen
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : (_isHovered ? Colors.white.withValues(alpha: 0.12) : Colors.transparent),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasActive ? 'Filters ($count)' : 'Filters',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: hasActive ? FontWeight.w700 : FontWeight.w500,
                      color: hasActive ? Colors.white : Colors.white.withValues(alpha: 0.90),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: hasActive || _isOpen ? Colors.white : Colors.white54,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _FilterMenuTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterMenuTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FilterMenuTile> createState() => _FilterMenuTileState();
}

class _FilterMenuTileState extends State<_FilterMenuTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.isSelected || _isHovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onTap(); // Keep secondary flyout in sync on hover
      },
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Colors.white.withValues(alpha: 0.12)
                : (_isHovered ? Colors.white.withValues(alpha: 0.08) : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected
                  ? Colors.white.withValues(alpha: 0.15)
                  : (_isHovered ? Colors.white.withValues(alpha: 0.10) : Colors.transparent),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: highlighted ? FontWeight.w600 : FontWeight.w400,
                  color: highlighted ? Colors.white.withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: highlighted ? Colors.white : Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSubMenuTile extends StatefulWidget {
  final String title;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterSubMenuTile({
    required this.title,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FilterSubMenuTile> createState() => _FilterSubMenuTileState();
}

class _FilterSubMenuTileState extends State<_FilterSubMenuTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.isSelected || _isHovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primary.withValues(alpha: 0.20)
                : (_isHovered ? Colors.white.withValues(alpha: 0.08) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.primaryLight.withValues(alpha: 0.40)
                  : (_isHovered ? Colors.white.withValues(alpha: 0.12) : Colors.transparent),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              // Custom check indicator with glow
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: widget.isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: widget.isSelected
                        ? AppColors.primaryLight
                        : (_isHovered
                            ? Colors.white.withValues(alpha: 0.50)
                            : Colors.white.withValues(alpha: 0.25)),
                    width: 1.5,
                  ),
                ),
                child: widget.isSelected
                    ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),

              // Item Title
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: highlighted ? FontWeight.w600 : FontWeight.w400,
                    color: highlighted ? Colors.white : Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),

              // Channel Count Pill
              Text(
                '(${widget.count})',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: highlighted
                      ? Colors.white.withValues(alpha: 0.70)
                      : Colors.white.withValues(alpha: 0.40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sleek Mobile Filter Bottom Sheet with Categories and Languages
class _MobileFilterSheet extends StatefulWidget {
  final HomeController controller;
  const _MobileFilterSheet({required this.controller});

  @override
  State<_MobileFilterSheet> createState() => _MobileFilterSheetState();
}

class _MobileFilterSheetState extends State<_MobileFilterSheet> {
  int _activeTab = 0; // 0 = Categories, 1 = Languages

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: const Color(0xF210121C),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
              width: 1.0,
            ),
          ),
          child: Column(
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 2. Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    const Text(
                      'Filter Channels',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        widget.controller.resetAllFilters();
                        setState(() {});
                      },
                      child: const Text(
                        'Reset All',
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      splashRadius: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),

              // 3. Segmented Switcher (Categories / Languages)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _activeTab == 0 ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'Categories',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _activeTab == 1 ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'Languages',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0x1FFFFFFF), height: 1),

              // 4. Options List
              Expanded(
                child: Obx(() {
                  if (_activeTab == 0) {
                    final selectedIds = widget.controller.selectedCategoryIds;
                    final isAll = selectedIds.contains('all');

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      physics: const BouncingScrollPhysics(),
                      itemCount: widget.controller.categories.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final cat = widget.controller.categories[idx];
                        final isSelected = isAll ? (cat.id == 'all') : selectedIds.contains(cat.id);

                        return InkWell(
                          onTap: () {
                            widget.controller.toggleCategory(cat.id);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withValues(alpha: 0.20) : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primaryLight : Colors.white.withValues(alpha: 0.10),
                                width: isSelected ? 1.4 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(cat.icon, size: 20, color: isSelected ? AppColors.primaryLight : Colors.white70),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    cat.title,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white70,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_rounded, color: AppColors.primaryLight, size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }

                  // Languages Tab
                  final selectedIds = widget.controller.selectedLanguageIds;
                  final isAll = selectedIds.contains('all');

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.controller.languages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final lang = widget.controller.languages[idx];
                      final isSelected = isAll ? (lang.id == 'all') : selectedIds.contains(lang.id);

                      return InkWell(
                        onTap: () {
                          widget.controller.toggleLanguage(lang.id);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withValues(alpha: 0.20) : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryLight : Colors.white.withValues(alpha: 0.10),
                              width: isSelected ? 1.4 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.language_rounded, size: 20, color: Colors.white70),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  lang.title,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_rounded, color: AppColors.primaryLight, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal Shelf with Cinejoy Section Divide & True Photographic Side Fade
class _CategoryShelf extends StatefulWidget {
  final CategoryModel category;
  final List<ChannelModel> channels;
  final HomeController controller;
  final bool isMobile;

  const _CategoryShelf({
    required this.category,
    required this.channels,
    required this.controller,
    this.isMobile = false,
  });

  @override
  State<_CategoryShelf> createState() => _CategoryShelfState();
}

class _CategoryShelfState extends State<_CategoryShelf> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  late bool _canScrollRight = widget.channels.length > 4;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScroll());
  }

  @override
  void didUpdateWidget(_CategoryShelf oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.channels.length != oldWidget.channels.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkScroll());
    }
  }

  void _checkScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final canLeft = pos.pixels > 8;
    final canRight = pos.pixels < pos.maxScrollExtent - 8;
    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  void _scroll(double delta) {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + delta).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: widget.isMobile ? 24 : 42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section Divide Header (Pure Typography, NO Icon Box, NO View All)
          Padding(
            padding: widget.isMobile
                ? const EdgeInsets.fromLTRB(16, 4, 16, 8)
                : const EdgeInsets.fromLTRB(28, 6, 28, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.category.title,
                  style: TextStyle(
                    fontSize: widget.isMobile ? 16 : 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '• ${widget.channels.length} channels',
                  style: TextStyle(
                    fontSize: widget.isMobile ? 12 : 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                const Spacer(),

                // Left & Right Carousel Navigation Arrows (Desktop/TV)
                if (!widget.isMobile) ...[
                  if (_canScrollLeft)
                    _ShelfArrowButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: () => _scroll(-450),
                      tooltip: 'Scroll left',
                    ),
                  if (_canScrollRight) ...[
                    const SizedBox(width: 6),
                    _ShelfArrowButton(
                      icon: Icons.chevron_right_rounded,
                      onTap: () => _scroll(450),
                      tooltip: 'Scroll right',
                    ),
                  ],
                ],
              ],
            ),
          ),

          // Horizontal Channels Carousel with Cinejoy Poster Scale & Ambient Side Fades
          SizedBox(
            height: widget.isMobile ? 260 : 350,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Horizontal Channels List with Reactive Scroll Notification
                Positioned.fill(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.axis == Axis.horizontal) {
                        final metrics = notification.metrics;
                        final canLeft = metrics.pixels > 8;
                        final canRight = metrics.pixels < metrics.maxScrollExtent - 8;
                        if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
                          setState(() {
                            _canScrollLeft = canLeft;
                            _canScrollRight = canRight;
                          });
                        }
                      }
                      return false;
                    },
                    child: ListView.separated(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      physics: const BouncingScrollPhysics(),
                      padding: widget.isMobile
                          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                          : const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                      itemCount: widget.channels.length,
                      separatorBuilder: (_, _) => SizedBox(width: widget.isMobile ? 12 : 16),
                      itemBuilder: (context, idx) {
                        final channel = widget.channels[idx];
                        return SizedBox(
                          width: widget.isMobile ? 145 : 200,
                          child: ChannelCard(
                            channel: channel,
                            onTap: () => widget.controller.playChannel(channel),
                            onFocusChange: (focused) {
                              if (focused) {
                                widget.controller.onChannelFocused(channel);
                              } else {
                                widget.controller.onChannelUnfocused(channel);
                              }
                            },
                            onHoverChange: (hovered) {
                              if (hovered) {
                                widget.controller.onChannelFocused(channel);
                              } else {
                                widget.controller.onChannelUnfocused(channel);
                              }
                            },
                            onFavoriteToggle: () => widget.controller.toggleFavorite(channel),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // 2. Left Edge Progressive Fade & Blur (fades cards seamlessly into obsidian canvas)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: widget.isMobile ? 24 : 80,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _canScrollLeft ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 0),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0xFF07080C),
                                  Color(0xEB07080C),
                                  Color(0x8007080C),
                                  Color(0x1F07080C),
                                  Colors.transparent,
                                ],
                                stops: [0.0, 0.28, 0.60, 0.82, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Right Edge Progressive Fade & Blur (fades cards seamlessly into obsidian canvas)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: widget.isMobile ? 24 : 80,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _canScrollRight ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 0),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                                colors: [
                                  Color(0xFF07080C),
                                  Color(0xEB07080C),
                                  Color(0x8007080C),
                                  Color(0x1F07080C),
                                  Colors.transparent,
                                ],
                                stops: [0.0, 0.28, 0.60, 0.82, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShelfArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _ShelfArrowButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Dedicated Right Side Column for Currently Hovered/Selected Channel & Event
/// Clean, containerless UI: Image -> Event Name -> Brief Info -> Time Progress
class _EpgDetailSideColumn extends StatelessWidget {
  final ChannelModel? channel;
  final EpgProgramModel? program;
  final bool isLoading;
  final AmbientPalette ambientPalette;

  const _EpgDetailSideColumn({
    required this.channel,
    required this.program,
    required this.isLoading,
    required this.ambientPalette,
  });

  @override
  Widget build(BuildContext context) {
    if (channel == null) {
      return Container(
        width: 350,
        padding: const EdgeInsets.fromLTRB(16, 24, 28, 28),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.tv_rounded,
                  size: 34,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No Channel Selected',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hover or select a channel\nto view live event details',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Colors.white.withValues(alpha: 0.60),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Shimmering Skeleton while live EPG metadata and artwork are loading
    if (isLoading) {
      return const Shimmer(
        child: SkeletonEpgSideColumn(),
      );
    }

    final timeFormatter = DateFormat('hh:mm a');
    final startTimeStr = program != null ? timeFormatter.format(program!.startTime) : '--:--';
    final endTimeStr = program != null ? timeFormatter.format(program!.endTime) : '--:--';

    return Container(
      width: 350,
      padding: const EdgeInsets.fromLTRB(12, 16, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Image (Program Poster or Channel Logo)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141210),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ambientPalette.accent.withValues(alpha: 0.25),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ambientPalette.glow.withValues(alpha: 0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.50),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (program?.posterUrl != null && program!.posterUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: program!.posterUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => _buildPlaceholder(),
                        errorWidget: (_, _, _) => _buildLogoFallback(),
                      )
                    else
                      _buildLogoFallback(),

                    // Subtle bottom gradient
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.55),
                            ],
                            stops: const [0.6, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // HD Pill
                    if (channel!.isHd)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xD9000000),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'HD',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 2. Channel & Category Metadata
          Row(
            children: [
              Flexible(
                child: Text(
                  channel!.channelName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ambientPalette.accent,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('•', style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${channel!.categoryName} • ${channel!.languageName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.50),
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 3. Name of That Event
          Text(
            program?.showName.trim() ?? 'Live Broadcast',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.0,
              height: 1.3,
              color: Colors.white,
              fontFamilyFallback: ['sans-serif', 'Arial'],
            ),
          ),

          const SizedBox(height: 14),

          // 4. Time Progress with Timing & Dynamic Ambient Styling
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$startTimeStr — $endTimeStr',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.70),
                  letterSpacing: 0.2,
                ),
              ),
              if (program != null)
                Text(
                  '${(program!.progress * 100).toInt()}% elapsed',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: ambientPalette.accent.withValues(alpha: 0.90),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: program?.progress ?? 0.35,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(ambientPalette.accent),
            ),
          ),

          const SizedBox(height: 16),

          // 5. Brief Info (Zero action buttons as requested)
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                program?.description.isNotEmpty == true
                    ? program!.description
                    : 'Now broadcasting live on ${channel!.channelName} via PrismTV network.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.6,
                  color: Colors.white.withValues(alpha: 0.65),
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: CachedNetworkImage(
          imageUrl: channel!.fullLogoUrl,
          fit: BoxFit.contain,
          placeholder: (_, _) => const ShimmerBox(
            width: 100,
            height: 60,
          ),
          errorWidget: (_, _, _) => const Icon(Icons.tv_rounded, size: 48, color: Colors.white38),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const ShimmerBox(
      width: double.infinity,
      height: double.infinity,
    );
  }
}

/// Cinejoy PK-style Ambient Top Bleed Atmosphere with Smooth Fluid Color Morphing
/// Top 42vh ambient light bleed that fades seamlessly into pitch obsidian (#07080C).
/// Calm, tranquil 500ms cubic morphing without muddy screen wash or harsh flickering.
class _AmbientAtmosphereMesh extends StatefulWidget {
  final AmbientPalette palette;

  const _AmbientAtmosphereMesh({
    required this.palette,
  });

  @override
  State<_AmbientAtmosphereMesh> createState() => _AmbientAtmosphereMeshState();
}

class _AmbientAtmosphereMeshState extends State<_AmbientAtmosphereMesh>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late AmbientPalette _fromPalette;
  late AmbientPalette _toPalette;
  late AmbientPalette _currentPalette;

  @override
  void initState() {
    super.initState();
    _fromPalette = widget.palette;
    _toPalette = widget.palette;
    _currentPalette = widget.palette;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    )..addListener(() {
        setState(() {
          _currentPalette = AmbientPalette.lerp(
            _fromPalette,
            _toPalette,
            _animation.value,
          );
        });
      });
  }

  @override
  void didUpdateWidget(_AmbientAtmosphereMesh oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.palette != oldWidget.palette) {
      _fromPalette = _currentPalette;
      _toPalette = widget.palette;

      final bool isGoingToDefault = !_toPalette.isActive;
      _controller.duration = isGoingToDefault
          ? const Duration(milliseconds: 300)
          : const Duration(milliseconds: 500);

      _animation = CurvedAnimation(
        parent: _controller,
        curve: isGoingToDefault ? Curves.easeOutQuad : Curves.easeOutCubic,
      );

      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasGlow = _currentPalette.isActive || _currentPalette.primaryGlow.a > 0.005;
    final topBleedColor = _currentPalette.primaryAccent;
    final secondaryBleed = _currentPalette.secondaryAccent;

    return Container(
      color: const Color(0xFF07080C),
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasGlow) ...[
              // 1. Cinejoy Top Ambient Bleed (dissolves smoothly to bottom transparent)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        topBleedColor.withValues(alpha: 0.22),
                        topBleedColor.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),

              // 2. Soft Upper-Right Radial Atmosphere Bloom (behind top event info / header)
              Positioned(
                top: 0,
                right: 0,
                width: MediaQuery.of(context).size.width * 0.55,
                height: MediaQuery.of(context).size.height * 0.60,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.40, -0.65),
                      radius: 1.15,
                      colors: [
                        topBleedColor.withValues(alpha: 0.24),
                        secondaryBleed.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. Channels Container Ambient Atmosphere Pool (rich ambient light behind left shelves & cards)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.12,
                left: 0,
                width: MediaQuery.of(context).size.width * 0.72,
                height: MediaQuery.of(context).size.height * 0.78,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.35, 0.05),
                      radius: 1.10,
                      colors: [
                        secondaryBleed.withValues(alpha: 0.16),
                        topBleedColor.withValues(alpha: 0.07),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.48, 1.0],
                    ),
                  ),
                ),
              ),
            ],

            // Soft Left/Right Cinematic Edge Vignette for crystal-clear readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.30),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.30),
                    ],
                    stops: const [0.0, 0.08, 0.92, 1.0],
                  ),
                ),
              ),
            ),

            // Base subtle bottom floor anchoring (only at very bottom edge, does not kill shelves)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF07080C).withValues(alpha: 0.50),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
