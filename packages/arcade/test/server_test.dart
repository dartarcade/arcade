import 'dart:async';
import 'dart:io';

import 'package:arcade/arcade.dart';
import 'package:arcade_test/arcade_test.dart';
import 'package:test/test.dart';

void main() {
  group('Server', () {
    late ArcadeTestServer server;

    tearDown(() async {
      await server.close();
    });

    test('initializes with custom init function', () async {
      var initCalled = false;

      server = await ArcadeTestServer.create(() async {
        initCalled = true;
        route.get('/test').handle((ctx) => 'initialized');
      });

      expect(initCalled, isTrue);

      final response = await server.get('/test');
      expect(response, isOk());
      expect(response, hasTextBody('initialized'));
    });

    test('handles basic HTTP requests', () async {
      server = await ArcadeTestServer.withRoutes(() {
        route.get('/').handle((ctx) => 'Hello, World!');
      });

      final response = await server.get('/');
      expect(response, isOk());
      expect(response, hasTextBody('Hello, World!'));
    });

    test('server lifecycle - starts and accepts connections', () async {
      server = await ArcadeTestServer.withRoutes(() {
        route.get('/ping').handle((ctx) => 'pong');
      });

      // Server should be accessible
      final response = await server.get('/ping');
      expect(response, isOk());
      expect(response, hasTextBody('pong'));
    });

    test('server provides correct base URL', () async {
      server = await ArcadeTestServer.withRoutes(() {
        route.get('/').handle((ctx) => 'test');
      });

      expect(server.baseUrl, startsWith('http://localhost:'));
      expect(server.wsBaseUrl, startsWith('ws://localhost:'));
      expect(server.serverPort, greaterThan(0));
    });

    test('async init function executes properly', () async {
      var asyncInitCompleted = false;

      server = await ArcadeTestServer.create(() async {
        // Simulate async work
        await Future.delayed(const Duration(milliseconds: 10));
        asyncInitCompleted = true;
        route.get('/async').handle((ctx) => 'async init done');
      });

      expect(asyncInitCompleted, isTrue);

      final response = await server.get('/async');
      expect(response, isOk());
      expect(response, hasTextBody('async init done'));
    });

    test('handles errors during initialization gracefully', () {
      expect(
        () => ArcadeTestServer.create(() {
          throw Exception('Init error');
        }),
        throwsA(isA<StateError>()),
      );
    });

    test('multiple sequential servers work correctly', () async {
      // First server
      server = await ArcadeTestServer.withRoutes(() {
        route.get('/first').handle((ctx) => 'first server');
      });

      var response = await server.get('/first');
      expect(response, isOk());
      expect(response, hasTextBody('first server'));

      await server.close();

      // Second server - should have clean state
      server = await ArcadeTestServer.withRoutes(() {
        route.get('/second').handle((ctx) => 'second server');
      });

      response = await server.get('/second');
      expect(response, isOk());
      expect(response, hasTextBody('second server'));

      // First server route should not exist
      response = await server.get('/first');
      expect(response, isNotFound());
    });

    test('server handles concurrent requests', () async {
      server = await ArcadeTestServer.withRoutes(() {
        route.get('/concurrent').handle((ctx) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return 'response';
        });
      });

      // Send multiple concurrent requests
      final futures = List.generate(5, (_) => server.get('/concurrent'));
      final responses = await Future.wait(futures);

      for (final response in responses) {
        expect(response, isOk());
        expect(response, hasTextBody('response'));
      }
    });

    test('server properly closes and releases resources', () async {
      server = await ArcadeTestServer.withRoutes(() {
        route.get('/close-test').handle((ctx) => 'working');
      });

      final response = await server.get('/close-test');
      expect(response, isOk());

      await server.close();

      // After closing, attempts to use the server should fail
      expect(() async => await server.get('/close-test'), throwsA(anything));
    });

    test('static file serving configuration', () async {
      // Create a temporary directory for static files
      final tempDir = await Directory.systemTemp.createTemp('arcade_test_');
      final testFile = File('${tempDir.path}/test.txt');
      await testFile.writeAsString('static content');

      // Create an index.html file
      final indexFile = File('${tempDir.path}/index.html');
      await indexFile.writeAsString('<html><body>Hello</body></html>');

      // Verify files exist
      expect(await testFile.exists(), isTrue);
      expect(await indexFile.exists(), isTrue);

      server = await ArcadeTestServer.withRoutes(() {
        route.get('/api/test').handle((ctx) => 'api endpoint');
      }, staticFilesDirectory: tempDir);

      // Test API route works
      final apiResponse = await server.get('/api/test');
      expect(apiResponse, isOk());
      expect(apiResponse, hasTextBody('api endpoint'));

      // Test static file serving
      final staticResponse = await server.get('/test.txt');
      expect(staticResponse, isOk());
      expect(staticResponse, hasTextBody('static content'));

      // Clean up
      await tempDir.delete(recursive: true);
    });

    test('server handles invalid paths gracefully', () async {
      server = await ArcadeTestServer.withRoutes(() {
        route.get('/valid').handle((ctx) => 'valid');
      });

      final response = await server.get('/invalid-path');
      expect(response, isNotFound());
    });
  });
}
