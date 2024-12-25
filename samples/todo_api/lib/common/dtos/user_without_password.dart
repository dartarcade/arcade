import 'package:drift_postgres/drift_postgres.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:luthor/luthor.dart';
import 'package:superclass/superclass.dart';
import 'package:todo_api/common/json_converters/pg_date_time_converter.dart';
import 'package:todo_api/common/json_converters/uuid_converter.dart';
import 'package:todo_api/core/database/tables/users.drift.dart';

part 'user_without_password.freezed.dart';

part 'user_without_password.g.dart';

part 'user_without_password.superclass.dart';

@Superclass(
  includeJsonSerialization: true,
  fieldAnnotations: {
    'id': [UuidConverter()],
    'createdAt': [PgDateTimeConverter()],
  },
  apply: [
    Omit<User>(fields: {'password'}),
  ],
)
typedef UserWithoutPassword = $UserWithoutPassword;

extension WithoutPassword on User {
  UserWithoutPassword get withoutPassword {
    return UserWithoutPassword(
      id: id,
      email: email,
      createdAt: createdAt,
    );
  }
}

// ignore: non_constant_identifier_names
final UserWithoutPasswordSchema = l.schema({
  'id': l.string().required(),
  'email': l.string().required(),
  'createdAt': l.string().dateTime().required(),
});
