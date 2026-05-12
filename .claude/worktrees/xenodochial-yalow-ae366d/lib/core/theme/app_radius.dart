import 'package:flutter/widgets.dart';

/// ─── Radius tokens ───────────────────────────────────────────────────
/// Theo Material 3 shape system.
class AppRadius {
  AppRadius._();

  // ── Raw values ─────────────────────────────────────────────
  static const double none     = 0;
  static const double xs       = 4;   // chip nhỏ
  static const double sm       = 8;   // button, input
  static const double md       = 12;  // card mặc định
  static const double lg       = 16;  // dialog, sheet
  static const double xl       = 24;  // bottom sheet, modal
  static const double full     = 999;  // pill / circular

  // ── BorderRadius helpers ───────────────────────────────────
  static BorderRadius get borderRadiusSm   => BorderRadius.circular(sm);
  static BorderRadius get borderRadiusMd   => BorderRadius.circular(md);
  static BorderRadius get borderRadiusLg   => BorderRadius.circular(lg);
  static BorderRadius get borderRadiusXl   => BorderRadius.circular(xl);
  static BorderRadius get borderRadiusFull => BorderRadius.circular(full);
}
