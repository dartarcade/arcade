import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:injectable/injectable.dart';
import 'package:todo_api/common/dtos/jwt_payload.dart';
import 'package:todo_api/config/env.dart';

@singleton
class JwtService {
  String generateToken({required JwtPayload payload}) {
    final jwt = JWT(payload.toJson());
    return jwt.sign(
      SecretKey(Env.accessTokenSecret),
      expiresIn: const Duration(days: 1),
    );
  }

  JwtPayload? verifyToken(String token) {
    final jwt = JWT.tryVerify(token, SecretKey(Env.accessTokenSecret));
    if (jwt == null || jwt.payload is! Map) {
      return null;
    }
    return JwtPayload.fromJson((jwt.payload as Map).cast());
  }
}
