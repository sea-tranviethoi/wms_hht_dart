import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Secure storage for tokens — replaces AsyncStorage (token) in RN
/// flutter_secure_storage uses Android Keystore / iOS Keychain
class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  // ─── Token ────────────────────────────────────────────────────

  Future<void> saveToken(String token) =>
      _storage.write(key: AppConstants.keyToken, value: token);

  Future<String?> getToken() =>
      _storage.read(key: AppConstants.keyToken);

  Future<void> deleteToken() =>
      _storage.delete(key: AppConstants.keyToken);

  // ─── Refresh Token ────────────────────────────────────────────

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: AppConstants.keyRefreshToken, value: token);

  Future<String?> getRefreshToken() =>
      _storage.read(key: AppConstants.keyRefreshToken);

  // ─── User Info (JSON) ─────────────────────────────────────────

  Future<void> saveUserInfo(Map<String, dynamic> info) =>
      _storage.write(
        key: AppConstants.keyUserInfo,
        value: jsonEncode(info),
      );

  Future<Map<String, dynamic>?> getUserInfo() async {
    final raw = await _storage.read(key: AppConstants.keyUserInfo);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ─── Clear All ────────────────────────────────────────────────

  Future<void> clearAll() => _storage.deleteAll();

  // ─── Host (server URL override) ───────────────────────────────

  Future<void> saveHostname(String host) =>
      _storage.write(key: AppConstants.keyHostname, value: host);

  Future<String?> getHostname() =>
      _storage.read(key: AppConstants.keyHostname);
}
