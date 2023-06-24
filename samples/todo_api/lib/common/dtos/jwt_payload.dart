import 'package:freezed_annotation/freezed_annotation.dart';

part 'jwt_payload.freezed.dart';

part 'jwt_payload.g.dart';

@freezed
class JwtPayload with _$JwtPayload {
  const factory JwtPayload({
    required int id,
  }) = _JwtPayload;

  factory JwtPayload.fromJson(Map<String, dynamic> json) =>
      _$JwtPayloadFromJson(json);
}
