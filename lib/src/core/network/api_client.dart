import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<Map<String, dynamic>> postForm({
    required String path,
    required Map<String, String> form,
    Map<String, String>? headers,
  }) async {
    final Uri uri = Uri.parse('$baseUrl$path');
    final http.Response response = await _client
        .post(
          uri,
          headers: <String, String>{
            'Content-Type': 'application/x-www-form-urlencoded',
            ...?headers,
          },
          body: form,
        )
        .timeout(const Duration(seconds: 20));

    return _decodeMapOrThrow(response);
  }

  Future<Map<String, dynamic>> postJson({
    required String path,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final Uri uri = Uri.parse('$baseUrl$path');
    final http.Response response = await _client
        .post(
          uri,
          headers: <String, String>{
            'Content-Type': 'application/json',
            ...?headers,
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    return _decodeMapOrThrow(response);
  }

  Future<Map<String, dynamic>> getJson({
    required String path,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) async {
    final Uri uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    final http.Response response = await _client
        .get(uri, headers: <String, String>{...?headers})
        .timeout(const Duration(seconds: 20));

    return _decodeMapOrThrow(response);
  }

  Future<List<dynamic>> getJsonList({
    required String path,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) async {
    final Uri uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    final http.Response response = await _client
        .get(uri, headers: <String, String>{...?headers})
        .timeout(const Duration(seconds: 20));

    return _decodeListOrThrow(response);
  }

  Map<String, dynamic> _decodeMapOrThrow(http.Response response) {
    final bool isSuccess =
        response.statusCode >= 200 && response.statusCode < 300;

    // Decode defensively: gateways/proxies (Cloud Run, load balancers) can
    // return a plain-text or HTML body such as "Internal Server Error" on a
    // 5xx, which is NOT valid JSON. Parsing that unconditionally used to throw
    // a confusing FormatException; instead we fall back to a clean message.
    Object? decoded;
    try {
      decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (isSuccess) {
      if (decoded is Map<String, dynamic>) return decoded;
      throw ApiException(
        'Unexpected response payload format.',
        statusCode: response.statusCode,
      );
    }

    final String message = (decoded is Map<String, dynamic>)
        ? (decoded['detail']?.toString() ??
              _httpErrorFallback(response.statusCode))
        : _httpErrorFallback(response.statusCode);
    throw ApiException(message, statusCode: response.statusCode);
  }

  List<dynamic> _decodeListOrThrow(http.Response response) {
    final bool isSuccess =
        response.statusCode >= 200 && response.statusCode < 300;

    Object? decoded;
    try {
      decoded = response.body.isEmpty ? <dynamic>[] : jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (isSuccess) {
      if (decoded is List<dynamic>) return decoded;
      throw ApiException(
        'Expected a JSON array but got something else.',
        statusCode: response.statusCode,
      );
    }

    final String message = (decoded is Map<String, dynamic>)
        ? (decoded['detail']?.toString() ??
              _httpErrorFallback(response.statusCode))
        : _httpErrorFallback(response.statusCode);
    throw ApiException(message, statusCode: response.statusCode);
  }

  /// Human-readable fallback when the backend returns an error status with a
  /// body that is empty or not valid JSON (e.g. a gateway error page).
  String _httpErrorFallback(int statusCode) {
    if (statusCode >= 500) {
      return 'Server error (HTTP $statusCode). The record stays pending and '
          'will be retried automatically.';
    }
    if (statusCode == 401) return 'Session expired. Please sign in again.';
    if (statusCode == 403) return 'Access denied (HTTP 403).';
    if (statusCode == 404) return 'Not found (HTTP 404).';
    return 'Request failed (HTTP $statusCode).';
  }
}
