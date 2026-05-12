/// Hằng số toàn app — port từ env/info.js + AppConfig.dart cũ
class AppConstants {
  AppConstants._();

  // ─── App Info ─────────────────────────────────────────────────
  static const String appVersion  = '1.10.2';
  static const String appBuild    = '1';
  static const String appName     = 'FBTHHT';

  // ─── Server ───────────────────────────────────────────────────
  /// Host mặc định — override bằng SharedPreferences nếu cần
  static const String defaultHost = 'http://133.167.47.242:9500';

  // ─── API Timeout ──────────────────────────────────────────────
  static const Duration apiTimeout        = Duration(seconds: 30);
  static const Duration connectTimeout    = Duration(seconds: 30);
  static const Duration receiveTimeout    = Duration(seconds: 30);

  // ─── Storage Keys ─────────────────────────────────────────────
  static const String keyToken            = 'dataToken';
  static const String keyRefreshToken     = 'refreshToken';
  static const String keyUserInfo         = 'userInfo';
  static const String keyHostname         = 'hostname';
  static const String keyLanguage         = 'language';
  static const String keyLocation         = 'selectedLocation';

  // ─── Master Data Cache Keys (sqflite tables) ──────────────────
  static const String tableProducts       = 'products';
  static const String tableBins           = 'bins';
  static const String tableLocations      = 'locations';
  static const String tableUnits          = 'units';
  static const String tableSuppliers      = 'suppliers';
  static const String tableVendors        = 'vendors';
  static const String tableRoles          = 'roles';
  static const String tableDevices        = 'devices';

  // ─── Crypto ───────────────────────────────────────────────────
  /// Passphrase cứng cho TripleDES decrypt QR login
  /// TODO: Đưa ra server config sau khi migrate xong
  static const String qrPassphrase        = 'WmsHt123@456';

  // ─── Sound Assets ─────────────────────────────────────────────
  static const String soundCorrect        = 'sounds/correct.mp3';
  static const String soundError          = 'sounds/error.mp3';
  static const String soundWarning        = 'sounds/warning.mp3';

  // ─── OTA ──────────────────────────────────────────────────────
  static const String otaDownloadPath     = 'downloads/fbt_hht.apk';
  static const String otaVersionEndpoint  = '/api/Devices/DownloadApiAsync';
}
