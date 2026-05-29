import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Shared typography constants for the entire app (HHT — Honeywell CK65, 320px wide)
///
/// All values are fixed px — do NOT use .sp to avoid ScreenUtil scaling
/// on small screens.
class AppStyles {
  AppStyles._();

  // ─── Font family ─────────────────────────────────────────────
  static const String font = 'MSPGothic';

  // ─── Icon sizes ──────────────────────────────────────────────
  static const double sizeAppBarIcon        = 8; // Icon on AppBar (back, refresh…)
  static const double sizeBottomButtonIcon     = 8; // Icon inside bottom bar buttons (戻る, 開始…)
  static const double sizePrimaryButton        = 8; // Text of primary action button (次へ, 完了・送信…)
  static const double sizePrimaryButtonIcon    = 8; // Icon of primary action button
  static const double sizeSearchIcon        = 8; // Magnifier icon in search bar
  static const double sizeSearchClearIcon   = 8; // Clear (×) icon in search bar

  // ─── Button height ──────────────────────────────────────────────
  static const double heightBottomButton       = 16; // Height of bottom bar buttons
  static const double heightPrimaryButton      = 16; // Height of primary action button

  // ─── Spinner / Progress ─────────────────────────────────────────
  static const double sizeSpinner          = 16; // Diameter of CircularProgressIndicator
  static const double widthSpinnerStroke   = 1;  // strokeWidth of CircularProgressIndicator

  // ─── Font sizes ──────────────────────────────────────────────
  static const double sizeNavButtonIcon   = 8; // Navigation button icon ← → (prev/next)
  static const double sizeBadgeCheckIcon = 8; // ✓ icon inside circular badge
  static const double sizeCardIcon       = 8; // Small inline icon inside a card (bin, qty…)
  static const double sizeFieldIcon      = 8; // Small icon inside a form field (product code, clear, calendar…)
  static const double sizeFieldButtonIcon = 8; // Icon on button next to a field (QR scanner, calendar picker)
  static const double sizeIndicatorIcon = 8; // ↓ indicator icon between form sections (移動, 入荷…)
  static const double sizeCounter       = 8; // Page-count badge (1 / 1, 2 / 5…)
  static const double sizeDialogTitle   = 8; // Title in AlertDialog (通知, 確認…)
  static const double sizeDialogContent = 8; // Content text in AlertDialog
  static const double sizeDialogAction  = 8; // Action button in AlertDialog (閉じる, はい…)
  static const double sizeMenuLabel    = 8; // Primary label on menu tile (入荷, ピッキング…)
  static const double sizeMenuSubtitle = 8; // Secondary subtitle on menu tile (Warehouse Receipt…)
  static const double sizeAppBar    = 8; // AppBar title
  static const double sizeTitle     = 8; // Main header (receiptNo, stockTakeNo…)
  static const double sizeListTitle = 8; // List tile title (ModuleListTile)
  static const double sizeInput     = 8; // TextField input text
  static const double sizeBody      = 8; // Main body text
  static const double sizeCard      = 8; // Card / item title
  static const double sizeInfo      = 8; // Secondary text (date, status, remarks)
  static const double sizeSub       = 8; // Small text (description, subtitle)
  static const double sizeMini      = 8; // Very small label (mini label inside a card)
  static const double sizeButton       = 8; // Inline button text
  static const double sizeBottomButton = 8; // Bottom bar button text (戻る…)
  static const double sizeHint      = 8; // Hint text in TextField
  static const double sizeLabel     = 8; // FormLabel above a field
  static const double sizeCaption   = 8; // Caption / small hint

  // ─── Common TextStyles ───────────────────────────────────────

  static const TextStyle appBarTitle = TextStyle(
    fontFamily: font,
    fontSize: sizeAppBar,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static const TextStyle headerTitle = TextStyle(
    fontFamily: font,
    fontSize: sizeTitle,
    fontWeight: FontWeight.bold,
    color: AppColors.blackTextColor,
  );

  static const TextStyle body = TextStyle(
    fontFamily: font,
    fontSize: sizeBody,
    color: AppColors.blackTextColor,
  );

  static const TextStyle bodyBold = TextStyle(
    fontFamily: font,
    fontSize: sizeBody,
    fontWeight: FontWeight.bold,
    color: AppColors.blackTextColor,
  );

  static const TextStyle info = TextStyle(
    fontFamily: font,
    fontSize: sizeInfo,
    color: AppColors.grayTextColor,
  );

  static const TextStyle sub = TextStyle(
    fontFamily: font,
    fontSize: sizeSub,
    color: AppColors.grayTextColor,
  );

  static const TextStyle label = TextStyle(
    fontFamily: font,
    fontSize: sizeLabel,
    fontWeight: FontWeight.w600,
    color: AppColors.grayTextColor,
  );

  static const TextStyle button = TextStyle(
    fontFamily: font,
    fontSize: sizeButton,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );
}
