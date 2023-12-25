import 'package:arcade_orm/arcade_orm.dart';
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
  group('insert', () {
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
            operator: TableOperator.insert,
            transaction: null,
            isVerbose: false,
            insertWithParams: any(named: "insertWithParams"),
          ),
        ).thenAnswer(
          (_) => Future.value({"nInserted": 1}),
        );
      });

      tearDown(() {
        clearOrms();
        reset(mockAdapter);
        reset(mockTransaction);
      });

      test("operate", () async {
        final arcadeOrm = await ArcadeOrm.init(
          adapter: mockAdapter,
        );
        final table = UserTable(arcadeOrm);
        final insertQuery = table.insert()
          ..insertWith({"name": "foo", "age": 20})
          ..insertWith({"email": "foo@examle.com"});
        await insertQuery.exec();
        verify(
          () => mockAdapter.operate(
            operator: TableOperator.insert,
            transaction: null,
            isVerbose: false,
            // havingParams: [],
            selectParams: [],
            includeParams: [],
            groupParams: [],
            sortParams: [],
            updateWithParams: {},
            insertWithParams: [
              {"name": "foo", "age": 20},
              {"email": "foo@examle.com"},
            ],
          ),
        ).called(1);
      });

      test("data", () async {
        final arcadeOrm = await ArcadeOrm.init(
          adapter: mockAdapter,
        );
        final table = UserTable(arcadeOrm);
        final insertQuery = table.insert()
          ..insertWith({"name": "foo", "age": 20})
          ..insertWith({"email": "foo@examle.com"});
        final data = await insertQuery.exec();
        expect(data, isA<ExecResultData>());
        expect((data as ExecResultData).data, equals({"nInserted": 1}));
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
        final insertQuery = table.insert(transaction: trx)
          ..insertWith({"name": "foo", "age": 20});
        await insertQuery.exec();
        verify(
          () => mockAdapter.operate(
            operator: TableOperator.insert,
            transaction: trx,
            isVerbose: false,
            // havingParams: [],
            selectParams: [],
            includeParams: [],
            groupParams: [],
            sortParams: [],
            updateWithParams: {},
            insertWithParams: [
              {"name": "foo", "age": 20},
            ],
          ),
        ).called(1);
      });
    });

    test("db record - failure", () async {
      when(
        () => mockAdapter.operate(
          operator: TableOperator.insert,
          transaction: null,
          isVerbose: false,
          insertWithParams: any(named: "insertWithParams"),
        ),
      ).thenThrow(
        ArcadeOrmException(message: "Insert Failed", originalError: null),
      );
      final arcadeOrm = await ArcadeOrm.init(
        adapter: mockAdapter,
      );
      final table = UserTable(arcadeOrm);
      final insertQuery = table.insert()
        ..insertWith({"name": "foo", "age": 20})
        ..insertWith({"email": "foo@examle.com"});
      final data = await insertQuery.exec();
      expect(data, isA<ExecResultFailure>());
      expect((data as ExecResultFailure).exception.message, "Insert Failed");
    });
  });
}
