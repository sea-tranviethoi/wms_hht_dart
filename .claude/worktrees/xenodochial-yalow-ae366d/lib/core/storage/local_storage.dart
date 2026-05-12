import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../config/app_config.dart';
import '../../data/models/auth/login_response.dart';

class LocalStorage {
  final SharedPreferences _prefs;

  LocalStorage(this._prefs);

  // Token Management
  Future<void> saveToken(LoginResponse response) async {
    await _prefs.setString(
      AppConfig.keyDataToken,
      jsonEncode(response.toJson()),
    );
  }

  Future<String?> getToken() async {
    final tokenData = _prefs.getString(AppConfig.keyDataToken);
    if (tokenData != null) {
      try {
        final data = jsonDecode(tokenData);
        return data['token'] as String?;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<LoginResponse?> getTokenData() async {
    final tokenData = _prefs.getString(AppConfig.keyDataToken);
    if (tokenData != null) {
      try {
        final data = jsonDecode(tokenData);
        return LoginResponse.fromJson(data);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // String operations
  Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    return _prefs.getString(key);
  }

  // JSON operations (accept Map or List)
  Future<void> saveJson(String key, dynamic data) async {
    await _prefs.setString(key, jsonEncode(data));
  }

  Future<dynamic> getJson(String key) async {
    final data = _prefs.getString(key);
    if (data != null) {
      try {
        return jsonDecode(data);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // List operations
  Future<void> saveList(String key, List<dynamic> list) async {
    await _prefs.setString(key, jsonEncode(list));
  }

  Future<List<dynamic>?> getList(String key) async {
    final data = _prefs.getString(key);
    if (data != null) {
      try {
        return jsonDecode(data) as List<dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Remove
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  Future<void> removeMultiple(List<String> keys) async {
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  // Clear all
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

