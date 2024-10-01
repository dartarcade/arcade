import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';

mixin CreatedAt on Table {
  TimestampColumn get createdAt =>
      customType(PgTypes.timestampWithTimezone).withDefault(now())();
}
