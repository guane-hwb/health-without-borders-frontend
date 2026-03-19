import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
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

    return _decodeOrThrow(response);
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

    return _decodeOrThrow(response);
  }

  Map<String, dynamic> _decodeOrThrow(http.Response response) {
    final Object? decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw ApiException(
        'Unexpected response payload format.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final String message =
        decoded['detail']?.toString() ?? 'Request failed with backend.';
    throw ApiException(message, statusCode: response.statusCode);
  }
}
