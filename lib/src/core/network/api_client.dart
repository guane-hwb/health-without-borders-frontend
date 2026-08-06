// lib/src/core/network/api_client.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
}

abstract class TokenProvider {
  Future<String?> refreshAccessToken();
}

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client() {
    if (kReleaseMode && baseUrl.startsWith('http://')) {
      throw ArgumentError(
        'In release mode, baseUrl must use HTTPS to prevent cleartext traffic.',
      );
    }
  }

  final String baseUrl;
  final http.Client _client;

  static const List<String> _publicRoutes = <String>[
    '/api/v1/login/access-token',
    '/api/v1/login/refresh',
  ];

  TokenProvider? _tokenProvider;

  set tokenProvider(TokenProvider? provider) => _tokenProvider = provider;

  bool _isPublicRoute(String path) => _publicRoutes.contains(path);

  Future<http.Response> _dispatch(
    String path, {
    required Map<String, String> headers,
    required Future<http.Response> Function(Map<String, String> headers) send,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final http.Response response = await send(headers).timeout(timeout);

    if (response.statusCode >= 300 && response.statusCode < 400) {
      throw ApiException(
        'Untrusted redirect (HTTP ${response.statusCode}). '
        'The current network is intercepting requests.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode != 401 ||
        _tokenProvider == null ||
        _isPublicRoute(path)) {
      return response;
    }

    final String? newToken = await _tokenProvider!.refreshAccessToken();
    if (newToken == null || newToken.isEmpty) {
      return response;
    }

    final Map<String, String> retryHeaders = <String, String>{
      ...headers,
      'Authorization': 'Bearer $newToken',
    };
    return send(retryHeaders).timeout(timeout);
  }

  Future<Map<String, dynamic>> postForm({
    required String path,
    required Map<String, String> form,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final Uri uri = Uri.parse('$baseUrl$path');
    final http.Response response = await _dispatch(
      path,
      headers: <String, String>{...?headers},
      timeout: timeout,
      send: (Map<String, String> h) => _client.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
          ...h,
        },
        body: form,
      ),
    );

    return _decodeMapOrThrow(response);
  }

  Future<Map<String, dynamic>> postJson({
    required String path,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final Uri uri = Uri.parse('$baseUrl$path');
    final http.Response response = await _dispatch(
      path,
      headers: <String, String>{...?headers},
      timeout: timeout,
      send: (Map<String, String> h) => _client.post(
        uri,
        headers: <String, String>{'Content-Type': 'application/json', ...h},
        body: jsonEncode(body),
      ),
    );

    return _decodeMapOrThrow(response);
  }

  Future<Map<String, dynamic>> getJson({
    required String path,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final Uri uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: queryParams);
    final http.Response response = await _dispatch(
      path,
      headers: <String, String>{...?headers},
      timeout: timeout,
      send: (Map<String, String> h) => _client.get(uri, headers: h),
    );

    return _decodeMapOrThrow(response);
  }

  Future<List<dynamic>> getJsonList({
    required String path,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final Uri uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: queryParams);
    final http.Response response = await _dispatch(
      path,
      headers: <String, String>{...?headers},
      timeout: timeout,
      send: (Map<String, String> h) => _client.get(uri, headers: h),
    );

    return _decodeListOrThrow(response);
  }

  Future<Map<String, dynamic>> patchJson({
    required String path,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final Uri uri = Uri.parse('$baseUrl$path');
    final http.Response response = await _dispatch(
      path,
      headers: <String, String>{...?headers},
      timeout: timeout,
      send: (Map<String, String> h) => _client.patch(
        uri,
        headers: <String, String>{'Content-Type': 'application/json', ...h},
        body: jsonEncode(body),
      ),
    );

    return _decodeMapOrThrow(response);
  }

  Future<void> delete({
    required String path,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final Uri uri = Uri.parse('$baseUrl$path');
    final http.Response response = await _dispatch(
      path,
      headers: <String, String>{...?headers},
      timeout: timeout,
      send: (Map<String, String> h) => _client.delete(uri, headers: h),
    );

    final bool isSuccess =
        response.statusCode >= 200 && response.statusCode < 300;
    if (isSuccess) return;

    Object? decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }
    final String message = (decoded is Map<String, dynamic>)
        ? (decoded['detail']?.toString() ??
              _httpErrorFallback(response.statusCode))
        : _httpErrorFallback(response.statusCode);
    throw ApiException(message, statusCode: response.statusCode);
  }

  Map<String, dynamic> _decodeMapOrThrow(http.Response response) {
    final bool isSuccess =
        response.statusCode >= 200 && response.statusCode < 300;

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

  String _httpErrorFallback(int statusCode) {
    if (statusCode >= 500) {
      return 'Server error (HTTP $statusCode). Please try again later.';
    }
    if (statusCode == 401) return 'Session expired. Please sign in again.';
    if (statusCode == 403) return 'Access denied (HTTP 403).';
    if (statusCode == 404) return 'Not found (HTTP 404).';
    return 'Request failed (HTTP $statusCode).';
  }
}
