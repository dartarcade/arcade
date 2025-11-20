import 'dart:async';

import 'package:arcade/arcade.dart';
import 'package:arcade_test/arcade_test.dart';
import 'package:test/test.dart';

void main() {
  group('Hooks', () {
    late ArcadeTestServer server;

    tearDown(() async {
      await server.close();
    });

    group('Before Hooks', () {
      test('executes before route handler', () async {
        final executionOrder = <String>[];

        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/test')
              .before((ctx) {
                executionOrder.add('before');
                ctx.responseHeaders.add('X-Before', 'executed');
                return ctx;
              })
              .handle((ctx) {
                executionOrder.add('handler');
                return {'order': executionOrder};
              });
        });

        final response = await server.get('/test');
        expect(response, isOk());
        expect(response.header('X-Before'), equals('executed'));
        expect(
          response,
          hasJsonBody({
            'order': ['before', 'handler'],
          }),
        );
      });

      test('can modify request context', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/user/:id')
              .before((ctx) {
                // Add computed data to context
                ctx.responseHeaders.add('X-User-Id', ctx.pathParameters['id']!);
                return ctx;
              })
              .handle((ctx) {
                return {
                  'userId': ctx.pathParameters['id'],
                  'hasHeader': ctx.responseHeaders.value('X-User-Id') != null,
                };
              });
        });

        final response = await server.get('/user/123');
        expect(response, isOk());
        expect(response.header('X-User-Id'), equals('123'));
        expect(
          response,
          hasJsonBody({
            'userId': '123',
            'hasHeader': true,
          }),
        );
      });

      test('can short-circuit request', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/protected')
              .before((ctx) {
                final token = ctx.requestHeaders.value('authorization');
                if (token != 'Bearer valid-token') {
                  ctx.statusCode = 401;
                  throw const UnauthorizedException(message: 'Invalid token');
                }
                return ctx;
              })
              .handle((ctx) => {'message': 'Protected resource'});
        });

        // Without auth
        var response = await server.get('/protected');
        expect(response.statusCode, equals(401));

        // With auth
        response = await server.get(
          '/protected',
          headers: {'Authorization': 'Bearer valid-token'},
        );
        expect(response, isOk());
        expect(response, hasJsonBody({'message': 'Protected resource'}));
      });

      test('multiple before hooks execute in order', () async {
        final executionOrder = <String>[];

        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/test')
              .before((ctx) {
                executionOrder.add('before1');
                ctx.responseHeaders.add('X-Hook-1', 'true');
                return ctx;
              })
              .before((ctx) {
                executionOrder.add('before2');
                ctx.responseHeaders.add('X-Hook-2', 'true');
                return ctx;
              })
              .before((ctx) {
                executionOrder.add('before3');
                ctx.responseHeaders.add('X-Hook-3', 'true');
                return ctx;
              })
              .handle((ctx) {
                executionOrder.add('handler');
                return {'order': executionOrder};
              });
        });

        final response = await server.get('/test');
        expect(response, isOk());
        expect(response.header('X-Hook-1'), equals('true'));
        expect(response.header('X-Hook-2'), equals('true'));
        expect(response.header('X-Hook-3'), equals('true'));
        expect(
          response,
          hasJsonBody({
            'order': ['before1', 'before2', 'before3', 'handler'],
          }),
        );
      });

      test('async before hooks', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/async')
              .before((ctx) async {
                // Simulate async operation
                await Future.delayed(const Duration(milliseconds: 10));
                ctx.responseHeaders.add('X-Async', 'completed');
                return ctx;
              })
              .handle((ctx) => {'async': 'handled'});
        });

        final response = await server.get('/async');
        expect(response, isOk());
        expect(response.header('X-Async'), equals('completed'));
        expect(response, hasJsonBody({'async': 'handled'}));
      });
    });

    group('After Hooks', () {
      test('executes after route handler', () async {
        final executionOrder = <String>[];

        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/test')
              .handle((ctx) {
                executionOrder.add('handler');
                return {'order': executionOrder};
              })
              .after((ctx, result) {
                executionOrder.add('after');
                ctx.responseHeaders.add('X-After', 'executed');
                // Modify the result
                if (result is Map<String, dynamic>) {
                  final modifiedResult = Map<String, dynamic>.from(result);
                  modifiedResult['afterExecuted'] = true;
                  return (ctx, modifiedResult);
                }
                return (ctx, result);
              });
        });

        final response = await server.get('/test');
        expect(response, isOk());
        expect(response.header('X-After'), equals('executed'));
        // The after hook runs before response serialization, so it's included
        final body = response.json() as Map<String, dynamic>;
        expect(body['order'], equals(['handler', 'after']));
        expect(body['afterExecuted'], isTrue);
      });

      test('can modify response', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/data')
              .handle((ctx) {
                return {'data': 'original'};
              })
              .after((ctx, result) {
                ctx.responseHeaders.add('X-Modified', 'true');
                // Transform the response
                if (result is Map) {
                  return (
                    ctx,
                    {
                      ...result,
                      'modified': true,
                      'timestamp': '2024-01-01',
                    },
                  );
                }
                return (ctx, result);
              });
        });

        final response = await server.get('/data');
        expect(response, isOk());
        expect(response.header('X-Modified'), equals('true'));
        expect(
          response,
          hasJsonBody({
            'data': 'original',
            'modified': true,
            'timestamp': '2024-01-01',
          }),
        );
      });

      test('multiple after hooks execute in order', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/test')
              .handle((ctx) => {'value': 0})
              .after((ctx, result) {
                ctx.responseHeaders.add('X-After-1', 'true');
                if (result is Map<String, dynamic>) {
                  final modifiedResult = Map<String, dynamic>.from(result);
                  modifiedResult['value'] =
                      (modifiedResult['value'] as int) + 1;
                  return (ctx, modifiedResult);
                }
                return (ctx, result);
              })
              .after((ctx, result) {
                ctx.responseHeaders.add('X-After-2', 'true');
                if (result is Map<String, dynamic>) {
                  final modifiedResult = Map<String, dynamic>.from(result);
                  modifiedResult['value'] =
                      (modifiedResult['value'] as int) + 10;
                  return (ctx, modifiedResult);
                }
                return (ctx, result);
              })
              .after((ctx, result) {
                ctx.responseHeaders.add('X-After-3', 'true');
                if (result is Map<String, dynamic>) {
                  final modifiedResult = Map<String, dynamic>.from(result);
                  modifiedResult['value'] =
                      (modifiedResult['value'] as int) + 100;
                  return (ctx, modifiedResult);
                }
                return (ctx, result);
              });
        });

        final response = await server.get('/test');
        expect(response, isOk());
        expect(response.header('X-After-1'), equals('true'));
        expect(response.header('X-After-2'), equals('true'));
        expect(response.header('X-After-3'), equals('true'));
        expect(response, hasJsonBody({'value': 111})); // 0 + 1 + 10 + 100
      });

      test('async after hooks', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/async')
              .handle((ctx) {
                return {'status': 'processing'};
              })
              .after((ctx, result) async {
                // Simulate async operation
                await Future.delayed(const Duration(milliseconds: 10));
                ctx.responseHeaders.add('X-Async-After', 'completed');
                if (result is Map<String, dynamic>) {
                  final modifiedResult = Map<String, dynamic>.from(result);
                  modifiedResult['status'] = 'completed';
                  return (ctx, modifiedResult);
                }
                return (ctx, result);
              });
        });

        final response = await server.get('/async');
        expect(response, isOk());
        expect(response.header('X-Async-After'), equals('completed'));
        expect(response, hasJsonBody({'status': 'completed'}));
      });

      test('after hook with different return types', () async {
        server = await ArcadeTestServer.withRoutes(() {
          // String response
          route.get('/string').handle((ctx) => 'Hello').after((ctx, result) {
            ctx.responseHeaders.add('X-Type', 'string');
            return (ctx, '$result, World!');
          });

          // List response
          route.get('/list').handle((ctx) => [1, 2, 3]).after((ctx, result) {
            ctx.responseHeaders.add('X-Type', 'list');
            if (result is List) {
              return (ctx, [...result, 4, 5]);
            }
            return (ctx, result);
          });

          // Null response
          route.get('/null').handle((ctx) => null).after((ctx, result) {
            ctx.responseHeaders.add('X-Type', 'null');
            return (ctx, result ?? 'default');
          });
        });

        var response = await server.get('/string');
        expect(response, isOk());
        expect(response.text(), equals('Hello, World!'));
        expect(response.header('X-Type'), equals('string'));

        response = await server.get('/list');
        expect(response, isOk());
        expect(response.json(), equals([1, 2, 3, 4, 5]));
        expect(response.header('X-Type'), equals('list'));

        response = await server.get('/null');
        expect(response, isOk());
        expect(response.text(), equals('default'));
        expect(response.header('X-Type'), equals('null'));
      });
    });

    group('Global Hooks', () {
      test('global before hooks apply to all routes', () async {
        server = await ArcadeTestServer.create(() async {
          // Register global before hook
          route.registerGlobalBeforeHook((ctx) {
            ctx.responseHeaders.add('X-Global', 'true');
            ctx.responseHeaders.add('X-Request-Id', '12345');
            return ctx;
          });

          route.get('/endpoint1').handle((ctx) => {'endpoint': 1});
          route.get('/endpoint2').handle((ctx) => {'endpoint': 2});
          route.post('/endpoint3').handle((ctx) => {'endpoint': 3});
        });

        var response = await server.get('/endpoint1');
        expect(response, isOk());
        expect(response.header('X-Global'), equals('true'));
        expect(response.header('X-Request-Id'), equals('12345'));

        response = await server.get('/endpoint2');
        expect(response, isOk());
        expect(response.header('X-Global'), equals('true'));
        expect(response.header('X-Request-Id'), equals('12345'));

        response = await server.post('/endpoint3');
        expect(response, isOk());
        expect(response.header('X-Global'), equals('true'));
        expect(response.header('X-Request-Id'), equals('12345'));
      });

      test('global after hooks apply to all routes', () async {
        server = await ArcadeTestServer.create(() async {
          // Register global after hook
          route.registerGlobalAfterHook((ctx, result) {
            ctx.responseHeaders.add('X-Processed', 'true');
            ctx.responseHeaders.add('X-Timestamp', '2024-01-01');
            return (ctx, result);
          });

          route.get('/data1').handle((ctx) => {'id': 1});
          route.get('/data2').handle((ctx) => {'id': 2});
        });

        var response = await server.get('/data1');
        expect(response, isOk());
        expect(response.header('X-Processed'), equals('true'));
        expect(response.header('X-Timestamp'), equals('2024-01-01'));

        response = await server.get('/data2');
        expect(response, isOk());
        expect(response.header('X-Processed'), equals('true'));
        expect(response.header('X-Timestamp'), equals('2024-01-01'));
      });

      test('global hooks execute before route-specific hooks', () async {
        final executionOrder = <String>[];

        server = await ArcadeTestServer.create(() async {
          // Global hooks
          route.registerGlobalBeforeHook((ctx) {
            executionOrder.add('global-before');
            return ctx;
          });

          route.registerGlobalAfterHook((ctx, result) {
            executionOrder.add('global-after');
            return (ctx, result);
          });

          // Route with its own hooks
          route
              .get('/test')
              .before((ctx) {
                executionOrder.add('route-before');
                return ctx;
              })
              .handle((ctx) {
                executionOrder.add('handler');
                return {'order': executionOrder};
              })
              .after((ctx, result) {
                executionOrder.add('route-after');
                return (ctx, result);
              });
        });

        final response = await server.get('/test');
        expect(response, isOk());
        // Global before -> Route before -> Handler -> Global after -> Route after
        expect(
          response,
          hasJsonBody({
            'order': [
              'global-before',
              'route-before',
              'handler',
              'global-after',
              'route-after',
            ],
          }),
        );
      });

      test('multiple global hooks', () async {
        server = await ArcadeTestServer.create(() async {
          // Register multiple global hooks
          route.registerAllGlobalBeforeHooks([
            (ctx) {
              ctx.responseHeaders.add('X-Hook-1', 'true');
              return ctx;
            },
            (ctx) {
              ctx.responseHeaders.add('X-Hook-2', 'true');
              return ctx;
            },
          ]);

          route.registerAllGlobalAfterHooks([
            (ctx, result) {
              ctx.responseHeaders.add('X-After-1', 'true');
              return (ctx, result);
            },
            (ctx, result) {
              ctx.responseHeaders.add('X-After-2', 'true');
              return (ctx, result);
            },
          ]);

          route.get('/test').handle((ctx) => {'status': 'ok'});
        });

        final response = await server.get('/test');
        expect(response, isOk());
        expect(response.header('X-Hook-1'), equals('true'));
        expect(response.header('X-Hook-2'), equals('true'));
        expect(response.header('X-After-1'), equals('true'));
        expect(response.header('X-After-2'), equals('true'));
      });
    });

    group('Hook Error Handling', () {
      test('before hook throwing exception', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/error')
              .before((ctx) {
                throw const BadRequestException(
                  message: 'Invalid request from hook',
                );
              })
              .handle((ctx) => {'message': 'Should not reach here'});
        });

        final response = await server.get('/error');
        expect(response.statusCode, equals(400));
        final body = response.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['message'], contains('Invalid request from hook'));
      });

      test('after hook throwing exception', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/error')
              .handle((ctx) {
                return {'status': 'ok'};
              })
              .after((ctx, result) {
                throw const InternalServerErrorException(
                  message: 'After hook error',
                );
              });
        });

        final response = await server.get('/error');
        expect(response.statusCode, equals(500));
        final body = response.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['message'], contains('After hook error'));
      });

      test('async hook errors', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/async-error')
              .before((ctx) async {
                await Future.delayed(const Duration(milliseconds: 10));
                throw const ForbiddenException(message: 'Async forbidden');
              })
              .handle((ctx) => {'message': 'Should not reach here'});
        });

        final response = await server.get('/async-error');
        expect(response.statusCode, equals(403));
        final body = response.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['message'], contains('Async forbidden'));
      });
    });

    group('Hook Use Cases', () {
      test('authentication hook', () async {
        // Simple auth check hook
        BeforeHookHandler requireAuth() {
          return (ctx) {
            final authHeader = ctx.requestHeaders.value('authorization');
            if (authHeader == null || !authHeader.startsWith('Bearer ')) {
              throw const UnauthorizedException(
                message: 'Authentication required',
              );
            }

            // Extract token and add user info to headers (simplified)
            final token = authHeader.substring(7);
            if (token == 'admin-token') {
              ctx.responseHeaders.add('X-User-Role', 'admin');
            } else if (token == 'user-token') {
              ctx.responseHeaders.add('X-User-Role', 'user');
            } else {
              throw const UnauthorizedException(message: 'Invalid token');
            }

            return ctx;
          };
        }

        server = await ArcadeTestServer.withRoutes(() {
          route.get('/public').handle((ctx) => {'message': 'Public content'});

          route
              .get('/protected')
              .before(requireAuth())
              .handle((ctx) => {'message': 'Protected content'});

          route
              .get('/admin')
              .before(requireAuth())
              .before((ctx) {
                // Additional admin check
                if (ctx.responseHeaders.value('X-User-Role') != 'admin') {
                  throw const ForbiddenException(
                    message: 'Admin access required',
                  );
                }
                return ctx;
              })
              .handle((ctx) => {'message': 'Admin content'});
        });

        // Public endpoint
        var response = await server.get('/public');
        expect(response, isOk());

        // Protected without auth
        response = await server.get('/protected');
        expect(response.statusCode, equals(401));

        // Protected with user auth
        response = await server.get(
          '/protected',
          headers: {'Authorization': 'Bearer user-token'},
        );
        expect(response, isOk());

        // Admin with user auth
        response = await server.get(
          '/admin',
          headers: {'Authorization': 'Bearer user-token'},
        );
        expect(response.statusCode, equals(403));

        // Admin with admin auth
        response = await server.get(
          '/admin',
          headers: {'Authorization': 'Bearer admin-token'},
        );
        expect(response, isOk());
      });

      test('logging hook', () async {
        final logs = <Map<String, dynamic>>[];

        AfterHookHandler loggingHook() {
          return (ctx, result) {
            logs.add({
              'method': ctx.method.methodString,
              'path': ctx.path,
              'status': ctx.statusCode,
              'timestamp': DateTime.now().toIso8601String(),
            });
            return (ctx, result);
          };
        }

        server = await ArcadeTestServer.create(() async {
          route.registerGlobalAfterHook(loggingHook());

          route.get('/success').handle((ctx) => {'status': 'ok'});
          route.get('/error').handle((ctx) {
            ctx.statusCode = 500;
            return {'error': 'Something went wrong'};
          });
        });

        await server.get('/success');
        await server.get('/error');

        expect(logs.length, equals(2));
        expect(logs[0]['method'], equals('GET'));
        expect(logs[0]['path'], equals('/success'));
        expect(logs[0]['status'], equals(200));
        expect(logs[1]['path'], equals('/error'));
        expect(logs[1]['status'], equals(500));
      });

      test('CORS hook', () async {
        BeforeHookHandler corsHook() {
          return (ctx) {
            ctx.responseHeaders.add('Access-Control-Allow-Origin', '*');
            ctx.responseHeaders.add(
              'Access-Control-Allow-Methods',
              'GET, POST, PUT, DELETE, OPTIONS',
            );
            ctx.responseHeaders.add(
              'Access-Control-Allow-Headers',
              'Content-Type, Authorization',
            );

            // Handle preflight
            if (ctx.method == HttpMethod.options) {
              ctx.statusCode = 204;
              // For OPTIONS, we need to prevent the handler from running
              // by throwing an exception that results in 204
              throw const ArcadeHttpException('', 204);
            }

            return ctx;
          };
        }

        server = await ArcadeTestServer.create(() async {
          route.registerGlobalBeforeHook(corsHook());

          route.get('/api/data').handle((ctx) => {'data': 'test'});
          route.post('/api/data').handle((ctx) => {'created': true});
          route.options('/api/data').handle((ctx) => null);
        });

        // Regular request
        var response = await server.get('/api/data');
        expect(response, isOk());
        expect(response.header('Access-Control-Allow-Origin'), equals('*'));

        // OPTIONS request (preflight)
        response = await server.options('/api/data');
        expect(response.statusCode, equals(204));
        expect(
          response.header('Access-Control-Allow-Methods'),
          contains('GET'),
        );
        expect(response.body, isEmpty);
      });

      test('rate limiting hook', () async {
        final requestCounts = <String, int>{};
        final requestTimes = <String, DateTime>{};

        BeforeHookHandler rateLimitHook({
          int limit = 5,
          Duration window = const Duration(minutes: 1),
        }) {
          return (ctx) {
            final clientId =
                ctx.requestHeaders.value('x-client-id') ?? 'anonymous';
            final now = DateTime.now();

            // Reset count if window expired
            final lastRequest = requestTimes[clientId];
            if (lastRequest != null && now.difference(lastRequest) > window) {
              requestCounts[clientId] = 0;
            }

            // Check rate limit
            final count = (requestCounts[clientId] ?? 0) + 1;
            if (count > limit) {
              ctx.statusCode = 503;
              throw const ServiceUnavailableException(
                message: 'Rate limit exceeded',
              );
            }

            // Update counts
            requestCounts[clientId] = count;
            requestTimes[clientId] = now;

            // Add rate limit headers
            ctx.responseHeaders.add('X-RateLimit-Limit', limit.toString());
            ctx.responseHeaders.add(
              'X-RateLimit-Remaining',
              (limit - count).toString(),
            );

            return ctx;
          };
        }

        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/api/limited')
              .before(rateLimitHook(limit: 3))
              .handle((ctx) => {'message': 'Success'});
        });

        // Make requests with same client ID
        for (var i = 1; i <= 3; i++) {
          final response = await server.get(
            '/api/limited',
            headers: {'X-Client-Id': 'test-client'},
          );
          expect(response, isOk());
          expect(response.header('X-RateLimit-Limit'), equals('3'));
          expect(
            response.header('X-RateLimit-Remaining'),
            equals((3 - i).toString()),
          );
        }

        // Fourth request should be rate limited
        final response = await server.get(
          '/api/limited',
          headers: {'X-Client-Id': 'test-client'},
        );
        expect(response.statusCode, equals(503));
      });
    });
  });
}
