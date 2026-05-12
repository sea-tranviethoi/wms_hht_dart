import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/sound_manager.dart';
import '../hardware/keyboard_event_bus.dart';
import '../hardware/keyence_scanner.dart';
import '../hardware/native_keyboard_channel.dart';
import '../network/dio_client.dart';
import '../network/network_info.dart';
import '../storage/cache_storage.dart';
import '../storage/secure_storage.dart';
import '../update/app_updater.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/datasources/remote/master_remote_datasource.dart';
import '../../data/datasources/remote/bundle_remote_datasource.dart';
import '../../data/datasources/remote/picking_remote_datasource.dart';
import '../../data/datasources/remote/putaway_remote_datasource.dart';
import '../../data/datasources/remote/wr_remote_datasource.dart';
import '../../data/datasources/remote/bin_movement_remote_datasource.dart';
import '../../data/datasources/remote/bin_audit_remote_datasource.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/bin_audit_repository.dart';
import '../../data/repositories/bin_movement_repository.dart';
import '../../data/repositories/master_repository.dart';

/// Service Locator toàn app — thay thế Context API của React Native
///
/// Cách dùng:
/// ```dart
/// // Lấy instance
/// final dioClient = sl<DioClient>();
/// final soundManager = sl<SoundManager>();
/// ```
final GetIt sl = GetIt.instance;

/// Khởi tạo tất cả dependencies — gọi 1 lần trong main()
Future<void> initDependencies() async {
  // ─── External / Platform ──────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);
  sl.registerSingleton<FlutterSecureStorage>(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
  sl.registerSingleton<Connectivity>(Connectivity());

  // ─── Core: Storage ────────────────────────────────────────────
  sl.registerSingleton<SecureStorage>(
    SecureStorage(storage: sl<FlutterSecureStorage>()),
  );
  sl.registerSingleton<CacheStorage>(
    CacheStorage(sl<SharedPreferences>()),
  );

  // ─── Core: Network ────────────────────────────────────────────
  sl.registerSingleton<NetworkInfo>(
    NetworkInfoImpl(connectivity: sl<Connectivity>()),
  );

  // Hostname có thể đã được save từ lần trước
  final savedHost = await sl<SecureStorage>().getHostname();
  sl.registerSingleton<DioClient>(
    DioClient(sl<SecureStorage>(), baseUrl: savedHost),
  );

  // ─── Core: Security ───────────────────────────────────────────
  // CryptoService chỉ có static methods — không cần register vào sl
  // Gọi trực tiếp: CryptoService.decryptQRCode(...)

  // ─── Core: Hardware (Android only) ───────────────────────────
  sl.registerSingleton<KeyboardEventBus>(KeyboardEventBus.instance);
  sl.registerSingleton<KeyenceScanner>(KeyenceScanner.instance);
  if (!kIsWeb) {
    await sl<KeyenceScanner>().init();
    // Native keyboard events (Keyence side buttons) → KeyboardEventBus
    NativeKeyboardChannel.instance.startListening();
  }

  // ─── Core: Audio ──────────────────────────────────────────────
  sl.registerSingleton<SoundManager>(SoundManager.instance);
  if (!kIsWeb) {
    await sl<SoundManager>().init();
  }

  // ─── Core: Update ─────────────────────────────────────────────
  sl.registerSingleton<AppUpdater>(AppUpdater(sl<DioClient>()));

  // ─── Data: Remote DataSources ─────────────────────────────────
  sl.registerSingleton<AuthRemoteDataSource>(
    AuthRemoteDataSource(sl<DioClient>()),
  );

  // ─── Data: Repositories ───────────────────────────────────────
  sl.registerSingleton<AuthRepository>(
    AuthRepository(
      remote: sl<AuthRemoteDataSource>(),
      storage: sl<SecureStorage>(),
    ),
  );

  sl.registerSingleton<MasterRemoteDataSource>(
    MasterRemoteDataSource(sl<DioClient>()),
  );
  sl.registerSingleton<MasterRepository>(
    MasterRepository(remote: sl<MasterRemoteDataSource>()),
  );

  sl.registerSingleton<PickingRemoteDataSource>(
    PickingRemoteDataSource(sl<DioClient>()),
  );

  sl.registerSingleton<PutawayRemoteDataSource>(
    PutawayRemoteDataSource(sl<DioClient>()),
  );

  sl.registerSingleton<BundleRemoteDataSource>(
    BundleRemoteDataSource(sl<DioClient>()),
  );

  sl.registerSingleton<WRRemoteDataSource>(
    WRRemoteDataSource(sl<DioClient>()),
  );

  sl.registerSingleton<BinMovementRemoteDataSource>(
    BinMovementRemoteDataSource(sl<DioClient>()),
  );
  sl.registerSingleton<BinMovementRepository>(
    BinMovementRepository(remote: sl<BinMovementRemoteDataSource>()),
  );

  sl.registerSingleton<BinAuditRemoteDataSource>(
    BinAuditRemoteDataSource(sl<DioClient>()),
  );
  sl.registerSingleton<BinAuditRepository>(
    BinAuditRepository(remote: sl<BinAuditRemoteDataSource>()),
  );
}
