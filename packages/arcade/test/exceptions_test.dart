import 'package:arcade/arcade.dart';
import 'package:arcade_test/arcade_test.dart';
import 'package:test/test.dart';

void main() {
  group('Exceptions', () {
    late ArcadeTestServer server;

    tearDown(() async {
      await server.close();
    });

    group('HTTP Exception Types', () {
      test('BadRequestException returns 400', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/bad-request').handle((ctx) {
            throw const BadRequestException(message: 'Invalid input');
          });
        });

        final response = await server.get('/bad-request');
        expect(response.statusCode, equals(400));
        final body = response.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['statusCode'], equals(400));
        expect(error['message'], equals('Invalid input'));
      });

      test('UnauthorizedException returns 401', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/unauthorized').handle((ctx) {
            throw const UnauthorizedException(message: 'Please login');
          });
        });

        final response = await server.get('/unauthorized');
        expect(response.statusCode, equals(401));
        final body = response.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['statusCode'], equals(401));
        expect(error['message'], equals('Please login'));
      });

      test('ForbiddenException returns 403', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/forbidden').handle((ctx) {
            throw const ForbiddenException(message: 'Access denied');
          });
        });

        final response = await server.get('/forbidden');
        expect(response.statusCode, equals(403));
        final body = response.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['statusCode'], equals(403));
        expect(error['message'], equals('Access denied'));
      });

      test('NotFoundException returns 404', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/not-found').handle((ctx) {
            throw const NotFoundException(message: 'Resource not found');
          });
        });

        final response = await server.get('/not-found');
        expect(response.statusCode, equals(404));
        final body = response.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['statusCode'], equals(404));
        expect(error['message'], equals('Resource not found'));
      });

      test('MethodNotAllowedException returns 405', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/method-not-allowed').handle((ctx) {
            throw const MethodNotAllowedException(
              message: 'Method not supported',
            );
          });
        });

        final response = await server.get('/method-not-allowed');
        expect(response.statusCode, equals(405));
        final body = response.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['statusCode'], equals(405));
        expect(error['message'], equals('Method not supported'));
      });

      test('ConflictException returns 409', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/conflict').handle((ctx) {
            throw const ConflictException(message: 'Resource conflict');
          });
        });

        final response = await server.get('/conflict');
        expect(response.statusCode, equals(409));
        final body = response.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['statusCode'], equals(409));
        expect(error['message'], equals('Resource conflict'));
      });

      test('ImATeapotException returns 418', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/teapot').handle((ctx) {
            throw const ImATeapotException(message: 'I refuse to brew coffee');
          });
        });

        final response = await server.get('/teapot');
        expect(response.statusCode, equals(418));
        final body = response.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['statusCode'], equals(418));
        expect(error['message'], equals('I refuse to brew coffee'));
      });

      test('UnprocessableEntityException returns 422', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/unprocessable').handle((ctx) {
            throw const UnprocessableEntityException(
              message: 'Validation failed',
            );
          });
        });

        final response = await server.get('/unprocessable');
        expect(response.statusCode, equals(422));
        final body = response.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['statusCode'], equals(422));
        expect(error['message'], equals('Validation failed'));
      });

      test('InternalServerErrorException returns 500', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/internal-error').handle((ctx) {
            throw const InternalServerErrorException(
              message: 'Something went wrong',
            );
          });
        });

        final response = await server.get('/internal-error');
        expect(response.statusCode, equals(500));
        final body = response.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['statusCode'], equals(500));
        expect(error['message'], equals('Something went wrong'));
      });

      test('ServiceUnavailableException returns 503', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/unavailable').handle((ctx) {
            throw const ServiceUnavailableException(
              message: 'Service temporarily unavailable',
            );
          });
        });

        final response = await server.get('/unavailable');
        expect(response.statusCode, equals(503));
        final body = response.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['statusCode'], equals(503));
        expect(error['message'], equals('Service temporarily unavailable'));
      });
    });

    group('Exception with Errors', () {
      test('exception can include additional error details', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.post('/validate').handle((ctx) {
            throw const BadRequestException(
              message: 'Validation failed',
              errors: {
                'email': 'Invalid email format',
                'password': 'Password too short',
              },
            );
          });
        });

        final response = await server.post('/validate');
        expect(response.statusCode, equals(400));
        final body = response.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['message'], equals('Validation failed'));
        expect(error['errors'], {
          'email': 'Invalid email format',
          'password': 'Password too short',
        });
      });

      test('nested error objects', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.post('/complex-error').handle((ctx) {
            throw const UnprocessableEntityException(
              message: 'Complex validation failed',
              errors: {
                'user': {
                  'profile': {
                    'age': 'Must be a number',
                    'email': 'Required field',
                  },
                },
                'settings': {'notifications': 'Invalid value'},
              },
            );
          });
        });

        final response = await server.post('/complex-error');
        expect(response.statusCode, equals(422));
        final body = response.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['errors'], isA<Map<String, dynamic>>());
        final errors = error['errors'] as Map<String, dynamic>;
        expect(errors['user'], isA<Map<String, dynamic>>());
        final userErrors = errors['user'] as Map<String, dynamic>;
        expect(userErrors['profile'], isA<Map<String, dynamic>>());
      });
    });

    group('Default Messages', () {
      test('exceptions use default messages when not provided', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/default-bad-request').handle((ctx) {
            throw const BadRequestException();
          });
          route.get('/default-unauthorized').handle((ctx) {
            throw const UnauthorizedException();
          });
          route.get('/default-forbidden').handle((ctx) {
            throw const ForbiddenException();
          });
        });

        var response = await server.get('/default-bad-request');
        var body = response.json() as Map<String, dynamic>;
        var error = body['error'] as Map<String, dynamic>;
        expect(error['message'], equals('Bad request'));

        response = await server.get('/default-unauthorized');
        body = response.json() as Map<String, dynamic>;
        error = body['error'] as Map<String, dynamic>;
        expect(error['message'], equals('Unauthorized'));

        response = await server.get('/default-forbidden');
        body = response.json() as Map<String, dynamic>;
        error = body['error'] as Map<String, dynamic>;
        expect(error['message'], equals('Forbidden'));
      });
    });

    group('Exception Handling in Different Contexts', () {
      test('exceptions in async handlers', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/async-error').handle((ctx) async {
            await Future.delayed(const Duration(milliseconds: 10));
            throw const InternalServerErrorException(
              message: 'Async operation failed',
            );
          });
        });

        final response = await server.get('/async-error');
        expect(response.statusCode, equals(500));
        final body = response.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['message'], equals('Async operation failed'));
      });

      test('exceptions in before hooks', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/hook-error')
              .before((ctx) {
                throw const UnauthorizedException(
                  message: 'Hook validation failed',
                );
              })
              .handle((ctx) => {'message': 'Should not reach here'});
        });

        final response = await server.get('/hook-error');
        expect(response.statusCode, equals(401));
        final body = response.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['message'], equals('Hook validation failed'));
      });

      test('exceptions in after hooks', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/after-hook-error')
              .handle((ctx) {
                return {'status': 'ok'};
              })
              .after((ctx, result) {
                throw const InternalServerErrorException(
                  message: 'Post-processing failed',
                );
              });
        });

        final response = await server.get('/after-hook-error');
        expect(response.statusCode, equals(500));
        final body = response.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['message'], equals('Post-processing failed'));
      });

      test('exceptions in route groups', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.group(
            '/api',
            defineRoutes: (route) {
              route().get('/error').handle((ctx) {
                throw const NotFoundException(
                  message: 'API endpoint not found',
                );
              });
            },
          );
        });

        final response = await server.get('/api/error');
        expect(response.statusCode, equals(404));
        final body = response.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['message'], equals('API endpoint not found'));
      });
    });

    group('Custom Exception Handling', () {
      test('custom ArcadeHttpException', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/custom').handle((ctx) {
            throw const ArcadeHttpException('Custom error', 418);
          });
        });

        final response = await server.get('/custom');
        expect(response.statusCode, equals(418));
        final body = response.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['message'], equals('Custom error'));
        expect(error['statusCode'], equals(418));
      });

      test('custom exception with errors', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/custom-with-errors').handle((ctx) {
            throw const ArcadeHttpException(
              'Custom validation error',
              422,
              errors: {'field1': 'Error 1', 'field2': 'Error 2'},
            );
          });
        });

        final response = await server.get('/custom-with-errors');
        expect(response.statusCode, equals(422));
        final body = response.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['message'], equals('Custom validation error'));
        expect(error['errors'], {'field1': 'Error 1', 'field2': 'Error 2'});
      });
    });

    group('Error Response Structure', () {
      test('error response includes stack trace in development', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/error-with-stack').handle((ctx) {
            throw const InternalServerErrorException(
              message: 'Error with stack trace',
            );
          });
        });

        final response = await server.get('/error-with-stack');
        expect(response.statusCode, equals(500));
        final body = response.json() as Map<String, dynamic>;
        expect(body.containsKey('error'), isTrue);
        expect(body.containsKey('stackTrace'), isTrue);
        expect(body['stackTrace'], isA<String>());
        expect(body['stackTrace'], contains('#0'));
      });

      test('toJson method returns correct structure', () {
        const exception = BadRequestException(
          message: 'Test error',
          errors: {'field': 'error'},
        );

        final json = exception.toJson();
        expect(json, {
          'statusCode': 400,
          'message': 'Test error',
          'errors': {'field': 'error'},
        });
      });
    });

    group('Non-ArcadeHttpException Handling', () {
      test('generic exceptions are converted to 500', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/generic-error').handle((ctx) {
            throw Exception('Generic error');
          });
        });

        final response = await server.get('/generic-error');
        expect(response.statusCode, equals(500));
        final body = response.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['statusCode'], equals(500));
        expect(error['message'], contains('Internal server error'));
      });

      test('runtime errors are converted to 500', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/runtime-error').handle((ctx) {
            // This will throw a runtime error
            final List<int> list = [];
            return list[10]; // Index out of bounds
          });
        });

        final response = await server.get('/runtime-error');
        expect(response.statusCode, equals(500));
        final body = response.json() as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['statusCode'], equals(500));
      });
    });
  });
}
