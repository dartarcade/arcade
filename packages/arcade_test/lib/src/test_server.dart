// ignore_for_file: invalid_use_of_internal_member

import 'dart:async';
import 'dart:io';

import 'package:arcade/arcade.dart';
import 'package:arcade_config/arcade_config.dart';
import 'package:arcade_test/src/state_management.dart';
import 'package:arcade_test/src/test_client.dart';
import 'package:arcade_test/src/test_response.dart';
import 'package:arcade_test/src/test_websocket.dart';

/// Main test server class for testing Arcade applications.
///
/// This class provides a complete testing environment for Arcade applications
/// with automatic server lifecycle management, state isolation, and convenient
/// testing methods.
///
/// Example usage:
/// ```dart
/// late ArcadeTestServer server;
///
/// setUp(() async {
///   server = await ArcadeTestServer.create(init);
/// });
///
/// tearDown(() => server.close());
///
/// test('GET /api/users returns list', () async {
///   final response = await server.get('/api/users');
///   expect(response, hasStatus(200));
/// });
/// ```
class ArcadeTestServer {
  final HttpServer _server;
  final int port;
  late final ArcadeTestClient _client;

  ArcadeTestServer._(this._server, this.port) {
    _client = ArcadeTestClient('http://localhost:$port');
  }

  /// Creates a new test server using the provided init function.
  ///
  /// [init] - The initialization function that sets up routes and configuration.
  /// [logLevel] - Log level for the server (default: LogLevel.error to keep tests quiet).
  /// [host] - Host to bind the server to (default: InternetAddress.loopbackIPv4).
  ///
  /// This method:
  /// 1. Resets all global Arcade state to ensure clean test isolation
  /// 2. Finds an available port automatically
  /// 3. Uses Arcade's actual runServer implementation for true integration testing
  ///
  /// Throws [StateError] if the server fails to start.
  ///
  /// Example:
  /// ```dart
  /// final server = await ArcadeTestServer.create(() async {
  ///   route.get('/hello').handle((ctx) => {'message': 'Hello, World!'});
  /// });
  /// ```
  static Future<ArcadeTestServer> create(
    Future<void> Function() init, {
    LogLevel logLevel = LogLevel.error,
    InternetAddress? host,
    Directory? staticFilesDirectory,
  }) async {
    // Reset all global state before test
    ArcadeTestState.resetAll();

    // Override static files directory if provided
    if (staticFilesDirectory != null) {
      ArcadeConfiguration.override(staticFilesDirectory: staticFilesDirectory);
    }

    try {
      // Find an available port
      final port = await _findAvailablePort();

      // Use Arcade's actual runServer implementation
      await runServer(
        port: port,
        init: init,
        logLevel: logLevel,
      );

      // Get the server instance that was stored by runServer
      if (serverInstance == null) {
        throw StateError('Failed to get server instance from runServer');
      }

      return ArcadeTestServer._(serverInstance!, port);
    } catch (e) {
      // Clean up state if server creation fails
      ArcadeTestState.resetAll();
      throw StateError('Failed to create test server: $e');
    }
  }

  /// Creates a new test server with inline route definitions.
  ///
  /// This is a convenience method for testing specific routes without
  /// creating a separate init function.
  ///
  /// [routes] - Function that defines routes using the global route object.
  /// [logLevel] - Log level for the server (default: LogLevel.fatal).
  /// [host] - Host to bind the server to (default: InternetAddress.loopbackIPv4).
  ///
  /// Example:
  /// ```dart
  /// final server = await ArcadeTestServer.withRoutes(() {
  ///   route.get('/test').handle((ctx) => 'test response');
  ///   route.post('/echo').handle((ctx) => ctx.body.asJson());
  /// });
  /// ```
  static Future<ArcadeTestServer> withRoutes(
    void Function() routes, {
    LogLevel logLevel = LogLevel.error,
    InternetAddress? host,
    Directory? staticFilesDirectory,
  }) {
    return create(
      () async => routes(),
      logLevel: logLevel,
      host: host,
      staticFilesDirectory: staticFilesDirectory,
    );
  }

  /// The base URL of the test server.
  ///
  /// This includes the protocol, host, and port, e.g., `http://localhost:8080`.
  String get baseUrl => 'http://localhost:$port';

  /// The WebSocket base URL of the test server.
  ///
  /// This includes the protocol, host, and port, e.g., `ws://localhost:8080`.
  String get wsBaseUrl => 'ws://localhost:$port';

  // HTTP Methods

  /// Makes a GET request to the specified path.
  ///
  /// [path] should start with a slash, e.g., `/api/users`.
  /// Optional [headers] can be provided for the request.
  ///
  /// Returns a [TestResponse] with the server's response.
  Future<TestResponse> get(
    String path, {
    Map<String, String>? headers,
  }) {
    return _client.get(path, headers: headers);
  }

  /// Makes a POST request to the specified path.
  ///
  /// [path] should start with a slash, e.g., `/api/users`.
  /// [body] can be a Map (will be JSON encoded), String, or other object.
  /// Optional [headers] can be provided for the request.
  ///
  /// Returns a [TestResponse] with the server's response.
  Future<TestResponse> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) {
    return _client.post(path, body: body, headers: headers);
  }

  /// Makes a PUT request to the specified path.
  ///
  /// [path] should start with a slash, e.g., `/api/users/123`.
  /// [body] can be a Map (will be JSON encoded), String, or other object.
  /// Optional [headers] can be provided for the request.
  ///
  /// Returns a [TestResponse] with the server's response.
  Future<TestResponse> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) {
    return _client.put(path, body: body, headers: headers);
  }

  /// Makes a PATCH request to the specified path.
  ///
  /// [path] should start with a slash, e.g., `/api/users/123`.
  /// [body] can be a Map (will be JSON encoded), String, or other object.
  /// Optional [headers] can be provided for the request.
  ///
  /// Returns a [TestResponse] with the server's response.
  Future<TestResponse> patch(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) {
    return _client.patch(path, body: body, headers: headers);
  }

  /// Makes a DELETE request to the specified path.
  ///
  /// [path] should start with a slash, e.g., `/api/users/123`.
  /// Optional [headers] can be provided for the request.
  ///
  /// Returns a [TestResponse] with the server's response.
  Future<TestResponse> delete(
    String path, {
    Map<String, String>? headers,
  }) {
    return _client.delete(path, headers: headers);
  }

  /// Makes a HEAD request to the specified path.
  ///
  /// [path] should start with a slash, e.g., `/api/users/123`.
  /// Optional [headers] can be provided for the request.
  ///
  /// Returns a [TestResponse] with the server's response.
  Future<TestResponse> head(
    String path, {
    Map<String, String>? headers,
  }) {
    return _client.head(path, headers: headers);
  }

  /// Makes an OPTIONS request to the specified path.
  ///
  /// [path] should start with a slash, e.g., `/api/users`.
  /// Optional [headers] can be provided for the request.
  ///
  /// Returns a [TestResponse] with the server's response.
  Future<TestResponse> options(
    String path, {
    Map<String, String>? headers,
  }) {
    return _client.options(path, headers: headers);
  }

  // WebSocket Methods

  /// Connects to a WebSocket endpoint on the test server.
  ///
  /// [path] should start with a slash, e.g., `/ws`.
  ///
  /// Returns a [TestWebSocket] for interacting with the WebSocket connection.
  ///
  /// Example:
  /// ```dart
  /// final ws = await server.connectWebSocket('/ws');
  /// ws.send('ping', 'test data');
  /// final message = await ws.waitForMessage('pong');
  /// await ws.close();
  /// ```
  Future<TestWebSocket> connectWebSocket(String path) {
    return TestWebSocket.connect('$wsBaseUrl$path');
  }

  // Server Management

  /// Closes the test server and cleans up all resources.
  ///
  /// This method:
  /// 1. Closes the HTTP server
  /// 2. Closes the HTTP client
  /// 3. Resets all global Arcade state
  ///
  /// It's safe to call this method multiple times.
  ///
  /// Example:
  /// ```dart
  /// await server.close();
  /// ```
  Future<void> close() async {
    await _server.close();
    _client.close();
    ArcadeTestState.resetAll();
  }

  /// Gets the current port the server is running on.
  ///
  /// This is useful for debugging or when you need the port number
  /// for other purposes.
  int get serverPort => port;

  /// Gets a snapshot of the current Arcade state for debugging.
  ///
  /// This is useful for debugging test issues or ensuring
  /// state is properly isolated between tests.
  Map<String, dynamic> get stateSnapshot => ArcadeTestState.getStateSnapshot();

  /// Validates that the Arcade state is clean.
  ///
  /// Throws a [StateError] if any global state is not in its initial state.
  /// This can be useful to ensure tests are properly cleaning up after themselves.
  void validateCleanState() => ArcadeTestState.validateCleanState();

  // Private Methods

  /// Finds an available port for the test server.
  static Future<int> _findAvailablePort() async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    return port;
  }
}
