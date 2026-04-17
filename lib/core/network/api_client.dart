import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../config/app_config.dart';
import 'api_endpoints.dart';
import '../../data/models/auth/login_response.dart';

class ApiClient {
  late Dio _dio;
  final SharedPreferences _prefs;

  ApiClient(this._prefs) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.host,
      connectTimeout: AppConfig.apiTimeout,
      receiveTimeout: AppConfig.apiTimeout,
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(AuthInterceptor(_prefs));
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  Dio get dio => _dio;
}

class AuthInterceptor extends Interceptor {
  final SharedPreferences _prefs;
  final Dio _refreshDio = Dio();

  AuthInterceptor(this._prefs);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final tokenData = _prefs.getString(AppConfig.keyDataToken);

    if (tokenData != null) {
      try {
        final data = jsonDecode(tokenData);
        final token = data['token'] as String?;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        // Handle error
      }
    }

    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Handle token refresh
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry request
        final opts = err.requestOptions;
        try {
          final tokenData = _prefs.getString(AppConfig.keyDataToken);
          if (tokenData != null) {
            final data = jsonDecode(tokenData);
            final token = data['token'] as String?;
            if (token != null) {
              opts.headers['Authorization'] = 'Bearer $token';
            }
          }

          final response = await _refreshDio.request(
            opts.path,
            options: Options(
              method: opts.method,
              headers: opts.headers,
            ),
            data: opts.data,
            queryParameters: opts.queryParameters,
            cancelToken: opts.cancelToken,
          );
          return handler.resolve(response);
        } catch (e) {
          // If refresh fails, continue with error
        }
      }
    }
    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    try {
      final tokenData = _prefs.getString(AppConfig.keyDataToken);
      if (tokenData == null) return false;

      final data = jsonDecode(tokenData);
      final token = data['token'] as String?;
      final refreshToken = data['refreshToken'] as String?;

      if (token == null || refreshToken == null) return false;

      final response = await _refreshDio.post(
        '${AppConfig.host}${ApiEndpoints.refreshToken}',
        data: {
          'token': token,
          'refreshToken': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(response.data);
        if (loginResponse.flag) {
          await _prefs.setString(
            AppConfig.keyDataToken,
            jsonEncode(loginResponse.toJson()),
          );
          return true;
        }
      }
    } catch (e) {
      // Handle error
    }
    return false;
  }
}

