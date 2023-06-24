import 'package:dartseid/dartseid.dart';

class AuthedRequestContext extends RequestContext {
  final String userId;

  AuthedRequestContext({
    required super.route,
    required super.request,
    required this.userId,
  });
}
