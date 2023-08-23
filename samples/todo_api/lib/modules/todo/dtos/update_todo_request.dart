import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:luthor/luthor.dart';
import 'package:luthor_annotation/luthor_annotation.dart';

part 'update_todo_request.freezed.dart';

part 'update_todo_request.g.dart';

@luthor
@freezed
class UpdateTodoRequest with _$UpdateTodoRequest {
  const factory UpdateTodoRequest({
    String? title,
    bool? completed,
  }) = _UpdateTodoRequest;

  static SchemaValidationResult<UpdateTodoRequest> validate(
    Map<String, dynamic> json,
  ) =>
      _$UpdateTodoRequestValidate(json);

  factory UpdateTodoRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateTodoRequestFromJson(json);
}
