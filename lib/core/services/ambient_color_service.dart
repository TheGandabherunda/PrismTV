import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:palette_generator/palette_generator.dart';

/// Multi-Color Ambient Palette representing rich dynamic atmospheric lighting across the entire screen.
/// Matches Cinejoy PK luxury aesthetic: deep dark obsidian canvas (#09080C) with soft, organic auras.
class AmbientPalette {
  /// Whether an active channel/program is selected (false = default, zero color)
  final bool isActive;

  /// Primary vibrant accent color (e.g. ruby red, cinema amber, stadium azure)
  final Color primaryAccent;

  /// Secondary contrast/complementary accent color from artwork
  final Color secondaryAccent;

  /// Tertiary atmosphere accent color from artwork
  final Color tertiaryAccent;

  /// Canvas background tint (blended into ultra-dark obsidian when active, pure neutral when inactive)
  final Color backgroundTint;

  /// Light Pool 1: Upper-Right Hero Glow (emanating from behind the 16:9 poster)
  final Color primaryGlow;

  /// Light Pool 2: Upper-Center Atmosphere Glow (emanating behind search capsule and top shelves)
  final Color secondaryGlow;

  /// Light Pool 3: Subtle ambient fill
  final Color tertiaryGlow;

  /// Shelf fade color matching local background tint for seamless edge dissolving
  final Color shelfFade;

  /// Backward compatible aliases
  Color get accent => primaryAccent;
  Color get glow => primaryGlow;

  /// Left shelf edge fade blended with ambient secondary atmosphere
  Color get shelfFadeLeft => isActive
      ? Color.lerp(backgroundTint, secondaryAccent, 0.12)!
      : const Color(0xFF09080C);

  /// Right shelf edge fade blended with ambient primary hero atmosphere
  Color get shelfFadeRight => isActive
      ? Color.lerp(backgroundTint, primaryAccent, 0.16)!
      : const Color(0xFF09080C);

  const AmbientPalette({
    required this.isActive,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.tertiaryAccent,
    required this.backgroundTint,
    required this.primaryGlow,
    required this.secondaryGlow,
    required this.tertiaryGlow,
    required this.shelfFade,
  });

  /// Default neutral palette: BY DEFAULT ZERO COLOR IS THERE!
  /// Canvas is pure pitch dark obsidian (#09080C), with zero glowing light pools.
  static const AmbientPalette defaultPalette = AmbientPalette(
    isActive: false,
    primaryAccent: Color(0xFF09080C),
    secondaryAccent: Color(0xFF09080C),
    tertiaryAccent: Color(0xFF09080C),
    backgroundTint: Color(0xFF09080C), // Pure neutral dark obsidian
    primaryGlow: Colors.transparent, // ZERO color
    secondaryGlow: Colors.transparent, // ZERO color
    tertiaryGlow: Colors.transparent, // ZERO color
    shelfFade: Color(0xFF09080C), // Pure neutral dark obsidian
  );

  /// Continuously interpolates between two ambient palettes for silky-smooth, fluid color morphing
  static AmbientPalette lerp(AmbientPalette a, AmbientPalette b, double t) {
    return AmbientPalette(
      isActive: t > 0.01 ? (b.isActive || a.isActive) : b.isActive,
      primaryAccent: Color.lerp(a.primaryAccent, b.primaryAccent, t)!,
      secondaryAccent: Color.lerp(a.secondaryAccent, b.secondaryAccent, t)!,
      tertiaryAccent: Color.lerp(a.tertiaryAccent, b.tertiaryAccent, t)!,
      backgroundTint: Color.lerp(a.backgroundTint, b.backgroundTint, t)!,
      primaryGlow: Color.lerp(a.primaryGlow, b.primaryGlow, t)!,
      secondaryGlow: Color.lerp(a.secondaryGlow, b.secondaryGlow, t)!,
      tertiaryGlow: Color.lerp(a.tertiaryGlow, b.tertiaryGlow, t)!,
      shelfFade: Color.lerp(a.shelfFade, b.shelfFade, t)!,
    );
  }

  /// Curated cinematic color harmonies by category (Cinejoy aesthetic, never random neon)
  static (Color, Color, Color) getCategoryColors(String? categoryName) {
    final cat = (categoryName ?? '').toLowerCase().trim();
    if (cat.contains('entertain')) {
      return (const Color(0xFFB83A64), const Color(0xFFE11D48), const Color(0xFF9333EA)); // Warm Rose / Plum
    } else if (cat.contains('movie')) {
      return (const Color(0xFFD97706), const Color(0xFFEA580C), const Color(0xFFB45309)); // Cinema Amber / Gold
    } else if (cat.contains('sport')) {
      return (const Color(0xFF0284C7), const Color(0xFF2563EB), const Color(0xFF0D9488)); // Stadium Azure / Blue
    } else if (cat.contains('news')) {
      return (const Color(0xFFDC2626), const Color(0xFFEA580C), const Color(0xFF991B1B)); // Ruby Crimson
    } else if (cat.contains('music')) {
      return (const Color(0xFF9333EA), const Color(0xFFC026D3), const Color(0xFF4F46E5)); // Electric Violet / Magenta
    } else if (cat.contains('kid')) {
      return (const Color(0xFFF59E0B), const Color(0xFFF97316), const Color(0xFF10B981)); // Warm Solar Tangerine
    } else if (cat.contains('info') || cat.contains('docu') || cat.contains('know')) {
      return (const Color(0xFF059669), const Color(0xFF0D9488), const Color(0xFF0284C7)); // Emerald / Cyan
    } else if (cat.contains('spirit') || cat.contains('devo')) {
      return (const Color(0xFFEA580C), const Color(0xFFD97706), const Color(0xFF7C2D12)); // Saffron / Sacred Gold
    }
    // Default cinematic warmth
    return (const Color(0xFFB83A64), const Color(0xFFD97706), const Color(0xFF4338CA));
  }

  /// Generates a fast, harmonious seed palette for instant (0ms) response on hover
  static AmbientPalette getSeedPalette(String channelName, String categoryName) {
    final cached = AmbientColorService._cache[channelName];
    if (cached != null) return cached;

    final (c1, c2, c3) = getCategoryColors(categoryName);

    // Subtle +/- 12 degree harmonic shift per channel name so channels in same category have subtle personality
    final int hash = channelName.hashCode.abs();
    final double hueOffset = ((hash % 25) - 12).toDouble();

    final hsl1 = HSLColor.fromColor(c1);
    final primaryColor = hsl1.withHue((hsl1.hue + hueOffset + 360) % 360).toColor();

    final hsl2 = HSLColor.fromColor(c2);
    final secondaryColor = hsl2.withHue((hsl2.hue + hueOffset + 360) % 360).toColor();

    final hsl3 = HSLColor.fromColor(c3);
    final tertiaryColor = hsl3.withHue((hsl3.hue + hueOffset + 360) % 360).toColor();

    // Dark luxury obsidian canvas with ultra-subtle 1.5% tint (never washes out the screen!)
    final Color bg = Color.lerp(
      const Color(0xFF09080C),
      primaryColor,
      0.015,
    )!;

    return AmbientPalette(
      isActive: true,
      primaryAccent: primaryColor,
      secondaryAccent: secondaryColor,
      tertiaryAccent: tertiaryColor,
      backgroundTint: bg,
      primaryGlow: primaryColor.withValues(alpha: 0.20),
      secondaryGlow: secondaryColor.withValues(alpha: 0.12),
      tertiaryGlow: tertiaryColor.withValues(alpha: 0.05),
      shelfFade: bg,
    );
  }

  /// Computes a rich multi-color ambient palette from extracted PaletteGenerator swatches
  factory AmbientPalette.fromGenerator(
    PaletteGenerator generator, {
    String? categoryName,
    String? channelName,
  }) {
    // 1. Collect all candidate color swatches from the palette generator
    final List<Color> candidates = [];
    if (generator.vibrantColor != null) candidates.add(generator.vibrantColor!.color);
    if (generator.dominantColor != null) candidates.add(generator.dominantColor!.color);
    if (generator.lightVibrantColor != null) candidates.add(generator.lightVibrantColor!.color);
    if (generator.darkVibrantColor != null) candidates.add(generator.darkVibrantColor!.color);
    if (generator.mutedColor != null) candidates.add(generator.mutedColor!.color);
    if (generator.lightMutedColor != null) candidates.add(generator.lightMutedColor!.color);
    for (final c in generator.colors) {
      if (!candidates.contains(c)) candidates.add(c);
    }

    // Filter candidate swatches and sort by saturation to pick the most vibrant colors from the event image
    final List<Color> vibrantCandidates = candidates.where((c) {
      final hsl = HSLColor.fromColor(c);
      return hsl.lightness > 0.08 && hsl.lightness < 0.90 && hsl.saturation > 0.16;
    }).toList();

    vibrantCandidates.sort((a, b) {
      final sa = HSLColor.fromColor(a).saturation;
      final sb = HSLColor.fromColor(b).saturation;
      return sb.compareTo(sa);
    });

    // 2. Primary Color: strongest vibrant candidate directly from event image
    Color primaryColor;
    if (vibrantCandidates.isNotEmpty) {
      final c1 = vibrantCandidates.first;
      final hsl1 = HSLColor.fromColor(c1);
      final adjHsl1 = hsl1
          .withSaturation((hsl1.saturation < 0.35 ? 0.70 : hsl1.saturation).clamp(0.40, 0.98))
          .withLightness((hsl1.lightness < 0.28 ? 0.52 : hsl1.lightness > 0.75 ? 0.58 : hsl1.lightness).clamp(0.35, 0.65));
      primaryColor = adjHsl1.toColor();
    } else {
      // Elegant category fallback
      final (cat1, _, _) = getCategoryColors(categoryName);
      primaryColor = cat1;
    }

    final adjHsl1 = HSLColor.fromColor(primaryColor);

    // 3. Secondary Color: candidate with greatest hue distance from primary (at least 28 degrees)
    Color? c2;
    double maxDist = 0.0;
    for (final c in vibrantCandidates) {
      final hsl = HSLColor.fromColor(c);
      double dist = (hsl.hue - adjHsl1.hue).abs();
      if (dist > 180.0) dist = 360.0 - dist;
      if (dist > maxDist && dist >= 26.0) {
        maxDist = dist;
        c2 = c;
      }
    }

    Color secondaryColor;
    if (c2 != null) {
      final hsl2 = HSLColor.fromColor(c2);
      secondaryColor = hsl2
          .withSaturation((hsl2.saturation < 0.30 ? 0.65 : hsl2.saturation).clamp(0.38, 0.92))
          .withLightness((hsl2.lightness < 0.28 ? 0.50 : hsl2.lightness > 0.75 ? 0.55 : hsl2.lightness).clamp(0.35, 0.65))
          .toColor();
    } else {
      final (_, cat2, _) = getCategoryColors(categoryName);
      secondaryColor = cat2;
    }

    // 4. Tertiary Color: find a 3rd distinct color from the poster, or category tertiary
    Color? c3;
    for (final c in vibrantCandidates) {
      if (c == primaryColor || c == secondaryColor) continue;
      final hsl = HSLColor.fromColor(c);
      double d1 = (hsl.hue - adjHsl1.hue).abs();
      if (d1 > 180) d1 = 360 - d1;
      double d2 = (hsl.hue - HSLColor.fromColor(secondaryColor).hue).abs();
      if (d2 > 180) d2 = 360 - d2;
      if (d1 >= 20.0 && d2 >= 20.0) {
        c3 = c;
        break;
      }
    }

    Color tertiaryColor;
    if (c3 != null) {
      final hsl3 = HSLColor.fromColor(c3);
      tertiaryColor = hsl3
          .withSaturation((hsl3.saturation < 0.28 ? 0.60 : hsl3.saturation).clamp(0.35, 0.88))
          .withLightness((hsl3.lightness < 0.26 ? 0.48 : hsl3.lightness > 0.75 ? 0.52 : hsl3.lightness).clamp(0.32, 0.62))
          .toColor();
    } else {
      final (_, _, cat3) = getCategoryColors(categoryName);
      tertiaryColor = cat3;
    }

    // 5. Background Canvas Tint: 2% primary blended into pure luxury obsidian #09080C
    final Color bg = Color.lerp(
      const Color(0xFF09080C),
      primaryColor,
      0.02,
    )!;

    // 6. Calibrated Cinejoy Light Pools (Luminous, organic, deeply atmospheric)
    final Color primaryGlow = primaryColor.withValues(alpha: 0.28); // Luminous aura behind event poster
    final Color secondaryGlow = secondaryColor.withValues(alpha: 0.16); // Atmospheric ambient spill
    final Color tertiaryGlow = tertiaryColor.withValues(alpha: 0.08); // Subtle lower bloom

    return AmbientPalette(
      isActive: true,
      primaryAccent: primaryColor,
      secondaryAccent: secondaryColor,
      tertiaryAccent: tertiaryColor,
      backgroundTint: bg,
      primaryGlow: primaryGlow,
      secondaryGlow: secondaryGlow,
      tertiaryGlow: tertiaryGlow,
      shelfFade: bg,
    );
  }
}

/// High-performance Multi-Color Ambient Extraction Service with in-memory caching.
/// Decodes images to tiny 24x24 bitmaps via hardware Skia and runs fast quantization
/// without touching the Web DOM or blocking the UI thread.
class AmbientColorService {
  static final Map<String, AmbientPalette> _cache = {};

  /// Returns cached palette if available
  static AmbientPalette? getCached(String key) => _cache[key];

  /// Fast synchronous seed palette for 0ms immediate response
  static AmbientPalette getSeedPalette(String channelName, String categoryName) {
    return AmbientPalette.getSeedPalette(channelName, categoryName);
  }

  /// Extracts the multi-color ambient palette from an image URL (poster or channel logo).
  /// Falls back cleanly to logo or category palette if poster has no vibrant colors.
  static Future<AmbientPalette> extractPalette(
    String? imageUrl, {
    String? fallbackLogoUrl,
    String? categoryName,
    String? channelName,
  }) async {
    final key = imageUrl?.trim();
    if (key != null && key.isNotEmpty && _cache.containsKey(key)) {
      return _cache[key]!;
    }

    if (key != null && key.isNotEmpty) {
      try {
        final response = await http
            .get(Uri.parse(key))
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          final codec = await ui.instantiateImageCodec(
            response.bodyBytes,
            targetWidth: 24,
            targetHeight: 24,
          );
          final frame = await codec.getNextFrame();
          final ByteData? byteData = await frame.image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );

          if (byteData != null) {
            final generator = await PaletteGenerator.fromByteData(
              EncodedImage(byteData, width: 24, height: 24),
              maximumColorCount: 12,
            );

            final palette = AmbientPalette.fromGenerator(
              generator,
              categoryName: categoryName,
              channelName: channelName,
            );
            _cache[key] = palette;
            if (channelName != null) _cache[channelName] = palette;
            return palette;
          }
        }
      } catch (_) {}
    }

    // Try fallback logo if poster extraction had no image or failed
    if (fallbackLogoUrl != null && fallbackLogoUrl.trim().isNotEmpty && fallbackLogoUrl != key) {
      final logoKey = fallbackLogoUrl.trim();
      if (_cache.containsKey(logoKey)) {
        return _cache[logoKey]!;
      }
      try {
        final response = await http
            .get(Uri.parse(logoKey))
            .timeout(const Duration(seconds: 2));

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          final codec = await ui.instantiateImageCodec(
            response.bodyBytes,
            targetWidth: 24,
            targetHeight: 24,
          );
          final frame = await codec.getNextFrame();
          final ByteData? byteData = await frame.image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );

          if (byteData != null) {
            final generator = await PaletteGenerator.fromByteData(
              EncodedImage(byteData, width: 24, height: 24),
              maximumColorCount: 12,
            );

            final palette = AmbientPalette.fromGenerator(
              generator,
              categoryName: categoryName,
              channelName: channelName,
            );
            _cache[logoKey] = palette;
            if (channelName != null) _cache[channelName] = palette;
            return palette;
          }
        }
      } catch (_) {}
    }

    // Curated category seed palette
    return AmbientPalette.getSeedPalette(
      channelName ?? '',
      categoryName ?? '',
    );
  }
}

/// Tween for smooth continuous color morphing of ambient palettes
class AmbientPaletteTween extends Tween<AmbientPalette> {
  AmbientPaletteTween({super.begin, super.end});

  @override
  AmbientPalette lerp(double t) {
    return AmbientPalette.lerp(
      begin ?? AmbientPalette.defaultPalette,
      end ?? AmbientPalette.defaultPalette,
      t,
    );
  }
}
