# Arcade Test

Testing utilities for Arcade framework applications.

## Features

- **Test Server Management**: Easy setup/teardown of test servers with automatic port allocation
- **HTTP Testing**: Comprehensive HTTP testing utilities with request builders and response assertions
- **WebSocket Testing**: WebSocket client helpers and connection management
- **State Management**: Automatic cleanup of global Arcade state between tests
- **Custom Matchers**: Arcade-specific test matchers for common assertions

## Usage

```dart
import 'package:arcade_test/arcade_test.dart';
import 'package:my_app/init.dart'; // Your app's init function
import 'package:test/test.dart';

void main() {
  late ArcadeTestServer server;

  setUp(() async {
    server = await ArcadeTestServer.create(init);
  });

  tearDown(() => server.close());

  test('GET /api/users returns list', () async {
    final response = await server.get('/api/users');

    expect(response, hasStatus(200));
    expect(response.json(), isA<List>());
  });

  test('POST /api/users creates user', () async {
    final response = await server.post('/api/users',
      body: {'name': 'John Doe', 'email': 'john@example.com'},
    );

    expect(response, hasStatus(201));
    expect(response.json(), containsPair('name', 'John Doe'));
  });
}
```

## Installation

Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  arcade_test: ^<latest-version>
```

## API Reference

### ArcadeTestServer

Main class for testing Arcade applications.

#### Methods

- `ArcadeTestServer.create(Future<void> Function() init)`: Create a test server using your app's init function
- `get(String path, {Map<String, String>? headers})`: Make GET request
- `post(String path, {Object? body, Map<String, String>? headers})`: Make POST request
- `put(String path, {Object? body, Map<String, String>? headers})`: Make PUT request
- `delete(String path, {Map<String, String>? headers})`: Make DELETE request
- `connectWebSocket(String path)`: Connect to WebSocket endpoint
- `close()`: Close the test server and cleanup state

### TestResponse

Wrapper for HTTP responses with helper methods.

#### Methods

- `statusCode`: Get the HTTP status code
- `json()`: Parse response body as JSON
- `text()`: Get response body as text
- `headers`: Access response headers

### Custom Matchers

- `hasStatus(int code)`: Match HTTP status code
- `hasJsonBody(dynamic expected)`: Match JSON response body
- `hasTextBody(String expected)`: Match text response body
- `hasHeader(String name, String value)`: Match response header

## Contributing

See the main [Arcade repository](https://github.com/dartarcade/arcade) for contribution guidelines.
