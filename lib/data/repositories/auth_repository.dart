import '../datasources/remote/auth_remote_datasource.dart';
import '../../core/storage/secure_storage.dart';

/// Ported from services/token.js + authContext.signIn / signOut in App.js
class AuthRepository {
  final AuthRemoteDataSource _remote;
  final SecureStorage _storage;

  AuthRepository({
    required AuthRemoteDataSource remote,
    required SecureStorage storage,
  })  : _remote = remote,
        _storage = storage;

  // ─── Standard login ───────────────────────────────────────────
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final data = await _remote.login(email, password);
    if (data != null) {
      await _saveCredentials(email, password, 'NORMAL', data);
    }
    return data;
  }

  // ─── Login QR ─────────────────────────────────────────────────
  Future<Map<String, dynamic>?> loginByQR(String email, String password) async {
    final data = await _remote.loginByQR(email, password);
    if (data != null) {
      await _saveCredentials(email, password, 'QR', data);
    }
    return data;
  }

  // ─── Logout ───────────────────────────────────────────────────
  Future<void> logout() => _storage.clearAll();

  // ─── Fetch device list (OTA check) ───────────────────────────
  Future<List<dynamic>> getDevices() => _remote.getDevices();

  // ─── Private ──────────────────────────────────────────────────
  Future<void> _saveCredentials(
    String email,
    String password,
    String loginType,
    Map<String, dynamic> tokenData,
  ) async {
    final token = tokenData['token'] as String? ?? '';
    final refreshToken = tokenData['refreshToken'] as String? ?? '';

    await _storage.saveToken(token);
    if (refreshToken.isNotEmpty) {
      await _storage.saveRefreshToken(refreshToken);
    }
    await _storage.saveUserInfo({
      'username': email,
      'password': password,
      'loginType': loginType,
      'token': token,
      'refreshToken': refreshToken,
    });
  }
}
