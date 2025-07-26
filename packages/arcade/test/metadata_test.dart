import 'dart:async';
import 'dart:convert';

import 'package:arcade/arcade.dart';
import 'package:arcade_test/arcade_test.dart';
import 'package:test/test.dart';

// Custom context for testing metadata with extra storage
class TestContext extends RequestContext {
  final Map<String, dynamic> extra = {};

  TestContext.from(RequestContext ctx)
      : super(
          route: ctx.route,
          request: ctx.rawRequest,
        );
}

void main() {
  group('Route Metadata', () {
    late ArcadeTestServer server;

    tearDown(() async {
      await server.close();
    });

    group('Basic Metadata', () {
      test('stores and retrieves metadata on GET routes', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/users',
              extra: {'requiresAuth': true, 'role': 'admin'}).handle((ctx) {
            final metadata = ctx.route.metadata;
            return {
              'type': metadata?.type,
              'path': metadata?.path,
              'method': metadata?.method.name,
              'extra': metadata?.extra,
            };
          });
        });

        final response = await server.get('/users');
        expect(response, isOk());
        expect(
          response,
          hasJsonBody({
            'type': 'handler',
            'path': '/users',
            'method': 'get',
            'extra': {'requiresAuth': true, 'role': 'admin'},
          }),
        );
      });

      test('stores and retrieves metadata on POST routes', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.post('/api/data',
              extra: {'rateLimit': 100, 'version': 'v1'}).handle((ctx) {
            final metadata = ctx.route.metadata;
            return {
              'hasMetadata': metadata != null,
              'rateLimit': metadata?.extra?['rateLimit'],
              'version': metadata?.extra?['version'],
            };
          });
        });

        final response = await server.post('/api/data', body: {'test': true});
        expect(response, isOk());
        expect(
          response,
          hasJsonBody({
            'hasMetadata': true,
            'rateLimit': 100,
            'version': 'v1',
          }),
        );
      });

      test(
          'supports different metadata for different HTTP methods on same path',
          () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/resource', extra: {'operation': 'read'}).handle(
              (ctx) => {'metadata': ctx.route.metadata?.extra});

          route.post('/resource', extra: {'operation': 'create'}).handle(
              (ctx) => {'metadata': ctx.route.metadata?.extra});

          route.put('/resource', extra: {'operation': 'update'}).handle(
              (ctx) => {'metadata': ctx.route.metadata?.extra});

          route.delete('/resource', extra: {'operation': 'delete'}).handle(
              (ctx) => {'metadata': ctx.route.metadata?.extra});
        });

        final getResponse = await server.get('/resource');
        expect(
            getResponse,
            hasJsonBody({
              'metadata': {'operation': 'read'}
            }));

        final postResponse = await server.post('/resource', body: {});
        expect(
            postResponse,
            hasJsonBody({
              'metadata': {'operation': 'create'}
            }));

        final putResponse = await server.put('/resource', body: {});
        expect(
            putResponse,
            hasJsonBody({
              'metadata': {'operation': 'update'}
            }));

        final deleteResponse = await server.delete('/resource');
        expect(
            deleteResponse,
            hasJsonBody({
              'metadata': {'operation': 'delete'}
            }));
      });

      test('handles routes without metadata', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/no-metadata').handle((ctx) {
            return {
              'hasMetadata': ctx.route.metadata != null,
              'extra': ctx.route.metadata?.extra,
            };
          });
        });

        final response = await server.get('/no-metadata');
        expect(response, isOk());
        expect(
          response,
          hasJsonBody({
            'hasMetadata': true,
            'extra': null,
          }),
        );
      });

      test('supports empty metadata map', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/empty-meta', extra: {}).handle((ctx) {
            return {
              'hasExtra': ctx.route.metadata?.extra != null,
              'extraIsEmpty': ctx.route.metadata?.extra?.isEmpty ?? false,
            };
          });
        });

        final response = await server.get('/empty-meta');
        expect(response, isOk());
        expect(
          response,
          hasJsonBody({
            'hasExtra': true,
            'extraIsEmpty': true,
          }),
        );
      });

      test('supports complex metadata structures', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/complex', extra: {
            'auth': {
              'required': true,
              'roles': ['admin', 'moderator'],
              'scopes': ['read', 'write'],
            },
            'rateLimit': {
              'requests': 100,
              'window': 3600,
              'strategy': 'sliding',
            },
            'features': ['beta', 'experimental'],
            'version': 2,
          }).handle((ctx) => ctx.route.metadata?.extra ?? {});
        });

        final response = await server.get('/complex');
        expect(response, isOk());
        expect(
          response,
          hasJsonBody({
            'auth': {
              'required': true,
              'roles': ['admin', 'moderator'],
              'scopes': ['read', 'write'],
            },
            'rateLimit': {
              'requests': 100,
              'window': 3600,
              'strategy': 'sliding',
            },
            'features': ['beta', 'experimental'],
            'version': 2,
          }),
        );
      });
    });

    group('Metadata with Hooks', () {
      test('metadata is accessible in before hooks', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/secure',
              extra: {'requiresAuth': true, 'minRole': 'user'}).before((ctx) {
            final requiresAuth =
                ctx.route.metadata?.extra?['requiresAuth'] == true;
            final minRole = ctx.route.metadata?.extra?['minRole'];

            if (requiresAuth) {
              // Simulate auth check
              final testCtx = TestContext.from(ctx);
              testCtx.extra['authChecked'] = true;
              testCtx.extra['minRole'] = minRole;
              return testCtx;
            }

            return ctx;
          }).handle((ctx) {
            if (ctx is TestContext) {
              return {
                'authChecked': ctx.extra['authChecked'],
                'minRole': ctx.extra['minRole'],
              };
            }
            return {'authChecked': false, 'minRole': null};
          });
        });

        final response = await server.get('/secure');
        expect(response, isOk());
        expect(
          response,
          hasJsonBody({
            'authChecked': true,
            'minRole': 'user',
          }),
        );
      });

      test('metadata is accessible in after hooks', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/logged', extra: {'logLevel': 'debug', 'logEvents': true})
              .handle((ctx) => {'result': 'success'})
              .after((ctx, result) {
                final logLevel = ctx.route.metadata?.extra?['logLevel'];
                final logEvents =
                    ctx.route.metadata?.extra?['logEvents'] == true;

                if (logEvents) {
                  // Simulate logging
                  return (
                    ctx,
                    {
                      'result': result,
                      'logged': true,
                      'logLevel': logLevel,
                    }
                  );
                }

                return (ctx, result);
              });
        });

        final response = await server.get('/logged');
        expect(response, isOk());
        expect(
          response,
          hasJsonBody({
            'result': {'result': 'success'},
            'logged': true,
            'logLevel': 'debug',
          }),
        );
      });

      test('metadata flows through multiple hooks', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/flow', extra: {'step': 0}).before((ctx) {
            final step = ctx.route.metadata?.extra?['step'] as int;
            final testCtx = TestContext.from(ctx);
            testCtx.extra['step1'] = step + 1;
            return testCtx;
          }).before((ctx) {
            final step = ctx.route.metadata?.extra?['step'] as int;
            ctx.extra['step2'] = step + 2;
            return ctx;
          }).handle((RequestContext ctx) {
            final step = ctx.route.metadata?.extra?['step'] as int;
            if (ctx is TestContext) {
              return {
                'originalStep': step,
                'step1': ctx.extra['step1'],
                'step2': ctx.extra['step2'],
              };
            }
            return {'originalStep': step};
          });
        });

        final response = await server.get('/flow');
        expect(response, isOk());
        expect(
          response,
          hasJsonBody({
            'originalStep': 0,
            'step1': 1,
            'step2': 2,
          }),
        );
      });
    });

    group('Metadata with Route Groups', () {
      test('routes in groups have their own metadata', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.group<RequestContext>('/api', defineRoutes: (route) {
            route().get('/v1/users', extra: {
              'version': 1,
              'deprecated': false
            }).handle((ctx) => ctx.route.metadata?.extra ?? {});

            route().get('/v2/users', extra: {
              'version': 2,
              'deprecated': false
            }).handle((ctx) => ctx.route.metadata?.extra ?? {});

            route().get('/v0/users', extra: {
              'version': 0,
              'deprecated': true
            }).handle((ctx) => ctx.route.metadata?.extra ?? {});
          });
        });

        final v1Response = await server.get('/api/v1/users');
        expect(v1Response, hasJsonBody({'version': 1, 'deprecated': false}));

        final v2Response = await server.get('/api/v2/users');
        expect(v2Response, hasJsonBody({'version': 2, 'deprecated': false}));

        final v0Response = await server.get('/api/v0/users');
        expect(v0Response, hasJsonBody({'version': 0, 'deprecated': true}));
      });

      test('nested groups preserve metadata at each level', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.group<RequestContext>('/api', defineRoutes: (route) {
            route().group<RequestContext>('/admin', defineRoutes: (route) {
              route().get('/users', extra: {
                'area': 'admin',
                'resource': 'users',
                'permissions': ['read', 'write', 'delete'],
              }).handle((ctx) => ctx.route.metadata?.extra ?? {});

              route().get('/settings', extra: {
                'area': 'admin',
                'resource': 'settings',
                'permissions': ['read', 'write'],
              }).handle((ctx) => ctx.route.metadata?.extra ?? {});
            });

            route().group<RequestContext>('/public', defineRoutes: (route) {
              route().get('/info', extra: {
                'area': 'public',
                'resource': 'info',
                'permissions': ['read'],
              }).handle((ctx) => ctx.route.metadata?.extra ?? {});
            });
          });
        });

        final adminUsers = await server.get('/api/admin/users');
        expect(
          adminUsers,
          hasJsonBody({
            'area': 'admin',
            'resource': 'users',
            'permissions': ['read', 'write', 'delete'],
          }),
        );

        final adminSettings = await server.get('/api/admin/settings');
        expect(
          adminSettings,
          hasJsonBody({
            'area': 'admin',
            'resource': 'settings',
            'permissions': ['read', 'write'],
          }),
        );

        final publicInfo = await server.get('/api/public/info');
        expect(
          publicInfo,
          hasJsonBody({
            'area': 'public',
            'resource': 'info',
            'permissions': ['read'],
          }),
        );
      });
    });

    group('Metadata with Path Parameters', () {
      test('metadata is available for parameterized routes', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/users/:id', extra: {
            'resource': 'user',
            'paramValidation': {'id': 'uuid'},
          }).handle((ctx) => {
                'params': ctx.pathParameters,
                'metadata': ctx.route.metadata?.extra,
              });
        });

        final response =
            await server.get('/users/123e4567-e89b-12d3-a456-426614174000');
        expect(response, isOk());
        expect(
          response,
          hasJsonBody({
            'params': {'id': '123e4567-e89b-12d3-a456-426614174000'},
            'metadata': {
              'resource': 'user',
              'paramValidation': {'id': 'uuid'},
            },
          }),
        );
      });

      test('metadata works with multiple path parameters', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/posts/:year/:month/:slug', extra: {
            'resource': 'blog-post',
            'cache': true,
            'ttl': 3600,
          }).handle((ctx) => {
                'params': ctx.pathParameters,
                'cacheEnabled': ctx.route.metadata?.extra?['cache'] == true,
                'ttl': ctx.route.metadata?.extra?['ttl'],
              });
        });

        final response = await server.get('/posts/2024/01/hello-world');
        expect(response, isOk());
        expect(
          response,
          hasJsonBody({
            'params': {
              'year': '2024',
              'month': '01',
              'slug': 'hello-world',
            },
            'cacheEnabled': true,
            'ttl': 3600,
          }),
        );
      });
    });

    group('Metadata Use Cases', () {
      test('authorization based on metadata', () async {
        server = await ArcadeTestServer.withRoutes(() {
          // Register global authorization hook
          route.registerGlobalBeforeHook((ctx) {
            final requiredRole = ctx.route.metadata?.extra?['requiredRole'];
            if (requiredRole != null) {
              // Simulate role check
              final userRole =
                  ctx.requestHeaders.value('x-user-role') ?? 'guest';
              if (userRole != requiredRole && userRole != 'admin') {
                throw const ForbiddenException(
                    message: 'Insufficient permissions');
              }
            }
            return ctx;
          });

          route.get('/public').handle((ctx) => {'message': 'Public access'});

          route.get('/users-only', extra: {'requiredRole': 'user'}).handle(
              (ctx) => {'message': 'User access granted'});

          route.get('/admin-only', extra: {'requiredRole': 'admin'}).handle(
              (ctx) => {'message': 'Admin access granted'});
        });

        // Public route - no auth required
        final publicResponse = await server.get('/public');
        expect(publicResponse, isOk());
        expect(publicResponse, hasJsonBody({'message': 'Public access'}));

        // User route without role header
        final noRoleResponse = await server.get('/users-only');
        expect(noRoleResponse, hasStatus(403));

        // User route with user role
        final userResponse = await server.get(
          '/users-only',
          headers: {'x-user-role': 'user'},
        );
        expect(userResponse, isOk());
        expect(userResponse, hasJsonBody({'message': 'User access granted'}));

        // Admin route with user role
        final userToAdminResponse = await server.get(
          '/admin-only',
          headers: {'x-user-role': 'user'},
        );
        expect(userToAdminResponse, hasStatus(403));

        // Admin route with admin role
        final adminResponse = await server.get(
          '/admin-only',
          headers: {'x-user-role': 'admin'},
        );
        expect(adminResponse, isOk());
        expect(adminResponse, hasJsonBody({'message': 'Admin access granted'}));
      });

      test('rate limiting based on metadata', () async {
        final requestCounts = <String, int>{};

        server = await ArcadeTestServer.withRoutes(() {
          // Register global rate limiting hook
          route.registerGlobalBeforeHook((ctx) {
            final rateLimit = ctx.route.metadata?.extra?['rateLimit'] as int?;
            if (rateLimit != null) {
              final path = ctx.route.path;
              final count = requestCounts[path] ?? 0;
              if (count >= rateLimit) {
                // Using ServiceUnavailableException as TooManyRequestsException doesn't exist
                throw const ServiceUnavailableException(
                    message: 'Rate limit exceeded');
              }
              requestCounts[path] = count + 1;
            }
            return ctx;
          });

          route.get('/unlimited').handle((ctx) => {'message': 'No rate limit'});

          route.get('/limited', extra: {'rateLimit': 3}).handle(
              (ctx) => {'message': 'Request processed'});
        });

        // Unlimited endpoint
        for (var i = 0; i < 5; i++) {
          final response = await server.get('/unlimited');
          expect(response, isOk());
        }

        // Limited endpoint - first 3 requests succeed
        for (var i = 0; i < 3; i++) {
          final response = await server.get('/limited');
          expect(response, isOk());
          expect(response, hasJsonBody({'message': 'Request processed'}));
        }

        // Fourth request should fail
        final exceededResponse = await server.get('/limited');
        expect(exceededResponse, hasStatus(503));
      });

      test('API versioning with metadata', () async {
        server = await ArcadeTestServer.withRoutes(() {
          // Version selection based on header
          route.get('/api/users', extra: {
            'versions': {
              'v1': (RequestContext ctx) => {
                    'version': 1,
                    'data': ['user1']
                  },
              'v2': (RequestContext ctx) => {
                    'version': 2,
                    'data': ['user1', 'user2']
                  },
              'v3': (RequestContext ctx) => {
                    'version': 3,
                    'users': [
                      {'id': 1, 'name': 'user1'},
                      {'id': 2, 'name': 'user2'},
                    ]
                  },
            }
          }).handle((ctx) {
            final versions = ctx.route.metadata?.extra?['versions']
                as Map<String, Function>?;
            final requestedVersion =
                ctx.requestHeaders.value('api-version') ?? 'v2';
            final handler = versions?[requestedVersion] as Map<String, dynamic>
                Function(RequestContext)?;

            if (handler != null) {
              return handler(ctx);
            }

            return {'error': 'Unsupported API version'};
          });
        });

        // Default version (v2)
        final defaultResponse = await server.get('/api/users');
        expect(defaultResponse, isOk());
        expect(
            defaultResponse,
            hasJsonBody({
              'version': 2,
              'data': ['user1', 'user2']
            }));

        // v1
        final v1Response =
            await server.get('/api/users', headers: {'api-version': 'v1'});
        expect(v1Response, isOk());
        expect(
            v1Response,
            hasJsonBody({
              'version': 1,
              'data': ['user1']
            }));

        // v3
        final v3Response =
            await server.get('/api/users', headers: {'api-version': 'v3'});
        expect(v3Response, isOk());
        expect(
            v3Response,
            hasJsonBody({
              'version': 3,
              'users': [
                {'id': 1, 'name': 'user1'},
                {'id': 2, 'name': 'user2'},
              ]
            }));

        // Unsupported version
        final v4Response =
            await server.get('/api/users', headers: {'api-version': 'v4'});
        expect(v4Response, isOk());
        expect(v4Response, hasJsonBody({'error': 'Unsupported API version'}));
      });
    });

    group('WebSocket Metadata', () {
      test('WebSocket routes preserve metadata', () async {
        // Initialize WebSocket storage for this test
        await initializeWebSocketStorage();

        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/chat', extra: {
            'protocol': 'chat-v1',
            'maxConnections': 100,
            'features': ['typing-indicators', 'read-receipts'],
          }).handleWebSocket((context, message, manager) {
            final metadata = context.route.metadata?.extra;
            manager.emit(jsonEncode({
              'echo': message,
              'protocol': metadata?['protocol'],
              'features': metadata?['features'],
            }));
          });
        });

        final ws = await server.connectWebSocket('/ws/chat');

        // Start listening for messages before sending
        final messageFuture = ws.messages.first;

        ws.send(null, 'Hello WebSocket');

        final response = await messageFuture.timeout(
          const Duration(seconds: 2),
          onTimeout: () =>
              throw TimeoutException('No WebSocket response received'),
        );
        final data =
            jsonDecode(response.data as String) as Map<String, dynamic>;

        expect(data['echo'], equals('Hello WebSocket'));
        expect(data['protocol'], equals('chat-v1'));
        expect(
            data['features'], equals(['typing-indicators', 'read-receipts']));

        await ws.close();

        // Clean up WebSocket storage
        await disposeWebSocketStorage();
      });
    });

    group('Not Found Routes with Metadata', () {
      test('notFound routes can have metadata', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.notFound(
              (ctx) => {
                    'error': 'Route not found',
                    'path': ctx.path,
                    'metadata': ctx.route.metadata?.extra,
                  },
              extra: {
                'errorType': 'not_found',
                'suggestions': ['/api/users', '/api/posts'],
              });
        });

        final response = await server.get('/non-existent');
        expect(response, hasStatus(404));
        expect(
          response,
          hasJsonBody({
            'error': 'Route not found',
            'path': '/non-existent',
            'metadata': {
              'errorType': 'not_found',
              'suggestions': ['/api/users', '/api/posts'],
            },
          }),
        );
      });
    });

    group('getRouteMetadata Function', () {
      test('can retrieve all route metadata', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/users', extra: {'resource': 'users'}).handle((ctx) => []);
          route.post('/users', extra: {
            'resource': 'users',
            'action': 'create'
          }).handle((ctx) => {});
          route.get('/posts', extra: {'resource': 'posts'}).handle((ctx) => []);

          route.get('/metadata').handle((ctx) {
            final allMetadata = getRouteMetadata();
            // Filter to our test routes
            final testRoutes = allMetadata
                .where((m) =>
                    m.path == '/users' ||
                    m.path == '/posts' ||
                    m.path == '/metadata')
                .map((m) => {
                      'path': m.path,
                      'method': m.method.name,
                      'extra': m.extra,
                    })
                .toList();
            return testRoutes;
          });
        });

        final response = await server.get('/metadata');
        expect(response, isOk());

        final body = response.json() as List;
        expect(body.length, greaterThanOrEqualTo(4)); // At least our 4 routes

        // Check our specific routes exist
        expect(
          body.any((route) {
            if (route is! Map<String, dynamic>) return false;
            return route['path'] == '/users' &&
                route['method'] == 'get' &&
                (route['extra'] as Map<String, dynamic>)['resource'] == 'users';
          }),
          isTrue,
        );

        expect(
          body.any((route) {
            if (route is! Map<String, dynamic>) return false;
            return route['path'] == '/users' &&
                route['method'] == 'post' &&
                (route['extra'] as Map<String, dynamic>)['resource'] ==
                    'users' &&
                (route['extra'] as Map<String, dynamic>)['action'] == 'create';
          }),
          isTrue,
        );

        expect(
          body.any((route) {
            if (route is! Map<String, dynamic>) return false;
            return route['path'] == '/posts' &&
                route['method'] == 'get' &&
                (route['extra'] as Map<String, dynamic>)['resource'] == 'posts';
          }),
          isTrue,
        );
      });
    });
  });
}
