import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:luthor/luthor.dart';
import 'package:luthor_annotation/luthor_annotation.dart';

part 'register_request.freezed.dart';

part 'register_request.g.dart';

@luthor
@freezed
class RegisterRequest with _$RegisterRequest {
  const factory RegisterRequest({
    @isEmail required String email,
    @HasMin(8) required String password,
  }) = _RegisterRequest;

  static SchemaValidationResult<RegisterRequest> validate(
    Map<String, dynamic> json,
  ) =>
      _$RegisterRequestValidate(json);

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
}
