import 'package:drift_postgres/drift_postgres.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:superclass/superclass.dart';
import 'package:todo_api/common/json_converters/pg_date_time_converter.dart';
import 'package:todo_api/common/json_converters/uuid_converter.dart';
import 'package:todo_api/core/database/tables/todos.drift.dart';

part 'todo_without_user.freezed.dart';

part 'todo_without_user.g.dart';

part 'todo_without_user.superclass.dart';

@Superclass(
  includeJsonSerialization: true,
  fieldAnnotations: {
    'id': [UuidConverter()],
    'createdAt': [PgDateTimeConverter()],
  },
  apply: [
    Omit<Todo>(fields: {'user'}),
  ],
)
typedef TodoWithoutUser = $TodoWithoutUser;

extension WithoutUser on Todo {
  TodoWithoutUser get withoutUser {
    return TodoWithoutUser(
      id: id,
      title: title,
      completed: completed,
      createdAt: createdAt,
    );
  }
}
