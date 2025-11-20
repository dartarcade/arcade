// ignore_for_file: invalid_use_of_internal_member

import 'package:arcade/arcade.dart';
import 'package:arcade_test/arcade_test.dart';
import 'package:test/test.dart';

void main() {
  group('Basic Arcade Test Package Functionality', () {
    test('Simple GET request works', () async {
      final server = await ArcadeTestServer.withRoutes(() {
        route.get('/hello').handle((context) => {'message': 'Hello, World!'});
      });

      final response = await server.get('/hello');

      expect(response.statusCode, equals(200));
      expect(response.isJson, isTrue);
      expect(response.json(), equals({'message': 'Hello, World!'}));

      await server.close();
    });

    test('POST request with body works', () async {
      final server = await ArcadeTestServer.withRoutes(() {
        route.post('/echo').handle((context) async {
          final bodyResult = await context.jsonMap();
          return switch (bodyResult) {
            BodyParseSuccess(value: final value) => value,
            BodyParseFailure(error: final error) => {
              'error': 'Parse error: $error',
            },
          };
        });
      });

      final response = await server.post('/echo', body: {'test': 'data'});

      expect(response.statusCode, equals(200));
      expect(response.json(), equals({'test': 'data'}));

      await server.close();
    });

    test('Path parameters work', () async {
      final server = await ArcadeTestServer.withRoutes(() {
        route.get('/users/:id').handle((context) {
          final id = context.pathParameters['id'];
          return {'userId': id, 'name': 'User $id'};
        });
      });

      final response = await server.get('/users/42');

      expect(response.statusCode, equals(200));
      expect(response.json(), equals({'userId': '42', 'name': 'User 42'}));

      await server.close();
    });

    test('Custom matchers work', () async {
      final server = await ArcadeTestServer.withRoutes(() {
        route.get('/test').handle((context) => {'result': 'success'});
      });

      final response = await server.get('/test');

      expect(response, hasStatus(200));
      expect(response, isJson());
      expect(response, hasJsonBody({'result': 'success'}));
      expect(response, containsJsonKey('result'));
      expect(response, hasContentType('application/json'));

      await server.close();
    });

    test('State isolation between tests', () async {
      // This test should start with clean state
      expect(routes.length, equals(0));

      final server = await ArcadeTestServer.withRoutes(() {
        route.get('/isolated').handle((context) => {'isolated': true});
      });

      expect(routes.length, greaterThan(0));

      await server.close();

      // State should be cleaned up after close
      expect(routes.length, equals(0));
    });
  });
}
