import 'package:flutter/material.dart';

/// Port từ RootColors.js
/// Giữ nguyên tên màu để dễ tra cứu khi chuyển đổi
class AppColors {
  AppColors._();

  // ─── Primary ──────────────────────────────────────────────────
  static const Color primary       = Color(0xFFc02941);
  static const Color primaryDark   = Color(0xFF8c0032);
  static const Color primaryLight  = Color(0xFFf05577);

  // ─── Neutral ──────────────────────────────────────────────────
  static const Color white         = Color(0xFFFFFFFF);
  static const Color lighter       = Color(0xFFF3F3F3);
  static const Color light         = Color(0xFFDAE1E7);
  static const Color dark          = Color(0xFF444444);
  static const Color darker        = Color(0xFF222222);
  static const Color black         = Color(0xFF000000);
  static const Color gray          = Color(0xFFafadad);

  // ─── Theme ────────────────────────────────────────────────────
  static const Color themeBackground       = Color(0xFF246189);
  static const Color themeBackgroundSecond = Color(0xFFfaf7f5);

  // ─── Text ─────────────────────────────────────────────────────
  static const Color blackTextColor       = Color(0xFF000033);
  static const Color grayTextColor        = Color(0xFF737272);
  static const Color lightGrayTextColor   = Color(0xFFD3D3D3); // 'lightgray'
  static const Color whiteTextColor       = Color(0xFFffffff);
  static const Color textError            = Color(0xFFFF0000);
  static const Color textBlueDark         = Color(0xFF05375a);
  static const Color textPlaceholder      = Color(0xFF666666);
  static const Color textPurple           = Color(0xFF800080);
  static const Color textWarning          = Color(0xFFFFA500);
  static const Color textNearWhite        = Color(0xFFfcfbfb);

  // ─── Accent / Status ──────────────────────────────────────────
  static const Color blueColor            = Color(0xFF0000FF);
  static const Color amberColor           = Color(0xFFFFC000);
  static const Color wageningenGreen      = Color(0xFF299D35);
  static const Color goldColor            = Color(0xFFFFD700); // 'gold'
  static const Color red                  = Color(0xFFFF0000);
  static const Color lightGreen           = Color(0xFF40d375);
  static const Color greenColor           = Color(0xFF008000);
  static const Color greenDarkColor       = Color(0xFF207868);
  static const Color lightNormalGray      = Color(0x80000000); // rgba(0,0,0,0.5)

  // ─── Soft colors ──────────────────────────────────────────────
  static const Color chineseSilver        = Color(0xFFC8C7C8);
  static const Color argentColor          = Color(0xFFC2C0C0);
  static const Color ghostWhiteColor      = Color(0xFFf8f9fc);
  static const Color spanishPinkColor     = Color(0xFFF5B9BD);
  static const Color sandyTanColor        = Color(0xFFfadcc8);
  static const Color peachOrange          = Color(0xFFf4aa76);
  static const Color diamondColor         = Color(0xFFc1e3f4);
  static const Color paleLavender         = Color(0xFFDCC7F8);
  static const Color blueJeansColor       = Color(0xFF52b2fd);
  static const Color lightYellow          = Color(0xFFfef7d6);

  // ─── Header / Active ──────────────────────────────────────────
  static const Color headerColor          = Color(0xFFd5e7f7);
  static const Color activeColor          = Color(0xFFd5e7f7);

  // ─── Buttons ──────────────────────────────────────────────────
  static const Color btnRed               = Color(0xFFd3455b);
  static const Color btnBlue              = Color(0xFF2c88d9);
  static const Color btnGreen             = Color(0xFF207868);
  static const Color btnBrown             = Color(0xFF897a5f);
  static const Color btnActive            = Color(0xFFc0c0c0);

  // ─── Table / Border ───────────────────────────────────────────
  static const Color borderTable          = Color(0xFFc3cfd9);
  static const Color borderInput          = Color(0xFFf33b3b);

  // ─── Background ───────────────────────────────────────────────
  static const Color orangeLight          = Color(0xFFfae6d8);
  static const Color boxColor             = Color(0xFFf2f5f7);
  static const Color rowCompleted         = Color(0xFFEBFFD8);

  // ─── Settings Tiles (MainMenu) ────────────────────────────────
  static const Color settingsColor1       = Color(0xFF3b60f3); // 入荷
  static const Color settingsColor2       = Color(0xFFef3bf3); // 棚上げ
  static const Color settingsColor3       = Color(0xFFfd9627); // ピッキング
  static const Color settingsColor4       = Color(0xFFf33b3b); // 事前セット
  static const Color settingsColor5       = Color(0xFFff85eb); // 棚移動
  static const Color settingsColor6       = Color(0xFF76f33b); // 棚卸
  static const Color settingsColor7       = Color(0xFFf3ec3b); // ログアウト

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
