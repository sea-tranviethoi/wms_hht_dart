import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Hằng số typography dùng chung toàn app (HHT — Honeywell CK65, 320px wide)
///
/// Tất cả giá trị là fixed px — KHÔNG dùng .sp để tránh ScreenUtil scale
/// trên màn hình nhỏ.
class AppStyles {
  AppStyles._();

  // ─── Font family ─────────────────────────────────────────────
  static const String font = 'MSPGothic';

  // ─── Icon sizes ──────────────────────────────────────────────
  static const double sizeTopBarIcon       = 24; // Icon on AppBar (back, refresh...)
  static const double sizeBottomButtonIcon = 20; // Icon inside bottom bar buttons (戻る, 開始...)
  static const double sizeSearchIcon = 20; // Icon size for search bar (magnifier and clear)

  // ─── Button height ───────────────────────────────────────────
  static const double heightBottomButton = 32; // Height of bottom bar buttons
  static const double heightTenantTile   = 48; // Height of tenant selection tiles

  // ─── Spinner / Progress ─────────────────────────────────────────
  static const double sizeSpinner          = 24; // Đường kính CircularProgressIndicator
  static const double widthSpinnerStroke   = 2;  // strokeWidth CircularProgressIndicator

  // ─── Font sizes ──────────────────────────────────────────────
  static const double sizeMainTitle  = 16; // AppBar title, page headers
  static const double sizeItemTitle  = 16; // List tile / card / button text
  static const double sizeBodyText   = 16; // Body content, inputs, dialog content
  static const double sizeInfoText   = 16; // Secondary info, labels, hints
  static const double sizeSubText    = 16; // Captions, mini labels, smallest text

  // ─── Common TextStyles ───────────────────────────────────────

  static const TextStyle appBarTitle = TextStyle(
    fontFamily: font,
    fontSize: sizeMainTitle,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static const TextStyle headerTitle = TextStyle(
    fontFamily: font,
    fontSize: sizeMainTitle,
    fontWeight: FontWeight.bold,
    color: AppColors.blackTextColor,
  );

  static const TextStyle body = TextStyle(
    fontFamily: font,
    fontSize: sizeBodyText,
    color: AppColors.blackTextColor,
  );

  static const TextStyle bodyBold = TextStyle(
    fontFamily: font,
    fontSize: sizeBodyText,
    fontWeight: FontWeight.bold,
    color: AppColors.blackTextColor,
  );

  static const TextStyle info = TextStyle(
    fontFamily: font,
    fontSize: sizeInfoText,
    color: AppColors.grayTextColor,
  );

  static const TextStyle sub = TextStyle(
    fontFamily: font,
    fontSize: sizeInfoText,
    color: AppColors.grayTextColor,
  );

  static const TextStyle label = TextStyle(
    fontFamily: font,
    fontSize: sizeInfoText,
    fontWeight: FontWeight.w600,
    color: AppColors.grayTextColor,
  );

  static const TextStyle button = TextStyle(
    fontFamily: font,
    fontSize: sizeItemTitle,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );
}
