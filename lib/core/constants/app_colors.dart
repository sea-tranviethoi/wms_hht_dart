import 'package:flutter/material.dart';

/// Palette: Dusty Muted Pastel
class AppColors {
  AppColors._();

  // ─── Base UI ──────────────────────────────────────────────────
  static const Color white    = Color(0xFFFFFFFF);
  static const Color lighter  = Color(0xFFF3F3F3);
  static const Color light    = Color(0xFFDAE1E7);
  static const Color gray     = Color(0xFFafadad);
  static const Color darker   = Color(0xFF222222);
  static const Color black    = Color(0xFF000000);

  // ─── Text ─────────────────────────────────────────────────────
  static const Color blackTextColor  = Color(0xFF2D2D2D);
  static const Color grayTextColor   = Color(0xFF737272);
  static const Color textError       = Color(0xFF8A4040);
  static const Color textWarning     = Color(0xFFB86840);
  static const Color textPlaceholder = Color(0xFF8A8A8A);

  // ─── Brand ────────────────────────────────────────────────────
  static const Color primary         = Color(0xFF3D6E96);
  static const Color primaryLight    = Color(0xFF5A8AB0);
  static const Color themeBackground = Color(0xFF3D6E96);

  // ─── Semantic ─────────────────────────────────────────────────
  static const Color wageningenGreen = Color(0xFF4E7A5E);
  static const Color greenDark       = Color(0xFF3A5E48);
  static const Color ghostWhiteColor = Color(0xFFF8F9FC);
  static const Color headerColor     = Color(0xFFDDE6EE);
  static const Color borderTable     = Color(0xFFCAD4DC);

  // ─── Buttons ──────────────────────────────────────────────────
  static const Color btnRed   = Color(0xFF8A4040);
  static const Color btnBlue  = Color(0xFF3D6E96);
  static const Color btnGreen = Color(0xFF4E7A5E);
  static const Color btnBrown = Color(0xFFB86840);

  // ─── Helper ───────────────────────────────────────────────────
  static Color onColor(Color background) => white;

  // ─── Module colors — Dusty Muted Pastel ──────────────────────
  static const Color settingsColor1 = Color(0xFF3D6E96); // Blue  Steel Blue  — 入荷
  static const Color settingsColor2 = Color(0xFF6B4E8A); // Purple Dusty Violet— 棚上げ
  static const Color settingsColor3 = Color(0xFFB86840); // Orange Burnt Orange — ピッキング
  static const Color settingsColor4 = Color(0xFFA85670); // Pink  Dusty Rose  — 事前セット
  static const Color settingsColor5 = Color(0xFF4E7A5E); // Green Sage Green  — 棚移動
  static const Color settingsColor6 = Color(0xFF8A8030); // Yellow Olive Gold  — 棚卸
  static const Color settingsColor7 = Color(0xFF8A4040); // Red   Dusty Red   — ログアウト
}
