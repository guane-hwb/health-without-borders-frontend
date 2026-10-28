// lib/src/core/network/app_version.dart

import 'package:flutter/foundation.dart';

/// The build this app reports to the backend in `X-App-Version`, for example
/// `1.2.3+45 (android)`. The backend logs it on login and refresh, so the
/// team can see which build each device runs before an NFC key rotation
/// (security review N5).
///
/// Flutter does not expose `--build-name`/`--build-number` to Dart, so the
/// release pipeline passes them as `--dart-define=HWB_APP_VERSION=1.2.3+45`.
/// A build without it sends no header (the backend logs `none`).
const String appVersionHeaderName = 'X-App-Version';

const String _buildVersion = String.fromEnvironment('HWB_APP_VERSION');

final RegExp _format = RegExp(r'^\d{1,4}\.\d{1,4}\.\d{1,4}(\+\d{1,9})?$');

/// The header value, or null when the build carries no valid version.
String? appVersionHeaderValue({
  String version = _buildVersion,
  bool isWeb = kIsWeb,
  TargetPlatform? platform,
}) {
  final String trimmed = version.trim();
  if (!_format.hasMatch(trimmed)) return null;
  final String? name = isWeb
      ? 'web'
      : switch (platform ?? defaultTargetPlatform) {
          TargetPlatform.android => 'android',
          TargetPlatform.iOS => 'ios',
          _ => null,
        };
  return name == null ? trimmed : '$trimmed ($name)';
}
