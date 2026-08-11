import 'package:flutter/material.dart';

// ──────────────────────────────────────────────────────
// WIKI ROULETTE COLOR PALETTE
// Premium dark glassmorphism design system
// ──────────────────────────────────────────────────────

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF050505);
  static const Color surface = Color(0xFF0D0D0F);
  static const Color surfaceElevated = Color(0xFF141416);
  static const Color cardSurface = Color(0xFF111113);

  // Glass
  static const Color glass = Color(0x0FFFFFFF);          // rgba(255,255,255,0.06)
  static const Color glassBorder = Color(0x1AFFFFFF);    // rgba(255,255,255,0.10)
  static const Color glassLight = Color(0x18FFFFFF);     // rgba(255,255,255,0.09)

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);
  static const Color textDisabled = Color(0xFF52525B);

  // Brand accents
  static const Color accent = Color(0xFF8B5CF6);        // Purple
  static const Color accentLight = Color(0xFFA78BFA);
  static const Color accentDark = Color(0xFF7C3AED);
  static const Color secondaryAccent = Color(0xFF22D3EE); // Cyan
  static const Color secondaryAccentDark = Color(0xFF06B6D4);

  // Semantic
  static const Color success = Color(0xFF34D399);
  static const Color successDark = Color(0xFF059669);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);
  static const Color errorDark = Color(0xFFDC2626);

  // Gradients
  static const List<Color> accentGradient = [accent, secondaryAccent];
  static const List<Color> backgroundGradient = [
    Color(0xFF0A0A0F),
    Color(0xFF050505),
  ];
  static const List<Color> cardGradient = [
    Color(0xFF15151A),
    Color(0xFF0D0D12),
  ];

  // Glow colors (for radial gradients)
  static const Color accentGlow = Color(0x338B5CF6);
  static const Color cyanGlow = Color(0x2222D3EE);

  // Bottom nav
  static const Color navBackground = Color(0xFF0A0A0E);

  // Streak
  static const Color streak = Color(0xFFFF6B2C);

  // Level bar
  static const Color xpBarFill = accent;
  static const Color xpBarBg = Color(0xFF1A1A2E);
}
