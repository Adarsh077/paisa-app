import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paisa_app/services/auth_service.dart';

class ApiService {
  static final AuthService _authService = AuthService();

  static Future<http.Response> get(String url) async {
    final headers = await _authService.getAuthHeaders();
    return await http.get(Uri.parse(url), headers: headers);
  }

  static Future<http.Response> post(String url, {Object? body}) async {
    final headers = await _authService.getAuthHeaders();
    return await http.post(
      Uri.parse(url),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> put(String url, {Object? body}) async {
    final headers = await _authService.getAuthHeaders();
    return await http.put(
      Uri.parse(url),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> delete(String url) async {
    final headers = await _authService.getAuthHeaders();
    return await http.delete(Uri.parse(url), headers: headers);
  }
}
