import 'package:freezed_annotation/freezed_annotation.dart';

part 'jwt_payload.freezed.dart';

part 'jwt_payload.g.dart';

@freezed
abstract class JwtPayload with _$JwtPayload {
  const factory JwtPayload({
    required String id,
  }) = _JwtPayload;

  factory JwtPayload.fromJson(Map<String, dynamic> json) =>
      _$JwtPayloadFromJson(json);
}
