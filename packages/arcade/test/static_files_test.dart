import 'dart:io';

import 'package:arcade/arcade.dart';
import 'package:arcade_config/arcade_config.dart';
import 'package:arcade_test/arcade_test.dart';
import 'package:test/test.dart';

void main() {
  group('Static Files', () {
    late ArcadeTestServer server;
    late Directory tempDir;
    late File tempFile;
    late File nestedFile;
    late File indexFile;

    setUpAll(() async {
      // Create temporary directory structure for testing
      tempDir = await Directory.systemTemp.createTemp('arcade_static_test_');

      // Create test files
      tempFile = File('${tempDir.path}/test.txt');
      await tempFile.writeAsString('Hello from static file');

      // Create nested directory and file
      final nestedDir = Directory('${tempDir.path}/nested');
      await nestedDir.create();
      nestedFile = File('${nestedDir.path}/deep.txt');
      await nestedFile.writeAsString('Deep nested content');

      // Create index.html
      indexFile = File('${tempDir.path}/index.html');
      await indexFile.writeAsString('<h1>Welcome to Arcade</h1>');

      // Create other file types
      final cssFile = File('${tempDir.path}/style.css');
      await cssFile.writeAsString('body { color: blue; }');

      final jsFile = File('${tempDir.path}/script.js');
      await jsFile.writeAsString('console.log("Hello");');

      final jsonFile = File('${tempDir.path}/data.json');
      await jsonFile.writeAsString('{"message": "Hello JSON"}');
    });

    tearDown(() async {
      await server.close();
    });

    tearDownAll(() async {
      // Clean up temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Basic Static File Serving', () {
      test('serves static files from configured directory', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/api/test').handle((ctx) => {'message': 'API endpoint'});
        }, staticFilesDirectory: tempDir);

        // Test static file
        final response = await server.get('/test.txt');
        expect(response, isOk());
        expect(response.text(), equals('Hello from static file'));
        expect(response.contentType?.mimeType, equals('text/plain'));
      });

      test('serves nested static files', () async {
        server = await ArcadeTestServer.withRoutes(
          () {},
          staticFilesDirectory: tempDir,
        );

        final response = await server.get('/nested/deep.txt');
        expect(response, isOk());
        expect(response.text(), equals('Deep nested content'));
      });

      test(
        'does not automatically serve index.html for directory paths',
        () async {
          server = await ArcadeTestServer.withRoutes(
            () {},
            staticFilesDirectory: tempDir,
          );

          // Root directory does not automatically serve index.html
          final response = await server.get('/');
          expect(response, isNotFound());

          // But index.html can be accessed directly
          final indexResponse = await server.get('/index.html');
          expect(indexResponse, isOk());
          expect(indexResponse.text(), equals('<h1>Welcome to Arcade</h1>'));
          expect(indexResponse.contentType?.mimeType, equals('text/html'));
        },
      );

      test('returns 404 for non-existent static files', () async {
        server = await ArcadeTestServer.withRoutes(
          () {},
          staticFilesDirectory: tempDir,
        );

        final response = await server.get('/non-existent.txt');
        expect(response, isNotFound());
      });
    });

    group('Content Types', () {
      test('serves files with correct content types', () async {
        server = await ArcadeTestServer.withRoutes(
          () {},
          staticFilesDirectory: tempDir,
        );

        // HTML
        var response = await server.get('/index.html');
        expect(response, isOk());
        expect(response.contentType?.mimeType, equals('text/html'));

        // CSS
        response = await server.get('/style.css');
        expect(response, isOk());
        expect(response.contentType?.mimeType, equals('text/css'));

        // JavaScript
        response = await server.get('/script.js');
        expect(response, isOk());
        expect(response.contentType?.mimeType, equals('text/javascript'));

        // JSON
        response = await server.get('/data.json');
        expect(response, isOk());
        expect(response.contentType?.mimeType, equals('application/json'));
      });

      test('serves binary files correctly', () async {
        // Create a binary file
        final binaryFile = File('${tempDir.path}/image.png');
        final binaryData = List<int>.generate(256, (i) => i);
        await binaryFile.writeAsBytes(binaryData);

        server = await ArcadeTestServer.withRoutes(
          () {},
          staticFilesDirectory: tempDir,
        );

        final response = await server.get('/image.png');
        expect(response, isOk());
        expect(response.contentType?.mimeType, equals('image/png'));
        expect(response.bodyBytes, equals(binaryData));
      });
    });

    group('Route Priority', () {
      test('routes take priority over static files', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/test.txt').handle((ctx) => 'Dynamic route response');
        }, staticFilesDirectory: tempDir);

        final response = await server.get('/test.txt');
        expect(response, isOk());
        expect(response.text(), equals('Dynamic route response'));
      });

      test('wildcard routes can override static files', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/*').handle((ctx) => 'Catch all route');
        }, staticFilesDirectory: tempDir);

        final response = await server.get('/test.txt');
        expect(response, isOk());
        expect(response.text(), equals('Catch all route'));
      });
    });

    group('Security', () {
      test('prevents directory traversal attacks', () async {
        server = await ArcadeTestServer.withRoutes(
          () {},
          staticFilesDirectory: tempDir,
        );

        // Try to access parent directory
        var response = await server.get('/../etc/passwd');
        expect(response, isNotFound());

        // Try with encoded traversal
        response = await server.get('/..%2F..%2Fetc%2Fpasswd');
        expect(response, isNotFound());

        // Try with double encoding
        response = await server.get('/..%252F..%252Fetc%252Fpasswd');
        expect(response, isNotFound());
      });

      test('serves hidden files (security concern)', () async {
        // Create a hidden file
        final hiddenFile = File('${tempDir.path}/.hidden');
        await hiddenFile.writeAsString('Secret content');

        server = await ArcadeTestServer.withRoutes(
          () {},
          staticFilesDirectory: tempDir,
        );

        // Note: This is a security concern - arcade serves hidden files
        final response = await server.get('/.hidden');
        expect(response, isOk());
        expect(response.text(), equals('Secret content'));
      });

      test('does not serve files outside static directory', () async {
        // Create a file outside the static directory
        final outsideFile = File('${tempDir.parent.path}/outside.txt');
        await outsideFile.writeAsString('Outside content');

        server = await ArcadeTestServer.withRoutes(
          () {},
          staticFilesDirectory: tempDir,
        );

        final response = await server.get('/../outside.txt');
        expect(response, isNotFound());

        // Clean up
        await outsideFile.delete();
      });
    });

    group('Configuration', () {
      test('can change static directory during initialization', () async {
        final altDir = await Directory.systemTemp.createTemp(
          'arcade_alt_static_',
        );
        final altFile = File('${altDir.path}/alt.txt');
        await altFile.writeAsString('Alternative content');

        try {
          server = await ArcadeTestServer.create(() async {
            // Change static directory during init
            ArcadeConfiguration.override(staticFilesDirectory: altDir);

            route.get('/api/test').handle((ctx) => 'API');
          });

          final response = await server.get('/alt.txt');
          expect(response, isOk());
          expect(response.text(), equals('Alternative content'));
        } finally {
          await altDir.delete(recursive: true);
        }
      });

      test('handles non-existent static directory gracefully', () async {
        final nonExistentDir = Directory('${tempDir.path}/does_not_exist');

        server = await ArcadeTestServer.withRoutes(() {
          route.get('/api/test').handle((ctx) => 'API works');
        }, staticFilesDirectory: nonExistentDir);

        // API routes should still work
        var response = await server.get('/api/test');
        expect(response, isOk());
        expect(response.text(), equals('API works'));

        // Static files should return 404
        response = await server.get('/any-file.txt');
        expect(response, isNotFound());
      });
    });

    group('Special Cases', () {
      test('handles files with special characters in names', () async {
        final specialFile = File('${tempDir.path}/file with spaces.txt');
        await specialFile.writeAsString('Special file content');

        final encodedFile = File('${tempDir.path}/file%20encoded.txt');
        await encodedFile.writeAsString('Encoded file content');

        server = await ArcadeTestServer.withRoutes(
          () {},
          staticFilesDirectory: tempDir,
        );

        // URL encoded request
        var response = await server.get('/file%20with%20spaces.txt');
        expect(response, isOk());
        expect(response.text(), equals('Special file content'));

        // Already encoded filename
        response = await server.get('/file%2520encoded.txt');
        expect(response, isOk());
        expect(response.text(), equals('Encoded file content'));
      });

      test('handles empty files', () async {
        final emptyFile = File('${tempDir.path}/empty.txt');
        await emptyFile.writeAsString('');

        server = await ArcadeTestServer.withRoutes(
          () {},
          staticFilesDirectory: tempDir,
        );

        final response = await server.get('/empty.txt');
        expect(response, isOk());
        expect(response.text(), equals(''));
        expect(response.contentLength, equals(0));
      });

      test('handles large files', () async {
        final largeFile = File('${tempDir.path}/large.txt');
        final largeContent = 'x' * 1024 * 1024; // 1MB
        await largeFile.writeAsString(largeContent);

        server = await ArcadeTestServer.withRoutes(
          () {},
          staticFilesDirectory: tempDir,
        );

        final response = await server.get('/large.txt');
        expect(response, isOk());
        expect(response.text().length, equals(1024 * 1024));
      });
    });

    group('HTTP Methods', () {
      test(
        'serves static files for all HTTP methods (potential issue)',
        () async {
          server = await ArcadeTestServer.withRoutes(
            () {},
            staticFilesDirectory: tempDir,
          );

          // GET should work
          var response = await server.get('/test.txt');
          expect(response, isOk());

          // Note: Arcade serves static files for all methods - this could be a security issue
          response = await server.post('/test.txt');
          expect(response, isOk());
          expect(response.text(), equals('Hello from static file'));

          response = await server.put('/test.txt');
          expect(response, isOk());
          expect(response.text(), equals('Hello from static file'));

          response = await server.delete('/test.txt');
          expect(response, isOk());
          expect(response.text(), equals('Hello from static file'));
        },
      );

      test('HEAD requests work for static files', () async {
        server = await ArcadeTestServer.withRoutes(
          () {},
          staticFilesDirectory: tempDir,
        );

        final response = await server.head('/test.txt');
        expect(response, isOk());
        expect(response.body, isEmpty); // HEAD responses have no body
        expect(response.contentLength, equals(22)); // "Hello from static file"
      });
    });

    group('Integration with Routes', () {
      test('static files work with route groups', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.group(
            '/api',
            defineRoutes: (route) {
              route().get('/test').handle((ctx) => {'api': 'response'});
            },
          );
        }, staticFilesDirectory: tempDir);

        // API route
        var response = await server.get('/api/test');
        expect(response, isOk());
        expect(response, hasJsonBody({'api': 'response'}));

        // Static file
        response = await server.get('/test.txt');
        expect(response, isOk());
        expect(response.text(), equals('Hello from static file'));
      });

      test('static files do not run through before hooks', () async {
        server = await ArcadeTestServer.create(() async {
          ArcadeConfiguration.override(staticFilesDirectory: tempDir);

          route.registerGlobalBeforeHook((ctx) {
            ctx.responseHeaders.add('X-Custom-Header', 'test');
            return ctx;
          });

          route.get('/api/test').handle((ctx) => 'API');
        });

        // Static files do not run through before hooks
        final response = await server.get('/test.txt');
        expect(response, isOk());
        expect(response.header('X-Custom-Header'), isNull);
        expect(response.text(), equals('Hello from static file'));

        // But API routes do get the header
        final apiResponse = await server.get('/api/test');
        expect(apiResponse, isOk());
        expect(apiResponse.header('X-Custom-Header'), equals('test'));
      });
    });
  });
}
