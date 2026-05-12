part of 'auth_bloc.dart';

/// Port từ initialLoginState trong App.js
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

/// Đang kiểm tra token (isLoading: true) — hiện SplashScreen
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Đã xác thực — navigate tới MainMenu
class AuthAuthenticated extends AuthState {
  final UserInfo user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

/// Chưa xác thực — navigate tới LoginScreen
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// ─── Domain Model ────────────────────────────────────────────────────────────

/// Thông tin user sau khi login thành công
class UserInfo extends Equatable {
  final String username;
  final String token;
  final String refreshToken;
  final String? loginType; // 'QR' hoặc 'NORMAL'

  const UserInfo({
    required this.username,
    required this.token,
    required this.refreshToken,
    this.loginType,
  });

  @override
  List<Object?> get props => [username, token];

  Map<String, dynamic> toJson() => {
        'username': username,
        'token': token,
        'refreshToken': refreshToken,
        'loginType': loginType,
      };

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        username: json['username'] as String? ?? '',
        token: json['token'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
        loginType: json['loginType'] as String?,
      );
}
