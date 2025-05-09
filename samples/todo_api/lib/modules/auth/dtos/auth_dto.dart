import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:luthor/luthor.dart';
import 'package:todo_api/common/dtos/user_without_password.dart';
import 'package:todo_api/core/database/tables/users.drift.dart';

part 'auth_dto.freezed.dart';

part 'auth_dto.g.dart';

@luthor
@freezed
abstract class AuthRequestDto with _$AuthRequestDto {
  const factory AuthRequestDto({
    @isEmail required String email,
    @HasMin(8) required String password,
  }) = _AuthRequestDto;

  factory AuthRequestDto.fromJson(Map<String, dynamic> json) =>
      _$AuthRequestDtoFromJson(json);

  const AuthRequestDto._();

  UsersCompanion get insertCompanion {
    return UsersCompanion.insert(email: email, password: password);
  }
}

@freezed
abstract class AuthResponseDto with _$AuthResponseDto {
  const factory AuthResponseDto({
    required String token,
    required UserWithoutPassword user,
  }) = _AuthResponseDto;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseDtoFromJson(json);
}

// ignore: non_constant_identifier_names
final AuthResponseDtoSchema = l.withName('AuthResponseDto').schema(
  {
    'token': l.string().required(),
    'user': UserWithoutPasswordSchema.required(),
  },
);
