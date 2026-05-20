# HTTP Client — `ApiClient`

`lib/src/core/network/api_client.dart`

`ApiClient` is the centralized network layer. All repositories use it; no one calls `http.Client` directly.

## Configuration

```dart
final apiClient = ApiClient(baseUrl: AppEnv.apiBaseUrl);
```

`baseUrl` is read from the environment variable `API_BASE_URL` defined in `.env`.

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

All requests have a **20-second** timeout. After this time, `http.Client` throws a `TimeoutException` that repositories must catch.

## HTTP Client Injection (testing)

`ApiClient` accepts an optional `http.Client`. This allows a mock to be injected into tests:

```dart
final mockClient = MockClient((request) async {
  return http.Response('{"access_token": "fake"}', 200);
});

final apiClient = ApiClient(baseUrl: 'http://test', client: mockClient);
```