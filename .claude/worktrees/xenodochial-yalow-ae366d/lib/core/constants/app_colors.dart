import 'package:flutter/material.dart';

/// ─── AppColors ────────────────────────────────────────────────────────
/// Canonical color palette cho FBTHHT.
///
/// Tất cả màu sắc dùng trong UI đều phải tham chiếu qua class này.
/// Không hardcode `Color(0x...)` ở chỗ khác (trừ `app_theme.dart` khi
/// reference các const ở đây).
class AppColors {
  AppColors._();

  // ─── Primary (Fresh Teal palette) ─────────────────────────────
  static const Color primary       = Color(0xFF0D9488); // Teal 600
  static const Color primaryDark   = Color(0xFF0F766E); // Teal 700
  static const Color primaryLight  = Color(0xFF14B8A6); // Teal 500

  // ─── Neutral ──────────────────────────────────────────────────
  static const Color white         = Color(0xFFFFFFFF);
  static const Color lighter       = Color(0xFFF3F3F3);
  static const Color light         = Color(0xFFDAE1E7);
  static const Color dark          = Color(0xFF444444);
  static const Color darker        = Color(0xFF222222);
  static const Color black         = Color(0xFF000000);
  static const Color gray          = Color(0xFFAFADAD);

  // ─── Theme ────────────────────────────────────────────────────
  static const Color themeBackground = Color(0xFF134E4A); // Teal 900 (AppBar)
  static const Color ghostWhiteColor = Color(0xFFF8F9FC); // Scaffold bg

  // ─── Text ─────────────────────────────────────────────────────
  static const Color blackTextColor   = Color(0xFF000033);
  static const Color grayTextColor    = Color(0xFF737272);
  static const Color textPlaceholder  = Color(0xFF666666);
  static const Color textWarning      = Color(0xFFFFA500);
  static const Color textError        = Color(0xFFFF0000);

  // ─── Selected / Highlight rows ────────────────────────────────
  static const Color headerColor   = Color(0xFFCCFBF1); // Teal 100 (selected tile)
  static const Color rowCompleted  = Color(0xFFEBFFD8); // Light green tint

  // ─── Buttons ──────────────────────────────────────────────────
  static const Color btnRed   = Color(0xFFE11D48); // Rose 600 (danger)
  static const Color btnBlue  = Color(0xFF0EA5E9); // Sky 500
  static const Color btnGreen = Color(0xFF15803D); // Green 700 (success)

  // ─── Borders / Backgrounds ────────────────────────────────────
  static const Color borderTable = Color(0xFFC3CFD9);
  static const Color orangeLight = Color(0xFFFAE6D8); // Filter chip bg

  // ─── Dark theme surfaces ──────────────────────────────────────
  static const Color darkScaffold    = Color(0xFF121316);
  static const Color darkSurface     = Color(0xFF1A1B1E);
  static const Color darkSurfaceCard = Color(0xFF1F2024);
  static const Color darkSurfaceHigh = Color(0xFF2A2B2F);
  static const Color darkOutline     = Color(0xFF3F4146);

  // ─── Semantic shadows / overlays ──────────────────────────────
  static const Color shadowSubtle = Color(0x14000000); // black @ 8%
  static const Color shadowLight  = Color(0x42000000); // black @ 26%
  static const Color shadowMedium = Color(0x8A000000); // black @ 54%

  // ─── Semantic status pairs (badges) ───────────────────────────
  static const Color statusDoneBg    = Color(0xFFD1FAE5); // Emerald 100
  static const Color statusDoneFg    = Color(0xFF15803D); // Green 700
  static const Color statusPendingBg = Color(0xFFFFEDD5); // Orange 100
  static const Color statusPendingFg = Color(0xFFC2410C); // Orange 700
  static const Color statusErrorBg   = Color(0xFFFEE2E2); // Red 100

  // ─── Module Tiles (MainMenu) — harmonized Tailwind 600 ────────
  static const Color settingsColor1 = Color(0xFF2563EB); // 入荷         Blue 600
  static const Color settingsColor2 = Color(0xFF9333EA); // 棚上げ       Purple 600
  static const Color settingsColor3 = Color(0xFFEA580C); // ピッキング   Orange 600
  static const Color settingsColor4 = Color(0xFFDB2777); // 事前セット   Pink 600
  static const Color settingsColor5 = Color(0xFF0891B2); // 棚移動       Cyan 600
  static const Color settingsColor6 = Color(0xFF059669); // 棚卸         Emerald 600
  static const Color settingsColor7 = Color(0xFF475569); // ログアウト   Slate 600

  /// Danh sách màu cho 7 tile MainMenu (index 0-6)
  static const List<Color> menuTileColors = [
    settingsColor1,
    settingsColor2,
    settingsColor3,
    settingsColor4,
    settingsColor5,
    settingsColor6,
    settingsColor7,
  ];
}
