// lib/src/core/network/reachability.dart

import 'package:http/http.dart' as http;
import '../utils/app_logger.dart';

class Reachability {
  Reachability({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  static const Duration probeTimeout = Duration(seconds: 4);

  Future<bool> probe() async {
    try {
      final http.Response response = await _client
          .get(Uri.parse('$baseUrl/health-check'))
          .timeout(probeTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }
      final String contentType = response.headers['content-type'] ?? '';
      return contentType.contains('application/json');
    } catch (e) {
      AppLogger.d('Sonda de alcanzabilidad fallida: $e');
      return false;
    }
  }
}
