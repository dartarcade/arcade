import 'package:dartseid/dartseid.dart';
import 'package:dartseid_example/core/context/authed_request_context.dart';

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
