import 'package:flutter/material.dart';

class AppColors {
  // Deep Cinematic TV Backgrounds
  static const Color background = Color(0xFF0A0C13);
  static const Color surface = Color(0xFF121524);
  static const Color surfaceElevated = Color(0xFF1B2036);
  static const Color surfaceCard = Color(0xFF15192C);

  // Prism Accents
  static const Color primary = Color(0xFF00E5FF);       // Neon Cyan
  static const Color primaryGlow = Color(0x3300E5FF);
  static const Color secondary = Color(0xFF7C4DFF);     // Royal Violet
  static const Color accent = Color(0xFFFF2A85);        // Neon Magenta
  static const Color gold = Color(0xFFFFB300);          // Kannada / Bherunda Gold

  // Focus States for TV Remote (D-Pad)
  static const Color focusedBorder = Color(0xFF00E5FF);
  static const Color focusedGlow = Color(0x6600E5FF);
  static const Color focusedBackground = Color(0xFF232A48);
  static const Color unfocusedBorder = Color(0x1FFFFFFF);

  // Typography
  static const Color textPrimary = Color(0xFFF1F3F9);
  static const Color textSecondary = Color(0xFF8E95AF);
  static const Color textMuted = Color(0xFF5A6178);

  // Gradients
  static const LinearGradient prismGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF), Color(0xFFFF2A85)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardOverlay = LinearGradient(
    colors: [Colors.transparent, Color(0xEE0A0C13)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

