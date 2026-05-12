import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

/// Port từ services/token.js
/// fc_GetToken, fc_GetTokenByQR, fc_RefreshToken
class AuthRemoteDataSource {
  final DioClient _dioClient;

  AuthRemoteDataSource(this._dioClient);

  Dio get _dio => _dioClient.dio;

  // ─── Login thường (username/password) ────────────────────────
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/Account/identity/loginasync',
        data: {'emailAddress': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>?;
      if (data != null && data['flag'] == true) return data;
      return null;
    } on DioException {
      return null;
    }
  }

  // ─── Login bằng QR (sau khi decrypt) ─────────────────────────
  Future<Map<String, dynamic>?> loginByQR(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/Account/identity/loginht',
        data: {'emailAddress': email, 'password': password, 'remember': true},
      );
      final data = response.data as Map<String, dynamic>?;
      if (data != null && data['flag'] == true) return data;
      return null;
    } on DioException {
      return null;
    }
  }

  // ─── Refresh token ────────────────────────────────────────────
  Future<Map<String, dynamic>?> refreshToken(
    String token,
    String refreshToken,
  ) async {
    try {
      final response = await _dio.post(
        '/api/Account/identity/refresh-token',
        data: {'token': token, 'refreshToken': refreshToken},
      );
      final data = response.data as Map<String, dynamic>?;
      if (data != null && data['flag'] == true) return data;
      return null;
    } on DioException {
      return null;
    }
  }

  // ─── Lấy danh sách devices (để check version OTA) ────────────
  Future<List<dynamic>> getDevices() async {
    try {
      final response = await _dio.get('/api/Devices');
      return (response.data as List?) ?? [];
    } on DioException {
      return [];
    }
  }
}
