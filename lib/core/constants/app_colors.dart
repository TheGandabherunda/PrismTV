import 'package:flutter/material.dart';

/// PrismTV Brand Design System - Sunset Coral to Electric Violet Modern Palette
/// Features pure pitch black (#000000) paired with warm sunset peach/coral,
/// rose orchid, and rich electric violet matching our triangular prism identity.
class AppColors {
  // Pure Pitch Black & OLED Dark Surfaces (Zero Gray Wash)
  static const Color background = Color(0xFF000000);         // 100% True OLED Pitch Black
  static const Color surface = Color(0xFF0D0B0D);            // Deep obsidian with warm plum-dark depth
  static const Color surfaceCard = Color(0xFF151216);        // Sleek dark glass card
  static const Color surfaceElevated = Color(0xFF1E1820);    // Elevated modal/popover surface
  static const Color surfaceHover = Color(0xFF2A222C);       // Interactive hover surface

  // Signature Brand Accents (Sunset Coral -> Orchid -> Electric Violet)
  static const Color primary = Color(0xFFA51EE5);            // Electric Violet / Magenta
  static const Color primaryLight = Color(0xFFC77DF0);       // Soft Lilac Violet
  static const Color primaryGlow = Color(0x38A51EE5);        // 22% violet glow
  
  static const Color secondary = Color(0xFFF28B6E);          // Warm Sunset Coral / Peach
  static const Color secondaryLight = Color(0xFFF9B39E);     // Soft Peach
  static const Color secondaryGlow = Color(0x38F28B6E);      // 22% coral glow
  
  static const Color accent = Color(0xFFC76F97);             // Rose Orchid
  static const Color gold = Color(0xFFFFB800);               // Royal Solar Gold
  static const Color liveRed = Color(0xFFFF1744);            // Pulsing Live Broadcast Red

  // Focus & Selection States (TV Remote D-Pad & Mouse Hover)
  static const Color focusedBorder = Color(0xFFA51EE5);      // Radiant Violet Focus Ring
  static const Color focusedGlow = Color(0x66A51EE5);        // High-energy focus halo
  static const Color focusedBackground = Color(0xFF221626);  // Deep violet-espresso obsidian
  static const Color unfocusedBorder = Color(0x1AFFFFFF);    // 10% translucent border
  static const Color unfocusedCardBorder = Color(0x12FFFFFF);// 7% subtle card border

  // Typography (Ultra-Crisp & High Contrast)
  static const Color textPrimary = Color(0xFFFFFFFF);        // 100% Pure White
  static const Color textSecondary = Color(0xFFA1A1AA);      // Zinc 400
  static const Color textMuted = Color(0xFF52525B);          // Zinc 600

  // Brand Signature Gradients (Warm Coral -> Rose Orchid -> Electric Violet)
  static const LinearGradient prismGradient = LinearGradient(
    colors: [Color(0xFFF28B6E), Color(0xFFC76F97), Color(0xFFA51EE5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient activeTabGradient = LinearGradient(
    colors: [Color(0xFFE87A5B), Color(0xFFA51EE5)],
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
    colors: [Color(0xFFF28B6E), Color(0xFFA51EE5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
