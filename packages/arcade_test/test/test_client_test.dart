import 'dart:convert';

import 'package:arcade/arcade.dart';
import 'package:arcade_test/arcade_test.dart';
import 'package:test/test.dart';

void main() {
  group('ArcadeTestClient', () {
    late ArcadeTestServer server;
    late ArcadeTestClient client;

    setUp(() async {
      server = await ArcadeTestServer.withRoutes(() {
        // Echo endpoint for testing Maps
        route.post('/echo').handle((ctx) async {
          final bodyResult = await ctx.jsonMap();
          return switch (bodyResult) {
            BodyParseSuccess(value: final value) => value,
            BodyParseFailure(error: final error) => {
                'error': 'Parse failed: $error'
              },
          };
        });

        // Echo endpoint for testing any JSON (including Lists)
        route.post('/echo-any').handle((ctx) async {
          try {
            final body = await ctx.body();
            final decoded = jsonDecode(body);
            return decoded;
          } catch (e) {
            return {'error': 'Parse failed: $e'};
          }
        });

        // Headers echo endpoint
        route.get('/headers').handle((ctx) {
          final headers = <String, String>{};
          ctx.requestHeaders.forEach((name, values) {
            headers[name] = values.join(', ');
          });
          return headers;
        });

        // Text response endpoint
        route.get('/text').handle((ctx) => 'Plain text response');

        // Empty response endpoint
        route.get('/empty').handle((ctx) => null);

        // Various HTTP methods
        route.get('/method').handle((ctx) => {'method': 'GET'});
        route.post('/method').handle((ctx) => {'method': 'POST'});
        route.put('/method').handle((ctx) => {'method': 'PUT'});
        route.patch('/method').handle((ctx) => {'method': 'PATCH'});
        route.delete('/method').handle((ctx) => {'method': 'DELETE'});
        route.head('/method').handle((ctx) => {'method': 'HEAD'});
        route.options('/method').handle((ctx) => {'method': 'OPTIONS'});
      });

      client = ArcadeTestClient(server.baseUrl);
    });

    tearDown(() async {
      client.close();
      await server.close();
    });

    group('HTTP Methods', () {
      test('GET request', () async {
        final response = await client.get('/method');
        expect(response.statusCode, equals(200));
        expect(response.json(), equals({'method': 'GET'}));
      });

      test('POST request', () async {
        final response = await client.post('/method');
        expect(response.statusCode, equals(200));
        expect(response.json(), equals({'method': 'POST'}));
      });

      test('PUT request', () async {
        final response = await client.put('/method');
        expect(response.statusCode, equals(200));
        expect(response.json(), equals({'method': 'PUT'}));
      });

      test('PATCH request', () async {
        final response = await client.patch('/method');
        expect(response.statusCode, equals(200));
        expect(response.json(), equals({'method': 'PATCH'}));
      });

      test('DELETE request', () async {
        final response = await client.delete('/method');
        expect(response.statusCode, equals(200));
        expect(response.json(), equals({'method': 'DELETE'}));
      });

      test('HEAD request', () async {
        final response = await client.head('/method');
        expect(response.statusCode, equals(200));
        expect(response.body, isEmpty);
      });

      test('OPTIONS request', () async {
        final response = await client.options('/method');
        expect(response.statusCode, equals(200));
        expect(response.json(), equals({'method': 'OPTIONS'}));
      });
    });

    group('Request Bodies', () {
      test('sends JSON body from Map', () async {
        final data = {
          'name': 'Test',
          'value': 42,
          'nested': {'key': 'value'}
        };
        final response = await client.post('/echo', body: data);

        expect(response.statusCode, equals(200));
        expect(response.json(), equals(data));
      });

      test('sends JSON body from List', () async {
        final data = [
          1,
          2,
          3,
          {'key': 'value'}
        ];
        final response = await client.post('/echo-any', body: data);

        expect(response.statusCode, equals(200));
        expect(response.json(), equals(data));
      });

      test('sends string body', () async {
        final response = await client.post('/echo', body: 'raw string');

        expect(response.statusCode, equals(200));
        // Server will fail to parse as JSON
        expect(response.json()['error'], contains('Parse failed'));
      });

      test('sends null body', () async {
        final response = await client.post('/echo', body: null);

        expect(response.statusCode, equals(200));
        // Empty body should fail JSON parsing
        expect(response.json()['error'], contains('Parse failed'));
      });

      test('auto-encodes body to JSON', () async {
        final data = {'test': true};
        final response = await client.post('/echo', body: data);

        expect(response.headers['content-type']?.first, contains('application/json'));
        expect(response.json(), equals(data));
      });
    });

    group('Headers', () {
      test('sends custom headers', () async {
        final response = await client.get('/headers', headers: {
          'X-Custom-Header': 'custom-value',
          'X-Test': 'test-value',
        });

        expect(response.statusCode, equals(200));
        final body = response.json();
        expect(body['x-custom-header'], equals('custom-value'));
        expect(body['x-test'], equals('test-value'));
      });

      test('sets content-type for JSON body', () async {
        final response = await client.post('/headers', body: {'test': true});

        expect(response.statusCode, equals(200));
        final body = response.json();
        expect(body['content-type'], contains('application/json')); // This should work as it's a string in the map
      });

      test('preserves user content-type header', () async {
        final response = await client.post(
          '/headers',
          body: 'plain text',
          headers: {'Content-Type': 'text/plain'},
        );

        expect(response.statusCode, equals(200));
        final body = response.json();
        expect(body['content-type'], equals('text/plain'));
      });
    });

    group('Response Handling', () {
      test('handles JSON response', () async {
        final response = await client.get('/method');

        expect(response.statusCode, equals(200));
        expect(response.isJson, isTrue);
        expect(response.contentType?.mimeType, contains('application/json'));
        expect(response.json(), equals({'method': 'GET'}));
      });

      test('handles text response', () async {
        final response = await client.get('/text');

        expect(response.statusCode, equals(200));
        expect(response.isJson, isFalse);
        expect(response.contentType?.mimeType, contains('text/html')); // Arcade returns text/html for strings
        expect(response.text(), equals('Plain text response'));
      });

      test('handles empty response', () async {
        final response = await client.get('/empty');

        expect(response.statusCode, equals(200)); // Arcade returns 200 for null
        expect(response.body, equals('null')); // Arcade returns "null" string
        expect(response.body.length, equals(4)); // "null" is 4 characters
      });

      test('handles 404 response', () async {
        final response = await client.get('/nonexistent');

        expect(response.statusCode, equals(404));
        expect(
            response.statusCode >= 200 && response.statusCode < 300, isFalse);
      });
    });

    group('URL Building', () {
      test('builds correct URLs', () async {
        final customClient = ArcadeTestClient('http://example.com:8080');

        // The client should properly construct URLs
        expect(customClient.baseUrl, equals('http://example.com:8080'));

        customClient.close();
      });

      test('handles paths with and without leading slash', () async {
        // Both should work the same now
        final response1 = await client.get('/method');
        final response2 = await client.get('method');

        expect(response1.statusCode, equals(200));
        expect(response2.statusCode, equals(200)); // Both should work
      });
    });

    group('Error Handling', () {
      test('handles connection errors gracefully', () async {
        final badClient = ArcadeTestClient('http://localhost:99999');

        expect(
          () => badClient.get('/test'),
          throwsA(anyOf([
            isA<ArgumentError>(), // Invalid port
            isA<Exception>(),     // Other connection errors
          ])),
        );

        badClient.close();
      });
    });

    group('Client Lifecycle', () {
      test('close method works without errors', () {
        final testClient = ArcadeTestClient('http://localhost:8080');

        // Should not throw
        expect(() => testClient.close(), returnsNormally);
      });

      test('multiple clients can be used simultaneously', () async {
        final client1 = ArcadeTestClient(server.baseUrl);
        final client2 = ArcadeTestClient(server.baseUrl);

        final response1 = await client1.get('/method');
        final response2 = await client2.get('/method');

        expect(response1.statusCode, equals(200));
        expect(response2.statusCode, equals(200));

        client1.close();
        client2.close();
      });
    });
  });
}
