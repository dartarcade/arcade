import 'dart:async';

import 'package:arcade_orm/arcade_orm.dart';

class ArcadeOrmMockAdapter implements ArcadeOrmAdapterBase {
  @override
  late ArcadeOrm orm;
  @override
  final dynamic connection;

  ArcadeOrmMockAdapter({
    required this.connection,
  });

  @override
  Future<void> init() {
    // TODO: implement init
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> operate({
    required TableOperator operator,
    required ArcadeOrmTransaction? transaction,
    required bool isExplain,
    String? rawSql,
    Map<String, dynamic>? rawNoSql,
    List<Map<String, WhereParam>> whereParams = const [],
    List<Map<String, WhereParam>> havingParams = const [],
    List<Map<String, SelectParam>> selectParams = const [],
    List<IncludeParam> includeParams = const [],
    List<String> groupParams = const [],
    List<Map<String, int>> sortParams = const [],
    List<Map<String, dynamic>> updateWithParams = const [],
    List<Map<String, dynamic>> createWithParams = const [],
    int? limit,
    int? skip,
  }) {
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
}

Future<dynamic> orming() async {
  final a = await ArcadeOrm.init(
    adapter: ArcadeOrmMockAdapter(connection: ""),
  );

  final t = a.table(
    "users",
    {
      "id": ColumnInt()..nullable(),
      "name": ColumnString(),
      "json": ColumnJson(),
    },
    converter: (
      fromJson: (Map<String, dynamic> j) {},
      toJson: () => {},
    ),
  );

  t.index({"id": 1, "name": 1});

  // final trx = t.transaction();
  // final b = await trx.start();
  // trx.commit();
  // trx.rollback();

  final data = await t.transaction().start(
    (trx) async {
      final r = t.findOne(transaction: trx)
        ..where({
          "id": array([1, 2, 4])
        })
        ..where({"id": eq(10)})
        ..where(
          and([
            {
              "name": like("%aa"),
              "id": array([1, 2, 4]),
            },
            {"name": eq("2")}
          ]),
        )
        ..where(
          or([
            {
              "name": like("%aa"),
              "id": between(1, 200),
            }
          ]),
        )
        ..select({
          "id": show(),
          "_id": hide(),
          "nom": field("name"),
          "avg": avg("name"),
          "count": count("name"),
          "countD": count("DISTINCT(name)"),
          "countD2": countDistinct("name"),
          "x": distinct("name"),
          "max": max("name"),
        })
        ..include(
          "profile",
          on: "profileId",
          where: and([
            {"bio": notEq(null)},
            {"bio": notEq("")},
          ]),
          joinType: JoinOperation.left,
        )
        ..group("id")
        ..sort({"name": 1})
        ..having(and([]))
        ..limit(10)
        ..skip(0);

      Future<String> fromJsonFn(Map<String, dynamic> j) async {
        return "";
      }

      final result = await r.exec(converter: (fromJson: fromJsonFn));

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
