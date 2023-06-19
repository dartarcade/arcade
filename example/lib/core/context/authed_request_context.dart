import 'package:dartseid/dartseid.dart';

class AuthedRequestContext extends RequestContext {
  final String userId;

  AuthedRequestContext({
    required super.path,
    required super.method,
    required super.headers,
    super.pathParameters,
    super.queryParameters,
    required super.body,
    required this.userId,
  });
}
