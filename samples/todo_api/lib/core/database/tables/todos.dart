import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:todo_api/core/database/shared/created_at.dart';
import 'package:todo_api/core/database/tables/users.dart';

class Todos extends Table with CreatedAt {
  UuidColumn get id => customType(PgTypes.uuid).withDefault(genRandomUuid())();

  TextColumn get title => text()();

  BoolColumn get completed => boolean()();

  UuidColumn get user => customType(PgTypes.uuid).references(Users, #id)();

  @override
  Set<Column> get primaryKey => {id};
}
