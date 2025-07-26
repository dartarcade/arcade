import 'package:arcade/arcade.dart';
import 'package:arcade_test/arcade_test.dart';
import 'package:test/test.dart';

void main() {
  group('TestResponse', () {
    // Set up a test server to create real responses
    late ArcadeTestServer server;

    setUp(() async {
      server = await ArcadeTestServer.withRoutes(() {
        route.get('/json').handle((ctx) => {'test': true, 'value': 42});
        route.get('/text').handle((ctx) => 'Plain text response');
        route.get('/empty').handle((ctx) => null);
        route.get('/custom-headers').handle((ctx) {
          // Headers are set by the framework
          return 'test';
        });
        route.get('/html').handle((ctx) {
          // Content type is automatically detected
          return '<h1>Hello</h1>';
        });
      });
    });

    tearDown(() async {
      await server.close();
    });

    group('Basic Properties', () {
      test('has correct status code', () async {
        final response = await server.get('/json');
        expect(response.statusCode, equals(200));
      });

      test('has headers', () async {
        final response = await server.get('/custom-headers');
        expect(response.headers, isNotNull);
        // Headers won't have custom values in current implementation
      });

      test('has body', () async {
        final response = await server.get('/text');
        expect(response.body, equals('Plain text response'));
      });

      test('handles empty body', () async {
        final response = await server.get('/empty');
        expect(response.statusCode, equals(200));
        expect(response.body, equals('null'));
      });
    });

    group('Content Type Detection', () {
      test('detects JSON content type', () async {
        final response = await server.get('/json');
        expect(response.contentType?.mimeType, equals('application/json'));
        expect(response.isJson, isTrue);
        expect(response.isHtml, isFalse);
        expect(response.isText, isFalse);
      });

      test('detects text content type', () async {
        final response = await server.get('/text');
        expect(response.contentType?.mimeType, equals('text/html'));
        expect(response.isJson, isFalse);
        expect(response.isHtml, isTrue);
      });

      test('detects HTML content type', () async {
        final response = await server.get('/html');
        expect(response.contentType?.mimeType, equals('text/html'));
        expect(response.isHtml, isTrue);
        expect(response.isJson, isFalse);
      });
    });

    group('JSON Parsing', () {
      test('parses valid JSON object', () async {
        final response = await server.get('/json');

        final json = response.json() as Map<String, dynamic>;
        expect(json, isA<Map>());
        expect(json['test'], equals(true));
        expect(json['value'], equals(42));
      });

      test('throws on text response', () async {
        final response = await server.get('/text');
        expect(() => response.json(), throwsFormatException);
      });

      test('parses null body as JSON', () async {
        final response = await server.get('/empty');
        expect(response.json(), isNull);
      });
    });

    group('Text Parsing', () {
      test('returns body as text', () async {
        final response = await server.get('/text');
        expect(response.text(), equals('Plain text response'));
      });

      test('returns null as string for empty body', () async {
        final response = await server.get('/empty');
        expect(response.text(), equals('null'));
      });
    });

    group('Headers', () {
      test('can access individual headers', () async {
        final response = await server.get('/json');
        expect(response.hasHeader('content-type'), isTrue);
        expect(response.hasHeader('x-nonexistent'), isFalse);
        expect(response.header('content-type'), contains('application/json'));
        expect(response.header('x-nonexistent'), isNull);
      });

      test('can access header values list', () async {
        final response = await server.get('/json');
        final contentTypeValues = response.headerValues('content-type');
        expect(contentTypeValues, isNotEmpty);
        expect(contentTypeValues.first, contains('application/json'));
      });
    });

    group('toString', () {
      test('provides meaningful string representation', () async {
        final response = await server.get('/text');

        final str = response.toString();
        expect(str, contains('TestResponse'));
        expect(str, contains('statusCode: 200'));
        expect(
            str,
            contains(
                'contentType: text/html')); // Arcade returns text/html for strings
        expect(str,
            contains('bodyLength: 19')); // "Plain text response" is 19 chars
      });
    });
  });
}
