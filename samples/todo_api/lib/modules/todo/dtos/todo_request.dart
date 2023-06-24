import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:luthor/luthor.dart';
import 'package:luthor_annotation/luthor_annotation.dart';

part 'todo_request.freezed.dart';

part 'todo_request.g.dart';

@luthor
@freezed
class TodoRequest with _$TodoRequest {
  const factory TodoRequest({
    @HasMin(1) required String title,
  }) = _TodoRequest;

  static SchemaValidationResult<TodoRequest> validate(
          Map<String, dynamic> json,) =>
      _$validate(json);

  factory TodoRequest.fromJson(Map<String, dynamic> json) =>
      _$TodoRequestFromJson(json);
}
