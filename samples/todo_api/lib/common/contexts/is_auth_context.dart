import 'package:arcade/arcade.dart';

class IsAuthContext extends RequestContext {
  final int userId;

  IsAuthContext({
    required super.request,
    required super.route,
    required this.userId,
  });
}
