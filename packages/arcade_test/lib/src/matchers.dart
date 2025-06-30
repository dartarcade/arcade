import 'dart:convert';
import 'dart:io';

import 'package:arcade_test/src/test_response.dart';
import 'package:arcade_test/src/test_websocket.dart';
import 'package:test/test.dart';

/// Custom test matchers for Arcade HTTP responses and WebSocket messages.
///
/// This library provides a comprehensive set of matchers for testing HTTP
/// responses and WebSocket communications in Arcade applications.
///
/// ## Response Status Matchers
///
/// Test HTTP status codes with clear, readable assertions:
/// ```dart
/// expect(response, hasStatus(200));
/// expect(response, isOk());
/// expect(response, isCreated());
/// expect(response, isNotFound());
/// expect(response, isServerError());
/// ```
///
/// ## Response Body Matchers
///
/// Validate response body content in various formats:
/// ```dart
/// expect(response, hasJsonBody({'name': 'John', 'age': 30}));
/// expect(response, hasTextBody('Hello, World!'));
/// expect(response, hasEmptyBody());
/// expect(response, containsJsonKey('user_id'));
/// expect(response, hasJsonPath('user.profile.name', 'John'));
/// ```
///
/// ## Response Header Matchers
///
/// Check response headers and content types:
/// ```dart
/// expect(response, hasHeader('authorization'));
/// expect(response, hasHeader('content-type', 'application/json'));
/// expect(response, hasContentType('application/json'));
/// expect(response, isJson());
/// expect(response, isHtml());
/// ```
///
/// ## WebSocket Message Matchers
///
/// Test WebSocket message content and structure:
/// ```dart
/// expect(message, hasEvent('pong'));
/// expect(message, hasMessageData({'result': 'success'}));
/// ```

// =============================================================================
// Response Status Matchers
// =============================================================================

/// Matches an HTTP response with the specified status code.
///
/// Example:
/// ```dart
/// expect(response, hasStatus(200));
/// expect(response, hasStatus(404));
/// ```
Matcher hasStatus(int expectedStatus) => _HasStatusMatcher(expectedStatus);

/// Matches an HTTP response with status code 200 (OK).
///
/// Example:
/// ```dart
/// expect(response, isOk());
/// ```
Matcher isOk() => hasStatus(200);

/// Matches an HTTP response with status code 201 (Created).
///
/// Example:
/// ```dart
/// expect(response, isCreated());
/// ```
Matcher isCreated() => hasStatus(201);

/// Matches an HTTP response with status code 404 (Not Found).
///
/// Example:
/// ```dart
/// expect(response, isNotFound());
/// ```
Matcher isNotFound() => hasStatus(404);

/// Matches an HTTP response with a 5xx server error status code.
///
/// This matcher accepts any status code from 500-599.
///
/// Example:
/// ```dart
/// expect(response, isServerError());
/// ```
Matcher isServerError() => _IsServerErrorMatcher();

/// Matches an HTTP response with status code 204 (No Content).
///
/// This is typically returned for successful requests with empty responses.
///
/// Example:
/// ```dart
/// expect(response, isNoContent());
/// ```
Matcher isNoContent() => hasStatus(204);

/// Matches an HTTP response with status code 400 (Bad Request).
///
/// This corresponds to Arcade's [BadRequestException].
///
/// Example:
/// ```dart
/// expect(response, isBadRequest());
/// ```
Matcher isBadRequest() => hasStatus(400);

/// Matches an HTTP response with status code 401 (Unauthorized).
///
/// This corresponds to Arcade's [UnauthorizedException].
///
/// Example:
/// ```dart
/// expect(response, isUnauthorized());
/// ```
Matcher isUnauthorized() => hasStatus(401);

/// Matches an HTTP response with status code 403 (Forbidden).
///
/// This corresponds to Arcade's [ForbiddenException].
///
/// Example:
/// ```dart
/// expect(response, isForbidden());
/// ```
Matcher isForbidden() => hasStatus(403);

/// Matches an HTTP response with status code 405 (Method Not Allowed).
///
/// This corresponds to Arcade's [MethodNotAllowedException].
///
/// Example:
/// ```dart
/// expect(response, isMethodNotAllowed());
/// ```
Matcher isMethodNotAllowed() => hasStatus(405);

/// Matches an HTTP response with status code 409 (Conflict).
///
/// This corresponds to Arcade's [ConflictException].
///
/// Example:
/// ```dart
/// expect(response, isConflict());
/// ```
Matcher isConflict() => hasStatus(409);

/// Matches an HTTP response with status code 418 (I'm a teapot).
///
/// This corresponds to Arcade's [ImATeapotException].
///
/// Example:
/// ```dart
/// expect(response, isImATeapot());
/// ```
Matcher isImATeapot() => hasStatus(418);

/// Matches an HTTP response with status code 422 (Unprocessable Entity).
///
/// This corresponds to Arcade's [UnprocessableEntityException].
///
/// Example:
/// ```dart
/// expect(response, isUnprocessableEntity());
/// ```
Matcher isUnprocessableEntity() => hasStatus(422);

/// Matches an HTTP response with status code 500 (Internal Server Error).
///
/// This corresponds to Arcade's [InternalServerErrorException].
///
/// Example:
/// ```dart
/// expect(response, isInternalServerError());
/// ```
Matcher isInternalServerError() => hasStatus(500);

/// Matches an HTTP response with status code 503 (Service Unavailable).
///
/// This corresponds to Arcade's [ServiceUnavailableException].
///
/// Example:
/// ```dart
/// expect(response, isServiceUnavailable());
/// ```
Matcher isServiceUnavailable() => hasStatus(503);

// =============================================================================
// Response Body Matchers
// =============================================================================

/// Matches an HTTP response with the specified JSON body.
///
/// The matcher performs deep comparison of the JSON structure.
/// Use [equals] for exact matching or other matchers for partial matching.
///
/// Examples:
/// ```dart
/// // Exact JSON matching
/// expect(response, hasJsonBody({'name': 'John', 'age': 30}));
///
/// // Partial matching with other matchers
/// expect(response, hasJsonBody(containsPair('name', 'John')));
/// ```
Matcher hasJsonBody(dynamic expected) => _HasJsonBodyMatcher(expected);

/// Matches an HTTP response with the specified text body.
///
/// Example:
/// ```dart
/// expect(response, hasTextBody('Hello, World!'));
/// expect(response, hasTextBody(startsWith('Welcome')));
/// ```
Matcher hasTextBody(dynamic expected) => _HasTextBodyMatcher(expected);

/// Matches an HTTP response with an empty body.
///
/// Example:
/// ```dart
/// expect(response, hasEmptyBody());
/// ```
Matcher hasEmptyBody() => _HasEmptyBodyMatcher();

/// Matches an HTTP response whose JSON body contains the specified key.
///
/// For nested objects, use dot notation in the key path.
///
/// Examples:
/// ```dart
/// expect(response, containsJsonKey('user_id'));
/// expect(response, containsJsonKey('user.profile.name'));
/// ```
Matcher containsJsonKey(String key) => _ContainsJsonKeyMatcher(key);

/// Matches an HTTP response with a specific value at the given JSON path.
///
/// The path uses dot notation to navigate nested objects and square brackets
/// for array indices.
///
/// Examples:
/// ```dart
/// expect(response, hasJsonPath('user.name', 'John'));
/// expect(response, hasJsonPath('users[0].email', 'john@example.com'));
/// expect(response, hasJsonPath('metadata.count', greaterThan(0)));
/// ```
Matcher hasJsonPath(String path, dynamic expected) =>
    _HasJsonPathMatcher(path, expected);

// =============================================================================
// Response Header Matchers
// =============================================================================

/// Matches an HTTP response that has the specified header.
///
/// If [value] is provided, also checks that the header has the expected value.
/// The header name comparison is case-insensitive.
///
/// Examples:
/// ```dart
/// // Check header presence
/// expect(response, hasHeader('authorization'));
///
/// // Check header value
/// expect(response, hasHeader('content-type', 'application/json'));
/// expect(response, hasHeader('cache-control', contains('no-cache')));
/// ```
Matcher hasHeader(String name, [dynamic value]) =>
    _HasHeaderMatcher(name, value);

/// Matches an HTTP response with the specified content type.
///
/// The comparison is case-insensitive and handles MIME type parameters.
///
/// Examples:
/// ```dart
/// expect(response, hasContentType('application/json'));
/// expect(response, hasContentType('text/html'));
/// expect(response, hasContentType('image/png'));
/// ```
Matcher hasContentType(String mimeType) => _HasContentTypeMatcher(mimeType);

/// Matches an HTTP response with JSON content type.
///
/// This matcher accepts 'application/json' and any MIME type ending with '+json'.
///
/// Example:
/// ```dart
/// expect(response, isJson());
/// ```
Matcher isJson() => _IsJsonResponseMatcher();

/// Matches an HTTP response with HTML content type.
///
/// This matcher accepts 'text/html' content type.
///
/// Example:
/// ```dart
/// expect(response, isHtml());
/// ```
Matcher isHtml() => _IsHtmlResponseMatcher();

// =============================================================================
// WebSocket Message Matchers
// =============================================================================

/// Matches a WebSocket message with the specified event type.
///
/// Example:
/// ```dart
/// expect(message, hasEvent('pong'));
/// expect(message, hasEvent('user_joined'));
/// ```
Matcher hasEvent(String event) => _HasEventMatcher(event);

/// Matches a WebSocket message with the specified data.
///
/// The matcher performs deep comparison of the message data.
///
/// Examples:
/// ```dart
/// expect(message, hasMessageData('ping'));
/// expect(message, hasMessageData({'userId': 123, 'status': 'online'}));
/// expect(message, hasMessageData(contains('success')));
/// ```
Matcher hasMessageData(dynamic expected) => _HasMessageDataMatcher(expected);

// =============================================================================
// Matcher Implementations
// =============================================================================

class _HasStatusMatcher extends Matcher {
  final int expectedStatus;

  const _HasStatusMatcher(this.expectedStatus);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! TestResponse) {
      addStateInfo(matchState,
          {'error': 'Expected TestResponse but got ${item.runtimeType}'});
      return false;
    }

    return item.statusCode == expectedStatus;
  }

  @override
  Description describe(Description description) {
    return description.add('HTTP response with status code $expectedStatus');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (matchState['error'] != null) {
      return mismatchDescription.add(matchState['error'] as String);
    }

    if (item is TestResponse) {
      return mismatchDescription
          .add('had status code ${item.statusCode} instead of $expectedStatus');
    }

    return mismatchDescription.add('was not a TestResponse');
  }
}

class _IsServerErrorMatcher extends Matcher {
  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! TestResponse) {
      addStateInfo(matchState,
          {'error': 'Expected TestResponse but got ${item.runtimeType}'});
      return false;
    }

    return item.statusCode >= 500 && item.statusCode < 600;
  }

  @override
  Description describe(Description description) {
    return description.add('HTTP response with 5xx server error status code');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (matchState['error'] != null) {
      return mismatchDescription.add(matchState['error'] as String);
    }

    if (item is TestResponse) {
      return mismatchDescription.add(
          'had status code ${item.statusCode} which is not a server error (5xx)');
    }

    return mismatchDescription.add('was not a TestResponse');
  }
}

class _HasJsonBodyMatcher extends Matcher {
  final dynamic expected;

  const _HasJsonBodyMatcher(this.expected);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! TestResponse) {
      addStateInfo(matchState,
          {'error': 'Expected TestResponse but got ${item.runtimeType}'});
      return false;
    }

    try {
      final actual = item.json();
      if (expected is Matcher) {
        return (expected as Matcher).matches(actual, matchState);
      }
      return equals(expected).matches(actual, matchState);
    } catch (e) {
      addStateInfo(matchState, {
        'error': 'Failed to parse response body as JSON: $e',
        'body': item.body,
      });
      return false;
    }
  }

  @override
  Description describe(Description description) {
    if (expected is Matcher) {
      return description
          .add('HTTP response with JSON body that ')
          .addDescriptionOf(expected);
    }
    return description
        .add('HTTP response with JSON body ')
        .addDescriptionOf(expected);
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (matchState['error'] != null) {
      mismatchDescription.add(matchState['error'] as String);
      if (matchState['body'] != null) {
        mismatchDescription.add('\nActual body: ${matchState['body']}');
      }
      return mismatchDescription;
    }

    if (item is TestResponse) {
      try {
        final actual = item.json();
        if (expected is Matcher) {
          return (expected as Matcher).describeMismatch(
              actual, mismatchDescription, matchState, verbose);
        }
        return equals(expected)
            .describeMismatch(actual, mismatchDescription, matchState, verbose);
      } catch (e) {
        return mismatchDescription.add('could not parse JSON: $e');
      }
    }

    return mismatchDescription.add('was not a TestResponse');
  }
}

class _HasTextBodyMatcher extends Matcher {
  final dynamic expected;

  const _HasTextBodyMatcher(this.expected);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! TestResponse) {
      addStateInfo(matchState,
          {'error': 'Expected TestResponse but got ${item.runtimeType}'});
      return false;
    }

    final actual = item.body;
    if (expected is Matcher) {
      return (expected as Matcher).matches(actual, matchState);
    }
    return equals(expected).matches(actual, matchState);
  }

  @override
  Description describe(Description description) {
    if (expected is Matcher) {
      return description
          .add('HTTP response with text body that ')
          .addDescriptionOf(expected);
    }
    return description
        .add('HTTP response with text body ')
        .addDescriptionOf(expected);
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (matchState['error'] != null) {
      return mismatchDescription.add(matchState['error'] as String);
    }

    if (item is TestResponse) {
      final actual = item.body;
      if (expected is Matcher) {
        return (expected as Matcher)
            .describeMismatch(actual, mismatchDescription, matchState, verbose);
      }
      return equals(expected)
          .describeMismatch(actual, mismatchDescription, matchState, verbose);
    }

    return mismatchDescription.add('was not a TestResponse');
  }
}

class _HasEmptyBodyMatcher extends Matcher {
  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! TestResponse) {
      addStateInfo(matchState,
          {'error': 'Expected TestResponse but got ${item.runtimeType}'});
      return false;
    }

    return item.body.isEmpty;
  }

  @override
  Description describe(Description description) {
    return description.add('HTTP response with empty body');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (matchState['error'] != null) {
      return mismatchDescription.add(matchState['error'] as String);
    }

    if (item is TestResponse) {
      return mismatchDescription
          .add('had body with ${item.body.length} characters: "${item.body}"');
    }

    return mismatchDescription.add('was not a TestResponse');
  }
}

class _ContainsJsonKeyMatcher extends Matcher {
  final String key;

  const _ContainsJsonKeyMatcher(this.key);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! TestResponse) {
      addStateInfo(matchState,
          {'error': 'Expected TestResponse but got ${item.runtimeType}'});
      return false;
    }

    try {
      final json = item.json();
      return _hasJsonKey(json, key);
    } catch (e) {
      addStateInfo(matchState, {
        'error': 'Failed to parse response body as JSON: $e',
        'body': item.body,
      });
      return false;
    }
  }

  bool _hasJsonKey(dynamic json, String keyPath) {
    if (json is! Map<String, dynamic>) {
      return false;
    }

    final parts = keyPath.split('.');
    dynamic current = json;

    for (final part in parts) {
      if (current is! Map<String, dynamic>) {
        return false;
      }
      if (!current.containsKey(part)) {
        return false;
      }
      current = current[part];
    }

    return true;
  }

  @override
  Description describe(Description description) {
    return description
        .add('HTTP response with JSON body containing key "$key"');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (matchState['error'] != null) {
      mismatchDescription.add(matchState['error'] as String);
      if (matchState['body'] != null) {
        mismatchDescription.add('\nActual body: ${matchState['body']}');
      }
      return mismatchDescription;
    }

    if (item is TestResponse) {
      try {
        final json = item.json();
        return mismatchDescription.add('JSON body did not contain key "$key"').add(
            '\nActual JSON: ${const JsonEncoder.withIndent('  ').convert(json)}');
      } catch (e) {
        return mismatchDescription.add('could not parse JSON: $e');
      }
    }

    return mismatchDescription.add('was not a TestResponse');
  }
}

class _HasJsonPathMatcher extends Matcher {
  final String path;
  final dynamic expected;

  const _HasJsonPathMatcher(this.path, this.expected);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! TestResponse) {
      addStateInfo(matchState,
          {'error': 'Expected TestResponse but got ${item.runtimeType}'});
      return false;
    }

    try {
      final json = item.json();
      final actual = _getJsonPath(json, path);

      if (actual == null) {
        addStateInfo(matchState, {
          'error': 'JSON path "$path" not found',
          'json': json,
        });
        return false;
      }

      if (expected is Matcher) {
        return (expected as Matcher).matches(actual, matchState);
      }
      return equals(expected).matches(actual, matchState);
    } catch (e) {
      addStateInfo(matchState, {
        'error': 'Failed to parse response body as JSON: $e',
        'body': item.body,
      });
      return false;
    }
  }

  dynamic _getJsonPath(dynamic json, String path) {
    dynamic current = json;
    final parts = <String>[];
    final buffer = StringBuffer();
    bool inBrackets = false;

    // Parse path with support for array indices
    for (int i = 0; i < path.length; i++) {
      final char = path[i];
      if (char == '[' && !inBrackets) {
        if (buffer.isNotEmpty) {
          parts.add(buffer.toString());
          buffer.clear();
        }
        inBrackets = true;
      } else if (char == ']' && inBrackets) {
        parts.add(buffer.toString());
        buffer.clear();
        inBrackets = false;
      } else if (char == '.' && !inBrackets) {
        if (buffer.isNotEmpty) {
          parts.add(buffer.toString());
          buffer.clear();
        }
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      parts.add(buffer.toString());
    }

    // Navigate through the JSON structure
    for (final part in parts) {
      if (part.startsWith('[') && part.endsWith(']')) {
        // Array index
        final indexStr = part.substring(1, part.length - 1);
        final index = int.tryParse(indexStr);
        if (index == null || current is! List || index >= current.length) {
          return null;
        }
        current = current[index];
      } else {
        // Object key
        if (current is! Map<String, dynamic> || !current.containsKey(part)) {
          return null;
        }
        current = current[part];
      }
    }

    return current;
  }

  @override
  Description describe(Description description) {
    if (expected is Matcher) {
      return description
          .add('HTTP response with JSON path "$path" that ')
          .addDescriptionOf(expected);
    }
    return description
        .add('HTTP response with JSON path "$path" equal to ')
        .addDescriptionOf(expected);
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (matchState['error'] != null) {
      mismatchDescription.add(matchState['error'] as String);
      if (matchState['body'] != null) {
        mismatchDescription.add('\nActual body: ${matchState['body']}');
      } else if (matchState['json'] != null) {
        mismatchDescription.add(
            '\nActual JSON: ${const JsonEncoder.withIndent('  ').convert(matchState['json'])}');
      }
      return mismatchDescription;
    }

    if (item is TestResponse) {
      try {
        final json = item.json();
        final actual = _getJsonPath(json, path);

        if (actual == null) {
          return mismatchDescription.add('JSON path "$path" was not found').add(
              '\nActual JSON: ${const JsonEncoder.withIndent('  ').convert(json)}');
        }

        mismatchDescription
            .add('JSON path "$path" had value ')
            .addDescriptionOf(actual)
            .add(' instead of ')
            .addDescriptionOf(expected);

        if (expected is Matcher) {
          mismatchDescription.add('\n');
          (expected as Matcher).describeMismatch(
              actual, mismatchDescription, matchState, verbose);
        }

        return mismatchDescription;
      } catch (e) {
        return mismatchDescription.add('could not parse JSON: $e');
      }
    }

    return mismatchDescription.add('was not a TestResponse');
  }
}

class _HasHeaderMatcher extends Matcher {
  final String name;
  final dynamic expectedValue;

  const _HasHeaderMatcher(this.name, this.expectedValue);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! TestResponse) {
      addStateInfo(matchState,
          {'error': 'Expected TestResponse but got ${item.runtimeType}'});
      return false;
    }

    // Check if header exists (case-insensitive)
    String? actualValue;
    item.headers.forEach((name_, values) {
      if (name_.toLowerCase() == name.toLowerCase()) {
        actualValue = values.isNotEmpty ? values.first : null;
      }
    });

    if (actualValue == null) {
      addStateInfo(matchState, {
        'headerNotFound': true,
        'availableHeaders': _getHeaderNames(item.headers),
      });
      return false;
    }

    // If no expected value specified, just check presence
    if (expectedValue == null) {
      return true;
    }

    // Check header value
    if (expectedValue is Matcher) {
      return (expectedValue as Matcher).matches(actualValue, matchState);
    }
    return equals(expectedValue).matches(actualValue, matchState);
  }

  @override
  Description describe(Description description) {
    if (expectedValue == null) {
      return description.add('HTTP response with header "$name"');
    }
    if (expectedValue is Matcher) {
      return description
          .add('HTTP response with header "$name" that ')
          .addDescriptionOf(expectedValue);
    }
    return description
        .add('HTTP response with header "$name" equal to ')
        .addDescriptionOf(expectedValue);
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (matchState['error'] != null) {
      return mismatchDescription.add(matchState['error'] as String);
    }

    if (item is TestResponse) {
      if (matchState['headerNotFound'] == true) {
        mismatchDescription.add('did not have header "$name"');
        final availableHeaders =
            matchState['availableHeaders'] as List<String>?;
        if (availableHeaders != null && availableHeaders.isNotEmpty) {
          mismatchDescription
              .add('\nAvailable headers: ${availableHeaders.join(', ')}');
        }
        return mismatchDescription;
      }

      // Header exists but value doesn't match
      final actualValue = item.header(name);
      if (expectedValue is Matcher) {
        mismatchDescription.add('header "$name" ');
        return (expectedValue as Matcher).describeMismatch(
            actualValue, mismatchDescription, matchState, verbose);
      }
      return mismatchDescription
          .add('header "$name" was ')
          .addDescriptionOf(actualValue)
          .add(' instead of ')
          .addDescriptionOf(expectedValue);
    }

    return mismatchDescription.add('was not a TestResponse');
  }
}

class _HasContentTypeMatcher extends Matcher {
  final String expectedMimeType;

  const _HasContentTypeMatcher(this.expectedMimeType);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! TestResponse) {
      addStateInfo(matchState,
          {'error': 'Expected TestResponse but got ${item.runtimeType}'});
      return false;
    }

    final contentType = item.contentType;
    if (contentType == null) {
      addStateInfo(matchState, {'contentTypeNull': true});
      return false;
    }

    return contentType.mimeType.toLowerCase() == expectedMimeType.toLowerCase();
  }

  @override
  Description describe(Description description) {
    return description
        .add('HTTP response with content type "$expectedMimeType"');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (matchState['error'] != null) {
      return mismatchDescription.add(matchState['error'] as String);
    }

    if (item is TestResponse) {
      if (matchState['contentTypeNull'] == true) {
        return mismatchDescription.add('had no content type header');
      }

      final contentType = item.contentType;
      return mismatchDescription
          .add('had content type "${contentType?.mimeType}" '
              'instead of "$expectedMimeType"');
    }

    return mismatchDescription.add('was not a TestResponse');
  }
}

class _IsJsonResponseMatcher extends Matcher {
  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! TestResponse) {
      addStateInfo(matchState,
          {'error': 'Expected TestResponse but got ${item.runtimeType}'});
      return false;
    }

    return item.isJson;
  }

  @override
  Description describe(Description description) {
    return description.add('HTTP response with JSON content type');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (matchState['error'] != null) {
      return mismatchDescription.add(matchState['error'] as String);
    }

    if (item is TestResponse) {
      final contentType = item.contentType;
      if (contentType == null) {
        return mismatchDescription.add('had no content type header');
      }
      return mismatchDescription
          .add('had content type "${contentType.mimeType}" which is not JSON');
    }

    return mismatchDescription.add('was not a TestResponse');
  }
}

class _IsHtmlResponseMatcher extends Matcher {
  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! TestResponse) {
      addStateInfo(matchState,
          {'error': 'Expected TestResponse but got ${item.runtimeType}'});
      return false;
    }

    return item.isHtml;
  }

  @override
  Description describe(Description description) {
    return description.add('HTTP response with HTML content type');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (matchState['error'] != null) {
      return mismatchDescription.add(matchState['error'] as String);
    }

    if (item is TestResponse) {
      final contentType = item.contentType;
      if (contentType == null) {
        return mismatchDescription.add('had no content type header');
      }
      return mismatchDescription
          .add('had content type "${contentType.mimeType}" which is not HTML');
    }

    return mismatchDescription.add('was not a TestResponse');
  }
}

class _HasEventMatcher extends Matcher {
  final String expectedEvent;

  const _HasEventMatcher(this.expectedEvent);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! WebSocketMessage) {
      addStateInfo(matchState,
          {'error': 'Expected WebSocketMessage but got ${item.runtimeType}'});
      return false;
    }

    return item.event == expectedEvent;
  }

  @override
  Description describe(Description description) {
    return description.add('WebSocket message with event "$expectedEvent"');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (matchState['error'] != null) {
      return mismatchDescription.add(matchState['error'] as String);
    }

    if (item is WebSocketMessage) {
      if (item.event == null) {
        return mismatchDescription
            .add('had no event (raw message: ${item.data})');
      }
      return mismatchDescription
          .add('had event "${item.event}" instead of "$expectedEvent"');
    }

    return mismatchDescription.add('was not a WebSocketMessage');
  }
}

class _HasMessageDataMatcher extends Matcher {
  final dynamic expected;

  const _HasMessageDataMatcher(this.expected);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! WebSocketMessage) {
      addStateInfo(matchState,
          {'error': 'Expected WebSocketMessage but got ${item.runtimeType}'});
      return false;
    }

    if (expected is Matcher) {
      return (expected as Matcher).matches(item.data, matchState);
    }
    return equals(expected).matches(item.data, matchState);
  }

  @override
  Description describe(Description description) {
    if (expected is Matcher) {
      return description
          .add('WebSocket message with data that ')
          .addDescriptionOf(expected);
    }
    return description
        .add('WebSocket message with data ')
        .addDescriptionOf(expected);
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (matchState['error'] != null) {
      return mismatchDescription.add(matchState['error'] as String);
    }

    if (item is WebSocketMessage) {
      if (expected is Matcher) {
        mismatchDescription.add('message data ');
        return (expected as Matcher).describeMismatch(
            item.data, mismatchDescription, matchState, verbose);
      }
      return equals(expected).describeMismatch(
          item.data, mismatchDescription, matchState, verbose);
    }

    return mismatchDescription.add('was not a WebSocketMessage');
  }
}

// Helper function to get header names from HttpHeaders
List<String> _getHeaderNames(HttpHeaders headers) {
  final names = <String>[];
  headers.forEach((String name, List<String> values) {
    names.add(name);
  });
  return names;
}
