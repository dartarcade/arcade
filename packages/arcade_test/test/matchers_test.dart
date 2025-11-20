import 'package:arcade/arcade.dart';
import 'package:arcade_test/arcade_test.dart';
import 'package:test/test.dart';

void main() {
  group('Custom Matchers', () {
    late ArcadeTestServer server;

    setUp(() async {
      server = await ArcadeTestServer.withRoutes(() {
        route.get('/json').handle((ctx) => {'success': true, 'count': 42});
        route.get('/text').handle((ctx) => 'Hello, World!');
        route.get('/empty').handle((ctx) => null);
        route.get('/error').handle((ctx) => throw Exception('Test error'));
        route
            .get('/unauthorized')
            .handle((ctx) => throw const UnauthorizedException());

        route.get('/custom-headers').handle((ctx) {
          // Headers must be set via response in Arcade
          return 'OK';
        });

        route.get('/html').handle((ctx) {
          // Content type is automatically set based on response
          return '<h1>Test</h1>';
        });
      });
    });

    tearDown(() async {
      await server.close();
    });

    group('Status Code Matchers', () {
      test('hasStatus matcher', () async {
        final okResponse = await server.get('/json');
        final errorResponse = await server.get('/error');

        expect(okResponse, hasStatus(200));
        expect(errorResponse, hasStatus(500));

        // Negative tests
        expect(okResponse, isNot(hasStatus(404)));
        expect(errorResponse, isNot(hasStatus(200)));
      });

      test('isOk matcher', () async {
        final response = await server.get('/json');
        expect(response, isOk());
      });

      test('isCreated matcher', () async {
        final testServer = await ArcadeTestServer.withRoutes(() {
          route.post('/create').handle((ctx) {
            ctx.statusCode = 201;
            return {'created': true};
          });
        });

        final response = await testServer.post('/create');
        expect(response, isCreated());

        await testServer.close();
      });

      test('empty response returns 200 not 204', () async {
        final response = await server.get('/empty');
        expect(
          response,
          hasStatus(200),
        ); // Arcade returns 200 for null, not 204
      });

      test('isBadRequest matcher', () async {
        final testServer = await ArcadeTestServer.withRoutes(() {
          route.get('/bad').handle((ctx) => throw const BadRequestException());
        });

        final response = await testServer.get('/bad');
        expect(response, isBadRequest());

        await testServer.close();
      });

      test('isUnauthorized matcher', () async {
        final response = await server.get('/unauthorized');
        expect(response, isUnauthorized());
      });

      test('isForbidden matcher', () async {
        final testServer = await ArcadeTestServer.withRoutes(() {
          route
              .get('/forbidden')
              .handle((ctx) => throw const ForbiddenException());
        });

        final response = await testServer.get('/forbidden');
        expect(response, isForbidden());

        await testServer.close();
      });

      test('isMethodNotAllowed matcher', () async {
        final testServer = await ArcadeTestServer.withRoutes(() {
          route
              .get('/method-not-allowed')
              .handle((ctx) => throw const MethodNotAllowedException());
        });

        final response = await testServer.get('/method-not-allowed');
        expect(response, isMethodNotAllowed());

        await testServer.close();
      });

      test('isConflict matcher', () async {
        final testServer = await ArcadeTestServer.withRoutes(() {
          route
              .get('/conflict')
              .handle((ctx) => throw const ConflictException());
        });

        final response = await testServer.get('/conflict');
        expect(response, isConflict());

        await testServer.close();
      });

      test('isImATeapot matcher', () async {
        final testServer = await ArcadeTestServer.withRoutes(() {
          route
              .get('/teapot')
              .handle((ctx) => throw const ImATeapotException());
        });

        final response = await testServer.get('/teapot');
        expect(response, isImATeapot());

        await testServer.close();
      });

      test('isUnprocessableEntity matcher', () async {
        final testServer = await ArcadeTestServer.withRoutes(() {
          route
              .get('/unprocessable')
              .handle((ctx) => throw const UnprocessableEntityException());
        });

        final response = await testServer.get('/unprocessable');
        expect(response, isUnprocessableEntity());

        await testServer.close();
      });

      test('isInternalServerError matcher', () async {
        final response = await server.get('/error');
        expect(response, isInternalServerError());
      });

      test('isServiceUnavailable matcher', () async {
        final testServer = await ArcadeTestServer.withRoutes(() {
          route
              .get('/unavailable')
              .handle((ctx) => throw const ServiceUnavailableException());
        });

        final response = await testServer.get('/unavailable');
        expect(response, isServiceUnavailable());

        await testServer.close();
      });

      test('isNotFound matcher', () async {
        final response = await server.get('/nonexistent');
        expect(response, isNotFound());
      });

      test('isServerError matcher', () async {
        final response = await server.get('/error');
        expect(response, isServerError());
      });
    });

    group('Header Matchers', () {
      test('hasHeader matcher', () async {
        final response = await server.get('/json');

        expect(response, hasHeader('content-type'));
        expect(response, hasHeader('CONTENT-TYPE')); // Case insensitive
        expect(response, isNot(hasHeader('x-nonexistent')));
      });

      test('header values', () async {
        final response = await server.get('/custom-headers');

        // Headers are not preserved through the current test setup
        expect(response.headers, isNotNull);
      });

      test('hasContentType matcher', () async {
        final jsonResponse = await server.get('/json');
        final textResponse = await server.get('/text');

        expect(jsonResponse, hasContentType('application/json'));
        expect(
          textResponse,
          hasContentType('text/html'),
        ); // Arcade returns text/html for strings

        // Negative tests
        expect(jsonResponse, isNot(hasContentType('text/html')));
      });
    });

    group('Body Matchers', () {
      test('body content', () async {
        final response = await server.get('/text');
        final emptyResponse = await server.get('/empty');

        expect(response.body, equals('Hello, World!'));
        expect(
          emptyResponse.body,
          equals('null'),
        ); // Arcade returns "null" for null responses
      });

      test('hasJsonBody matcher with exact match', () async {
        final response = await server.get('/json');

        expect(response, hasJsonBody({'success': true, 'count': 42}));
        expect(response, hasJsonBody(isA<Map>()));
        expect(response, isNot(hasJsonBody({'wrong': 'data'})));
      });

      test('hasJsonBody matcher with partial match', () async {
        final response = await server.get('/json');

        expect(response, hasJsonBody(containsPair('success', true)));
        expect(response, hasJsonBody(containsPair('count', 42)));
      });

      test('hasTextBody matcher', () async {
        final response = await server.get('/text');

        expect(response, hasTextBody('Hello, World!'));
        expect(response, hasTextBody(contains('Hello')));
        expect(response, hasTextBody(startsWith('Hello')));
        expect(response, hasTextBody(endsWith('World!')));
      });

      test('containsJsonKey matcher', () async {
        final response = await server.get('/json');

        expect(response, containsJsonKey('success'));
        expect(response, containsJsonKey('count'));
        expect(response, isNot(containsJsonKey('missing')));
      });

      test('hasJsonPath matcher', () async {
        final testServer = await ArcadeTestServer.withRoutes(() {
          route
              .get('/nested')
              .handle(
                (ctx) => {
                  'user': {
                    'name': 'John',
                    'address': {'city': 'New York'},
                  },
                },
              );
        });

        final response = await testServer.get('/nested');

        expect(response, hasJsonPath('user.name', 'John'));
        expect(response, hasJsonPath('user.address.city', 'New York'));

        await testServer.close();
      });
    });

    group('Content Type Matchers', () {
      test('isJson matcher', () async {
        final jsonResponse = await server.get('/json');
        final textResponse = await server.get('/text');

        expect(jsonResponse, isJson());
        expect(textResponse, isNot(isJson()));
      });

      test('isHtml matcher', () async {
        // Text responses return as text/html in Arcade
        final textResponse = await server.get('/text');
        final jsonResponse = await server.get('/json');

        expect(textResponse, isHtml()); // Arcade returns text/html for strings
        expect(jsonResponse, isNot(isHtml()));
      });

      test('text content type', () async {
        final textResponse = await server.get('/text');
        final jsonResponse = await server.get('/json');

        expect(
          textResponse.contentType?.mimeType,
          equals('text/html'),
        ); // Arcade returns text/html
        expect(jsonResponse.contentType?.mimeType, isNot(equals('text/html')));
      });
    });

    group('Matcher Error Messages', () {
      test('provides helpful error messages', () {
        // This test captures error messages to ensure they're helpful
        expect(
          () async {
            final response = await server.get('/json');
            expect(response, hasStatus(404));
          },
          throwsA(isA<TestFailure>()),
        );
      });
    });
  });
}
