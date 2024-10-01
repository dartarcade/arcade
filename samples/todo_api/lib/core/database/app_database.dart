import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:injectable/injectable.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:todo_api/core/database/app_database.drift.dart';
import 'package:todo_api/core/database/tables/todos.dart';
import 'package:todo_api/core/database/tables/users.dart';
import 'package:todo_api/core/env.dart';

@singleton
@DriftDatabase(tables: [Users, Todos])
class AppDatabase extends $AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.create(todos);
        }

        if (from < 3) {
          await m.addColumn(todos, todos.completed);
        }

        if (from < 4) {
          await m.addColumn(users, users.createdAt);
          await m.addColumn(todos, todos.createdAt);
        }
      },
    );
  }

  static QueryExecutor _openConnection() {
    final databaseUri = Uri.parse(Env.databaseUrl);
    final [username, password] = databaseUri.userInfo.split(':');
    final sslMode = switch (databaseUri.queryParameters['sslmode']) {
      'disable' => pg.SslMode.disable,
      _ => pg.SslMode.require,
    };
    return PgDatabase(
      endpoint: pg.Endpoint(
        host: databaseUri.host,
        database: databaseUri.pathSegments.first,
        username: username,
        password: password,
      ),
      settings: pg.ConnectionSettings(sslMode: sslMode),
    );
  }
}
