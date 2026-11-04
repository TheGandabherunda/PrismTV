import 'package:flutter/material.dart';

/// PrismTV Brand Design System - Distinct Modern Entertainment Palette
/// Exclusively crafted for PrismTV by TheGandabherunda.
/// Replaces generic blues/hotstar palettes with pure pitch black (#000000)
/// paired with electric ultraviolet, sunset rose, and royal solar gold.
class AppColors {
  // Pure Pitch Black & OLED Dark Surfaces (Zero Gray / Zero Navy Blue Wash)
  static const Color background = Color(0xFF000000);         // 100% True OLED Pitch Black
  static const Color surface = Color(0xFF070709);            // Neutral dark obsidian
  static const Color surfaceCard = Color(0xFF0F0F14);        // Refined dark glass card
  static const Color surfaceElevated = Color(0xFF17171E);    // Elevated modal/popover surface
  static const Color surfaceHover = Color(0xFF22222C);       // Interactive hover surface

  // Signature PrismTV Modern Brand Accents
  static const Color primary = Color(0xFFA855F7);            // Electric Ultra-Violet
  static const Color primaryLight = Color(0xFFC084FC);       // Soft Violet
  static const Color primaryGlow = Color(0x38A855F7);        // 22% violet glow
  
  static const Color secondary = Color(0xFFFF2A6D);          // Neon Sunset Rose
  static const Color secondaryGlow = Color(0x33FF2A6D);      // 20% rose glow
  
  static const Color accent = Color(0xFFFF7A00);             // Cyber Amber
  static const Color gold = Color(0xFFFFB800);               // Royal Solar Gold (TheGandabherunda)
  static const Color liveRed = Color(0xFFFF1744);            // Pulsing Live Broadcast Red

  // Focus & Selection States (TV D-Pad & Desktop Hover)
  static const Color focusedBorder = Color(0xFFA855F7);      // Radiant Violet Focus Ring
  static const Color focusedGlow = Color(0x66A855F7);        // High-energy focus halo
  static const Color focusedBackground = Color(0xFF1B1428);  // Deep violet obsidian (NOT navy blue)
  static const Color unfocusedBorder = Color(0x1AFFFFFF);    // 10% translucent border
  static const Color unfocusedCardBorder = Color(0x12FFFFFF);// 7% subtle card border

  // Typography (Ultra-Crisp & High Contrast)
  static const Color textPrimary = Color(0xFFFFFFFF);        // 100% Pure White
  static const Color textSecondary = Color(0xFFA1A1AA);      // Zinc 400
  static const Color textMuted = Color(0xFF52525B);          // Zinc 600

  // Brand Signature Gradients
  static const LinearGradient prismGradient = LinearGradient(
    colors: [Color(0xFFA855F7), Color(0xFFFF2A6D), Color(0xFFFFB800)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient activeTabGradient = LinearGradient(
    colors: [Color(0xFF9333EA), Color(0xFFE11D48)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardOverlay = LinearGradient(
    colors: [Colors.transparent, Color(0xB3000000), Color(0xF8000000)],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF000000), Color(0x99000000), Colors.transparent],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static const LinearGradient hdBadgeGradient = LinearGradient(
    colors: [Color(0xFFA855F7), Color(0xFFFF2A6D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
