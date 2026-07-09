import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_session.dart';
import 'api_response.dart';

List<Map<String, dynamic>> parseApiList(Object? value) {
  final list = value as List<dynamic>? ?? [];
  return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException([this.message = 'Su sesión ha expirado']);
  @override
  String toString() => message;
}

class ApiClient {
  static const String baseUrl = String.fromEnvironment(
    'SIGO_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000/api',
  );

  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<ApiResponse<T>> get<T>(
    String path,
    T Function(Object? value) parseDatos,
  ) async {
    try {
      final response = await _client.get(
            _uri(path),
            headers: _headers(),
          ).timeout(
            const Duration(seconds: 12),
          );
      return _parseResponse(response, parseDatos);
    } on TimeoutException {
      throw Exception(
        'La API no respondió a tiempo. Verifique el backend en $baseUrl',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar con la API. Verifique que Node esté corriendo en $baseUrl',
      );
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Object? value) parseDatos,
  ) async {
    try {
      final response = await _client
          .post(
            _uri(path),
            headers: _headers(json: true),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));

      return _parseResponse(response, parseDatos);
    } on TimeoutException {
      throw Exception(
        'La API no respondió a tiempo. Verifique el backend en $baseUrl',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar con la API. Verifique que Node esté corriendo en $baseUrl',
      );
    }
  }

  Future<ApiResponse<T>> put<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Object? value) parseDatos,
  ) async {
    try {
      final response = await _client
          .put(
            _uri(path),
            headers: _headers(json: true),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));

      return _parseResponse(response, parseDatos);
    } on TimeoutException {
      throw Exception(
        'La API no respondió a tiempo. Verifique el backend en $baseUrl',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar con la API. Verifique que Node esté corriendo en $baseUrl',
      );
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String path,
    T Function(Object? value) parseDatos,
  ) async {
    try {
      final response = await _client
          .delete(
            _uri(path),
            headers: _headers(),
          )
          .timeout(const Duration(seconds: 12));

      return _parseResponse(response, parseDatos);
    } on TimeoutException {
      throw Exception(
        'La API no respondió a tiempo. Verifique el backend en $baseUrl',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar con la API. Verifique que Node esté corriendo en $baseUrl',
      );
    }
  }

  Uri _uri(String path) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$baseUrl/$cleanPath');
  }

  Map<String, String> _headers({bool json = false}) {
    final headers = <String, String>{};

    if (json) {
      headers['Content-Type'] = 'application/json';
    }

    final token = AuthSession.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  ApiResponse<T> _parseResponse<T>(
    http.Response response,
    T Function(Object? value) parseDatos,
  ) {
    final decoded = _decodeResponse(response);
    return ApiResponse<T>.fromJson(decoded, parseDatos);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final Object? raw;
    try {
      raw = jsonDecode(response.body);
    } on FormatException {
      final preview = response.body
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      throw Exception(
        'La API respondió un formato no JSON (${response.statusCode}). '
        '${preview.length > 120 ? preview.substring(0, 120) : preview}',
      );
    }

    if (raw is! Map<String, dynamic>) {
      throw Exception('La API respondió un JSON inesperado');
    }

    final decoded = raw;
    final ok = decoded['ok'] == true;

    if (response.statusCode == 401) {
      AuthSession.clear();
      AuthSession.onSessionExpired?.call();
      throw UnauthorizedException(
        decoded['mensaje']?.toString() ?? 'Su sesión ha expirado. Por favor inicie sesión nuevamente.',
      );
    }

    if (response.statusCode >= 400 || !ok) {
      throw Exception(
        decoded['mensaje']?.toString() ?? 'Error al consumir la API',
      );
    }

    return decoded;
  }

  /// Obtiene respuesta completa como mapa (útil para endpoints paginados).
  Future<Map<String, dynamic>> getFull(String path) async {
    try {
      final response = await _client
          .get(_uri(path), headers: _headers())
          .timeout(const Duration(seconds: 12));
      return _decodeResponse(response);
    } on TimeoutException {
      throw Exception(
        'La API no respondió a tiempo. Verifique el backend en $baseUrl',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar con la API. Verifique que Node esté corriendo en $baseUrl',
      );
    }
  }
}
