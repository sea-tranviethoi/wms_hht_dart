import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import 'app_radius.dart';
import 'app_elevation.dart';

/// ─── AppTheme ─────────────────────────────────────────────────────────
/// Material 3 theme tổng hợp cho FBTHHT.
///
/// Sử dụng:
/// ```dart
/// MaterialApp.router(
///   theme: AppTheme.lightTheme,
///   ...
/// )
/// ```
class AppTheme {
  AppTheme._();

  // ── Font family ─────────────────────────────────────────────
  static const String _fontFamily = 'MSPGothic';

  // ── Color Scheme ────────────────────────────────────────────
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    // Primary
    primary:           AppColors.primary,
    onPrimary:         AppColors.white,
    primaryContainer:  AppColors.primaryLight,
    onPrimaryContainer: AppColors.white,
    // Secondary
    secondary:           AppColors.btnGreen,
    onSecondary:         AppColors.white,
    secondaryContainer:  AppColors.statusDoneBg,
    onSecondaryContainer: AppColors.darker,
    // Tertiary
    tertiary:           AppColors.btnBlue,
    onTertiary:         AppColors.white,
    tertiaryContainer:  AppColors.headerColor,
    onTertiaryContainer: AppColors.darker,
    // Error
    error:           AppColors.btnRed,
    onError:         AppColors.white,
    errorContainer:  AppColors.statusErrorBg,
    onErrorContainer: AppColors.darker,
    // Surface
    surface:           AppColors.white,
    onSurface:         AppColors.blackTextColor,
    surfaceContainerHighest: AppColors.ghostWhiteColor,
    onSurfaceVariant:  AppColors.grayTextColor,
    // Outline
    outline:           AppColors.borderTable,
    outlineVariant:    AppColors.light,
    // Other
    shadow:            AppColors.black,
    scrim:             AppColors.black,
    inverseSurface:    AppColors.darker,
    onInverseSurface:  AppColors.white,
    inversePrimary:    AppColors.primaryLight,
  );

  // ── Light Theme ─────────────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = _lightColorScheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: _fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.ghostWhiteColor,
      splashFactory: InkRipple.splashFactory,

      // ── Page transitions (smoother nav across platforms) ────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
        },
      ),

      // ── AppBar ─────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.themeBackground,
        foregroundColor: AppColors.white,
        elevation: AppElevation.level0,
        scrolledUnderElevation: AppElevation.level2,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        iconTheme: IconThemeData(color: AppColors.white, size: 22),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          color: AppColors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),

      // ── Input fields ───────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.ghostWhiteColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          fontFamily: _fontFamily,
          color: AppColors.textPlaceholder,
          fontSize: 13,
        ),
        labelStyle: const TextStyle(
          fontFamily: _fontFamily,
          color: AppColors.grayTextColor,
          fontSize: 13,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: _fontFamily,
          color: AppColors.themeBackground,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: AppColors.gray,
        suffixIconColor: AppColors.gray,
        errorStyle: const TextStyle(
          fontFamily: _fontFamily,
          color: AppColors.textError,
          fontSize: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderRadiusSm,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderRadiusSm,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderRadiusSm,
          borderSide: const BorderSide(
            color: AppColors.themeBackground,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderRadiusSm,
          borderSide: const BorderSide(color: AppColors.textError, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderRadiusSm,
          borderSide: const BorderSide(color: AppColors.textError, width: 1.5),
        ),
      ),

      // ── ElevatedButton (primary) ───────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.gray,
          disabledForegroundColor: AppColors.lighter,
          elevation: AppElevation.level1,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusSm),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ── FilledButton (secondary) ───────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.themeBackground,
          foregroundColor: AppColors.white,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusSm),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ── OutlinedButton ─────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.themeBackground,
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: const BorderSide(color: AppColors.themeBackground, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusSm),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── TextButton ─────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.themeBackground,
          minimumSize: const Size(48, 40),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusSm),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ── IconButton ─────────────────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.darker,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusSm),
        ),
      ),

      // ── FAB ────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: AppElevation.level3,
        focusElevation: AppElevation.level3,
        hoverElevation: AppElevation.level3,
        highlightElevation: AppElevation.level3,
        shape: CircleBorder(),
      ),

      // ── Card ───────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: AppElevation.level1,
        shadowColor: AppColors.shadowSubtle,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusMd),
        clipBehavior: Clip.antiAlias,
      ),

      // ── ListTile ───────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.themeBackground,
        textColor: AppColors.blackTextColor,
        tileColor: Colors.transparent,
        selectedTileColor: AppColors.headerColor,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minVerticalPadding: 8,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          color: AppColors.blackTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          color: AppColors.grayTextColor,
          fontSize: 12,
        ),
      ),

      // ── Dialog ─────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        elevation: AppElevation.level3,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusLg),
        titleTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          color: AppColors.blackTextColor,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          color: AppColors.darker,
          fontSize: 14,
          height: 1.4,
        ),
      ),

      // ── BottomSheet ────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.white,
        elevation: AppElevation.level4,
        modalBackgroundColor: AppColors.white,
        modalElevation: AppElevation.level4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── SnackBar ───────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darker,
        contentTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          color: AppColors.white,
          fontSize: 13,
        ),
        actionTextColor: AppColors.primaryLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusSm),
        elevation: AppElevation.level2,
      ),

      // ── Divider ────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.light,
        thickness: 0.6,
        space: 1,
      ),

      // ── Chip ───────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lighter,
        disabledColor: AppColors.lighter,
        selectedColor: AppColors.primary,
        secondarySelectedColor: AppColors.themeBackground,
        labelStyle: const TextStyle(
          fontFamily: _fontFamily,
          color: AppColors.darker,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: _fontFamily,
          color: AppColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusFull),
      ),

      // ── ProgressIndicator ──────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.lighter,
        circularTrackColor: AppColors.lighter,
      ),

      // ── Tab Bar ────────────────────────────────────────────
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.grayTextColor,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      // ── Switch / Checkbox / Radio ──────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.white
                : AppColors.lighter),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.gray),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : Colors.transparent),
        side: const BorderSide(color: AppColors.gray, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusSm),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.gray),
      ),

      // ── Text Theme ─────────────────────────────────────────
      textTheme: const TextTheme(
        // Display (rarely used in HHT)
        displayLarge:  TextStyle(fontFamily: _fontFamily, color: AppColors.blackTextColor),
        displayMedium: TextStyle(fontFamily: _fontFamily, color: AppColors.blackTextColor),
        displaySmall:  TextStyle(fontFamily: _fontFamily, color: AppColors.blackTextColor),
        // Headline
        headlineLarge:  TextStyle(fontFamily: _fontFamily, fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.blackTextColor),
        headlineMedium: TextStyle(fontFamily: _fontFamily, fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.blackTextColor),
        headlineSmall:  TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.blackTextColor),
        // Title
        titleLarge:  TextStyle(fontFamily: _fontFamily, fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.blackTextColor),
        titleMedium: TextStyle(fontFamily: _fontFamily, fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.blackTextColor),
        titleSmall:  TextStyle(fontFamily: _fontFamily, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.blackTextColor),
        // Body
        bodyLarge:  TextStyle(fontFamily: _fontFamily, fontSize: 14, color: AppColors.darker, height: 1.45),
        bodyMedium: TextStyle(fontFamily: _fontFamily, fontSize: 13, color: AppColors.darker, height: 1.4),
        bodySmall:  TextStyle(fontFamily: _fontFamily, fontSize: 12, color: AppColors.grayTextColor, height: 1.35),
        // Label
        labelLarge:  TextStyle(fontFamily: _fontFamily, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darker),
        labelMedium: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.grayTextColor),
        labelSmall:  TextStyle(fontFamily: _fontFamily, fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.grayTextColor),
      ),
    );
  }

  // ── Dark Color Scheme ───────────────────────────────────────
  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary:           AppColors.primaryLight,
    onPrimary:         AppColors.darker,
    primaryContainer:  AppColors.primaryDark,
    onPrimaryContainer: AppColors.white,
    secondary:           AppColors.btnGreen,
    onSecondary:         AppColors.darker,
    secondaryContainer:  AppColors.statusDoneFg,
    onSecondaryContainer: AppColors.white,
    tertiary:           AppColors.btnBlue,
    onTertiary:         AppColors.darker,
    tertiaryContainer:  AppColors.btnBlue,
    onTertiaryContainer: AppColors.white,
    error:           AppColors.btnRed,
    onError:         AppColors.white,
    errorContainer:  AppColors.primaryDark,
    onErrorContainer: AppColors.white,
    surface:           AppColors.darkSurface,
    onSurface:         AppColors.white,
    surfaceContainerHighest: AppColors.darkSurfaceHigh,
    onSurfaceVariant:  AppColors.light,
    outline:           AppColors.darkOutline,
    outlineVariant:    AppColors.darkSurfaceHigh,
    shadow:            AppColors.black,
    scrim:             AppColors.black,
    inverseSurface:    AppColors.white,
    onInverseSurface:  AppColors.darker,
    inversePrimary:    AppColors.primary,
  );

  // ── Dark Theme ──────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = lightTheme;
    return base.copyWith(
      brightness: Brightness.dark,
      colorScheme: _darkColorScheme,
      scaffoldBackgroundColor: AppColors.darkScaffold,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.white,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: AppColors.darkSurfaceCard,
      ),
      dividerTheme: base.dividerTheme.copyWith(
        color: AppColors.darkOutline,
      ),
      listTileTheme: base.listTileTheme.copyWith(
        textColor: AppColors.white,
        titleTextStyle: base.listTileTheme.titleTextStyle?.copyWith(
          color: AppColors.white,
        ),
        subtitleTextStyle: base.listTileTheme.subtitleTextStyle?.copyWith(
          color: AppColors.light,
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: AppColors.darkSurfaceHigh,
      ),
      // Dialogs/notifications stay white in both themes — UX requirement
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: AppColors.white,
        titleTextStyle: base.dialogTheme.titleTextStyle?.copyWith(
          color: AppColors.blackTextColor,
        ),
        contentTextStyle: base.dialogTheme.contentTextStyle?.copyWith(
          color: AppColors.blackTextColor,
        ),
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: AppColors.darkSurfaceCard,
        modalBackgroundColor: AppColors.darkSurfaceCard,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.white,
        displayColor: AppColors.white,
      ),
    );
  }
}
