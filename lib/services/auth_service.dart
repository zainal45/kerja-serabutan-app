import '../core/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  /// Login with email and password. Returns User + stores the token.
  Future<User> login(String email, String password) async {
    final response = await _api.post(ApiConfig.login, {
      'email': email.trim(),
      'password': password,
    });

    final token = response['token']?.toString();
    if (token == null || token.isEmpty) {
      throw const ApiException('Token tidak ditemukan dalam respons');
    }
    await _api.setToken(token);

    final userData = response['user'] ?? response['data'];
    if (userData == null) {
      throw const ApiException('Data pengguna tidak ditemukan dalam respons');
    }
    return User.fromJson(userData as Map<String, dynamic>);
  }

  /// Register a new account. Returns User + stores the token.
  Future<User> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final response = await _api.post(ApiConfig.register, {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'password': password,
      'role': role,
    });

    final token = response['token']?.toString();
    if (token == null || token.isEmpty) {
      throw const ApiException('Token tidak ditemukan dalam respons');
    }
    await _api.setToken(token);

    final userData = response['user'] ?? response['data'];
    if (userData == null) {
      throw const ApiException('Data pengguna tidak ditemukan dalam respons');
    }
    return User.fromJson(userData as Map<String, dynamic>);
  }

  /// Fetch the currently authenticated user's profile.
  Future<User> getMe() async {
    final response = await _api.get(ApiConfig.me);
    final userData = response['user'] ?? response['data'] ?? response;
    return User.fromJson(userData as Map<String, dynamic>);
  }

  /// Logout — clear stored token.
  Future<void> logout() async {
    await _api.clearToken();
  }

  /// Load saved token from SharedPreferences.
  Future<void> loadToken() async {
    await _api.loadToken();
  }

  bool get isAuthenticated => _api.hasToken;
}
