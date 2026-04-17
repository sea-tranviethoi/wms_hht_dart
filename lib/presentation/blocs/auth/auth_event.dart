part of 'auth_bloc.dart';

/// Port từ loginReducer actions trong App.js
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// Kiểm tra token cũ khi app khởi động (= RETRIEVE_TOKEN)
class AppStarted extends AuthEvent {
  const AppStarted();
}

/// Đăng nhập thành công (= LOGIN)
class LoggedIn extends AuthEvent {
  final UserInfo user;
  const LoggedIn(this.user);
  @override
  List<Object?> get props => [user];
}

/// Đăng xuất (= LOGOUT)
class LoggedOut extends AuthEvent {
  const LoggedOut();
}
