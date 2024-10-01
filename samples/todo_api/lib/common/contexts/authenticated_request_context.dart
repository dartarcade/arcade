import 'package:arcade/arcade.dart';

class AuthenticatedRequestContext extends RequestContext {
  AuthenticatedRequestContext({
    required super.route,
    required super.request,
    required this.id,
  });

  final String id;
}
