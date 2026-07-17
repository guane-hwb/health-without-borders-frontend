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

/// Renews access tokens on behalf of [ApiClient] without creating a dependency
/// cycle: [ApiClient] depends only on this narrow interface, while the concrete
/// implementation ([AuthRepository]) already depends on [ApiClient]. The
/// provider is injected after construction via [ApiClient.tokenProvider].
abstract class TokenProvider {
  /// Attempts to obtain a fresh access token using the stored refresh token.
  ///
  /// Returns the new access token on success, or `null` when the session is
  /// truly over (refresh token missing, expired, or revoked). On a transient
  /// failure (network / 5xx) it throws, so the caller keeps its work pending
  /// for a later retry instead of forcing a re-login.
  Future<String?> refreshAccessToken();
}

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  /// Routes that must NEVER carry a bearer token or trigger an auto-refresh.
  /// `/login/refresh` is listed here so a 401 from the refresh call itself is
  /// surfaced as-is instead of recursing into another refresh attempt.
  static const List<String> _publicRoutes = <String>[
    '/api/v1/login/access-token',
    '/api/v1/login/refresh',
  ];

  TokenProvider? _tokenProvider;

  /// Wires the component that can renew access tokens. Injected once at startup
  /// (see `app.dart`). When null, no auto-refresh happens and a 401 propagates
  /// unchanged — which keeps token-agnostic tests working as before.
  set tokenProvider(TokenProvider? provider) => _tokenProvider = provider;

  bool _isPublicRoute(String path) => _publicRoutes.contains(path);

  /// Central request dispatcher. Runs [send], and — for a protected route that
  /// comes back 401 while a [TokenProvider] is wired — renews the access token
  /// ONCE and replays the request with the fresh bearer. Every authenticated
  /// call routes through here, so the refresh-and-retry guarantee is structural
  /// rather than something each caller has to remember to opt into.
  Future<http.Response> _dispatch(
    String path, {
    required Map<String, String> headers,
    required Future<http.Response> Function(Map<String, String> headers) send,
  }) async {
    final http.Response response = await send(
      headers,
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 401 ||
        _tokenProvider == null ||
        _isPublicRoute(path)) {
      return response;
    }

    final String? newToken = await _tokenProvider!.refreshAccessToken();
    if (newToken == null || newToken.isEmpty) {
      // Refresh failed: session is genuinely over. Surface the original 401.
      return response;
    }

    final Map<String, String> retryHeaders = <String, String>{
      ...headers,
      'Authorization': 'Bearer $newToken',
    };
    return send(retryHeaders).timeout(const Duration(seconds: 20));
  }

  Future<Map<String, dynamic>> postForm({
    required String path,
    required Map<String, String> form,
    Map<String, String>? headers,
  }) async {
    final Uri uri = Uri.parse('$baseUrl$path');
    final http.Response response = await _dispatch(
      path,
      headers: <String, String>{...?headers},
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
  }) async {
    final Uri uri = Uri.parse('$baseUrl$path');
    final http.Response response = await _dispatch(
      path,
      headers: <String, String>{...?headers},
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
  }) async {
    final Uri uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: queryParams);
    final http.Response response = await _dispatch(
      path,
      headers: <String, String>{...?headers},
      send: (Map<String, String> h) => _client.get(uri, headers: h),
    );

    return _decodeMapOrThrow(response);
  }

  Future<List<dynamic>> getJsonList({
    required String path,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) async {
    final Uri uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: queryParams);
    final http.Response response = await _dispatch(
      path,
      headers: <String, String>{...?headers},
      send: (Map<String, String> h) => _client.get(uri, headers: h),
    );

    return _decodeListOrThrow(response);
  }

  Future<Map<String, dynamic>> patchJson({
    required String path,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final Uri uri = Uri.parse('$baseUrl$path');
    final http.Response response = await _dispatch(
      path,
      headers: <String, String>{...?headers},
      send: (Map<String, String> h) => _client.patch(
        uri,
        headers: <String, String>{'Content-Type': 'application/json', ...h},
        body: jsonEncode(body),
      ),
    );

    return _decodeMapOrThrow(response);
  }

  /// Sends a DELETE request. Succeeds on any 2xx (including a 204 with an empty
  /// body); throws [ApiException] carrying the backend `detail` on any error.
  Future<void> delete({
    required String path,
    Map<String, String>? headers,
  }) async {
    final Uri uri = Uri.parse('$baseUrl$path');
    final http.Response response = await _dispatch(
      path,
      headers: <String, String>{...?headers},
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
