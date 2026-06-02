import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;
  static const String _tokenKey = 'auth_token';

  // ─── Token Management ────────────────────────────────────────────────────────

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  bool get hasToken => _token != null && _token!.isNotEmpty;

  // ─── Headers ─────────────────────────────────────────────────────────────────

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // ─── URL Builder ─────────────────────────────────────────────────────────────

  Uri _buildUri(String path, [Map<String, String>? params]) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (params != null && params.isNotEmpty) {
      return uri.replace(queryParameters: params);
    }
    return uri;
  }

  // ─── Response Handler ────────────────────────────────────────────────────────

  dynamic _handleResponse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      decoded = {'message': body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final message = decoded is Map
        ? decoded['message']?.toString() ?? 'Terjadi kesalahan'
        : 'Terjadi kesalahan';
    throw ApiException(message, statusCode: response.statusCode);
  }

  // ─── HTTP Methods ─────────────────────────────────────────────────────────────

  Future<dynamic> get(String path, {Map<String, String>? params}) async {
    try {
      final response = await http
          .get(_buildUri(path, params), headers: _headers)
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Tidak ada koneksi internet');
    } on HttpException {
      throw const ApiException('Kesalahan jaringan');
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            _buildUri(path),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Tidak ada koneksi internet');
    } on HttpException {
      throw const ApiException('Kesalahan jaringan');
    }
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .put(
            _buildUri(path),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Tidak ada koneksi internet');
    } on HttpException {
      throw const ApiException('Kesalahan jaringan');
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final response = await http
          .delete(_buildUri(path), headers: _headers)
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Tidak ada koneksi internet');
    } on HttpException {
      throw const ApiException('Kesalahan jaringan');
    }
  }

  /// Multipart POST for file uploads.
  Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    Map<String, String>? filePaths,
  }) async {
    try {
      final request =
          http.MultipartRequest('POST', _buildUri(path));
      request.headers.addAll({
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      });
      request.fields.addAll(fields);

      if (filePaths != null) {
        for (final entry in filePaths.entries) {
          final file = await http.MultipartFile.fromPath(entry.key, entry.value);
          request.files.add(file);
        }
      }

      final streamedResponse = await request.send()
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds * 2));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Tidak ada koneksi internet');
    }
  }

  /// Multipart PUT for file updates.
  Future<dynamic> putMultipart(
    String path, {
    required Map<String, String> fields,
    Map<String, String>? filePaths,
  }) async {
    try {
      final request =
          http.MultipartRequest('PUT', _buildUri(path));
      request.headers.addAll({
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      });
      request.fields.addAll(fields);

      if (filePaths != null) {
        for (final entry in filePaths.entries) {
          final file = await http.MultipartFile.fromPath(entry.key, entry.value);
          request.files.add(file);
        }
      }

      final streamedResponse = await request.send()
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds * 2));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Tidak ada koneksi internet');
    }
  }
}
