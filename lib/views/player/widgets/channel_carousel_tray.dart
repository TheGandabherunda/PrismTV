import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/channel_model.dart';
import '../../home/widgets/channel_card.dart';

/// Redesigned Categorized Channel Tray for Live TV Player
/// Organizes channels by categories synced with Home Screen filters
/// 100% Remote D-Pad & Keyboard Navigable with Focus Highlight
class ChannelCarouselTray extends StatefulWidget {
  final List<ChannelModel> channels;
  final List<MapEntry<CategoryModel, List<ChannelModel>>>? categorizedSections;
  final ChannelModel activeChannel;
  final ValueChanged<ChannelModel> onSelect;
  final VoidCallback onClose;

  const ChannelCarouselTray({
    super.key,
    required this.channels,
    this.categorizedSections,
    required this.activeChannel,
    required this.onSelect,
    required this.onClose,
  });

  @override
  State<ChannelCarouselTray> createState() => _ChannelCarouselTrayState();
}

class _ChannelCarouselTrayState extends State<ChannelCarouselTray> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();

  int _selectedCategoryIndex = 0; // 0 = All Channels

  List<String> _categoryTitles = [];
  List<ChannelModel> _currentChannels = [];

  @override
  void initState() {
    super.initState();
    _buildCategoryList();
    _updateDisplayedChannels();

    // Auto-scroll to active channel when tray opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToActiveChannel();
    });
  }

  @override
  void didUpdateWidget(ChannelCarouselTray oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.channels != oldWidget.channels ||
        widget.categorizedSections != oldWidget.categorizedSections) {
      _buildCategoryList();
      _updateDisplayedChannels();
    }
  }

  void _buildCategoryList() {
    final titles = <String>['All Channels'];
    if (widget.categorizedSections != null && widget.categorizedSections!.isNotEmpty) {
      for (final sec in widget.categorizedSections!) {
        titles.add(sec.key.title);
      }
    }
    _categoryTitles = titles;
    if (_selectedCategoryIndex >= _categoryTitles.length) {
      _selectedCategoryIndex = 0;
    }
  }

  void _updateDisplayedChannels() {
    if (widget.categorizedSections == null || widget.categorizedSections!.isEmpty) {
      _currentChannels = widget.channels;
      return;
    }

    if (_selectedCategoryIndex == 0) {
      // Flatten all channels from active categories (respects home screen filters!)
      final list = <ChannelModel>[];
      for (final sec in widget.categorizedSections!) {
        list.addAll(sec.value);
      }
      _currentChannels = list.isNotEmpty ? list : widget.channels;
    } else {
      final secIndex = _selectedCategoryIndex - 1;
      if (secIndex < widget.categorizedSections!.length) {
        _currentChannels = widget.categorizedSections![secIndex].value;
      } else {
        _currentChannels = widget.channels;
      }
    }
  }

  void _scrollToActiveChannel() {
    final idx = _currentChannels.indexWhere((c) => c.channelId == widget.activeChannel.channelId);
    if (idx > 0 && _scrollController.hasClients) {
      final targetOffset = (idx * 216.0) - 120.0;
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _selectCategory(int index) {
    if (_selectedCategoryIndex == index) return;
    setState(() {
      _selectedCategoryIndex = index;
      _updateDisplayedChannels();
    });
    // Reset channels scroll offset
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  void _scrollRelative(double delta) {
    if (!_scrollController.hasClients) return;
    final current = _scrollController.offset;
    final target = (current + delta).clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Color(0x5507080C),
                Color(0xB807080C),
                Color(0xFA07080C),
                Color(0xFF07080C),
              ],
              stops: [0.0, 0.16, 0.42, 0.72, 1.0],
            ),
          ),
          padding: const EdgeInsets.only(top: 8, bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Center Downward Collapse Arrow Button (Top Center)
              Center(
                child: Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.select ||
                          event.logicalKey == LogicalKeyboardKey.enter ||
                          event.logicalKey == LogicalKeyboardKey.space) {
                        widget.onClose();
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Builder(
                    builder: (ctx) {
                      final hasFocus = Focus.of(ctx).hasFocus;
                      return Tooltip(
                        message: 'Hide channels (Esc / Down)',
                        child: InkWell(
                          onTap: widget.onClose,
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 36,
                            height: 36,
                            margin: const EdgeInsets.only(top: 4, bottom: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasFocus
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.14),
                              border: Border.all(
                                color: hasFocus
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.22),
                                width: 1.2,
                              ),
                              boxShadow: hasFocus
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primaryGlow.withValues(alpha: 0.5),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 2. Centered & Properly Rounded Category Chips Row (Capsule Pill Shaped)
              if (_categoryTitles.length > 1)
                Container(
                  height: 44,
                  margin: const EdgeInsets.only(top: 2, bottom: 10),
                  child: Center(
                    child: SingleChildScrollView(
                      controller: _categoryScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_categoryTitles.length, (idx) {
                          final title = _categoryTitles[idx];
                          final isSelected = _selectedCategoryIndex == idx;

                          return Padding(
                            padding: EdgeInsets.only(right: idx < _categoryTitles.length - 1 ? 8 : 0),
                            child: Focus(
                              onKeyEvent: (node, event) {
                                if (event is KeyDownEvent) {
                                  if (event.logicalKey == LogicalKeyboardKey.select ||
                                      event.logicalKey == LogicalKeyboardKey.enter ||
                                      event.logicalKey == LogicalKeyboardKey.space) {
                                    _selectCategory(idx);
                                    return KeyEventResult.handled;
                                  }
                                }
                                return KeyEventResult.ignored;
                              },
                              child: Builder(
                                builder: (ctx) {
                                  final hasFocus = Focus.of(ctx).hasFocus;
                                  return InkWell(
                                    onTap: () => _selectCategory(idx),
                                    borderRadius: BorderRadius.circular(24),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 160),
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary
                                            : (hasFocus
                                                ? Colors.white.withValues(alpha: 0.20)
                                                : Colors.white.withValues(alpha: 0.08)),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: hasFocus
                                              ? Colors.white
                                              : (isSelected
                                                  ? AppColors.primaryLight
                                                  : Colors.white.withValues(alpha: 0.14)),
                                          width: hasFocus || isSelected ? 1.5 : 1.0,
                                        ),
                                        boxShadow: isSelected || hasFocus
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.primaryGlow.withValues(alpha: 0.38),
                                                  blurRadius: 10,
                                                  spreadRadius: 1,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: isSelected || hasFocus ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected || hasFocus ? Colors.white : Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),

              // 3. Horizontal Channels Carousel (Cinejoy Card Design, Full D-pad Focus)
              SizedBox(
                height: 330,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ListView.separated(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      itemCount: _currentChannels.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final ch = _currentChannels[index];
                        final isActive = ch.channelId == widget.activeChannel.channelId;

                        return Focus(
                          onFocusChange: (focused) {
                            if (focused && _scrollController.hasClients) {
                              // Ensure focused card scrolls comfortably into view
                              final cardOffset = index * 216.0;
                              final visibleMin = _scrollController.offset;
                              final visibleMax = visibleMin + MediaQuery.of(context).size.width - 240;
                              if (cardOffset < visibleMin || cardOffset > visibleMax) {
                                _scrollController.animateTo(
                                  (cardOffset - 100.0).clamp(0.0, _scrollController.position.maxScrollExtent),
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            }
                          },
                          child: SizedBox(
                            width: 195,
                            child: ChannelCard(
                              channel: ch,
                              isActive: isActive,
                              onTap: () => widget.onSelect(ch),
                            ),
                          ),
                        );
                      },
                    ),

                    // Left Edge Progressive Fade
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 56,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                const Color(0xD907080C),
                                const Color(0xD907080C).withValues(alpha: 0.50),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.50, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Right Edge Progressive Fade
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 56,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [
                                const Color(0xD907080C),
                                const Color(0xD907080C).withValues(alpha: 0.50),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.50, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Floating Left Scroll Button
                    Positioned(
                      left: 8,
                      top: 130,
                      child: _ScrollNavButton(
                        icon: Icons.chevron_left_rounded,
                        onTap: () => _scrollRelative(-480),
                      ),
                    ),

                    // Floating Right Scroll Button
                    Positioned(
                      right: 8,
                      top: 130,
                      child: _ScrollNavButton(
                        icon: Icons.chevron_right_rounded,
                        onTap: () => _scrollRelative(480),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScrollNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ScrollNavButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      child: Builder(
        builder: (ctx) {
          final hasFocus = Focus.of(ctx).hasFocus;
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasFocus ? AppColors.primary : Colors.black.withValues(alpha: 0.70),
                border: Border.all(
                  color: hasFocus ? Colors.white : Colors.white.withValues(alpha: 0.25),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: hasFocus ? AppColors.primaryGlow.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            ),
          );
        },
      ),
    );
  }
}
