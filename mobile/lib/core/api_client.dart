import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'token_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  // Android emulator's special alias for the host machine's localhost.
  // static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
  static const String baseUrl = 'https://gastoapp-production-b3d5.up.railway.app/api/v1';
  final TokenStorage _tokenStorage;

  /// Called whenever a request comes back 401 Unauthorized (expired/invalid token).
  /// Wired up in main.dart to trigger logout + redirect to login.
  void Function()? onUnauthorized;

  ApiClient(this._tokenStorage);

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _tokenStorage.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on SocketException {
      throw ApiException(0, "Can't reach the server. Check your connection and try again.");
    } on TimeoutException {
      throw ApiException(0, 'The request took too long. Please try again.');
    } on HttpException {
      throw ApiException(0, 'A network error occurred. Please try again.');
    } on FormatException {
      throw ApiException(0, 'Received an unexpected response from the server.');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      onUnauthorized?.call();
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    String message = response.body;
    try {
      final decoded = jsonDecode(response.body);
      message = decoded['detail']?.toString() ?? response.body;
    } catch (_) {}
    throw ApiException(response.statusCode, message);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) {
    return _guard(() async {
      final response = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      return _handleResponse(response);
    });
  }

  Future<dynamic> get(String path, {bool auth = true}) {
    return _guard(() async {
      final response = await http
          .get(Uri.parse('$baseUrl$path'), headers: await _headers(auth: auth))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 401) onUnauthorized?.call();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body.isEmpty ? null : jsonDecode(response.body);
      }
      throw ApiException(response.statusCode, response.body);
    });
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) {
    return _guard(() async {
      final response = await http
          .patch(
            Uri.parse('$baseUrl$path'),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      return _handleResponse(response);
    });
  }

  Future<void> delete(String path, {bool auth = true}) {
    return _guard(() async {
      final response = await http
          .delete(Uri.parse('$baseUrl$path'), headers: await _headers(auth: auth))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 401) onUnauthorized?.call();
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      throw ApiException(response.statusCode, response.body);
    });
  }
}