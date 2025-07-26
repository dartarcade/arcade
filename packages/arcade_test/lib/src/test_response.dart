import 'dart:convert';
import 'dart:io';

/// Wrapper around HTTP response with convenient testing methods.
///
/// This class provides easy access to response data and common
/// testing operations like parsing JSON and accessing headers.
class TestResponse {
  final HttpClientResponse _response;
  final String _body;
  final List<int> _bodyBytes;

  TestResponse._(this._response, this._body, this._bodyBytes);

  /// Creates a TestResponse from an HttpClientResponse.
  ///
  /// This method reads the response body and creates a TestResponse wrapper.
  static Future<TestResponse> fromResponse(HttpClientResponse response) async {
    final bodyBytes = await response.fold<List<int>>(
      <int>[],
      (previous, element) => previous..addAll(element),
    );
    // Try to decode as UTF-8, but if it fails (e.g., binary data), use empty string
    String body;
    try {
      body = utf8.decode(bodyBytes);
    } catch (_) {
      body = '';
    }
    return TestResponse._(response, body, bodyBytes);
  }

  /// The HTTP status code of the response.
  int get statusCode => _response.statusCode;

  /// The response headers.
  HttpHeaders get headers => _response.headers;

  /// The raw response body as a string.
  String get body => _body;

  /// The raw response body as bytes.
  List<int> get bodyBytes => _bodyBytes;

  /// The content length of the response.
  int get contentLength => _response.contentLength;

  /// Parses the response body as JSON.
  ///
  /// Returns the parsed JSON object. Throws if the body is not valid JSON.
  ///
  /// Example:
  /// ```dart
  /// final response = await server.get('/api/user');
  /// final userData = response.json();
  /// expect(userData['name'], equals('John Doe'));
  /// ```
  dynamic json() {
    try {
      return jsonDecode(_body);
    } catch (e) {
      throw FormatException('Response body is not valid JSON: $_body', _body);
    }
  }

  /// Returns the response body as text.
  ///
  /// This is equivalent to accessing the [body] property directly.
  String text() => _body;

  /// Gets a header value by name.
  ///
  /// Returns the first value of the header with the given name,
  /// or null if the header is not present.
  ///
  /// Example:
  /// ```dart
  /// final contentType = response.header('content-type');
  /// expect(contentType, contains('application/json'));
  /// ```
  String? header(String name) {
    return headers.value(name);
  }

  /// Gets all values for a header name.
  ///
  /// Returns a list of all values for the header with the given name,
  /// or an empty list if the header is not present.
  List<String> headerValues(String name) {
    return headers[name] ?? [];
  }

  /// Checks if the response has a specific header.
  ///
  /// Returns true if the response contains a header with the given name.
  bool hasHeader(String name) {
    return headers[name] != null;
  }

  /// Returns the content type of the response.
  ///
  /// Returns null if no content type is specified.
  ContentType? get contentType => headers.contentType;

  /// Checks if the response is JSON.
  ///
  /// Returns true if the content type indicates JSON data.
  bool get isJson {
    final ct = contentType;
    return ct != null &&
        (ct.mimeType == 'application/json' || ct.mimeType.endsWith('+json'));
  }

  /// Checks if the response is HTML.
  ///
  /// Returns true if the content type indicates HTML data.
  bool get isHtml {
    final ct = contentType;
    return ct != null && ct.mimeType == 'text/html';
  }

  /// Checks if the response is plain text.
  ///
  /// Returns true if the content type indicates plain text.
  bool get isText {
    final ct = contentType;
    return ct != null && ct.mimeType == 'text/plain';
  }

  /// Returns a string representation of the response for debugging.
  @override
  String toString() {
    return 'TestResponse(statusCode: $statusCode, '
        'contentType: ${contentType?.mimeType}, '
        'bodyLength: ${_bodyBytes.length})';
  }
}
