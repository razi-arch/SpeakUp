import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_motion.dart';
import 'app_radius.dart';
import 'app_text.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,

      colorScheme: const ColorScheme(
        brightness:       Brightness.light,
        primary:          AppColors.green,
        onPrimary:        Colors.white,
        primaryContainer: AppColors.greenLight,
        onPrimaryContainer: AppColors.greenDark,
        secondary:        AppColors.sky,
        onSecondary:      Colors.white,
        secondaryContainer: AppColors.skyLight,
        onSecondaryContainer: AppColors.skyDark,
        tertiary:         AppColors.amber,
        onTertiary:       Colors.white,
        tertiaryContainer: AppColors.amberLight,
        onTertiaryContainer: AppColors.amberDark,
        error:            AppColors.rose,
        onError:          Colors.white,
        errorContainer:   AppColors.roseLight,
        onErrorContainer: AppColors.roseDark,
        surface:          AppColors.bgCard,
        onSurface:        AppColors.ink,
        surfaceContainerHighest: AppColors.bgRaised,
        outline:          AppColors.ink4,
        outlineVariant:   AppColors.ink5,
        shadow:           AppColors.ink,
      ),

      // ── Typography ──────────────────────────────────
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        TextTheme(
          displayLarge:  AppText.display(),
          headlineMedium: AppText.heading(),
          titleLarge:    AppText.title(),
          labelLarge:    AppText.button(),
          bodyMedium:    AppText.body(),
          bodySmall:     AppText.caption(),
        ),
      ),

      // ── Elevated button — Primary ───────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(AppColors.green),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          textStyle: WidgetStatePropertyAll(AppText.button()),
          minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 14, horizontal: 26),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.pill),
          ),
          shadowColor: const WidgetStatePropertyAll(AppColors.greenDark),
          elevation: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.pressed) ? 1 : 3),
          animationDuration: AppMotion.mid,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),

      // ── Outlined button — Secondary ─────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(AppColors.ink),
          textStyle: WidgetStatePropertyAll(AppText.button(color: AppColors.ink)),
          backgroundColor: const WidgetStatePropertyAll(AppColors.bgCard),
          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 13, horizontal: 24),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.pill),
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.ink4, width: 1.5),
          ),
          animationDuration: AppMotion.mid,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),

      // ── Text button ─────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(AppColors.green),
          textStyle: WidgetStatePropertyAll(AppText.button(color: AppColors.green)),
          animationDuration: AppMotion.mid,
        ),
      ),

      // ── Cards ───────────────────────────────────────
      cardTheme: const CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shadowColor: Color(0x141C1917),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
      ),

      // ── Input fields ────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg,
        hintStyle: AppText.body(color: AppColors.ink3),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: const BorderSide(color: AppColors.ink4, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: const BorderSide(color: AppColors.ink4, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: const BorderSide(color: AppColors.rose, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: const BorderSide(color: AppColors.rose, width: 1.5),
        ),
      ),

      // ── Chips ───────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.ink5,
        labelStyle: AppText.caption(color: AppColors.ink2),
        side: const BorderSide(color: AppColors.ink4, width: 1),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // ── Divider ─────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.ink4,
        thickness: 1,
        space: 1,
      ),

      // ── App bar ─────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgCard,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        titleTextStyle: AppText.title(),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        surfaceTintColor: Colors.transparent,
      ),

      // ── Bottom navigation / NavigationRail ──────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: const Color(0xFF1A5C42),
        selectedIconTheme: const IconThemeData(color: Colors.white, size: 22),
        unselectedIconTheme: const IconThemeData(
          color: Color(0x99FFFFFF), // white 60%
          size: 22,
        ),
        selectedLabelTextStyle: AppText.caption(color: Colors.white),
        unselectedLabelTextStyle: AppText.caption(
          color: const Color(0x99FFFFFF),
        ),
        indicatorColor: const Color(0x2EFFFFFF), // white 18%
        indicatorShape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        minWidth: 120,
        groupAlignment: -1,
        useIndicator: true,
      ),

      // ── Progress indicator ───────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.green,
        linearTrackColor: AppColors.ink5,
        linearMinHeight: 9,
      ),

      // ── Snackbar / Toast ────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: AppText.body(color: Colors.white),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Misc ─────────────────────────────────────────
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      focusColor: AppColors.greenLight,
    );
  }
}
