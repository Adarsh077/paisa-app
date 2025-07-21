import 'package:flutter/foundation.dart';
import 'package:paisa_app/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isAuthenticated = false;
  bool _isInitialLoading = false;
  bool _isLoginLoading = false;
  bool _isRegisterLoading = false;
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialLoading => _isInitialLoading;
  bool get isLoginLoading => _isLoginLoading;
  bool get isRegisterLoading => _isRegisterLoading;
  String? get errorMessage => _errorMessage;

  Future<void> checkAuthStatus() async {
    _isInitialLoading = true;
    notifyListeners();

    try {
      _isAuthenticated = await _authService.isLoggedIn();
    } catch (e) {
      _isAuthenticated = false;
    }

    _isInitialLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoginLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.login(email, password);
      if (token != null) {
        _isAuthenticated = true;
        _errorMessage = null;
      } else {
        _isAuthenticated = false;
        _errorMessage = 'Invalid email or password';
      }
    } catch (e) {
      _isAuthenticated = false;
      _errorMessage = 'Login failed. Please try again.';
    }

    _isLoginLoading = false;
    notifyListeners();
    return _isAuthenticated;
  }

  Future<bool> register(String name, String email, String password) async {
    _isRegisterLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.register(name, email, password);
      if (token != null) {
        _isAuthenticated = true;
        _errorMessage = null;
      } else {
        _isAuthenticated = false;
        _errorMessage = 'Registration failed. Please try again.';
      }
    } catch (e) {
      _isAuthenticated = false;
      _errorMessage = 'Registration failed. Please try again.';
    }

    _isRegisterLoading = false;
    notifyListeners();
    return _isAuthenticated;
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
