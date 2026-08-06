part of 'auth_bloc.dart';

/// Ported from loginReducer actions in App.js
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// Checks the stored token at app startup (= RETRIEVE_TOKEN)
class AppStarted extends AuthEvent {
  const AppStarted();
}

/// Successful login (= LOGIN)
class LoggedIn extends AuthEvent {
  final UserInfo user;
  const LoggedIn(this.user);
  @override
  List<Object?> get props => [user];
}

/// Logout (= LOGOUT)
class LoggedOut extends AuthEvent {
  const LoggedOut();
}
