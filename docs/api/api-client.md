# HTTP Client — `ApiClient`

`lib/src/core/network/api_client.dart`

`ApiClient` is the centralized network layer. All repositories use it; no one calls `http.Client` directly.

## Configuration

```dart
final apiClient = ApiClient(baseUrl: AppEnv.apiBaseUrl);
```

`baseUrl` is read from the environment variable `API_BASE_URL` defined in `.env`.

## App version header

Every request carries `X-App-Version` with the build, for example `1.2.3+45 (android)` (`lib/src/core/network/app_version.dart`). The backend logs it on login and refresh, so the team can see which build each device runs before an NFC key rotation (security review N5).

Flutter does not expose `--build-name`/`--build-number` to Dart, so the build passes the version as a define. The release pipeline (`release.yml`) does it for every platform; a manual build must add it too, or it sends no header and the backend logs `app_version=none`:

```bash
flutter build apk --release --build-name=1.2.3 --build-number=45 \
  --dart-define=HWB_APP_VERSION=1.2.3+45 --dart-define=ENV_FILE=.env.production
```

The platform suffix (`android`, `ios`, `web`) is added by the app. A value outside `MAJOR.MINOR.PATCH[+BUILD]` sends no header.

## Available Methods

### `postForm` — URL-encoded forms

Used for login (OAuth2 form flow):

```dart
final data = await apiClient.postForm(
  path: '/api/v1/login/access-token',
  form: {'username': email, 'password': password},
);
```

### `postJson` — JSON body

Used to synchronize patients:

```dart
final data = await apiClient.postJson(
  path: '/api/v1/patients/sync',
  body: patientRecord.toJson(),
  headers: {'Authorization': 'Bearer $token'},
);
```

### `getJson` — GET with response object

```dart
final user = await apiClient.getJson(
  path: '/api/v1/users/me',
  headers: {'Authorization': 'Bearer $token'},
);
```

### `getJsonList` — GET with array response

```dart
final patients = await apiClient.getJsonList(
  path: '/api/v1/patients',
  headers: {'Authorization': 'Bearer $token'},
  queryParams: {'org_id': orgId},
);
```

## Error Handling

When the server responds with a code `>= 300`, `ApiClient` throws `ApiException`:

```dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;
}
```

The `detail` property of the backend JSON response is used as the error message when available.

**Example of handling in a repository:**

```dart
try {
  final data = await apiClient.postJson(...);
  return PatientSyncResponse.fromJson(data);
} on ApiException catch (e) {
  if (e.statusCode == 401) {
    // Expired token — redirect to login
  }
  rethrow;
}
```

## Timeout

All requests have a **20-second** timeout by default. After this time, `http.Client` throws a `TimeoutException` that repositories must catch.

`POST /api/v1/patients/sync` uses **90 seconds** (`PatientRepository.syncTimeout`): the server codes diagnoses with the LLM and writes to the FHIR Store inside the request (p95 25.6 s, up to 68 s in production). A timeout does not mean the record was not saved; the sync engine retries, which is safe, and the retry may come back with `stale_payload_base_version`.

## HTTP Client Injection (testing)

`ApiClient` accepts an optional `http.Client`. This allows a mock to be injected into tests:

```dart
final mockClient = MockClient((request) async {
  return http.Response('{"access_token": "fake"}', 200);
});

final apiClient = ApiClient(baseUrl: 'http://test', client: mockClient);
```