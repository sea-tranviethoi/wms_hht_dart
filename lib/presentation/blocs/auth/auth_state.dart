part of 'auth_bloc.dart';

/// Ported from initialLoginState in App.js
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

/// Checking the token (isLoading: true) — show SplashScreen
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated — navigate to MainMenu
class AuthAuthenticated extends AuthState {
  final UserInfo user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

/// Not authenticated — navigate to LoginScreen
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// ─── Domain Model ────────────────────────────────────────────────────────────

/// User information after a successful login
class UserInfo extends Equatable {
  final String username;
  final String token;
  final String refreshToken;
  final String? loginType; // 'QR' or 'NORMAL'

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
