import 'package:dartseid/dartseid.dart';

class AuthedRequestContext extends RequestContext {
  final String userId;

  AuthedRequestContext({
    super.route,
    required super.request,
    required this.userId,
  });
}
