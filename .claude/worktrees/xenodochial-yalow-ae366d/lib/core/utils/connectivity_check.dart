import 'package:connectivity_plus/connectivity_plus.dart';

// Deprecated: dùng NetworkInfo (core/network/network_info.dart) thay thế
// Giữ lại để tránh break các file cũ đang import
class ConnectivityCheck {
  static final Connectivity _connectivity = Connectivity();

  static Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  }

  static Future<bool> isWifiConnected() async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.wifi);
  }

  static Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivity.onConnectivityChanged;
}
