import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/widgets.dart';

/// ─── Spacing tokens ──────────────────────────────────────────────────
/// Thang spacing 4px chuẩn Material 3.
/// Sử dụng `.w` / `.h` để scale theo ScreenUtil (designSize 360x800).
///
///   ┌────┬─────┬──────────────────┐
///   │ Tên │ px  │ Use case          │
///   ├────┼─────┼──────────────────┤
///   │ xs  │  4  │ Khe trong icon    │
///   │ sm  │  8  │ Gap giữa label/ô │
///   │ md  │ 12  │ Padding card nhỏ │
///   │ lg  │ 16  │ Padding mặc định │
///   │ xl  │ 24  │ Padding section  │
///   │ xxl │ 32  │ Khoảng cách lớn  │
///   │ xxxl│ 48  │ Padding header   │
///   └────┴─────┴──────────────────┘
class AppSpacing {
  AppSpacing._();

  // ── Raw px values (logical pixels) ─────────────────────────
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 24;
  static const double xxl  = 32;
  static const double xxxl = 48;

  // ── EdgeInsets helpers (responsive) ────────────────────────
  static EdgeInsets get screenPadding => EdgeInsets.symmetric(
        horizontal: lg.w,
        vertical: md.h,
      );

  static EdgeInsets get cardPadding => EdgeInsets.all(lg.w);

  static EdgeInsets get listItemPadding => EdgeInsets.symmetric(
        horizontal: lg.w,
        vertical: md.h,
      );

  static EdgeInsets get formFieldPadding => EdgeInsets.symmetric(
        horizontal: lg.w,
        vertical: md.h,
      );

  // ── Sized boxes (vertical gaps) ────────────────────────────
  static SizedBox get gapXs   => SizedBox(height: xs.h);
  static SizedBox get gapSm   => SizedBox(height: sm.h);
  static SizedBox get gapMd   => SizedBox(height: md.h);
  static SizedBox get gapLg   => SizedBox(height: lg.h);
  static SizedBox get gapXl   => SizedBox(height: xl.h);
  static SizedBox get gapXxl  => SizedBox(height: xxl.h);

  // ── Sized boxes (horizontal gaps) ──────────────────────────
  static SizedBox get hGapXs  => SizedBox(width: xs.w);
  static SizedBox get hGapSm  => SizedBox(width: sm.w);
  static SizedBox get hGapMd  => SizedBox(width: md.w);
  static SizedBox get hGapLg  => SizedBox(width: lg.w);
  static SizedBox get hGapXl  => SizedBox(width: xl.w);
}
