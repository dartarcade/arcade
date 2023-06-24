import 'package:freezed_annotation/freezed_annotation.dart';

part 'response_with_message.freezed.dart';

part 'response_with_message.g.dart';

@freezed
class ResponseWithMessage with _$ResponseWithMessage {
  const factory ResponseWithMessage({
    required String message,
  }) = _ResponseWithMessage;

  factory ResponseWithMessage.fromJson(Map<String, dynamic> json) =>
      _$ResponseWithMessageFromJson(json);
}
