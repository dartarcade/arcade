---
title: Arcade Test
description: Testing utilities for Arcade framework applications
---

The `arcade_test` package provides comprehensive testing utilities for Arcade applications, enabling easy testing of HTTP endpoints, WebSocket connections, and stateful components. It integrates seamlessly with Dart's built-in test framework and offers a rich set of matchers for response validation.

## Installation

Add `arcade_test` to your `pubspec.yaml`:

```yaml
dev_dependencies:
  arcade_test: ^<latest-version>
  test: ^1.24.0
```

## Core Concepts

### ArcadeTestServer

The `ArcadeTestServer` class provides lifecycle management for test servers with automatic port allocation:

```dart
abstract class ArcadeTestServer {
  // Create server with route configuration
  static Future<ArcadeTestServer> withRoutes(Function() routeSetup);

  // HTTP client methods
  Future<TestResponse> get(String path);
  Future<TestResponse> post(String path, {Object? body});
  Future<TestResponse> put(String path, {Object? body});
  Future<TestResponse> patch(String path, {Object? body});
  Future<TestResponse> delete(String path);
  Future<TestResponse> head(String path);
  Future<TestResponse> options(String path);

  // WebSocket connection
  Future<TestWebSocket> webSocket(String path);

  // Server management
  Future<void> close();
  String get baseUrl;
}
```

### TestResponse

Response wrapper with convenient parsing and validation methods:

```dart
class TestResponse {
  final int statusCode;
  final String body;
  final Map<String, List<String>> headers;

  // Parse response body
  Map<String, dynamic> get jsonMap;
  List<dynamic> get jsonList;

  // Content type checking
  bool get isJson;
  bool get isHtml;
  bool get isText;
}
```

### HTTP Status Matchers

Complete coverage of all Arcade-supported HTTP status codes:

```dart
// Success responses
Matcher isOk();              // 200
Matcher isCreated();         // 201
Matcher isNoContent();       // 204

// Client error responses
Matcher isBadRequest();      // 400
Matcher isUnauthorized();    // 401
Matcher isForbidden();       // 403
Matcher isNotFound();        // 404
Matcher isMethodNotAllowed(); // 405
Matcher isConflict();        // 409
Matcher isImATeapot();       // 418
Matcher isUnprocessableEntity(); // 422

// Server error responses
Matcher isInternalServerError(); // 500
Matcher isServiceUnavailable();  // 503
```

## Quick Start

### Basic HTTP Testing

```dart
import 'package:arcade/arcade.dart';
import 'package:arcade_test/arcade_test.dart';
import 'package:test/test.dart';

void main() {
  group('API Tests', () {
    late ArcadeTestServer testServer;

    setUpAll(() async {
      testServer = await ArcadeTestServer.withRoutes(() {
        route.get('/users').handle((context) {
          return [
            {'id': 1, 'name': 'Alice'},
            {'id': 2, 'name': 'Bob'},
          ];
        });

        route.post('/users').handle((context) async {
          final userData = await context.jsonMap();
          return {'id': 3, ...userData};
        });

        route.get('/users/:id').handle((context) {
          final id = context.pathParameters['id'];
          return {'id': int.parse(id!), 'name': 'User $id'};
        });
      });
    });

    tearDownAll(() async {
      await testServer.close();
    });

    test('GET /users returns user list', () async {
      final response = await testServer.get('/users');

      expect(response, isOk());
      expect(response, isJson());
      expect(response, hasJsonBody(isA<List>()));
      expect(response, hasJsonPath('[0].name', 'Alice'));
    });

    test('POST /users creates new user', () async {
      final newUser = {'name': 'Charlie', 'email': 'charlie@example.com'};
      final response = await testServer.post('/users', body: newUser);

      expect(response, isOk());
      expect(response, containsJsonKey('id'));
      expect(response, hasJsonPath('name', 'Charlie'));
    });

    test('GET /users/:id returns specific user', () async {
      final response = await testServer.get('/users/42');

      expect(response, isOk());
      expect(response, hasJsonBody({'id': 42, 'name': 'User 42'}));
    });
  });
}
```

### Response Body Validation

```dart
test('response body matchers', () async {
  final server = await ArcadeTestServer.withRoutes(() {
    route.get('/json').handle((ctx) => {'message': 'Hello', 'count': 42});
    route.get('/text').handle((ctx) => 'Plain text response');
    route.get('/empty').handle((ctx) => '');
  });

  // JSON response testing
  final jsonResponse = await server.get('/json');
  expect(jsonResponse, hasJsonBody({'message': 'Hello', 'count': 42}));
  expect(jsonResponse, containsJsonKey('message'));
  expect(jsonResponse, hasJsonPath('message', 'Hello'));
  expect(jsonResponse, hasJsonPath('count', greaterThan(40)));

  // Text response testing
  final textResponse = await server.get('/text');
  expect(textResponse, hasTextBody('Plain text response'));
  expect(textResponse, hasTextBody(contains('Plain')));

  // Empty response testing
  final emptyResponse = await server.get('/empty');
  expect(emptyResponse, hasEmptyBody());

  await server.close();
});
```

### Header and Content Type Testing

```dart
test('header validation', () async {
  final server = await ArcadeTestServer.withRoutes(() {
    route.get('/api/data').handle((ctx) {
      ctx.responseHeaders.set('x-custom-header', 'custom-value');
      ctx.responseHeaders.contentType = ContentType.json;
      return {'data': 'response'};
    });
  });

  final response = await server.get('/api/data');

  expect(response, hasHeader('x-custom-header'));
  expect(response, hasHeader('x-custom-header', 'custom-value'));
  expect(response, hasContentType('application/json'));
  expect(response, isJson());

  await server.close();
});
```

### Error Response Testing

```dart
test('error handling', () async {
  final server = await ArcadeTestServer.withRoutes(() {
    route.get('/not-found').handle((ctx) {
      throw ArcadeHttpException.notFound('Resource not found');
    });

    route.post('/validation-error').handle((ctx) {
      throw ArcadeHttpException.unprocessableEntity('Invalid data');
    });

    route.get('/server-error').handle((ctx) {
      throw ArcadeHttpException.internalServerError('Something went wrong');
    });
  });

  // Test 404 errors
  final notFoundResponse = await server.get('/not-found');
  expect(notFoundResponse, isNotFound());
  expect(notFoundResponse, hasTextBody('Resource not found'));

  // Test validation errors
  final validationResponse = await server.post('/validation-error');
  expect(validationResponse, isUnprocessableEntity());

  // Test server errors
  final serverErrorResponse = await server.get('/server-error');
  expect(serverErrorResponse, isInternalServerError());

  await server.close();
});
```

## WebSocket Testing

### Basic WebSocket Testing

```dart
test('WebSocket communication', () async {
  final server = await ArcadeTestServer.withRoutes(() {
    route.webSocket('/ws').handle((webSocket) {
      webSocket.listen((message) {
        if (message == 'ping') {
          webSocket.add('pong');
        } else {
          webSocket.add('echo: $message');
        }
      });
    });
  });

  final ws = await server.webSocket('/ws');

  // Send and receive messages
  ws.add('ping');
  final pongMessage = await ws.stream.first;
  expect(pongMessage, hasData('pong'));

  ws.add('hello');
  final echoMessage = await ws.stream.first;
  expect(echoMessage, hasData('echo: hello'));

  await ws.close();
  await server.close();
});
```

### Advanced WebSocket Testing

```dart
test('WebSocket events and JSON messages', () async {
  final server = await ArcadeTestServer.withRoutes(() {
    route.webSocket('/events').handle((webSocket) {
      webSocket.listen((message) {
        final data = jsonDecode(message);
        if (data['event'] == 'subscribe') {
          webSocket.add(jsonEncode({
            'event': 'subscribed',
            'channel': data['channel'],
            'status': 'success'
          }));
        }
      });
    });
  });

  final ws = await server.webSocket('/events');

  // Send subscription request
  ws.add(jsonEncode({
    'event': 'subscribe',
    'channel': 'notifications'
  }));

  final response = await ws.stream.first;
  expect(response, hasEvent('subscribed'));
  expect(response, hasJsonData({'channel': 'notifications', 'status': 'success'}));

  await ws.close();
  await server.close();
});
```

## State Management Testing

### Test Isolation with ArcadeTestState

```dart
test('state management and isolation', () async {
  final server = await ArcadeTestServer.withRoutes(() {
    route.get('/state').handle((ctx) {
      final state = ArcadeTestState.instance;
      return {
        'connections': state.connectionCount,
        'requests': state.requestCount,
      };
    });

    route.post('/increment').handle((ctx) {
      final state = ArcadeTestState.instance;
      state.incrementRequestCount();
      return {'requests': state.requestCount};
    });
  });

  // Initial state
  final initialResponse = await server.get('/state');
  expect(initialResponse, hasJsonPath('connections', 0));
  expect(initialResponse, hasJsonPath('requests', 0));

  // Increment counter
  final incrementResponse = await server.post('/increment');
  expect(incrementResponse, hasJsonPath('requests', 1));

  // Verify state persists
  final finalResponse = await server.get('/state');
  expect(finalResponse, hasJsonPath('requests', 1));

  await server.close();
});
```

### Server Lifecycle and Cleanup

```dart
group('Server lifecycle', () {
  test('automatic port allocation', () async {
    final server1 = await ArcadeTestServer.withRoutes(() {
      route.get('/test').handle((ctx) => 'server1');
    });

    final server2 = await ArcadeTestServer.withRoutes(() {
      route.get('/test').handle((ctx) => 'server2');
    });

    // Each server gets unique port
    expect(server1.baseUrl, isNot(equals(server2.baseUrl)));

    final response1 = await server1.get('/test');
    final response2 = await server2.get('/test');

    expect(response1, hasTextBody('server1'));
    expect(response2, hasTextBody('server2'));

    await server1.close();
    await server2.close();
  });

  test('proper cleanup on server close', () async {
    final server = await ArcadeTestServer.withRoutes(() {
      route.get('/test').handle((ctx) => 'ok');
    });

    final response = await server.get('/test');
    expect(response, isOk());

    await server.close();

    // Server should no longer be accessible
    // (In real tests, you might verify this differently)
  });
});
```

## Advanced Usage

### Custom Matchers

```dart
// Create custom matchers for your domain
Matcher hasUserStructure() {
  return allOf([
    containsJsonKey('id'),
    containsJsonKey('name'),
    containsJsonKey('email'),
    hasJsonPath('id', isA<int>()),
    hasJsonPath('email', contains('@')),
  ]);
}

test('custom matcher usage', () async {
  final server = await ArcadeTestServer.withRoutes(() {
    route.get('/user').handle((ctx) => {
      'id': 1,
      'name': 'John Doe',
      'email': 'john@example.com'
    });
  });

  final response = await server.get('/user');
  expect(response, hasJsonBody(hasUserStructure()));

  await server.close();
});
```

### Testing Middleware and Hooks

```dart
test('middleware integration', () async {
  final server = await ArcadeTestServer.withRoutes(() {
    // Add before hook
    route.before((ctx) {
      ctx.responseHeaders.set('x-middleware', 'processed');
      return ctx;
    });

    route.get('/protected').handle((ctx) {
      return {'message': 'Protected resource'};
    });
  });

  final response = await server.get('/protected');

  expect(response, isOk());
  expect(response, hasHeader('x-middleware', 'processed'));
  expect(response, hasJsonPath('message', 'Protected resource'));

  await server.close();
});
```

### Performance Testing

```dart
test('concurrent request handling', () async {
  final server = await ArcadeTestServer.withRoutes(() {
    route.get('/slow').handle((ctx) async {
      await Future.delayed(Duration(milliseconds: 100));
      return {'processed': DateTime.now().millisecondsSinceEpoch};
    });
  });

  // Send multiple concurrent requests
  final futures = List.generate(10, (i) => server.get('/slow'));
  final responses = await Future.wait(futures);

  // All requests should succeed
  for (final response in responses) {
    expect(response, isOk());
    expect(response, containsJsonKey('processed'));
  }

  await server.close();
});
```

## Integration with Arcade Features

### Testing with Dependency Injection

```dart
test('dependency injection in tests', () async {
  final server = await ArcadeTestServer.withRoutes(() {
    // Mock service for testing
    final mockUserService = MockUserService();

    route.get('/users/:id').handle((ctx) {
      final id = ctx.pathParameters['id']!;
      final user = mockUserService.getUser(int.parse(id));
      return user.toJson();
    });
  });

  final response = await server.get('/users/123');
  expect(response, isOk());
  expect(response, hasJsonPath('id', 123));

  await server.close();
});
```

### Testing File Uploads

```dart
test('file upload handling', () async {
  final server = await ArcadeTestServer.withRoutes(() {
    route.post('/upload').handle((ctx) async {
      final body = await ctx.body();
      return {
        'received': body.length,
        'contentType': ctx.request.headers.contentType?.toString(),
      };
    });
  });

  final response = await server.post('/upload', body: 'file content data');

  expect(response, isOk());
  expect(response, hasJsonPath('received', greaterThan(0)));

  await server.close();
});
```

## Available Matchers Reference

### Status Code Matchers

```dart
// 2xx Success
hasStatus(int code)     // Generic status code matcher
isOk()                  // 200 OK
isCreated()             // 201 Created
isNoContent()           // 204 No Content

// 4xx Client Errors
isBadRequest()          // 400 Bad Request
isUnauthorized()        // 401 Unauthorized
isForbidden()           // 403 Forbidden
isNotFound()            // 404 Not Found
isMethodNotAllowed()    // 405 Method Not Allowed
isConflict()            // 409 Conflict
isImATeapot()           // 418 I'm a teapot
isUnprocessableEntity() // 422 Unprocessable Entity

// 5xx Server Errors
isInternalServerError() // 500 Internal Server Error
isServiceUnavailable()  // 503 Service Unavailable
```

### Body Content Matchers

```dart
hasJsonBody(dynamic expected)           // Exact JSON match
hasTextBody(String expected)            // Exact text match
hasEmptyBody()                         // Empty response body
containsJsonKey(String key)            // JSON object contains key
hasJsonPath(String path, dynamic value) // JSON path-based matching
```

### Header Matchers

```dart
hasHeader(String name)                 // Header exists
hasHeader(String name, String value)   // Header with specific value
hasContentType(String contentType)     // Content-Type header
isJson()                              // Content-Type: application/json
isHtml()                              // Content-Type: text/html
isText()                              // Content-Type: text/plain
```

### WebSocket Matchers

```dart
hasData(String expected)               // WebSocket message data
hasEvent(String event)                 // Event-based message
hasJsonData(dynamic expected)          // JSON message content
```

## Best Practices

1. **Use `setUpAll` and `tearDownAll`**: Create and close test servers once per test group
2. **Isolate Test State**: Use `ArcadeTestState` for test-specific state management
3. **Test Edge Cases**: Include tests for error conditions and edge cases
4. **Use Descriptive Matchers**: Prefer specific matchers like `isNotFound()` over `hasStatus(404)`
5. **Test Headers and Content Types**: Verify complete response structure
6. **Mock External Dependencies**: Use dependency injection for testable code
7. **Test WebSocket Lifecycle**: Include connection, message exchange, and disconnection tests
8. **Verify Cleanup**: Ensure proper resource cleanup in tearDown methods

## Performance Considerations

### Memory Management

- Test servers automatically allocate ports and clean up resources
- Close WebSocket connections and servers in tearDown methods
- Use `setUpAll`/`tearDownAll` for expensive setup operations

### Test Execution Speed

- Group related tests to share server setup
- Use lightweight response validation
- Avoid unnecessary delays in test routes

## Next Steps

- Learn about [Basic Routing](/guides/basic-routing/) for route setup patterns
- Explore [WebSocket integration](/guides/websockets/) for real-time features
- See [Error Handling](/core/error-handling/) for exception testing strategies
- Check out [Request Context](/core/request-context/) for advanced request handling
