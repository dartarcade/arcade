import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:todo_api/core/database/shared/created_at.dart';

class Users extends Table with CreatedAt {
  UuidColumn get id => customType(PgTypes.uuid).withDefault(genRandomUuid())();

  TextColumn get email => text().unique()();

  TextColumn get password => text()();

  @override
  Set<Column> get primaryKey => {id};
}
