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
  static const double sizeAppBarIcon        = 8; // Icon trên AppBar (back, refresh...)
  static const double sizeBottomButtonIcon     = 8; // Icon trong nút bottom bar (戻る, 開始...)
  static const double sizePrimaryButton        = 8; // Text nút primary action (次へ, 完了・送信...)
  static const double sizePrimaryButtonIcon    = 8; // Icon nút primary action
  static const double sizeSearchIcon        = 8; // Icon kính lúp trong search bar
  static const double sizeSearchClearIcon   = 8; // Icon xóa (×) trong search bar

  // ─── Button height ──────────────────────────────────────────────
  static const double heightBottomButton       = 16; // Chiều cao nút bottom bar
  static const double heightPrimaryButton      = 16; // Chiều cao nút primary action

  // ─── Spinner / Progress ─────────────────────────────────────────
  static const double sizeSpinner          = 16; // Đường kính CircularProgressIndicator
  static const double widthSpinnerStroke   = 1;  // strokeWidth CircularProgressIndicator

  // ─── Font sizes ──────────────────────────────────────────────
  static const double sizeNavButtonIcon   = 8; // Icon nút điều hướng ← → (prev/next)
  static const double sizeBadgeCheckIcon = 8; // Icon ✓ trong circular badge
  static const double sizeCardIcon       = 8; // Icon nhỏ inline trong card (bin, qty...)
  static const double sizeFieldIcon      = 8; // Icon nhỏ trong form field (商品コード, clear, calendar...)
  static const double sizeFieldButtonIcon = 8; // Icon nút bên cạnh field (QR scanner, calendar picker)
  static const double sizeIndicatorIcon = 8; // Icon ↓ chỉ thị giữa form (移動, 入荷...)
  static const double sizeCounter       = 8; // Badge đếm trang (1 / 1, 2 / 5...)
  static const double sizeDialogTitle   = 8; // Title trong AlertDialog (通知, 確認...)
  static const double sizeDialogContent = 8; // Content text trong AlertDialog
  static const double sizeDialogAction  = 8; // Nút action trong AlertDialog (閉じる, はい...)
  static const double sizeMenuLabel    = 8; // Label chính trên menu tile (入荷, ピッキング...)
  static const double sizeMenuSubtitle = 8; // Subtitle phụ trên menu tile (Warehouse Receipt...)
  static const double sizeAppBar    = 8; // AppBar title
  static const double sizeTitle     = 8; // Header chính (receiptNo, stockTakeNo...)
  static const double sizeListTitle = 8; // List tile title (ModuleListTile)
  static const double sizeInput     = 8; // TextField input text
  static const double sizeBody      = 8; // Text nội dung chính
  static const double sizeCard      = 8; // Card / item title
  static const double sizeInfo      = 8; // Text phụ (ngày, trạng thái, ghi chú)
  static const double sizeSub       = 8; // Text nhỏ (description, subtitle)
  static const double sizeMini      = 8; // Label rất nhỏ (mini label trong card)
  static const double sizeButton       = 8; // Nút bấm inline
  static const double sizeBottomButton = 8; // Nút bấm bottom bar (戻る...)
  static const double sizeHint      = 8; // Hint text trong TextField
  static const double sizeLabel     = 8; // FormLabel trên field
  static const double sizeCaption   = 8; // Caption / hint nhỏ

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
