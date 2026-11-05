import 'package:flutter/material.dart';

/// PrismTV Brand Design System
/// Dark Theme & Icon Base: #1C1613
/// Light Theme Base: #F4F4F4
/// Signature Gradient Palette:
///   - 0%: #F4F4F4
///   - 30%: #F4F4F4
///   - 70%: #CB907D
///   - 100%: #A839C7
class AppColors {
  // Brand Core Colors
  static const Color iconColor = Color(0xFF1C1613);
  static const Color darkBackground = Color(0xFF1C1613);
  static const Color lightBackground = Color(0xFFF4F4F4);

  // Background & Surfaces (Default Dark #1C1613)
  static const Color background = Color(0xFF1C1613);         // #1C1613 Warm Dark Obsidian
  static const Color surface = Color(0xFF241E1A);            // Elevated warm dark
  static const Color surfaceCard = Color(0xFF2A231F);        // Sleek dark glass card
  static const Color surfaceElevated = Color(0xFF332B26);    // Elevated modal/popover surface
  static const Color surfaceHover = Color(0xFF3E342E);       // Interactive hover surface

  // Light Theme Surfaces
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFEBEBEB);
  static const Color lightSurfaceHover = Color(0xFFE2E2E2);

  // Signature Brand Accents
  static const Color primary = Color(0xFFA839C7);            // 100% Signature Electric Violet / Magenta
  static const Color primaryLight = Color(0xFFC762E4);       // Soft Violet
  static const Color primaryGlow = Color(0x38A839C7);        // 22% violet glow
  
  static const Color secondary = Color(0xFFCB907D);          // 70% Warm Sunset Coral / Terracotta
  static const Color secondaryLight = Color(0xFFDFC0B6);     // Soft Peach
  static const Color secondaryGlow = Color(0x38CB907D);      // 22% coral glow
  
  static const Color accent = Color(0xFFCB907D);             // Terracotta Accent
  static const Color gold = Color(0xFFFFB800);               // Royal Solar Gold
  static const Color liveRed = Color(0xFFFF1744);            // Pulsing Live Broadcast Red

  // Focus & Selection States (TV Remote D-Pad & Mouse Hover)
  static const Color focusedBorder = Color(0xFFA839C7);      // Radiant Violet Focus Ring
  static const Color focusedGlow = Color(0x66A839C7);        // High-energy focus halo
  static const Color focusedBackground = Color(0xFF352238);  // Deep violet obsidian
  static const Color unfocusedBorder = Color(0x1AFFFFFF);    // 10% translucent border
  static const Color unfocusedCardBorder = Color(0x12FFFFFF);// 7% subtle card border

  // Pure White & Light Contrast
  static const Color pureWhite = Color(0xFFFFFFFF);          // 100% Pure Clean White
  static const Color logoTile = Color(0xFFF4F4F4);           // Off-white logo tile
  static const Color whiteBorder = Color(0x33FFFFFF);        // Crisp 20% white separator/border

  // Typography
  static const Color textPrimary = Color(0xFFFFFFFF);        // 100% Pure White
  static const Color textSecondary = Color(0xFFB5ADA8);      // Muted warm silver
  static const Color textMuted = Color(0xFF756C67);          // Dim warm stone
  
  static const Color lightTextPrimary = Color(0xFF1C1613);   // Brand dark text for light mode
  static const Color lightTextSecondary = Color(0xFF6B6562);
  static const Color lightTextMuted = Color(0xFF948E8B);

  // Brand Signature Gradient (Exact: F4F4F4 0% -> 30% -> CB907D 70% -> A839C7 100%)
  static const LinearGradient brandGradient = LinearGradient(
    colors: [
      Color(0xFFF4F4F4), // 0%
      Color(0xFFF4F4F4), // 30%
      Color(0xFFCB907D), // 70%
      Color(0xFFA839C7), // 100%
    ],
    stops: [0.0, 0.30, 0.70, 1.0],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const LinearGradient prismGradient = LinearGradient(
    colors: [
      Color(0xFFCB907D),
      Color(0xFFA839C7),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient activeTabGradient = LinearGradient(
    colors: [Color(0xFFCB907D), Color(0xFFA839C7)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardOverlay = LinearGradient(
    colors: [Colors.transparent, Color(0xB31C1613), Color(0xF81C1613)],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1C1613), Color(0x991C1613), Colors.transparent],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static const LinearGradient hdBadgeGradient = LinearGradient(
    colors: [Color(0xFFCB907D), Color(0xFFA839C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
