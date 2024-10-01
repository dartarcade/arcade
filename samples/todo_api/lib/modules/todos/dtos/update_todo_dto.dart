import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:luthor/luthor.dart';
import 'package:superclass/superclass.dart';
import 'package:todo_api/core/database/tables/todos.drift.dart';

part 'update_todo_dto.freezed.dart';

part 'update_todo_dto.g.dart';

part 'update_todo_dto.superclass.dart';

@Superclass(
  includeJsonSerialization: true,
  classAnnotations: [Luthor()],
  fieldAnnotations: {
    'title': [HasMin(1, message: 'Title cannot be empty')],
  },
  apply: [
    Omit<Todo>(fields: {'id', 'user', 'createdAt'}),
    MakePartial<$PR>(),
  ],
)
typedef UpdateTodoDto = $UpdateTodoDto;
