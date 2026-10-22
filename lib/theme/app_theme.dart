import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_tokens.dart';

/// ---------------------------------------------------------------------------
/// SahandSoft Theme
/// ---------------------------------------------------------------------------
/// Builds the Material 3 light & dark ThemeData from the design tokens.
/// All screens obtain their colors through `Theme.of(context)` / the
/// semantic helpers below — never through hard-coded values.
/// ---------------------------------------------------------------------------

/// Semantic palette resolved for the current brightness.
class SahandPalette {
  const SahandPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.outline,
    required this.onSurface,
    required this.muted,
    required this.primary,
    required this.onPrimary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.idle,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color outline;
  final Color onSurface;
  final Color muted;
  final Color primary;
  final Color onPrimary;
  final Color success;
  final Color warning;
  final Color danger;
  final Color idle;

  static SahandPalette of(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? SahandPalette.dark : SahandPalette.light;
  }

  static const SahandPalette dark = SahandPalette(
    background: AppColors.darkBg,
    surface: AppColors.darkSurface,
    surfaceAlt: AppColors.darkSurfaceAlt,
    outline: AppColors.darkOutline,
    onSurface: AppColors.darkOnBg,
    muted: AppColors.darkMuted,
    primary: AppColors.brandBright,
    onPrimary: Color(0xFF06201F),
    success: AppColors.successDark,
    warning: AppColors.warningDark,
    danger: AppColors.dangerDark,
    idle: AppColors.idleDark,
  );

  static const SahandPalette light = SahandPalette(
    background: AppColors.lightBg,
    surface: AppColors.lightSurface,
    surfaceAlt: AppColors.lightSurfaceAlt,
    outline: AppColors.lightOutline,
    onSurface: AppColors.lightOnBg,
    muted: AppColors.lightMuted,
    primary: AppColors.brandDeep,
    onPrimary: Color(0xFFFFFFFF),
    success: AppColors.successLight,
    warning: AppColors.warningLight,
    danger: AppColors.dangerLight,
    idle: AppColors.idleLight,
  );
}

class SahandTheme {
  SahandTheme._();

  static const String fontFamily = AppFont.family;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: isDark ? AppColors.brandBright : AppColors.brandDeep,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? AppColors.brandBright : AppColors.brandDeep,
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      surfaceContainerHighest:
          isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
      outline: isDark ? AppColors.darkOutline : AppColors.lightOutline,
      error: isDark ? AppColors.dangerDark : AppColors.dangerLight,
    );

    final Color onSurface = isDark ? AppColors.darkOnBg : AppColors.lightOnBg;
    final Color muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    TextTheme textTheme = TextTheme(
      displaySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: onSurface),
      headlineMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: onSurface),
      headlineSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: onSurface),
      titleLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: onSurface),
      titleMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: onSurface),
      titleSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: onSurface),
      bodyLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: onSurface),
      bodyMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: onSurface),
      bodySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: muted),
      labelLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: onSurface),
      labelMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: muted),
      labelSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: muted),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBg : AppColors.lightBg,
      splashFactory: InkRipple.splashFactory,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: AppElevation.none,
        centerTitle: true,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        indicatorColor: AppColors.brandTintOf(
            isDark ? AppColors.brandBright : AppColors.brandDeep),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll<TextStyle>(
          TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: onSurface,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        indicatorColor: AppColors.brandTintOf(
            isDark ? AppColors.brandBright : AppColors.brandDeep),
        selectedIconTheme: IconThemeData(
            color: isDark ? AppColors.brandBright : AppColors.brandDeep),
        unselectedIconTheme:
            IconThemeData(color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
        selectedLabelTextStyle:
            TextStyle(fontFamily: fontFamily, color: onSurface, fontWeight: FontWeight.w700),
        unselectedLabelTextStyle:
            TextStyle(fontFamily: fontFamily, color: muted),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.lightOnBg,
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          color: isDark ? AppColors.darkOnBg : AppColors.lightSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        modalBackgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        showDragHandle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
        hintStyle: TextStyle(fontFamily: fontFamily, color: muted),
        labelStyle: TextStyle(fontFamily: fontFamily, color: muted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
              color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
              color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: isDark ? AppColors.brandBright : AppColors.brandDeep,
            width: 1.6,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? AppColors.brandBright : AppColors.brandDeep,
          foregroundColor: isDark ? const Color(0xFF06201F) : Colors.white,
          textStyle: TextStyle(
              fontFamily: fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppColors.brandBright : AppColors.brandDeep,
          textStyle: TextStyle(
              fontFamily: fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500),
          side: BorderSide(
              color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.brandBright : AppColors.brandDeep,
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        iconColor: muted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? AppColors.brandBright : AppColors.brandDeep;
          }
          return null;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm / 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? (isDark ? const Color(0xFF06201F) : Colors.white)
              : (isDark ? AppColors.darkMuted : Colors.white),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? (isDark ? AppColors.brandBright : AppColors.brandDeep)
              : (isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? AppColors.brandBright : AppColors.brandDeep,
        linearTrackColor:
            isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
      ),
    );
  }
}
