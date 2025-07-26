// ignore_for_file: invalid_use_of_internal_member

import 'package:arcade/arcade.dart';
import 'package:arcade_swagger/arcade_swagger.dart';
import 'package:arcade_test/arcade_test.dart';
import 'package:luthor/luthor.dart';
import 'package:test/test.dart';

void main() {
  group('Swagger Route Recognition', () {
    test('only includes routes with swagger metadata', () async {
      final server = await ArcadeTestServer.withRoutes(() {
        route.get('/api/v1/users').handle((context) => {'users': []});
        route.post('/api/v1/users').handle((context) => {'id': 1});
        route
            .get('/api/v1/users/:id')
            .handle((context) => {'id': context.pathParameters['id']});

        // Setup swagger after routes are defined
        setupSwagger(
          title: 'Test API',
          version: '1.0.0',
        );
      });

      final response = await server.get('/doc');
      expect(response.statusCode, equals(200));

      final openApiSpec = response.json();
      expect(openApiSpec['info']['title'], equals('Test API'));
      expect(openApiSpec['paths'], isNotNull);

      // Routes without swagger metadata are not included in OpenAPI spec
      expect(openApiSpec['paths'].keys, isEmpty);

      await server.close();
    });

    test('recognizes routes with swagger metadata', () async {
      final server = await ArcadeTestServer.withRoutes(() {
        route
            .swagger(
              summary: 'Get all users',
              description: 'Returns a list of all users',
              tags: ['users'],
              responses: {
                '200': l.schema({
                  'users': l.list(validators: [
                    l.schema({
                      'id': l.int(),
                      'name': l.string(),
                    }),
                  ]),
                }).required(),
              },
            )
            .get('/api/users')
            .handle((context) => {'users': []});

        route
            .swagger(
              summary: 'Create user',
              description: 'Creates a new user',
              tags: ['users'],
              request: l.schema({
                'name': l.string().required(),
                'email': l.string().email().required(),
              }),
              responses: {
                '201': l.schema({
                  'id': l.int(),
                  'name': l.string(),
                  'email': l.string(),
                }).required(),
              },
            )
            .post('/api/users')
            .handle((context) =>
                {'id': 1, 'name': 'John', 'email': 'john@example.com'});

        setupSwagger(
          title: 'User API',
          version: '1.0.0',
        );
      });

      final response = await server.get('/doc');
      expect(response.statusCode, equals(200));

      final openApiSpec = response.json();
      final paths = openApiSpec['paths'] as Map<String, dynamic>;

      // Check that routes are recognized
      expect(paths.keys, containsAll(['/api/users']));

      // Check GET endpoint
      final getUsersPath = paths['/api/users']['get'];
      expect(getUsersPath['summary'], equals('Get all users'));
      expect(
          getUsersPath['description'], equals('Returns a list of all users'));
      expect(getUsersPath['tags'], equals(['users']));

      // Check POST endpoint
      final createUserPath = paths['/api/users']['post'];
      expect(createUserPath['summary'], equals('Create user'));
      expect(createUserPath['description'], equals('Creates a new user'));
      expect(createUserPath['tags'], equals(['users']));
      expect(createUserPath['requestBody'], isNotNull);

      await server.close();
    });

    test('handles multiple routes with different metadata', () async {
      final server = await ArcadeTestServer.withRoutes(() {
        // Route with full swagger metadata
        route
            .swagger(
              summary: 'Health check',
              description: 'Returns service health status',
              responses: {
                '200': l.schema({
                  'status': l.string(),
                  'timestamp': l.string(),
                }).required(),
              },
            )
            .get('/health')
            .handle((context) => {
                  'status': 'ok',
                  'timestamp': DateTime.now().toIso8601String()
                });

        // Route with partial swagger metadata
        route
            .swagger(
              summary: 'Get version',
              responses: {
                '200': l.schema({
                  'version': l.string(),
                }).required(),
              },
            )
            .get('/version')
            .handle((context) => {'version': '1.0.0'});

        // Route without swagger metadata
        route.get('/internal/metrics').handle((context) => {'requests': 100});

        // Route with complex path parameters
        route
            .swagger(
              summary: 'Get resource',
              parameters: [
                const Parameter.path(
                  name: 'category',
                  schema: Schema.string(),
                ),
                const Parameter.path(
                  name: 'id',
                  schema: Schema.string(),
                ),
              ],
              responses: {
                '200': l.schema({
                  'resource': l.map(),
                }).required(),
              },
            )
            .get('/api/:category/:id')
            .handle((context) => {
                  'resource': {
                    'category': context.pathParameters['category'],
                    'id': context.pathParameters['id'],
                  }
                });

        setupSwagger(
          title: 'Mixed Routes API',
          version: '1.0.0',
        );
      });

      final response = await server.get('/doc');
      expect(response.statusCode, equals(200));

      final openApiSpec = response.json();
      final paths = openApiSpec['paths'] as Map<String, dynamic>;

      // Only routes with swagger metadata should be recognized
      expect(
          paths.keys,
          containsAll([
            '/health',
            '/version',
            '/api/{category}/{id}',
          ]));

      // Route without swagger metadata should not be included
      expect(paths.keys, isNot(contains('/internal/metrics')));

      // Routes with swagger metadata should have their details
      expect(paths['/health']['get']['summary'], equals('Health check'));
      expect(paths['/version']['get']['summary'], equals('Get version'));

      // Path parameters should be properly converted
      expect(paths['/api/{category}/{id}'], isNotNull);

      await server.close();
    });

    test('handles route groups with swagger metadata', () async {
      final server = await ArcadeTestServer.withRoutes(() {
        route.group<RequestContext>(
          '/api/v1',
          defineRoutes: (route) {
            route()
                .swagger(
                  summary: 'List products',
                  tags: ['products'],
                  responses: {
                    '200': l.schema({
                      'products': l.list(validators: [l.map()]),
                    }).required(),
                  },
                )
                .get('/products')
                .handle((context) => {'products': []});

            route()
                .swagger(
                  summary: 'Get product by ID',
                  tags: ['products'],
                  responses: {
                    '200': l.schema({
                      'id': l.string(),
                      'name': l.string(),
                    }).required(),
                  },
                )
                .get('/products/:id')
                .handle((context) => {
                      'id': context.pathParameters['id'],
                      'name': 'Product ${context.pathParameters['id']}',
                    });
          },
        );

        setupSwagger(
          title: 'Grouped Routes API',
          version: '1.0.0',
        );
      });

      final response = await server.get('/doc');
      expect(response.statusCode, equals(200));

      final openApiSpec = response.json();
      final paths = openApiSpec['paths'] as Map<String, dynamic>;

      // Group routes should be recognized with full path
      expect(
          paths.keys,
          containsAll([
            '/api/v1/products',
            '/api/v1/products/{id}',
          ]));

      expect(
          paths['/api/v1/products']['get']['summary'], equals('List products'));
      expect(paths['/api/v1/products/{id}']['get']['summary'],
          equals('Get product by ID'));

      await server.close();
    });

    test('handles late route registration', () async {
      final server = await ArcadeTestServer.withRoutes(() {
        // First set of routes
        route
            .swagger(
              summary: 'First route',
              responses: {
                '200': l.schema({'message': l.string()}).required()
              },
            )
            .get('/first')
            .handle((context) => {'message': 'first'});

        // Setup swagger
        setupSwagger(
          title: 'Late Registration API',
          version: '1.0.0',
        );

        // Routes added after swagger setup should still be recognized
        route
            .swagger(
              summary: 'Second route',
              responses: {
                '200': l.schema({'message': l.string()}).required()
              },
            )
            .get('/second')
            .handle((context) => {'message': 'second'});
      });

      final response = await server.get('/doc');
      expect(response.statusCode, equals(200));

      final openApiSpec = response.json();
      final paths = openApiSpec['paths'] as Map<String, dynamic>;

      // Only the first route (before setupSwagger) should be recognized
      expect(paths.keys, contains('/first'));
      expect(paths['/first']['get']['summary'], equals('First route'));

      // The second route (after setupSwagger) is not captured
      expect(paths.keys, isNot(contains('/second')));

      await server.close();
    });

    test('verifies extra metadata persistence (regression test)', () async {
      final server = await ArcadeTestServer.withRoutes(() {
        // This specifically tests the withExtra bug
        route
            .swagger(
              summary: 'Test extra persistence',
              description:
                  'This tests that swagger metadata is properly stored',
              deprecated: true,
              tags: ['test'],
              responses: {
                '200': l.schema({
                  'success': l.boolean(),
                }).required(),
              },
            )
            .get('/test-extra')
            .handle((context) => {'success': true});

        // Add another route with different metadata to ensure isolation
        route
            .swagger(
              summary: 'Another route',
              tags: ['other'],
              responses: {
                '200': l.schema({
                  'data': l.string(),
                }).required(),
              },
            )
            .get('/other')
            .handle((context) => {'data': 'test'});

        setupSwagger(
          title: 'Extra Metadata Test',
          version: '1.0.0',
        );
      });

      final response = await server.get('/doc');
      expect(response.statusCode, equals(200));

      final openApiSpec = response.json();
      final paths = openApiSpec['paths'] as Map<String, dynamic>;

      // Check that extra metadata is properly persisted
      final testExtraPath = paths['/test-extra']['get'];
      expect(testExtraPath['summary'], equals('Test extra persistence'));
      expect(testExtraPath['description'],
          equals('This tests that swagger metadata is properly stored'));
      expect(testExtraPath['deprecated'], equals(true));
      expect(testExtraPath['tags'], equals(['test']));

      // Check isolation between routes
      final otherPath = paths['/other']['get'];
      expect(otherPath['summary'], equals('Another route'));
      expect(otherPath['tags'], equals(['other']));
      expect(otherPath['deprecated'],
          isNull); // Should not inherit from previous route

      await server.close();
    });

    test('swagger UI endpoint is accessible', () async {
      final server = await ArcadeTestServer.withRoutes(() {
        route
            .swagger(
              summary: 'Test endpoint',
              responses: {
                '200': l.schema({'test': l.boolean()}).required()
              },
            )
            .get('/test')
            .handle((context) => {'test': true});

        setupSwagger(
          title: 'UI Test API',
          version: '1.0.0',
          uiPath: '/swagger-ui',
          docPath: '/api-docs',
        );
      });

      // Test custom doc path
      final docResponse = await server.get('/api-docs');
      expect(docResponse.statusCode, equals(200));
      expect(docResponse.json()['info']['title'], equals('UI Test API'));

      // Test custom UI path
      final uiResponse = await server.get('/swagger-ui');
      expect(uiResponse.statusCode, equals(200));
      expect(uiResponse.headers['content-type']?.first, contains('text/html'));

      await server.close();
    });
  });
}
