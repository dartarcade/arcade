import 'dart:io';

import 'package:dartseid/dartseid.dart';
import 'package:injectable/injectable.dart';
import 'package:todo_api/common/contexts/is_auth_context.dart';
import 'package:todo_api/common/services/jwt_service.dart';

@singleton
class AuthHook {
  final JwtService _jwtService;

  const AuthHook(this._jwtService);

  IsAuthContext hook(RequestContext context) {
    final token = context.requestHeaders[HttpHeaders.authorizationHeader]?.firstOrNull
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
