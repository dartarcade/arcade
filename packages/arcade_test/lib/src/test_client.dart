import 'dart:convert';
import 'dart:io';

import 'package:arcade_test/src/test_response.dart';

/// HTTP client for making test requests to an Arcade test server.
///
/// This class provides convenient methods for making HTTP requests
/// with automatic JSON encoding and custom headers support.
class ArcadeTestClient {
  final String baseUrl;
  final HttpClient _client;

  /// Creates a new test client for the given base URL.
  ///
  /// The [baseUrl] should include the protocol and port, e.g.:
  /// `http://localhost:8080`
  ArcadeTestClient(this.baseUrl) : _client = HttpClient();

  /// Makes a GET request to the specified path.
  ///
  /// [path] should start with a slash, e.g., `/api/users`.
  /// Optional [headers] can be provided for the request.
  ///
  /// Example:
  /// ```dart
  /// final response = await client.get('/api/users',
  ///   headers: {'Authorization': 'Bearer token'});
  /// ```
  Future<TestResponse> get(String path, {Map<String, String>? headers}) {
    return _makeRequest('GET', path, headers: headers);
  }

  /// Makes a POST request to the specified path.
  ///
  /// [path] should start with a slash, e.g., `/api/users`.
  /// [body] can be a Map (will be JSON encoded), String, or other object.
  /// Optional [headers] can be provided for the request.
  ///
  /// Example:
  /// ```dart
  /// final response = await client.post('/api/users',
  ///   body: {'name': 'John', 'email': 'john@example.com'});
  /// ```
  Future<TestResponse> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) {
    return _makeRequest('POST', path, body: body, headers: headers);
  }

  /// Makes a PUT request to the specified path.
  ///
  /// [path] should start with a slash, e.g., `/api/users/123`.
  /// [body] can be a Map (will be JSON encoded), String, or other object.
  /// Optional [headers] can be provided for the request.
  ///
  /// Example:
  /// ```dart
  /// final response = await client.put('/api/users/123',
  ///   body: {'name': 'John Updated'});
  /// ```
  Future<TestResponse> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) {
    return _makeRequest('PUT', path, body: body, headers: headers);
  }

  /// Makes a PATCH request to the specified path.
  ///
  /// [path] should start with a slash, e.g., `/api/users/123`.
  /// [body] can be a Map (will be JSON encoded), String, or other object.
  /// Optional [headers] can be provided for the request.
  ///
  /// Example:
  /// ```dart
  /// final response = await client.patch('/api/users/123',
  ///   body: {'email': 'newemail@example.com'});
  /// ```
  Future<TestResponse> patch(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) {
    return _makeRequest('PATCH', path, body: body, headers: headers);
  }

  /// Makes a DELETE request to the specified path.
  ///
  /// [path] should start with a slash, e.g., `/api/users/123`.
  /// Optional [headers] can be provided for the request.
  ///
  /// Example:
  /// ```dart
  /// final response = await client.delete('/api/users/123');
  /// ```
  Future<TestResponse> delete(String path, {Map<String, String>? headers}) {
    return _makeRequest('DELETE', path, headers: headers);
  }

  /// Makes a HEAD request to the specified path.
  ///
  /// [path] should start with a slash, e.g., `/api/users/123`.
  /// Optional [headers] can be provided for the request.
  ///
  /// Example:
  /// ```dart
  /// final response = await client.head('/api/users/123');
  /// expect(response.statusCode, equals(200));
  /// ```
  Future<TestResponse> head(String path, {Map<String, String>? headers}) {
    return _makeRequest('HEAD', path, headers: headers);
  }

  /// Makes an OPTIONS request to the specified path.
  ///
  /// [path] should start with a slash, e.g., `/api/users`.
  /// Optional [headers] can be provided for the request.
  ///
  /// Example:
  /// ```dart
  /// final response = await client.options('/api/users');
  /// final allowedMethods = response.header('Allow');
  /// ```
  Future<TestResponse> options(String path, {Map<String, String>? headers}) {
    return _makeRequest('OPTIONS', path, headers: headers);
  }

  /// Internal method to make HTTP requests.
  Future<TestResponse> _makeRequest(
    String method,
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    // Ensure proper URL joining
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$cleanBaseUrl$cleanPath');
    final request = await _client.openUrl(method, uri);

    // Set headers
    if (headers != null) {
      for (final entry in headers.entries) {
        request.headers.add(entry.key, entry.value);
      }
    }

    // Handle body
    if (body != null) {
      String bodyString;
      if (body is String) {
        bodyString = body;
        // Set content type if not already set
        if (request.headers.value('content-type') == null) {
          request.headers.contentType = ContentType.text;
        }
      } else if (body is Map || body is List) {
        bodyString = jsonEncode(body);
        request.headers.contentType = ContentType.json;
      } else {
        bodyString = body.toString();
        if (request.headers.value('content-type') == null) {
          request.headers.contentType = ContentType.text;
        }
      }

      request.write(bodyString);
    }

    final response = await request.close();
    return TestResponse.fromResponse(response);
  }

  /// Closes the HTTP client and releases resources.
  ///
  /// This should be called when the client is no longer needed.
  void close() {
    _client.close();
  }
}
