import 'dart:convert';
import 'dart:io';

import 'package:arcade_test/arcade_test.dart';
import 'package:test/test.dart';

void main() {
  group('TestResponse bodyBytes and contentLength', () {
    late HttpServer server;
    late ArcadeTestClient client;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      client = ArcadeTestClient('http://localhost:${server.port}');
    });

    tearDown(() async {
      await server.close();
    });

    test('bodyBytes returns raw response bytes', () async {
      final testBytes = [0, 1, 2, 3, 255, 254, 253];
      server.listen((request) {
        request.response
          ..headers.contentType = ContentType.binary
          ..add(testBytes)
          ..close();
      });

      final response = await client.get('/test');
      expect(response.bodyBytes, equals(testBytes));
    });

    test('bodyBytes works with text content', () async {
      const testText = 'Hello, World!';
      server.listen((request) {
        request.response
          ..headers.contentType = ContentType.text
          ..write(testText)
          ..close();
      });

      final response = await client.get('/test');
      expect(response.bodyBytes, equals(utf8.encode(testText)));
      expect(response.text(), equals(testText));
    });

    test('bodyBytes works with JSON content', () async {
      final testData = {'message': 'Hello', 'number': 42};
      final jsonString = jsonEncode(testData);

      server.listen((request) {
        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonString)
          ..close();
      });

      final response = await client.get('/test');
      expect(response.bodyBytes, equals(utf8.encode(jsonString)));
      expect(response.json(), equals(testData));
    });

    test('bodyBytes handles empty response', () async {
      server.listen((request) {
        request.response.close();
      });

      final response = await client.get('/test');
      expect(response.bodyBytes, isEmpty);
      expect(response.text(), isEmpty);
    });

    test(
      'bodyBytes handles binary data that cannot be decoded as UTF-8',
      () async {
        // Create invalid UTF-8 sequence
        final invalidUtf8 = [0xFF, 0xFE, 0xFD, 0xFC];

        server.listen((request) {
          request.response
            ..headers.contentType = ContentType.binary
            ..add(invalidUtf8)
            ..close();
        });

        final response = await client.get('/test');
        expect(response.bodyBytes, equals(invalidUtf8));
        // Body should be empty string when UTF-8 decoding fails
        expect(response.body, isEmpty);
      },
    );

    test('contentLength returns correct length', () async {
      const testText = 'Test content with known length';
      final contentBytes = utf8.encode(testText);

      server.listen((request) {
        request.response
          ..headers.contentType = ContentType.text
          ..headers.contentLength = contentBytes.length
          ..add(contentBytes)
          ..close();
      });

      final response = await client.get('/test');
      expect(response.contentLength, equals(contentBytes.length));
      expect(response.bodyBytes.length, equals(contentBytes.length));
    });

    test('contentLength returns -1 for chunked responses', () async {
      server.listen((request) {
        // Chunked response (no content-length header)
        request.response
          ..headers.contentType = ContentType.text
          ..write('Chunk 1')
          ..write('Chunk 2')
          ..close();
      });

      final response = await client.get('/test');
      expect(response.contentLength, equals(-1));
      expect(response.text(), equals('Chunk 1Chunk 2'));
    });

    test('bodyBytes preserves exact byte sequence for images', () async {
      // Simulate a small PNG header
      final pngHeader = [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0x00, 0x00, 0x00, 0x0D, // IHDR chunk length
        0x49, 0x48, 0x44, 0x52, // IHDR chunk type
      ];

      server.listen((request) {
        request.response
          ..headers.contentType = ContentType('image', 'png')
          ..add(pngHeader)
          ..close();
      });

      final response = await client.get('/test');
      expect(response.bodyBytes, equals(pngHeader));
      expect(response.contentType?.mimeType, equals('image/png'));
    });

    test('toString includes bodyLength from bodyBytes', () async {
      const testText = 'Test response';

      server.listen((request) {
        request.response
          ..headers.contentType = ContentType.text
          ..write(testText)
          ..close();
      });

      final response = await client.get('/test');
      final str = response.toString();
      expect(str, contains('bodyLength: ${utf8.encode(testText).length}'));
      expect(str, contains('statusCode: 200'));
      expect(str, contains('contentType: text/plain'));
    });

    test('bodyBytes works with large responses', () async {
      // Create 1MB of data
      final largeData = List<int>.generate(1024 * 1024, (i) => i % 256);

      server.listen((request) {
        request.response
          ..headers.contentType = ContentType.binary
          ..add(largeData)
          ..close();
      });

      final response = await client.get('/test');
      expect(response.bodyBytes, equals(largeData));
      expect(response.bodyBytes.length, equals(1024 * 1024));
    });
  });
}
