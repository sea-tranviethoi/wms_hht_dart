import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Simple settings storage (language, location, etc.)
/// Master data (products, bins…) → sqflite (see MasterLocalDataSource)
class CacheStorage {
  final SharedPreferences _prefs;

  CacheStorage(this._prefs);

  // ─── Language ─────────────────────────────────────────────────

  Future<bool> saveLanguage(String lang) =>
      _prefs.setString(AppConstants.keyLanguage, lang);

  String getLanguage() =>
      _prefs.getString(AppConstants.keyLanguage) ?? 'ja';

  // ─── Selected Location ────────────────────────────────────────

  Future<bool> saveLocation(String locationId) =>
      _prefs.setString(AppConstants.keyLocation, locationId);

  String? getLocation() =>
      _prefs.getString(AppConstants.keyLocation);

  // ─── Generic helpers ──────────────────────────────────────────

  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  String? getString(String key) => _prefs.getString(key);

  Future<bool> setBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);

  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> remove(String key) => _prefs.remove(key);

  Future<bool> clearAll() => _prefs.clear();
}
