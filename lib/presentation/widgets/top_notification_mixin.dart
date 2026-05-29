import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';

/// Chuyển exception thành thông báo lỗi thân thiện với user.
/// - DioException → "ネットワークエラー: <statusCode> <message>"
/// - Exception khác → text gọn (truncate sau dòng đầu)
String friendlyError(Object e) {
  if (e is DioException) {
    final code = e.response?.statusCode;
    final path = e.requestOptions.path;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'ネットワークタイムアウトしました。再試行してください。';
      case DioExceptionType.connectionError:
        return 'サーバーに接続できません。ネットワークをご確認ください。';
      case DioExceptionType.badResponse:
        if (code == 404) return 'APIが見つかりません (404): $path';
        if (code == 401) return '認証エラー (401)';
        if (code == 500) return 'サーバーエラー (500)';
        return 'サーバーエラー${code != null ? ' ($code)' : ''}';
      default:
        return 'ネットワークエラーが発生しました';
    }
  }
  // Generic error — chỉ lấy dòng đầu, tối đa 120 ký tự
  final raw = e.toString();
  final firstLine = raw.split('\n').first;
  return firstLine.length > 120
      ? '${firstLine.substring(0, 120)}…'
      : firstLine;
}

/// Mixin cung cấp top notification banner cho StatefulWidget.
///
/// Usage:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with TopNotificationMixin {
///   void _save() {
///     showTopNotification('保存しました', AppColors.wageningenGreen);
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: Stack(
///         children: [
///           // ... your content
///           buildTopBanner(),
///         ],
///       ),
///     );
///   }
/// }
/// ```
mixin TopNotificationMixin<T extends StatefulWidget> on State<T> {
  String? _topMessage;
  Color _topColor = AppColors.wageningenGreen;
  Timer? _topTimer;

  /// Hiển thị banner ở đỉnh màn hình.
  ///
  /// [color] mặc định green. Pass `AppColors.settingsColor7` cho lỗi.
  /// [duration] mặc định 3 giây.
  void showTopNotification(
    String message,
    Color color, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _topTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _topMessage = message;
      _topColor = color;
    });
    _topTimer = Timer(duration, () {
      if (mounted) setState(() => _topMessage = null);
    });
  }

  /// Đóng ngay notification (nếu đang hiển thị).
  void dismissTopNotification() {
    _topTimer?.cancel();
    if (mounted) setState(() => _topMessage = null);
  }

  /// Đặt block này vào trong `Stack` của body để render banner.
  Widget buildTopBanner() {
    if (_topMessage == null) return const SizedBox.shrink();
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        elevation: 2,
        color: _topColor,
        child: SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              _topMessage!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppStyles.font,
                color: AppColors.white,
                fontSize: AppStyles.sizeCard,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _topTimer?.cancel();
    super.dispose();
  }
}
