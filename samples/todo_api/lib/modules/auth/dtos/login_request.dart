import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:luthor/luthor.dart';
import 'package:luthor_annotation/luthor_annotation.dart';

part 'login_request.freezed.dart';

part 'login_request.g.dart';

@luthor
@freezed
class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    @isEmail required String email,
    @HasMin(8) required String password,
  }) = _LoginRequest;

  static SchemaValidationResult<LoginRequest> validate(
          Map<String, dynamic> json,) =>
      _$validate(json);

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}

@freezed
class LoginResponse with _$LoginResponse {
  const factory LoginResponse({
    required String message,
    required String token,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
}
