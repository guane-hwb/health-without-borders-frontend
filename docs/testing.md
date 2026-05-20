# Tests

## Run the complete suite

```bash
~/.pub-cache/bin/fvm flutter test
```

## Structure

```
test/
├── unit/
│   ├── login_unit_test.dart           # Authentication and parsing logic
│   ├── home_screen_test.dart          # Initial state of Home
│   └── porfile_tab_summary_test.dart  # Summary tab logic
└── widget/
    ├── login_widget_test.dart                   # Rendering the login form
    ├── home_screen_widget_test.dart             # Home widget tree
    └── porfile_tab_summary_widget_test.dart     # Summary tab rendering
```

## Unit tests (`test/unit/`)

These tests test pure business logic, without UI. They use repository mocks when necessary.

**Recommended pattern:**

```dart
void main() {
  group('AuthRepository', () {
    late AuthRepository repo;
    late MockApiClient mockClient;

    setUp(() {
      mockClient = MockApiClient();
      repo = AuthRepository(apiClient: mockClient);
    });

    test('login stores token on success', () async {
      when(mockClient.postForm(...)).thenAnswer(
        (_) async => {'access_token': 'fake-token'},
      );
      final session = await repo.login(email: 'a@b.com', password: 'pass');
      expect(session.email, 'a@b.com');
    });
  });
}
```

## Widget Tests (`test/widget/`)

The widget tree is tested using `WidgetTester`. `AppScope` with mocked dependencies is used.

**Recommended Pattern:**

```dart
void main() {
  testWidgets('LoginScreen muestra botón de ingreso', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen()),
    );
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
```

## Run a single file

```bash
~/.pub-cache/bin/fvm flutter test test/unit/login_unit_test.dart
```

## Add new tests

1. Place the file in `test/unit/` (logic) or `test/widget/` (UI).
2. Follow the same naming pattern: `<name>_test.dart`.
3. Verify that `flutter test` passes completely before opening the pull request.

!!! tip "NFC in tests"
    `NfcService` automatically exports the stub on non-mobile platforms via `dart.library.io`. The stub is always loaded in the test environment (`flutter_test`), so it's not necessary to mock the NFC hardware.