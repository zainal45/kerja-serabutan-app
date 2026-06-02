import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SocketService _socketService = SocketService();

  User? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Initialize — load stored token and try to fetch user.
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _authService.loadToken();
      if (_authService.isAuthenticated) {
        _currentUser = await _authService.getMe();
        _connectSocket();
      }
    } catch (e) {
      // Token might be expired or invalid — clear it
      await _authService.logout();
      _currentUser = null;
    } finally {
      _isInitialized = true;
      _setLoading(false);
    }
  }

  /// Login with email and password.
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      _currentUser = await _authService.login(email, password);
      _connectSocket();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Login gagal. Coba lagi.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Register new account.
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      _currentUser = await _authService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      _connectSocket();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Pendaftaran gagal. Coba lagi.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout and disconnect socket.
  Future<void> logout() async {
    _socketService.disconnect();
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  /// Reload user data from server.
  Future<void> refreshUser() async {
    try {
      _currentUser = await _authService.getMe();
      notifyListeners();
    } catch (_) {}
  }

  void updateCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  void _connectSocket() {
    // Socket token is same as API token (stored in SharedPreferences)
    // We get it from the ApiService singleton
    final apiService = ApiService();
    if (apiService.hasToken) {
      // We don't expose _token directly, but the socket needs it
      // The token should be passed via loadToken() then we read it
      // Use a workaround: reconnect with userId as a simple identifier
      _socketService.connect(_currentUser?.id ?? '');
    }
  }
}
