import 'package:arcade/arcade.dart';
import 'package:injectable/injectable.dart';
import 'package:todo_api/common/dtos/jwt_payload.dart';
import 'package:todo_api/common/dtos/response_with_message.dart';
import 'package:todo_api/common/services/hash_service.dart';
import 'package:todo_api/common/services/jwt_service.dart';
import 'package:todo_api/config/database.dart';
import 'package:todo_api/core/orm/prisma_client.dart';
import 'package:todo_api/modules/auth/dtos/login_request.dart';
import 'package:todo_api/modules/auth/dtos/register_request.dart';

@singleton
class AuthService {
  final HashService _hashService;
  final JwtService _jwtService;

  const AuthService(this._hashService, this._jwtService);

  Future<ResponseWithMessage> register(RegisterRequest dto) async {
    final user = await prisma.user.findUnique(
      where: UserWhereUniqueInput(email: dto.email),
    );
    if (user != null) {
      throw const ConflictException(
        message: 'User already exists. Please sign up',
      );
    }

    final newUser =
        dto.copyWith(password: await _hashService.hash(dto.password));
    await prisma.user.create(
      data: UserCreateInput(email: newUser.email, password: newUser.password),
    );

    return const ResponseWithMessage(message: 'Successfully registered');
  }

  Future<LoginResponse> login(LoginRequest dto) async {
    final user = await prisma.user.findUnique(
      where: UserWhereUniqueInput(email: dto.email),
    );
    if (user == null) {
      throw const BadRequestException(message: 'Invalid credentials');
    }

    final isPasswordValid = await _hashService.verify(
      password: dto.password,
      hash: user.password,
    );
    if (!isPasswordValid) {
      throw const BadRequestException(message: 'Invalid credentials');
    }

    return LoginResponse(
      message: 'Successfully logged in',
      token: _jwtService.generateToken(
        payload: JwtPayload(id: user.id),
      ),
    );
  }
}
