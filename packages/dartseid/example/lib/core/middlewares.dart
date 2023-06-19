import 'package:dartseid/dartseid.dart';
import 'package:dartseid_example/core/context/authed_request_context.dart';

final checkAuthMiddleware = Middleware((RequestContext context) async {
  return AuthedRequestContext(
    path: context.path,
    method: context.method,
    headers: context.headers,
    body: context.rawBody,
    userId: 'Hello',
  );
});

final printUserIdMiddleware = Middleware((AuthedRequestContext context) async {
  print('User ID: ${context.userId}');
  return context;
});
