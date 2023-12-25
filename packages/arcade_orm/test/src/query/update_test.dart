import 'dart:convert';

import 'package:arcade_orm/arcade_orm.dart';
import 'package:arcade_orm/src/query/where.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockAdapter extends Mock implements ArcadeOrmAdapterBase {}

class MockTransaction extends Mock implements ArcadeOrmTransaction {}

class UserTable extends ArcadeOrmTableSchema {
  UserTable(super.orm);

  @override
  final String tableName = "user";

  static const String id = "id";
  static const String name = "name";
  static const String email = "email";
  static const String age = "age";

  @override
  Map<String, ColumnMeta> schema = {
    id: const ColumnInt(),
    name: const ColumnString(),
    email: const ColumnString(),
    age: const ColumnInt(),
  };
}

void main() {
  final mockAdapter = MockAdapter();
  final mockTransaction = MockTransaction();

  group('update', () {
    setUp(() {
      when(() => mockAdapter.transaction()).thenReturn(mockTransaction);
    });

    tearDown(() {
      clearOrms();
      reset(mockAdapter);
      reset(mockTransaction);
    });

    group("success", () {
      setUp(() {
        when(
          () => mockAdapter.operate(
            operator: TableOperator.update,
            transaction: null,
            isExplain: false,
            whereParams: any(named: "whereParams"),
            updateWithParams: any(named: "updateWithParams"),
          ),
        ).thenAnswer(
          (_) => Future.value({"nUpdated": 1}),
        );
      });

      tearDown(() {
        clearOrms();
        reset(mockAdapter);
        reset(mockTransaction);
      });

      test("operate where", () async {
        final arcadeOrm = await ArcadeOrm.init(
          adapter: mockAdapter,
        );
        final table = UserTable(arcadeOrm);
        final updateQuery = table.update()
          ..where(
            and([
              {
                UserTable.name: eq("bar"),
                UserTable.age: gt(20),
              }
            ]),
          )
          ..updateWith({
            UserTable.name: "foo",
            UserTable.age: 20,
          });

        await updateQuery.exec();

        final captured = verify(
          () => mockAdapter.operate(
            operator: TableOperator.update,
            transaction: null,
            isExplain: false,
            whereParams: captureAny(named: "whereParams"),
            // havingParams: [],
            selectParams: [],
            includeParams: [],
            groupParams: [],
            sortParams: [],
            updateWithParams: any(named: "updateWithParams"),
            insertWithParams: [],
          ),
        ).captured;

        final capturedWhereParams =
            (captured.first as WhereExpressionNode).toMap();

        final andExpr = capturedWhereParams[WhereExpressionOperator.and.name]
            as List<Map<String, dynamic>>;

        expect(
          andExpr.first[UserTable.name],
          equals(WhereParam(operator: WhereOperator.eq, value: "bar")),
        );
        expect(
          andExpr.last[UserTable.age],
          equals(WhereParam(operator: WhereOperator.gt, value: 20)),
        );
      });

      test("operate updateWith", () async {
        final arcadeOrm = await ArcadeOrm.init(
          adapter: mockAdapter,
        );
        final table = UserTable(arcadeOrm);
        final updateQuery = table.update()
          ..where(
            and([
              {
                UserTable.name: eq("bar"),
                UserTable.age: gt(20),
              }
            ]),
          )
          ..updateWith({
            UserTable.name: "foo",
            UserTable.age: 20,
          })
          ..updateWith({
            UserTable.age: 30,
            UserTable.email: "foo@example.com",
          });

        await updateQuery.exec();

        final captured = verify(
          () => mockAdapter.operate(
            operator: TableOperator.update,
            transaction: null,
            isExplain: false,
            whereParams: any(named: "whereParams"),
            // havingParams: [],
            selectParams: [],
            includeParams: [],
            groupParams: [],
            sortParams: [],
            updateWithParams: captureAny(named: "updateWithParams"),
            insertWithParams: [],
          ),
        ).captured;

        final updateWithParams = captured.first as Map<String, dynamic>;

        expect(
          updateWithParams,
          equals({
            UserTable.name: "foo",
            UserTable.age: 30,
            UserTable.email: "foo@example.com",
          }),
        );
      });

      test("data", () async {
        final arcadeOrm = await ArcadeOrm.init(
          adapter: mockAdapter,
        );
        final table = UserTable(arcadeOrm);
        final udpateQuery = table.update()
          ..updateWith({"name": "foo", "age": 20});
        final data = await udpateQuery.exec();
        expect(data, isA<ExecResultData>());
        expect((data as ExecResultData).data, equals({"nUpdated": 1}));
      });

      test("operate with transaction", () async {
        when(() => mockTransaction.start())
            .thenAnswer((_) async => Future.value());
        final arcadeOrm = await ArcadeOrm.init(
          adapter: mockAdapter,
        );
        final table = UserTable(arcadeOrm);
        final trx = table.transaction();
        await trx.start();
        final insertQuery = table.update(transaction: trx)
          ..updateWith({"name": "foo", "age": 20});
        await insertQuery.exec();
        verify(
          () => mockAdapter.operate(
            operator: TableOperator.update,
            transaction: trx,
            isExplain: false,
            whereParams: any(named: "whereParams"),
            selectParams: [],
            includeParams: [],
            groupParams: [],
            sortParams: [],
            updateWithParams: {"name": "foo", "age": 20},
          ),
        ).called(1);
      });
    });
  });
}
