import 'package:arcade/arcade.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:todo_api/common/dtos/jwt_payload.dart';
import 'package:todo_api/common/dtos/user_without_password.dart';
import 'package:todo_api/common/services/hash_service.dart';
import 'package:todo_api/common/services/jwt_service.dart';
import 'package:todo_api/core/database/app_database.dart';
import 'package:todo_api/modules/auth/dtos/auth_dto.dart';

@singleton
class AuthService {
  const AuthService(this._db, this._hashService, this._jwtService);

  final AppDatabase _db;
  final HashService _hashService;
  final JwtService _jwtService;

  Future<AuthResponseDto> signup(AuthRequestDto request) async {
    final existingUserQuery = _db.users.selectOnly()
      ..addColumns([_db.users.id])
      ..where(_db.users.email.equals(request.email));
    final existingUserId = await existingUserQuery
        .map((row) => row.read(_db.users.id))
        .getSingleOrNull();
    if (existingUserId != null) {
      throw const ConflictException(
        message: 'User with that email already exists',
      );
    }

    final insertedUser = await _db.users
        .insertReturning(
          request
              .copyWith(password: _hashService.hash(request.password))
              .insertCompanion,
        )
        .then((user) => user.withoutPassword);

    final token = await _jwtService.generateToken(
      JwtPayload(id: insertedUser.id.uuid),
    );

    return AuthResponseDto(
      token: token,
      user: insertedUser,
    );
  }

  Future<AuthResponseDto> login(AuthRequestDto request) async {
    final userQuery = _db.users.select()
      ..where((tbl) => tbl.email.equals(request.email));
    final user = await userQuery.getSingleOrNull();
    if (user == null) {
      throw const BadRequestException(message: 'Invalid credentials');
    }

    if (!_hashService.verify(request.password, user.password)) {
      throw const BadRequestException(message: 'Invalid credentials');
    }

    final token = await _jwtService.generateToken(
      JwtPayload(id: user.id.uuid),
    );

    return AuthResponseDto(
      token: token,
      user: user.withoutPassword,
    );
  }
}
