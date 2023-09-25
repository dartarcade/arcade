import 'package:arcade/arcade.dart';
import 'package:arcade_example/core/context/authed_request_context.dart';
import 'package:arcade_logger/arcade_logger.dart';

Future<AuthedRequestContext> checkAuthMiddleware(RequestContext context) async {
  return AuthedRequestContext(
    request: context.rawRequest,
    route: context.route,
    userId: 'Hello',
  );
}

Future<AuthedRequestContext> printUserIdMiddleware(
  AuthedRequestContext context,
) async {
  const Logger('printUserIdMiddleware').debug('User ID: ${context.userId}');
  return context;
}
