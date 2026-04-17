import 'package:flutter/material.dart';

// Deprecated: dùng AppColors (core/constants/app_colors.dart) thay thế
// Giữ lại để tránh break các screen cũ đang import
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFFc02941);
  static const Color primaryLight = Color(0xFFf05577);
  static const Color primaryDark = Color(0xFF8c0032);
  static const Color lighter = Color(0xFFF3F3F3);

  // Accent Colors
  static const Color greenDark = Color(0xFF207868);
  static const Color btnGreen = Color(0xFF4CAF50);
  static const Color btnRed = Color(0xFFF44336);

  // Text Colors
  static const Color black = Color(0xFF000000);
  static const Color blackText = Color(0xFF212121);
  static const Color textPlaceholder = Color(0xFF9E9E9E);
  static const Color textError = Color(0xFFD32F2F);
  static const Color textBlueDark = Color(0xFF1565C0);

  // Background Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray = Color(0xFF9E9E9E);
  static const Color headerColor = Color(0xFFF5F5F5);

  // Menu Colors
  static const List<Color> menuColors = [
    Color(0xFF6D6875),
    Color(0xFF355C7D),
    Color(0xFF2A4849),
    Color(0xFF4F4A41),
    Color(0xFF5C5470),
    Color(0xFF7E685A),
  ];

  // Legacy names (không đổi để không break code cũ)
  // ignore: constant_identifier_names
  static const Color orange_light = Color(0xFFfae6d8);
  // ignore: constant_identifier_names
  static const Color Settings_Colors_3 = Color(0xFFfd9627);
  // ignore: constant_identifier_names
  static const Color btn_red = Color(0xFFd3455b);
  // ignore: constant_identifier_names
  static const Color btn_blue = Color(0xFF2c88d9);
  // ignore: constant_identifier_names
  static const Color btn_brown = Color(0xFF8B4513);
  static const Color borderTable = Color(0xFFc3cfd9);
  // ignore: constant_identifier_names
  static const Color text_warning = Color(0xFFFFA500);
  // ignore: constant_identifier_names
  static const Color text_placeholder = Color(0xFF666666);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'MSPGothic',
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.greenDark,
        error: AppColors.textError,
        surface: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.headerColor,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.black),
        titleTextStyle: TextStyle(
          fontFamily: 'MSPGothic',
          color: AppColors.black,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lighter, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lighter, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.textError, width: 2),
        ),
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: 'MSPGothic',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
