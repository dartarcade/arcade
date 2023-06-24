import 'dart:io';

import 'package:dartseid/dartseid.dart';
import 'package:injectable/injectable.dart';
import 'package:todo_api/common/contexts/is_auth_context.dart';
import 'package:todo_api/common/services/jwt_service.dart';

@singleton
class AuthMiddleware {
  final JwtService _jwtService;

  const AuthMiddleware(this._jwtService);

  IsAuthContext call(RequestContext context) {
    final token = context.headers[HttpHeaders.authorizationHeader]?.firstOrNull
        ?.split(' ')
        .lastOrNull;
    if (token == null) {
      throw const UnauthorizedException(
        message: 'Authorization header missing',
      );
    }

    final payload = _jwtService.verifyToken(token);
    if (payload == null) {
      throw const UnauthorizedException(message: 'Invalid token');
    }

    return IsAuthContext(
      request: context.rawRequest,
      route: context.route,
      userId: payload.id,
    );
  }
}
