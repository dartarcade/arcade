import 'dart:io';

import 'package:arcade/arcade.dart';
import 'package:arcade_test/arcade_test.dart';
import 'package:test/test.dart';

void main() {
  group('RequestContext', () {
    late ArcadeTestServer server;

    tearDown(() async {
      await server.close();
    });

    group('Request Properties', () {
      test('provides access to HTTP method', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/test')
              .handle(
                (ctx) => {
                  'method': ctx.method.methodString,
                  'isGet': ctx.method == HttpMethod.get,
                },
              );
          route
              .post('/test')
              .handle(
                (ctx) => {
                  'method': ctx.method.methodString,
                  'isPost': ctx.method == HttpMethod.post,
                },
              );
        });

        var response = await server.get('/test');
        expect(response, isOk());
        expect(response, hasJsonBody({'method': 'GET', 'isGet': true}));

        response = await server.post('/test');
        expect(response, isOk());
        expect(response, hasJsonBody({'method': 'POST', 'isPost': true}));
      });

      test('provides access to request path', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/api/v1/users').handle((ctx) => {'path': ctx.path});
        });

        final response = await server.get('/api/v1/users');
        expect(response, isOk());
        expect(response, hasJsonBody({'path': '/api/v1/users'}));
      });

      test('provides access to request headers', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/headers')
              .handle(
                (ctx) => {
                  'userAgent': ctx.requestHeaders.value('user-agent'),
                  'customHeader': ctx.requestHeaders.value('x-custom'),
                  'hasAuth': ctx.requestHeaders.value('authorization') != null,
                },
              );
        });

        final response = await server.get(
          '/headers',
          headers: {
            'X-Custom': 'test-value',
            'Authorization': 'Bearer token123',
          },
        );
        expect(response, isOk());
        final body = response.json() as Map<String, dynamic>;
        expect(body['customHeader'], equals('test-value'));
        expect(body['hasAuth'], isTrue);
      });

      test('provides access to query parameters', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/search')
              .handle(
                (ctx) => {
                  'query': ctx.queryParameters['q'],
                  'limit': ctx.queryParameters['limit'],
                  'allParams': ctx.queryParameters,
                },
              );
        });

        final response = await server.get(
          '/search?q=arcade&limit=10&sort=name',
        );
        expect(response, isOk());
        expect(
          response,
          hasJsonBody({
            'query': 'arcade',
            'limit': '10',
            'allParams': {'q': 'arcade', 'limit': '10', 'sort': 'name'},
          }),
        );
      });

      test('provides access to path parameters', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/users/:userId/posts/:postId')
              .handle(
                (ctx) => {
                  'userId': ctx.pathParameters['userId'],
                  'postId': ctx.pathParameters['postId'],
                  'allParams': ctx.pathParameters,
                },
              );
        });

        final response = await server.get('/users/123/posts/456');
        expect(response, isOk());
        expect(
          response,
          hasJsonBody({
            'userId': '123',
            'postId': '456',
            'allParams': {'userId': '123', 'postId': '456'},
          }),
        );
      });

      test('provides access to route metadata', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/secure', extra: {'requiresAuth': true, 'minRole': 'admin'})
              .handle(
                (ctx) => {
                  'routePath': ctx.route.path,
                  'routeMethod': ctx.route.method?.methodString,
                  'metadata': ctx.route.metadata?.extra,
                },
              );
        });

        final response = await server.get('/secure');
        expect(response, isOk());
        expect(
          response,
          hasJsonBody({
            'routePath': '/secure',
            'routeMethod': 'GET',
            'metadata': {'requiresAuth': true, 'minRole': 'admin'},
          }),
        );
      });
    });

    group('Request Body', () {
      test('reads raw body as string', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.post('/echo').handle((ctx) async {
            final body = await ctx.body();
            return {'received': body};
          });
        });

        final response = await server.post('/echo', body: 'Hello, Arcade!');
        expect(response, isOk());
        expect(response, hasJsonBody({'received': 'Hello, Arcade!'}));
      });

      test('parses JSON body', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.post('/json').handle((ctx) async {
            final result = await ctx.jsonMap();
            return switch (result) {
              BodyParseSuccess(:final value) => {
                'success': true,
                'data': value,
              },
              BodyParseFailure(:final error) => () {
                ctx.statusCode = 400;
                return {'success': false, 'error': error.toString()};
              }(),
            };
          });
        });

        // Valid JSON
        var response = await server.post(
          '/json',
          body: {'name': 'Test', 'age': 25},
        );
        expect(response, isOk());
        expect(
          response,
          hasJsonBody({
            'success': true,
            'data': {'name': 'Test', 'age': 25},
          }),
        );

        // Invalid JSON
        response = await server.post('/json', body: 'not json');
        expect(response.statusCode, equals(400));
        final invalidBody = response.json() as Map<String, dynamic>;
        expect(invalidBody['success'], isFalse);
      });

      test('parses JSON array body', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.post('/array').handle((ctx) async {
            final result = await ctx.jsonList();
            return switch (result) {
              BodyParseSuccess(:final value) => {
                'success': true,
                'count': value.length,
                'items': value,
              },
              BodyParseFailure() => () {
                ctx.statusCode = 400;
                return {'success': false};
              }(),
            };
          });
        });

        final response = await server.post('/array', body: [1, 2, 3, 4, 5]);
        expect(response, isOk());
        expect(
          response,
          hasJsonBody({
            'success': true,
            'count': 5,
            'items': [1, 2, 3, 4, 5],
          }),
        );
      });

      test('parses form data', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.post('/form').handle((ctx) async {
            final result = await ctx.formData();
            return switch (result) {
              BodyParseSuccess(:final value) => {
                'fields': value.data,
                'fileCount': value.files.length,
              },
              BodyParseFailure() => () {
                ctx.statusCode = 400;
                return {'error': 'Failed to parse form data'};
              }(),
            };
          });
        });

        // Create form data request
        final client = ArcadeTestClient(server.baseUrl);
        final uri = Uri.parse('${server.baseUrl}/form');
        final request = await HttpClient().postUrl(uri);

        // Set content type for form data
        request.headers.contentType = ContentType(
          'multipart',
          'form-data',
          parameters: {'boundary': '----FormBoundary7MA4YWxkTrZu0gW'},
        );

        // Write form data
        const formData = '''
------FormBoundary7MA4YWxkTrZu0gW\r
Content-Disposition: form-data; name="username"\r
\r
testuser\r
------FormBoundary7MA4YWxkTrZu0gW\r
Content-Disposition: form-data; name="email"\r
\r
test@example.com\r
------FormBoundary7MA4YWxkTrZu0gW--\r
''';

        request.write(formData);
        final httpResponse = await request.close();
        final response = await TestResponse.fromResponse(httpResponse);

        expect(response, isOk());
        expect(
          response,
          hasJsonBody({
            'fields': {'username': 'testuser', 'email': 'test@example.com'},
            'fileCount': 0,
          }),
        );

        client.close();
      });
    });

    group('Response Handling', () {
      test('sets response status code', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/created').handle((ctx) {
            ctx.statusCode = 201;
            return {'id': 123};
          });

          route.get('/no-content').handle((ctx) {
            ctx.statusCode = 204;
          });

          route.get('/error').handle((ctx) {
            ctx.statusCode = 500;
            return {'error': 'Internal server error'};
          });
        });

        var response = await server.get('/created');
        expect(response.statusCode, equals(201));
        expect(response, hasJsonBody({'id': 123}));

        response = await server.get('/no-content');
        expect(response.statusCode, equals(204));
        expect(response.body, isEmpty);

        response = await server.get('/error');
        expect(response.statusCode, equals(500));
        expect(response, hasJsonBody({'error': 'Internal server error'}));
      });

      test('sets response headers', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/custom-headers').handle((ctx) {
            ctx.responseHeaders.add('X-Custom-Header', 'test-value');
            ctx.responseHeaders.add('X-Request-Id', '12345');
            ctx.responseHeaders.contentType = ContentType.json;
            return {'success': true};
          });
        });

        final response = await server.get('/custom-headers');
        expect(response, isOk());
        expect(response.header('X-Custom-Header'), equals('test-value'));
        expect(response.header('X-Request-Id'), equals('12345'));
        expect(response.contentType?.mimeType, equals('application/json'));
      });

      test('handles different return types', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/string').handle((ctx) => 'Hello, World!');

          route.get('/map').handle((ctx) => {'message': 'Hello'});

          route.get('/list').handle((ctx) => [1, 2, 3]);

          route.get('/null').handle((ctx) => null);

          route.get('/void').handle((ctx) {
            ctx.responseHeaders.add('X-Processed', 'true');
          });
        });

        var response = await server.get('/string');
        expect(response, isOk());
        expect(response.text(), equals('Hello, World!'));

        response = await server.get('/map');
        expect(response, isOk());
        expect(response, hasJsonBody({'message': 'Hello'}));

        response = await server.get('/list');
        expect(response, isOk());
        expect(response.json(), equals([1, 2, 3]));

        response = await server.get('/null');
        expect(response, isOk());
        expect(response.text(), equals('null'));

        response = await server.get('/void');
        expect(response, isOk());
        expect(response.header('X-Processed'), equals('true'));
      });

      test('handles async handlers', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/async').handle((ctx) async {
            // Simulate async operation
            await Future.delayed(const Duration(milliseconds: 10));
            return {'delayed': true};
          });
        });

        final response = await server.get('/async');
        expect(response, isOk());
        expect(response, hasJsonBody({'delayed': true}));
      });
    });

    group('Raw Request Access', () {
      test('provides access to raw HttpRequest', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/raw').handle((ctx) {
            final raw = ctx.rawRequest;
            return {
              'method': raw.method,
              'uri': raw.uri.toString(),
              'httpVersion': raw.protocolVersion,
              'remotePort': raw.connectionInfo?.remotePort,
            };
          });
        });

        final response = await server.get('/raw');
        expect(response, isOk());
        final body = response.json() as Map<String, dynamic>;
        expect(body['method'], equals('GET'));
        expect(body['uri'], equals('/raw'));
        expect(body['remotePort'], isA<int>());
      });

      test('provides access to raw body bytes', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.post('/bytes').handle((ctx) async {
            final bytes = await ctx.rawBody;
            final totalBytes = bytes.fold<int>(
              0,
              (sum, chunk) => sum + chunk.length,
            );
            return {'chunks': bytes.length, 'totalBytes': totalBytes};
          });
        });

        final response = await server.post('/bytes', body: 'Test data');
        expect(response, isOk());
        expect(
          response,
          hasJsonBody({
            'chunks': 1,
            'totalBytes': 9, // "Test data".length
          }),
        );
      });
    });

    group('Content Type Handling', () {
      test('handles different content types', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.post('/content-type').handle((ctx) {
            final contentType = ctx.requestHeaders.contentType;
            return {
              'mimeType': contentType?.mimeType,
              'charset': contentType?.charset,
              'isJson': contentType?.subType == 'json',
              'isForm': contentType?.subType == 'x-www-form-urlencoded',
            };
          });
        });

        // JSON content
        var response = await server.post(
          '/content-type',
          body: {'test': 'data'},
        );
        expect(response, isOk());
        var body = response.json() as Map<String, dynamic>;
        expect(body['mimeType'], equals('application/json'));
        expect(body['isJson'], isTrue);

        // Form content
        final client = ArcadeTestClient(server.baseUrl);
        final uri = Uri.parse('${server.baseUrl}/content-type');
        final request = await HttpClient().postUrl(uri);
        request.headers.contentType = ContentType(
          'application',
          'x-www-form-urlencoded',
        );
        request.write('key=value&foo=bar');
        final httpResponse = await request.close();
        response = await TestResponse.fromResponse(httpResponse);

        expect(response, isOk());
        body = response.json() as Map<String, dynamic>;
        expect(body['mimeType'], equals('application/x-www-form-urlencoded'));
        expect(body['isForm'], isTrue);

        client.close();
      });

      test('handles URL-encoded form data', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.post('/urlencoded').handle((ctx) async {
            final result = await ctx.jsonMap();
            return switch (result) {
              BodyParseSuccess(:final value) => value,
              BodyParseFailure() => {'error': 'Failed to parse'},
            };
          });
        });

        final client = ArcadeTestClient(server.baseUrl);
        final uri = Uri.parse('${server.baseUrl}/urlencoded');
        final request = await HttpClient().postUrl(uri);
        request.headers.contentType = ContentType(
          'application',
          'x-www-form-urlencoded',
        );
        request.write('name=John+Doe&email=john%40example.com&age=30');
        final httpResponse = await request.close();
        final response = await TestResponse.fromResponse(httpResponse);

        expect(response, isOk());
        expect(
          response,
          hasJsonBody({
            'name': 'John Doe',
            'email': 'john@example.com',
            'age': '30',
          }),
        );

        client.close();
      });
    });
  });
}
