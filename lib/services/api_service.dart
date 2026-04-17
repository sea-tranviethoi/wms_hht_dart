import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService._();

  // Base URL for the API
  static const String baseUrl = 'http://133.167.47.242:9500';

  static final http.Client _client = http.Client();

  // Generic GET
  static Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final mergedHeaders = await _defaultHeaders(headers);
    return _client.get(uri, headers: mergedHeaders);
  }

  // Generic POST (JSON)
  static Future<http.Response> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final mergedHeaders = await _defaultHeaders(headers);
    return _client.post(
      uri,
      headers: mergedHeaders,
      body: jsonEncode(body ?? {}),
    );
  }

  // Generic PUT (JSON)
  static Future<http.Response> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final mergedHeaders = await _defaultHeaders(headers);
    return _client.put(
      uri,
      headers: mergedHeaders,
      body: jsonEncode(body ?? {}),
    );
  }

  // Generic PATCH (JSON)
  static Future<http.Response> patch(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final mergedHeaders = await _defaultHeaders(headers);
    return _client.patch(
      uri,
      headers: mergedHeaders,
      body: jsonEncode(body ?? {}),
    );
  }

  static Future<Map<String, String>> _defaultHeaders(
    Map<String, String>? headers,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final base = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      base['Authorization'] = 'Bearer $token';
    }
    if (headers != null) {
      base.addAll(headers);
    }
    return base;
  }

  // Example login method — adjust path/response parsing to your API
  // Returns a Map with keys: success(bool), message(String), data(Map?)
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      // Try a set of common endpoints and payload shapes used by different APIs.
      final pathsToTry = [
        '/api/Account/identity/loginasync', // specific endpoint provided by user
        '/login',
        '/auth/login',
        '/api/login',
        '/api/auth/login',
        '/authenticate',
        '/auth/token',
        '/token',
      ];

      final payloadVariants = [
        {'email': email, 'password': password},
        {'emailAddress': email, 'password': password, 'remember': true},
        {'username': email, 'password': password},
      ];

      http.Response? res;
      Exception? lastEx;
      http.Response? lastResponse;

      for (final p in pathsToTry) {
        for (final payload in payloadVariants) {
          try {
            res = await post(p, body: payload);
            lastResponse = res;
          } catch (e) {
            // Keep the last exception for reporting
            lastEx = e as Exception;
            res = null;
          }

          if (res != null && res.statusCode >= 200 && res.statusCode < 300) {
            break;
          }
        }
        if (res != null && res.statusCode >= 200 && res.statusCode < 300) {
          break;
        }
      }

      if (res == null) {
        final msg = lastResponse != null
            ? 'API returned status ${lastResponse.statusCode}: ${lastResponse.body}'
            : (lastEx != null
                  ? 'Connection error: ${lastEx.toString()}'
                  : 'Unable to connect to API');
        return {'success': false, 'message': msg};
      }

      // Try parse body as JSON, but guard against non-JSON responses
      final bodyString = res.body;
      dynamic body;
      try {
        body = bodyString.isNotEmpty ? jsonDecode(bodyString) : null;
      } catch (e) {
        // Invalid JSON from server — keep raw string
        body = {'message': bodyString};
      }

      // Try common token fields (works when body is Map)
      final token = body is Map
          ? (body['token'] ?? body['access_token'] ?? body['data']?['token'])
          : null;

      if (token != null && token is String && token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        return {'success': true, 'message': 'Login successful', 'data': body};
      }

      // If API returns a success flag inside JSON
      if (body is Map &&
          (body['success'] ?? body['ok'] ?? body['authenticated']) == true) {
        return {'success': true, 'message': 'Login successful', 'data': body};
      }

      // Provide a helpful message: prefer JSON message field, otherwise raw body or status
      final message = (body is Map && body['message'] != null)
          ? body['message'].toString()
          : (bodyString.isNotEmpty
                ? bodyString
                : 'Login failed (status ${res.statusCode})');

      return {
        'success': false,
        'message': message,
        'data': body is Map
            ? body
            : {'raw': bodyString, 'status': res.statusCode},
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}
