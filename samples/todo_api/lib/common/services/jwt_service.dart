import 'package:arcade/arcade.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:injectable/injectable.dart';
import 'package:todo_api/common/dtos/jwt_payload.dart';
import 'package:todo_api/core/env.dart';

@singleton
class JwtService {
  const JwtService();

  static final _secretKey = SecretKey(Env.jwtSecret);

  Future<String> generateToken(JwtPayload payload) async {
    final token = JWT(payload.toJson());
    return token.sign(_secretKey, expiresIn: const Duration(days: 1));
  }

  JwtPayload verifyToken(String s) {
    final token = JWT.tryVerify(s, _secretKey);
    if (token == null) {
      throw const UnauthorizedException();
    }
    return JwtPayload.fromJson(token.payload as Map<String, dynamic>);
  }
}
