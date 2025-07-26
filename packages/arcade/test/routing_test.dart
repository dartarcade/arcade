import 'package:arcade/arcade.dart';
import 'package:arcade_test/arcade_test.dart';
import 'package:test/test.dart';

void main() {
  group('Routing', () {
    late ArcadeTestServer server;

    tearDown(() async {
      await server.close();
    });

    group('HTTP Methods', () {
      test('GET method routing', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/users').handle((ctx) => {'method': 'GET'});
        });

        final response = await server.get('/users');
        expect(response, isOk());
        expect(response, hasJsonBody({'method': 'GET'}));

        // Test if other methods return 404
        final postResponse = await server.post('/users');
        expect(postResponse, isNotFound());
      });

      test('POST method routing', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.post('/users').handle((ctx) => {'method': 'POST'});
        });

        final response = await server.post('/users');
        expect(response, isOk());
        expect(response, hasJsonBody({'method': 'POST'}));

        // Test if other methods return 404
        final getResponse = await server.get('/users');
        expect(getResponse, isNotFound());
      });

      test('PUT method routing', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.put('/users/1').handle((ctx) => {'method': 'PUT'});
        });

        final response = await server.put('/users/1');
        expect(response, isOk());
        expect(response, hasJsonBody({'method': 'PUT'}));
      });

      test('DELETE method routing', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.delete('/users/1').handle((ctx) => {'method': 'DELETE'});
        });

        final response = await server.delete('/users/1');
        expect(response, isOk());
        expect(response, hasJsonBody({'method': 'DELETE'}));
      });

      test('PATCH method routing', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.patch('/users/1').handle((ctx) => {'method': 'PATCH'});
        });

        final response = await server.patch('/users/1');
        expect(response, isOk());
        expect(response, hasJsonBody({'method': 'PATCH'}));
      });

      test('HEAD method routing', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.head('/status').handle((ctx) => 'OK');
        });

        final response = await server.head('/status');
        expect(response, isOk());
        // HEAD responses don't have body
        expect(response.body, isEmpty);
      });

      test('OPTIONS method routing', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.options('/api').handle((ctx) => {'cors': 'enabled'});
        });

        final response = await server.options('/api');
        expect(response, isOk());
        expect(response, hasJsonBody({'cors': 'enabled'}));
      });

      test('ANY method matches all HTTP methods', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route
              .any('/universal')
              .handle((ctx) => {'method': ctx.method.methodString});
        });

        // Test various methods
        var response = await server.get('/universal');
        expect(response, isOk());
        expect(response, hasJsonBody({'method': 'GET'}));

        response = await server.post('/universal');
        expect(response, isOk());
        expect(response, hasJsonBody({'method': 'POST'}));

        response = await server.put('/universal');
        expect(response, isOk());
        expect(response, hasJsonBody({'method': 'PUT'}));

        response = await server.delete('/universal');
        expect(response, isOk());
        expect(response, hasJsonBody({'method': 'DELETE'}));
      });
    });

    group('Path Parameters', () {
      test('single path parameter', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/users/:id').handle((ctx) {
            return {'userId': ctx.pathParameters['id']};
          });
        });

        final response = await server.get('/users/123');
        expect(response, isOk());
        expect(response, hasJsonBody({'userId': '123'}));
      });

      test('multiple path parameters', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/posts/:postId/comments/:commentId').handle((ctx) {
            return {
              'postId': ctx.pathParameters['postId'],
              'commentId': ctx.pathParameters['commentId'],
            };
          });
        });

        final response = await server.get('/posts/42/comments/7');
        expect(response, isOk());
        expect(response, hasJsonBody({'postId': '42', 'commentId': '7'}));
      });

      test('path parameters with special characters', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/files/:filename').handle((ctx) {
            return {'filename': ctx.pathParameters['filename']};
          });
        });

        final response = await server.get('/files/my-file.txt');
        expect(response, isOk());
        expect(response, hasJsonBody({'filename': 'my-file.txt'}));
      });

      test('path parameters with URL encoding', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/search/:query').handle((ctx) {
            return {'query': ctx.pathParameters['query']};
          });
        });

        final response = await server.get('/search/hello%20world');
        expect(response, isOk());
        expect(response, hasJsonBody({'query': 'hello world'}));
      });
    });

    group('Query Parameters', () {
      test('single query parameter', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/search').handle((ctx) {
            return {'query': ctx.queryParameters['q']};
          });
        });

        final response = await server.get('/search?q=arcade');
        expect(response, isOk());
        expect(response, hasJsonBody({'query': 'arcade'}));
      });

      test('multiple query parameters', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/filter').handle((ctx) {
            return ctx.queryParameters;
          });
        });

        final response =
            await server.get('/filter?status=active&limit=10&sort=name');
        expect(response, isOk());
        expect(
            response,
            hasJsonBody({
              'status': 'active',
              'limit': '10',
              'sort': 'name',
            }));
      });

      test('query parameters with special characters', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/search').handle((ctx) {
            return ctx.queryParameters;
          });
        });

        final response =
            await server.get('/search?q=hello+world&email=test%40example.com');
        expect(response, isOk());
        expect(
            response,
            hasJsonBody({
              'q': 'hello world',
              'email': 'test@example.com',
            }));
      });

      test('empty query parameters', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/test').handle((ctx) {
            return {'count': ctx.queryParameters.length};
          });
        });

        final response = await server.get('/test');
        expect(response, isOk());
        expect(response, hasJsonBody({'count': 0}));
      });
    });

    group('Route Precedence', () {
      test('specific routes match before wildcard routes', () async {
        server = await ArcadeTestServer.withRoutes(() {
          // Register specific route first
          route.get('/users/profile').handle((ctx) => {'type': 'specific'});
          route.get('/users/:id').handle((ctx) => {'type': 'wildcard'});
        });

        // Specific route should match
        var response = await server.get('/users/profile');
        expect(response, isOk());
        expect(response, hasJsonBody({'type': 'specific'}));

        // Wildcard should match other paths
        response = await server.get('/users/123');
        expect(response, isOk());
        expect(response, hasJsonBody({'type': 'wildcard'}));
      });

      test('last matching route wins', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/test').handle((ctx) => {'handler': 'first'});
          route.get('/test').handle((ctx) => {'handler': 'second'});
        });

        final response = await server.get('/test');
        expect(response, isOk());
        expect(response, hasJsonBody({'handler': 'second'}));
      });
    });

    group('Route Groups', () {
      test('basic route group with prefix', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.group(
            '/api',
            defineRoutes: (route) {
              route().get('/users').handle((ctx) => {'endpoint': 'users'});
              route().get('/posts').handle((ctx) => {'endpoint': 'posts'});
            },
          );
        });

        var response = await server.get('/api/users');
        expect(response, isOk());
        expect(response, hasJsonBody({'endpoint': 'users'}));

        response = await server.get('/api/posts');
        expect(response, isOk());
        expect(response, hasJsonBody({'endpoint': 'posts'}));

        // Without prefix should not match
        response = await server.get('/users');
        expect(response, isNotFound());
      });

      test('nested route groups', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.group(
            '/api',
            defineRoutes: (route) {
              route().group(
                '/v1',
                defineRoutes: (route) {
                  route().get('/users').handle((ctx) => {'version': 'v1'});
                },
              );
              route().group(
                '/v2',
                defineRoutes: (route) {
                  route().get('/users').handle((ctx) => {'version': 'v2'});
                },
              );
            },
          );
        });

        var response = await server.get('/api/v1/users');
        expect(response, isOk());
        expect(response, hasJsonBody({'version': 'v1'}));

        response = await server.get('/api/v2/users');
        expect(response, isOk());
        expect(response, hasJsonBody({'version': 'v2'}));
      });

      test('route group with shared hooks', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.group(
            '/api',
            defineRoutes: (route) {
              route().get('/test1').handle((ctx) => {'endpoint': 'test1'});
              route().get('/test2').handle((ctx) => {'endpoint': 'test2'});
            },
            before: [
              (ctx) {
                ctx.responseHeaders.add('X-API-Version', 'v1');
                return ctx;
              }
            ],
          );
        });

        var response = await server.get('/api/test1');
        expect(response, isOk());
        expect(response.header('X-API-Version'), equals('v1'));

        response = await server.get('/api/test2');
        expect(response, isOk());
        expect(response.header('X-API-Version'), equals('v1'));
      });
    });

    group('Special Cases', () {
      test('empty path and slash normalize to same route', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('').handle((ctx) => {'path': 'root'});
          route.get('/').handle((ctx) => {'path': 'slash'});
        });

        // Both '' and '/' normalize to the same path, so the last route wins
        var response = await server.get('');
        expect(response, isOk());
        expect(response, hasJsonBody({'path': 'slash'}));

        response = await server.get('/');
        expect(response, isOk());
        expect(response, hasJsonBody({'path': 'slash'}));
      });

      test('trailing slashes', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/users').handle((ctx) => {'trailing': 'no'});
          route.get('/posts/').handle((ctx) => {'trailing': 'yes'});
        });

        // Test exact matches
        var response = await server.get('/users');
        expect(response, isOk());
        expect(response, hasJsonBody({'trailing': 'no'}));

        response = await server.get('/posts/');
        expect(response, isOk());
        expect(response, hasJsonBody({'trailing': 'yes'}));

        // In arcade, paths are normalized so /users/ matches /users
        response = await server.get('/users/');
        expect(response, isOk());
        expect(response, hasJsonBody({'trailing': 'no'}));

        response = await server.get('/posts');
        expect(response, isOk());
        expect(response, hasJsonBody({'trailing': 'yes'}));
      });

      test('case sensitivity', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/Users').handle((ctx) => {'case': 'upper'});
          route.get('/users').handle((ctx) => {'case': 'lower'});
        });

        var response = await server.get('/Users');
        expect(response, isOk());
        expect(response, hasJsonBody({'case': 'upper'}));

        response = await server.get('/users');
        expect(response, isOk());
        expect(response, hasJsonBody({'case': 'lower'}));
      });

      test('Unicode in paths', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/users/😀').handle((ctx) => {'emoji': true});
          route.get('/こんにちは').handle((ctx) => {'japanese': true});
        });

        var response = await server.get('/users/😀');
        expect(response, isOk());
        expect(response, hasJsonBody({'emoji': true}));

        response = await server.get('/こんにちは');
        expect(response, isOk());
        expect(response, hasJsonBody({'japanese': true}));
      });
    });

    group('Not Found Handling', () {
      test('default 404 response', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/exists').handle((ctx) => 'found');
        });

        final response = await server.get('/does-not-exist');
        expect(response, isNotFound());
        expect(response.isJson, isTrue);
      });

      test('custom not found handler', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/exists').handle((ctx) => 'found');
          route.notFound((ctx) => {'error': 'Custom 404', 'path': ctx.path});
        });

        final response = await server.get('/missing');
        expect(response, isNotFound());
        // Arcade's notFound handler returns plain text representation
        expect(response.text(), contains('Custom 404'));
        expect(response.text(), contains('/missing'));
      });

      test('method not allowed vs not found', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/users').handle((ctx) => 'GET users');
          route.post('/posts').handle((ctx) => 'POST posts');
        });

        // Wrong method should return 404
        var response = await server.post('/users');
        expect(response, isNotFound());

        // Non-existent path
        response = await server.get('/comments');
        expect(response, isNotFound());
      });
    });

    group('Route Metadata', () {
      test('routes can have metadata', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/users',
              extra: {'requiresAuth': true, 'role': 'admin'}).handle((ctx) {
            return {'meta': ctx.route.metadata?.extra};
          });
        });

        final response = await server.get('/users');
        expect(response, isOk());
        expect(
            response,
            hasJsonBody({
              'meta': {'requiresAuth': true, 'role': 'admin'}
            }));
      });

      test('route metadata persists through hooks', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/secure', extra: {'secure': true}).before((ctx) {
            final isSecure = ctx.route.metadata?.extra?['secure'] == true;
            if (isSecure) {
              ctx.responseHeaders.add('X-Secure', 'true');
            }
            return ctx;
          }).handle((ctx) => 'secured');
        });

        final response = await server.get('/secure');
        expect(response, isOk());
        expect(response.header('X-Secure'), equals('true'));
      });
    });
  });
}
