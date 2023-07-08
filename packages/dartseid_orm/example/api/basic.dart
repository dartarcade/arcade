import 'package:dartseid_orm/dartseid_orm.dart';

class DormMockAdapter implements DormAdapterBase {
  final dynamic _connection;

  DormMockAdapter({
    required dynamic connection,
  }) : _connection = connection;

  @override
  Future<void> init() {
    // TODO: implement init
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> operate({
    required TableOperator operator,
    required DormTransaction? transaction,
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
  DormTransaction transaction() {
    // TODO: implement transaction
    throw UnimplementedError();
  }
}

Future<dynamic> dorming() async {
  final a = await Dorm.init(
    adapter: DormMockAdapter(connection: ""),
  );

  final t = a.table(
    "users",
    {
      "id": ColumnInt(),
      "name": ColumnString(),
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

  // more dorming
  return data;
}
