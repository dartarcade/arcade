import 'package:arcade_orm/arcade_orm.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockAdapter extends Mock implements ArcadeOrmAdapterBase {}

class MockTransaction extends Mock implements ArcadeOrmTransaction {}

class UserTable extends ArcadeOrmTableSchema {
  UserTable(super.orm);

  @override
  final String tableName = "user";

  @override
  Map<String, ColumnMeta> schema = {};
}

void main() {
  final mockAdapter = MockAdapter();
  final mockTransaction = MockTransaction();
  group('raw', () {
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
            operator: TableOperator.raw,
            transaction: null,
            isVerbose: false,
            rawSql: any(named: "rawSql"),
            rawNoSqlAggregate: any(named: "rawNoSqlAggregate"),
            rawNoSqlAggregateOptions: any(named: "rawNoSqlAggregateOptions"),
          ),
        ).thenAnswer(
          (_) => Future.value({"nResult": 1}),
        );
      });

      test("operate sql", () async {
        final arcadeOrm = await ArcadeOrm.init(
          adapter: mockAdapter,
        );
        final table = UserTable(arcadeOrm);
        final rawQuery = table.raw()
          ..sql(
            "INSERT INTO user (name, email) VALUES (@name, @email)",
            params: {
              "name:": "John",
              "email": "john@example.com",
            },
          );
        await rawQuery.exec();
        verify(
          () => mockAdapter.operate(
            operator: TableOperator.raw,
            transaction: null,
            isVerbose: false,
            // havingParams: [],
            selectParams: [],
            includeParams: [],
            groupParams: [],
            sortParams: [],
            updateWithParams: {},
            insertWithParams: [],
            rawSql: "INSERT INTO user (name, email) VALUES (@name, @email)",
            rawParams: {
              "name:": "John",
              "email": "john@example.com",
            },
          ),
        ).called(1);
      });
      test("operate noSql", () async {
        final arcadeOrm = await ArcadeOrm.init(
          adapter: mockAdapter,
        );
        final table = UserTable(arcadeOrm);
        final rawQuery = table.raw()
          ..aggregate(
            [
              {
                "\$match": {
                  "name:": "John",
                  "email": "john@example.com",
                },
              },
              {
                "\$group": {
                  "_id": "\$name",
                  "count": {"\$sum"},
                },
              },
            ],
            options: {
              "useDisk": "true",
            },
          );
        await rawQuery.exec();
        verify(
          () => mockAdapter.operate(
            operator: TableOperator.raw,
            transaction: null,
            isVerbose: false,
            // havingParams: [],
            selectParams: [],
            includeParams: [],
            groupParams: [],
            sortParams: [],
            updateWithParams: {},
            insertWithParams: [],
            rawNoSqlAggregate: [
              {
                "\$match": {
                  "name:": "John",
                  "email": "john@example.com",
                },
              },
              {
                "\$group": {
                  "_id": "\$name",
                  "count": {"\$sum"},
                },
              },
            ],
            rawNoSqlAggregateOptions: {
              "useDisk": "true",
            },
          ),
        ).called(1);
      });
      test('with transaction', () async {
        when(() => mockTransaction.start())
            .thenAnswer((_) async => Future.value());
        final arcadeOrm = await ArcadeOrm.init(
          adapter: mockAdapter,
        );
        final table = UserTable(arcadeOrm);
        final trx = table.transaction();
        await trx.start();
        final rawQuery = table.raw(transaction: trx)
          ..sql("SELECT * FROM user WHERE id = @id", params: {"id": 1});
        await rawQuery.exec();
        verify(
          () => mockAdapter.operate(
            operator: TableOperator.raw,
            transaction: trx,
            isVerbose: false,
            // havingParams: [],
            selectParams: [],
            includeParams: [],
            groupParams: [],
            sortParams: [],
            updateWithParams: {},
            insertWithParams: [],
            rawSql: "SELECT * FROM user WHERE id = @id",
            rawParams: {"id": 1},
          ),
        ).called(1);
      });
    });

    test("db record - failure", () async {
      when(
        () => mockAdapter.operate(
          operator: TableOperator.raw,
          transaction: null,
          isVerbose: false,
          rawParams: any(named: "rawParams"),
          rawSql: any(named: "rawSql"),
          rawNoSqlAggregate: any(named: "rawNoSqlAggregate"),
          rawNoSqlAggregateOptions: any(named: "rawNoSqlAggregateOptions"),
        ),
      ).thenThrow(
        ArcadeOrmException(message: "Operation Failed", originalError: null),
      );
      final arcadeOrm = await ArcadeOrm.init(
        adapter: mockAdapter,
      );
      final table = UserTable(arcadeOrm);
      final rawQuery = table.raw()
        ..sql("SELECT * FROM user WHERE id = @id", params: {"id": 1});
      final data = await rawQuery.exec();
      expect(data, isA<ExecResultFailure>());
      expect((data as ExecResultFailure).exception.message, "Operation Failed");
    });
  });
}
