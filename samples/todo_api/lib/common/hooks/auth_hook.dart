import 'dart:io';

import 'package:arcade/arcade.dart';
import 'package:injectable/injectable.dart';
import 'package:todo_api/common/contexts/authenticated_request_context.dart';
import 'package:todo_api/common/services/jwt_service.dart';

@singleton
class AuthHook {
  const AuthHook(this._jwtService);

  final JwtService _jwtService;

  AuthenticatedRequestContext call(RequestContext context) {
    final authHeader =
        context.requestHeaders[HttpHeaders.authorizationHeader]?.firstOrNull;
    if (authHeader == null) {
      throw const UnauthorizedException();
    }

    final payload = _jwtService.verifyToken(
      authHeader.replaceFirst('Bearer ', ''),
    );

    return AuthenticatedRequestContext(
      route: context.route,
      request: context.rawRequest,
      id: payload.id,
    );
  }
}
