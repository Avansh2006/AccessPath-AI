import 'package:flutter/material.dart';

/// AccessPath AI Design System — Colors, Typography, Spacing, Radii, Shadows
/// Calm, modern, trustworthy, inclusive palette with excellent contrast ratios.

class AppColors {
  AppColors._();

  // Primary — Deep Teal
  static const Color primary = Color(0xFF0D7377);
  static const Color primaryLight = Color(0xFF14919B);
  static const Color primaryDark = Color(0xFF095B5E);
  static const Color primarySurface = Color(0xFFE6F5F5);

  // Secondary — Warm Amber
  static const Color secondary = Color(0xFFF59E0B);
  static const Color secondaryLight = Color(0xFFFBBF24);
  static const Color secondaryDark = Color(0xFFD97706);

  // Accent — Accessible Purple
  static const Color accent = Color(0xFF7C3AED);
  static const Color accentLight = Color(0xFFA78BFA);

  // Semantic
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Neutrals
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFF9FAFB);

  // Surfaces
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);

  // Score colors
  static const Color scoreExcellent = Color(0xFF059669);
  static const Color scoreGood = Color(0xFF10B981);
  static const Color scoreFair = Color(0xFFF59E0B);
  static const Color scorePoor = Color(0xFFEF4444);

  static Color scoreColor(double score) {
    if (score >= 8.0) return scoreExcellent;
    if (score >= 6.0) return scoreGood;
    if (score >= 4.0) return scoreFair;
    return scorePoor;
  }
}

class AppTypography {
  AppTypography._();

  static const String _fontFamily = 'Roboto';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textTertiary,
  );

  static const TextStyle scoreDisplay = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 1.1,
  );

  static const TextStyle scoreMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle scoreSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
  static const double massive = 64;
}

class AppRadii {
  AppRadii._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 999;

  static final BorderRadius borderRadiusSm = BorderRadius.circular(sm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(md);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(lg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(xl);
  static final BorderRadius borderRadiusXxl = BorderRadius.circular(xxl);
  static final BorderRadius borderRadiusFull = BorderRadius.circular(full);
}

class AppShadows {
  AppShadows._();

  static final List<BoxShadow> sm = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static final List<BoxShadow> md = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> lg = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.10),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> xl = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}

/// Build the Material ThemeData from our design system
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.headlineSmall,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderRadiusMd,
        ),
        textStyle: AppTypography.titleLarge,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderRadiusMd,
        ),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        textStyle: AppTypography.titleLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: AppRadii.borderRadiusMd,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadii.borderRadiusMd,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadii.borderRadiusMd,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textTertiary,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.borderRadiusMd,
        side: const BorderSide(color: AppColors.divider, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primarySurface,
      selectedColor: AppColors.primary,
      labelStyle: AppTypography.labelMedium,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.borderRadiusFull,
      ),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 0,
    ),
  );
}
