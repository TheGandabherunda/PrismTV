import 'package:flutter/material.dart';

/// Synchronized, high-performance Shimmer Animation Controller for obsidian dark themes.
/// Runs a single 60fps GPU-accelerated ticker across all child skeleton widgets.
class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;

  const Shimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
    this.baseColor = const Color(0xFF17141E),
    this.highlightColor = const Color(0xFF2C2438),
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return _ShimmerScope(
          percent: _controller.value,
          baseColor: widget.baseColor,
          highlightColor: widget.highlightColor,
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}

class _ShimmerScope extends InheritedWidget {
  final double percent;
  final Color baseColor;
  final Color highlightColor;

  const _ShimmerScope({
    required this.percent,
    required this.baseColor,
    required this.highlightColor,
    required super.child,
  });

  static _ShimmerScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ShimmerScope>();
  }

  @override
  bool updateShouldNotify(_ShimmerScope oldWidget) {
    return oldWidget.percent != percent ||
        oldWidget.baseColor != baseColor ||
        oldWidget.highlightColor != highlightColor;
  }
}

/// A standalone or synchronized shimmering skeleton box
class ShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;
  final Color? baseColor;
  final Color? highlightColor;
  final EdgeInsetsGeometry? margin;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.baseColor,
    this.highlightColor,
    this.margin,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  AnimationController? _fallbackController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = _ShimmerScope.of(context);
    if (scope == null && _fallbackController == null) {
      _fallbackController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat();
    } else if (scope != null && _fallbackController != null) {
      _fallbackController?.dispose();
      _fallbackController = null;
    }
  }

  @override
  void dispose() {
    _fallbackController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = _ShimmerScope.of(context);
    final percent = scope?.percent ?? _fallbackController?.value ?? 0.0;
    final base = widget.baseColor ?? scope?.baseColor ?? const Color(0xFF17141E);
    final highlight = widget.highlightColor ??
        scope?.highlightColor ??
        const Color(0xFF2E253B);

    final double start = (percent * 3.0) - 1.0;
    final double mid = start + 0.35;
    final double end = start + 0.70;

    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        shape: widget.shape,
        borderRadius: widget.shape == BoxShape.circle ? null : (widget.borderRadius ?? BorderRadius.circular(8)),
        gradient: LinearGradient(
          begin: const Alignment(-1.0, -0.3),
          end: const Alignment(1.0, 0.3),
          stops: [
            (start - 0.2).clamp(0.0, 1.0),
            start.clamp(0.0, 1.0),
            mid.clamp(0.0, 1.0),
            end.clamp(0.0, 1.0),
            (end + 0.2).clamp(0.0, 1.0),
          ],
          colors: [
            base,
            base,
            highlight,
            base,
            base,
          ],
        ),
      ),
    );
  }
}

/// Shimmering Skeleton for an individual 200x350 Channel Card
class SkeletonChannelCard extends StatelessWidget {
  const SkeletonChannelCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 350,
      decoration: BoxDecoration(
        color: const Color(0xD910121B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Top Bar: HD badge & Favorite placeholders
            Positioned(
              top: 12,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerBox(
                    width: 28,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const ShimmerBox(
                    width: 22,
                    height: 22,
                    shape: BoxShape.circle,
                  ),
                ],
              ),
            ),

            // Center Channel Logo Placeholder
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: ShimmerBox(
                  width: 90,
                  height: 64,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // Bottom Name and Category Bars with dark fade from bottom to top
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 20, 14, 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
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
                      color: Color(0x0AFFFFFF),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShimmerBox(
                      width: 125,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    ShimmerBox(
                      width: 65,
                      height: 10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmering Skeleton Shelf containing section header and 6 cards
class SkeletonShelf extends StatelessWidget {
  const SkeletonShelf({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Row(
              children: [
                ShimmerBox(
                  width: 130,
                  height: 20,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(width: 10),
                ShimmerBox(
                  width: 70,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),

          // Cards Row
          SizedBox(
            height: 350,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              itemCount: 6,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (_, _) => const SkeletonChannelCard(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmering Skeleton for the Right-Side EPG Column
class SkeletonEpgSideColumn extends StatelessWidget {
  const SkeletonEpgSideColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      padding: const EdgeInsets.fromLTRB(12, 32, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Shimmering 16:9 Event Poster Box
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141218),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: const ShimmerBox(
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 2. Metadata pills (Channel & Category)
          Row(
            children: [
              ShimmerBox(
                width: 95,
                height: 14,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(width: 8),
              Text('•', style: TextStyle(color: Colors.white.withValues(alpha: 0.2))),
              const SizedBox(width: 8),
              ShimmerBox(
                width: 110,
                height: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 3. Event Title Bar
          ShimmerBox(
            width: 220,
            height: 22,
            borderRadius: BorderRadius.circular(6),
          ),

          const SizedBox(height: 16),

          // 4. Time & Percentage Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(
                width: 120,
                height: 12,
                borderRadius: BorderRadius.circular(4),
              ),
              ShimmerBox(
                width: 50,
                height: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress Bar Placeholder
          ShimmerBox(
            width: double.infinity,
            height: 4,
            borderRadius: BorderRadius.circular(2),
          ),

          const SizedBox(height: 20),

          // 5. Multiline Description Shimmer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: double.infinity,
                  height: 12,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 8),
                ShimmerBox(
                  width: 240,
                  height: 12,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 8),
                ShimmerBox(
                  width: 180,
                  height: 12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

