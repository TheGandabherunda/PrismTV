import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/ambient_color_service.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../data/models/channel_model.dart';

class ChannelCard extends StatefulWidget {
  final ChannelModel channel;
  final VoidCallback onTap;
  final ValueChanged<bool>? onFocusChange;
  final ValueChanged<bool>? onHoverChange;
  final VoidCallback? onFavoriteToggle;
  final bool isActive;

  const ChannelCard({
    super.key,
    required this.channel,
    required this.onTap,
    this.onFocusChange,
    this.onHoverChange,
    this.onFavoriteToggle,
    this.isActive = false,
  });

  @override
  State<ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<ChannelCard> {
  bool _isFocused = false;
  bool _isHovered = false;
  Color? _extractedColor;

  @override
  void initState() {
    super.initState();
    _loadColor();
  }

  @override
  void didUpdateWidget(ChannelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.channel.channelId != oldWidget.channel.channelId) {
      _loadColor();
    }
  }

  void _loadColor() {
    // 1. Check if color already extracted in memory cache
    final cached = AmbientColorService.getCached(widget.channel.fullLogoUrl) ??
        AmbientColorService.getCached(widget.channel.channelName);
    if (cached != null) {
      _extractedColor = cached.primaryAccent;
      return;
    }

    // 2. Immediate synchronous seed color from category & channel name (zero network jank)
    _extractedColor = AmbientPalette.getSeedPalette(
      widget.channel.channelName,
      widget.channel.categoryName,
    ).primaryAccent;
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = _isFocused || _isHovered || widget.isActive;
    final cardAccent = _extractedColor ?? const Color(0xFF9333EA);

    // Subtle, clean Cinejoy matte card background with gentle glass depth
    const cardBg = Color(0xFF13141C);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 170;

        return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter ||
              event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.space) {
            widget.onTap();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyF) {
            widget.onFavoriteToggle?.call();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
        widget.onFocusChange?.call(focused);
      },
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          if (widget.onHoverChange != null) {
            widget.onHoverChange!(true);
          } else {
            widget.onFocusChange?.call(true);
          }
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          if (widget.onHoverChange != null) {
            widget.onHoverChange!(false);
          } else if (!_isFocused) {
            widget.onFocusChange?.call(false);
          }
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            // Subtle, clean Cinejoy hover scale (1.04 instead of 1.05+)
            scale: highlighted ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: cardBg,
                // Cinejoy rounded-xl (12px)
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isActive
                      ? AppColors.primary
                      : (highlighted
                          ? Colors.white.withValues(alpha: 0.28)
                          : Colors.white.withValues(alpha: 0.07)),
                  width: widget.isActive ? 1.8 : 1.0,
                ),
                // Cinejoy exact shadow-xl shadow-black/40 drop shadow
                boxShadow: highlighted
                    ? const [
                        BoxShadow(
                          color: Color(0x80000000), // rgba(0, 0, 0, 0.50)
                          blurRadius: 26,
                          offset: Offset(0, 14),
                          spreadRadius: -3,
                        ),
                        BoxShadow(
                          color: Color(0x40000000), // rgba(0, 0, 0, 0.25)
                          blurRadius: 10,
                          offset: Offset(0, 5),
                          spreadRadius: -2,
                        ),
                      ]
                    : const [
                        BoxShadow(
                          color: Color(0x52000000), // rgba(0, 0, 0, 0.32)
                          blurRadius: 18,
                          offset: Offset(0, 8),
                          spreadRadius: -4,
                        ),
                        BoxShadow(
                          color: Color(0x2E000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                          spreadRadius: -2,
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // 1. Subtle, Clean Logo Atmosphere (emanating softly behind the logo)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0.0, -0.22),
                            radius: 0.85,
                            colors: [
                              cardAccent.withValues(alpha: highlighted ? 0.28 : 0.09),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // 2. Channel Logo Centerpiece (in tall portrait frame)
                    Center(
                      child: Padding(
                        padding: isCompact
                            ? const EdgeInsets.fromLTRB(14, 20, 14, 52)
                            : const EdgeInsets.fromLTRB(20, 28, 20, 62),
                        child: widget.channel.logoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: widget.channel.fullLogoUrl,
                                fit: BoxFit.contain,
                                memCacheWidth: 200,
                                placeholder: (_, _) => Center(
                                  child: ShimmerBox(
                                    width: isCompact ? 60 : 84,
                                    height: isCompact ? 40 : 54,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                errorWidget: (_, _, _) => _buildPlaceholder(highlighted, cardAccent),
                              )
                            : _buildPlaceholder(highlighted, cardAccent),
                      ),
                    ),

                    // 3. Top Bar (Playing Pill / HD Badge on Left, Favorite Star on Right)
                    Positioned(
                      top: isCompact ? 6 : 10,
                      left: isCompact ? 6 : 12,
                      right: isCompact ? 6 : 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: widget.isActive
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.prismGradient,
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.5),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.play_arrow_rounded, size: 9, color: Colors.white),
                                        SizedBox(width: 2),
                                        Flexible(
                                          child: Text(
                                            'PLAYING',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : (widget.channel.isHd
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.45),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.14),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: const Text(
                                          'HD',
                                          style: TextStyle(
                                            fontSize: 9.0,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink()),
                          ),

                          // Favorite Star Button (Always touchable on mobile & TV)
                          if (widget.onFavoriteToggle != null)
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: widget.onFavoriteToggle,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: widget.channel.isFavorite
                                      ? const Color(0x55FFB800)
                                      : Colors.black.withValues(alpha: 0.42),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: widget.channel.isFavorite
                                        ? AppColors.gold.withValues(alpha: 0.80)
                                        : Colors.white.withValues(alpha: 0.20),
                                    width: 0.8,
                                  ),
                                ),
                                child: Icon(
                                  widget.channel.isFavorite
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 16,
                                  color: widget.channel.isFavorite
                                      ? AppColors.gold
                                      : Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // 4. Frosted Glass Bottom Bar with Dark Fade Upwards
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: isCompact
                            ? const EdgeInsets.fromLTRB(10, 14, 10, 10)
                            : const EdgeInsets.fromLTRB(14, 20, 14, 14),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          gradient: const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Color(0xF808090E),
                              Color(0xE808090E),
                              Color(0x7308090E),
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.45, 0.82, 1.0],
                          ),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withValues(alpha: highlighted ? 0.12 : 0.04),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.channel.channelName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: isCompact ? 12.0 : 13.5,
                                    fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600,
                                    color: highlighted ? Colors.white : const Color(0xFFF1F1F4),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.channel.languageName.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: isCompact ? 9.0 : 10.0,
                                    fontWeight: FontWeight.w800,
                                    color: highlighted ? cardAccent : AppColors.textMuted,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(bool highlighted, Color cardAccent) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.tv_rounded,
          size: 38,
          color: highlighted ? cardAccent : AppColors.textMuted,
        ),
        const SizedBox(height: 8),
        Text(
          widget.channel.channelName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
