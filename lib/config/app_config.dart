class AppConfig {
  static const String version = '1.10.2';
  static const String build = '1';
  static const String date = '2025-10-27';
  static const String env = 'Development';
  static const String host = 'http://133.167.47.242:9500';
  
  // API Timeout
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Storage Keys
  static const String keyUserToken = 'userToken';
  static const String keyUserName = 'userName';
  static const String keyPassword = 'passWord';
  static const String keyAccount = 'account';
  static const String keyDataToken = 'dataToken';
  static const String keyLoginType = 'loginType';
  
  // Master Data Keys
  static const String keyProducts = 'dataProducts';
  static const String keySuppliers = 'dataSuppliers';
  static const String keyBins = 'dataBins';
  static const String keyUnits = 'dataUnits';
  static const String keyLocations = 'dataLocations';
  static const String keyProductsWithInventory = 'dataProductsWithInventory';
  static const String keyRoles = 'roles';
}

