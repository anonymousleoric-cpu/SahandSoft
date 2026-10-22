import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// SahandSoft Design Tokens
/// ---------------------------------------------------------------------------
/// Single source of truth for the SahandSoft visual language.
/// Every color, radius, spacing and duration used across the app is defined
/// here so the whole brand can be adjusted from one place.
///
/// Do NOT hard-code colors in widgets — always reference [AppColors],
/// [AppRadius], [AppSpacing] or [AppDurations].
/// ---------------------------------------------------------------------------

abstract final class AppColors {
  // ---- Brand ---------------------------------------------------------------
  /// Deep teal — the primary brand color used for actions & highlights.
  static const Color brandDeep = Color(0xFF0B7C8C);

  /// Bright teal-cyan — primary on dark surfaces.
  static const Color brandBright = Color(0xFF2FD8C6);

  /// A soft tint of the brand color for icon containers / badges.
  static Color brandTintOf(Color base) => base.withValues(alpha: 0.14);

  // ---- Dark theme ----------------------------------------------------------
  static const Color darkBg = Color(0xFF0B1220); // very dark navy
  static const Color darkSurface = Color(0xFF111A2C);
  static const Color darkSurfaceAlt = Color(0xFF182338);
  static const Color darkOutline = Color(0xFF233047);
  static const Color darkOnBg = Color(0xFFE8EEF7);
  static const Color darkMuted = Color(0xFF8A97AB);

  // ---- Light theme ---------------------------------------------------------
  static const Color lightBg = Color(0xFFF4F6F9); // grayish white
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEDF1F6);
  static const Color lightOutline = Color(0xFFD8DFE9);
  static const Color lightOnBg = Color(0xFF101828);
  static const Color lightMuted = Color(0xFF5B6779);

  // ---- Semantic ------------------------------------------------------------
  static const Color successDark = Color(0xFF4ADE80); // soft green
  static const Color successLight = Color(0xFF15803D);
  static const Color warningDark = Color(0xFFFBBF24); // amber
  static const Color warningLight = Color(0xFFB45309);
  static const Color dangerDark = Color(0xFFF87171); // controlled red
  static const Color dangerLight = Color(0xFFDC2626);

  // ---- Connection state palette -------------------------------------------
  /// Neutral idle (disconnected but calm, not alarming).
  static const Color idleDark = Color(0xFF33415C);
  static const Color idleLight = Color(0xFF94A3B8);
}

abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double huge = 48;
}

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration pulse = Duration(milliseconds: 1800);
}

abstract final class AppElevation {
  static const double none = 0;
  static const double subtle = 1;
  static const double card = 2;
}

/// Typeface registered in pubspec as family "Sahand" (Shabnam, SIL OFL 1.1).
abstract final class AppFont {
  static const String family = 'Sahand';
}
