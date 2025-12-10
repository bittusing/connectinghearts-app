import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import '../config/api_config.dart';

class ApiClient {
  final StorageService _storageService = StorageService();
  final String _baseUrl = ApiConfig.apiBaseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getToken();
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  String _normalizeUrl(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$_baseUrl$normalizedPath';
  }

  Future<T> request<T>({
    required String path,
    required String method,
    Map<String, dynamic>? body,
    T Function(dynamic json)? fromJson,
  }) async {
    final url = Uri.parse(_normalizeUrl(path));
    final headers = await _getHeaders();

    http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(url, headers: headers);
        break;
      case 'POST':
        response = await http.post(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'PUT':
        response = await http.put(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'PATCH':
        response = await http.patch(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'DELETE':
        response = await http.delete(url, headers: headers);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.statusCode == 204 || response.body.isEmpty) {
        return null as T;
      }
      final jsonData = jsonDecode(response.body);
      if (fromJson != null) {
        return fromJson(jsonData);
      }
      return jsonData as T;
    } else {
      String errorMessage = 'Unknown error';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData['err'] is String) {
          errorMessage = errorData['err'];
        } else if (errorData['err']?['msg'] != null) {
          errorMessage = errorData['err']['msg'];
        } else if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        } else if (errorData['error'] != null) {
          errorMessage = errorData['error'];
        }
      } catch (_) {
        errorMessage = response.body.isNotEmpty 
            ? response.body 
            : 'Request failed with status ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
  }

  Future<T> get<T>(String path, {T Function(dynamic json)? fromJson}) {
    return request<T>(path: path, method: 'GET', fromJson: fromJson);
  }

  Future<T> post<T>(String path, {Map<String, dynamic>? body, T Function(dynamic json)? fromJson}) {
    return request<T>(path: path, method: 'POST', body: body, fromJson: fromJson);
  }

  Future<T> put<T>(String path, {Map<String, dynamic>? body, T Function(dynamic json)? fromJson}) {
    return request<T>(path: path, method: 'PUT', body: body, fromJson: fromJson);
  }

  Future<T> patch<T>(String path, {Map<String, dynamic>? body, T Function(dynamic json)? fromJson}) {
    return request<T>(path: path, method: 'PATCH', body: body, fromJson: fromJson);
  }

  Future<T> delete<T>(String path, {T Function(dynamic json)? fromJson}) {
    return request<T>(path: path, method: 'DELETE', fromJson: fromJson);
  }
}
