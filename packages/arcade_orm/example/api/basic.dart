import 'dart:async';

import 'package:arcade_orm/arcade_orm.dart';
import 'package:arcade_orm/src/query/include.dart';
import 'package:arcade_orm/src/query/select.dart';
import 'package:arcade_orm/src/query/where.dart';

typedef OptionsRecord = ({String? name, String? host, int? port});

class ArcadeOrmMockAdapter
    implements ArcadeOrmAdapterBase<OptionsRecord, String> {
  @override
  late ArcadeOrm orm;
  @override
  final OptionsRecord? options;

  @override
  final String connection;

  ArcadeOrmMockAdapter({
    required this.connection,
    this.options,
  });

  @override
  Future<void> init() {
    // TODO: implement init
    throw UnimplementedError();
  }

  @override
  ArcadeOrmTransaction transaction() {
    // TODO: implement transaction
    throw UnimplementedError();
  }

  @override
  void setArcadeOrmInstance(ArcadeOrm orm) {
    this.orm = orm;
  }

  @override
  FutureOr<void> close() {
    // TODO: implement close
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> operate(
      {required TableOperator operator,
      required ArcadeOrmTransaction? transaction,
      required bool isExplain,
      String? rawSql,
      Map<String, dynamic>? rawNoSql,
      WhereExpressionNode? whereParams,
      WhereExpressionNode? havingParams,
      List<Map<String, SelectParam>> selectParams = const [],
      List<IncludeParam> includeParams = const [],
      List<String> groupParams = const [],
      List<Map<String, int>> sortParams = const [],
      List<Map<String, dynamic>> updateWithParams = const [],
      List<Map<String, dynamic>> insertWithParams = const [],
      int? limit,
      int? skip}) {
    // TODO: implement operate
    throw UnimplementedError();
  }
}

class UserTable extends ArcadeOrmTableSchema {
  UserTable(super.orm);

  @override
  final String tableName = "user";

  static const String id = "id";
  static const String name = "name";
  static const String email = "email";
  static const String age = "age";
  static const String profileId = "profileId";

  @override
  Map<String, ColumnMeta> schema = const {
    id: ColumnInt(),
    name: ColumnString(),
    email: ColumnString(),
    age: ColumnInt(),
    profileId: ColumnInt(),
  };

  @override
  Map<String, ArcadeTableIndexRecord> index = {
    name: (1, unique: null),
  };

  @override
  Map<String, ArcadeOrmRelationshipRecord> relations = const {
    "profile": (
      type: ArcadeOrmRelationshipType.hasOne,
      table: ProfileTable.$tableName,
      localKey: profileId,
      foreignKey: ProfileTable.id,
    ),
  };
}

class ProfileTable extends ArcadeOrmTableSchema {
  ProfileTable(super.orm);

  static const String $tableName = "profile";

  @override
  String tableName = $tableName;

  static const String id = "id";
  static const String bio = "bio";

  @override
  Map<String, ColumnMeta> schema = {};
}

late final UserTable userTable;
late final ProfileTable profileTable;

Future<dynamic> orming() async {
  final orm = await ArcadeOrm.init(
    adapter: ArcadeOrmMockAdapter(connection: ""),
  );

  userTable = UserTable(orm);
  profileTable = ProfileTable(orm);

  final trx = userTable.transaction();
  await trx.start();
  userTable.findOne(transaction: trx);
  trx.commit();
  trx.rollback();

  final data = await userTable.transaction().start(
    (trx) async {
      final r = userTable.findOne(transaction: trx)
        ..where({
          UserTable.id: array([1, 2, 4]),
        })
        ..where({UserTable.id: eq(10)})
        ..where(
          and([
            {
              UserTable.name: like("%aa"),
              UserTable.id: array([1, 2, 4]),
            },
            {UserTable.name: eq("2")},
          ]),
        )
        ..where(
          or([
            {
              UserTable.name: like("%aa"),
              UserTable.id: between(1, 200),
            }
          ]),
        )
        ..select({
          UserTable.name: show(),
          UserTable.id: hide(),
          "nom": field(UserTable.name),
          "avg": avg(UserTable.age),
          "count": count(UserTable.name),
          "countD": count("DISTINCT(${UserTable.name})"),
          "countD2": countDistinct(UserTable.name),
          "x": distinct(UserTable.name),
          "max": max(UserTable.age),
        })
        ..include(
          profileTable,
          on: UserTable.profileId,
          where: and([
            {ProfileTable.bio: notEq(null)},
            {ProfileTable.bio: notEq("")},
          ]),
          joinType: JoinOperation.left,
        )
        ..group(UserTable.id)
        ..sort({UserTable.name: 1})
        ..limit(10)
        ..skip(0);

      Future<String> fromJsonFn(Map<String, dynamic> j) async {
        return "";
      }

      final result = await r.exec(fromJson: fromJsonFn);

      return switch (result) {
        ExecResultData(data: final data) => data,
        ExecResultFailure(exception: final _) => await () async {
            throw Exception("I am basic");
          }()
      };
    },
  );

  // more orming
  return data;
}
