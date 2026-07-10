// lib/src/features/admin/data/stats_repository.dart

import 'dart:async';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/brigade_stats.dart';

/// The statistics endpoint could not be reached.
///
/// Distinct from [ApiException], which means the server answered and said no.
/// This one means nobody answered: no network, DNS failure, or a timeout.
///
/// Raised here rather than letting `SocketException` escape, because the
/// presentation layer must not import `dart:io` — this app also builds for web,
/// where that library does not exist.
class StatsUnavailableException implements Exception {
  StatsUnavailableException(this.cause);

  final Object cause;

  @override
  String toString() => 'StatsUnavailableException($cause)';
}

/// Reads the aggregated statistics endpoint.
///
/// Scope is decided by the backend from the caller's role: a superadmin may
/// pass [organizationId] to narrow to one organization, or omit it for the
/// system-wide aggregate. An org_admin is always pinned to their own
/// organization and any [organizationId] is ignored. Clinical roles receive a
/// 403, so this repository is unreachable from a doctor or nurse session.
///
/// This endpoint is online-only. Unlike patient records, statistics are not
/// part of the offline-first path: callers must handle
/// [StatsUnavailableException] by telling the user, never by falling back to
/// stale or invented figures.
class StatsRepository {
  StatsRepository({
    required ApiClient apiClient,
    required AuthRepository authRepository,
  }) : _apiClient = apiClient,
       _authRepository = authRepository;

  final ApiClient _apiClient;
  final AuthRepository _authRepository;

  Future<Map<String, String>> _authHeaders() async {
    final String token = await _authRepository.getAccessToken();
    return <String, String>{'Authorization': 'Bearer $token'};
  }

  /// `yyyy-MM-dd`, which is what the backend's `date` query params expect.
  /// Written out rather than pulled from `intl`, which this project does not
  /// depend on.
  static String formatDate(DateTime d) {
    final String month = d.month.toString().padLeft(2, '0');
    final String day = d.day.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-$month-$day';
  }

  // ── GET /api/v1/stats/overview ──────────────────────────────────────────
  //
  // [dateFrom] and [dateTo] are inclusive. Supplying [dateFrom] switches the
  // backend's trend from "month-to-date vs. last month" to "this window vs.
  // the preceding window of equal length". No screen passes them yet; the
  // parameters exist so a date-range picker lands without touching this layer.

  Future<BrigadeStats> fetchOverview({
    String? organizationId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final Map<String, String> query = <String, String>{
      // Null-aware element: the entry is dropped when the value is null.
      // The date entries keep the collection-if because their value is a call,
      // not the nullable variable itself.
      'organization_id': ?organizationId,
      if (dateFrom != null) 'date_from': formatDate(dateFrom),
      if (dateTo != null) 'date_to': formatDate(dateTo),
    };

    try {
      final Map<String, dynamic> data = await _apiClient.getJson(
        path: '/api/v1/stats/overview',
        headers: await _authHeaders(),
        queryParams: query.isEmpty ? null : query,
      );
      return BrigadeStats.fromJson(data);
    } on http.ClientException catch (e) {
      // package:http wraps a SocketException into a ClientException on IO and
      // raises one directly on web, so this single catch covers both targets.
      throw StatsUnavailableException(e);
    } on TimeoutException catch (e) {
      throw StatsUnavailableException(e);
    }
  }
}
