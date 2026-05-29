// Deprecated: use AuthBloc (presentation/blocs/auth/auth_bloc.dart) instead
// Kept to avoid breaking existing screens that still import it
import 'package:flutter/foundation.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider(this._authRepository);

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _userName;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get userName => _userName;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authRepository.login(email, password);
      if (response != null) {
        _isAuthenticated = true;
        _userName = email;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> loginByQR(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authRepository.loginByQR(email, password);
      if (response != null) {
        _isAuthenticated = true;
        _userName = email;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authRepository.logout();
    } catch (_) {
      // ignore
    } finally {
      _isAuthenticated = false;
      _userName = null;
      _isLoading = false;
      notifyListeners();
    }
  }
}
