
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/network/network_info.dart';
import '../../../data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Ported from loginReducer + authContext (App.js)
///
/// Flow:
///   AppStarted → check token → AuthAuthenticated | AuthUnauthenticated
///   LoggedIn   → save token  → AuthAuthenticated
///   LoggedOut  → clear token → AuthUnauthenticated
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final SecureStorage _secureStorage;
  final NetworkInfo _networkInfo;

  AuthBloc({
    required AuthRepository authRepository,
    required SecureStorage secureStorage,
    required NetworkInfo networkInfo,
  })  : _authRepository = authRepository,
        _secureStorage = secureStorage,
        _networkInfo = networkInfo,
        super(const AuthLoading()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
  }

  // ─── AppStarted ───────────────────────────────────────────────
  /// Checks the stored token and refreshes it on app startup
  /// Ported from the first useEffect() in App.js
  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    // Check Wi-Fi connectivity
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      emit(const AuthUnauthenticated());
      return;
    }

    // Load saved user info
    final userInfo = await _secureStorage.getUserInfo();
    if (userInfo == null) {
      emit(const AuthUnauthenticated());
      return;
    }

    final username = userInfo['username'] as String?;
    final password = userInfo['password'] as String?;
    final loginType = userInfo['loginType'] as String?;

    if (username == null || password == null) {
      emit(const AuthUnauthenticated());
      return;
    }

    // Refresh the token
    try {
      final result = loginType == 'QR'
          ? await _authRepository.loginByQR(username, password)
          : await _authRepository.login(username, password);

      if (result != null) {
        final user = UserInfo(
          username: username,
          token: result['token'] as String? ?? '',
          refreshToken: result['refreshToken'] as String? ?? '',
          loginType: loginType,
        );
        await _saveUserSession(user, password);
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  // ─── LoggedIn ─────────────────────────────────────────────────
  Future<void> _onLoggedIn(
    LoggedIn event,
    Emitter<AuthState> emit,
  ) async {
    await _secureStorage.saveToken(event.user.token);
    if (event.user.refreshToken.isNotEmpty) {
      await _secureStorage.saveRefreshToken(event.user.refreshToken);
    }
    await _secureStorage.saveUserInfo(event.user.toJson());
    emit(AuthAuthenticated(event.user));
  }

  // ─── LoggedOut ────────────────────────────────────────────────
  Future<void> _onLoggedOut(
    LoggedOut event,
    Emitter<AuthState> emit,
  ) async {
    await _secureStorage.clearAll();
    emit(const AuthUnauthenticated());
  }

  // ─── Helpers ──────────────────────────────────────────────────
  Future<void> _saveUserSession(UserInfo user, String password) async {
    await _secureStorage.saveToken(user.token);
    if (user.refreshToken.isNotEmpty) {
      await _secureStorage.saveRefreshToken(user.refreshToken);
    }
    await _secureStorage.saveUserInfo({
      ...user.toJson(),
      'password': password,
    });
  }
}
