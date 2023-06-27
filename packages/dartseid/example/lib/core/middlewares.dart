import 'package:dartseid/dartseid.dart';
import 'package:dartseid_example/core/context/authed_request_context.dart';

final checkAuthMiddleware = Middleware((RequestContext context) async {
  return AuthedRequestContext(
    request: context.rawRequest,
    route: context.route,
    userId: 'Hello',
  );
});

final printUserIdMiddleware = Middleware((AuthedRequestContext context) async {
  logger.debug('User ID: ${context.userId}');
  return context;
});
