import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';

/// HTTP client dùng cho toàn bộ app
/// Port từ modules/fetchDataModule.js
///
/// Tính năng:
/// - Tự gắn Bearer token vào mọi request
/// - Retry 1 lần khi 401 (refresh token)
/// - Timeout 30 giây
/// - Hiện dialog lỗi + exit app khi không thể refresh token
class DioClient {
  late final Dio _dio;
  final SecureStorage _secureStorage;
  bool _isRefreshing = false;

  DioClient(this._secureStorage, {String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConstants.defaultHost,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout: AppConstants.apiTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_secureStorage, _dio, _getIsRefreshing, _setIsRefreshing),
      PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseBody: true,
        compact: true,
      ),
    ]);
  }

  bool _getIsRefreshing() => _isRefreshing;
  void _setIsRefreshing(bool v) => _isRefreshing = v;

  Dio get dio => _dio;

  /// Cập nhật baseUrl khi user thay đổi hostname trong settings
  void updateBaseUrl(String host) {
    _dio.options.baseUrl = host;
  }
}

// ─── Auth Interceptor ─────────────────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage;
  final Dio _dio;
  final bool Function() _getIsRefreshing;
  final void Function(bool) _setIsRefreshing;

  _AuthInterceptor(
    this._secureStorage,
    this._dio,
    this._getIsRefreshing,
    this._setIsRefreshing,
  );

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // ── Timeout / Network error ────────────────────────────────
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError) {
      _showErrorAndExit(
        'ネットワークエラー',
        'サーバーに接続できません。\nアプリを再起動してください。',
      );
      return handler.next(err);
    }

    // ── 401 Unauthorized → thử refresh token ─────────────────
    if (err.response?.statusCode == 401 && !_getIsRefreshing()) {
      _setIsRefreshing(true);
      try {
        final newToken = await _refreshToken();
        if (newToken != null) {
          await _secureStorage.saveToken(newToken);
          // Retry request gốc với token mới
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final response = await _dio.fetch(opts);
          _setIsRefreshing(false);
          return handler.resolve(response);
        }
      } catch (_) {
        // refresh thất bại
      }
      _setIsRefreshing(false);
      await _secureStorage.clearAll();
      _showErrorAndExit(
        'セッション期限切れ',
        'ログインセッションが切れました。\n再ログインしてください。',
      );
    }

    handler.next(err);
  }

  Future<String?> _refreshToken() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null) return null;

    final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
    try {
      final res = await refreshDio.post(
        '/api/Account/identity/refresh-token',
        data: {'refreshToken': refreshToken},
      );
      return res.data?['token'] as String?;
    } catch (_) {
      return null;
    }
  }

  void _showErrorAndExit(String title, String message) {
    final context = _navigatorKey.currentContext;
    if (context == null) {
      exit(0);
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => exit(0),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
    }
  }
}

/// GlobalKey để access context từ interceptor (không dùng BuildContext param)
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

/// Export navigatorKey để dùng trong MaterialApp
GlobalKey<NavigatorState> get appNavigatorKey => _navigatorKey;
