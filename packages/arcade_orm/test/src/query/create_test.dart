import 'package:arcade_orm/arcade_orm.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockAdapter extends Mock implements ArcadeOrmAdapterBase {}

class MockTransaction extends Mock implements ArcadeOrmTransaction {}

void main() {
  final mockAdapter = MockAdapter();
  final mockTransaction = MockTransaction();
  group('create', () {
    setUp(() {
      when(() => mockAdapter.transaction()).thenReturn(mockTransaction);
    });

    tearDown(() {
      clearOrms();
      reset(mockAdapter);
    });

    test("create db record - success", () async {
      when(
        () => mockAdapter.operate(
          operator: TableOperator.create,
          transaction: null,
          isExplain: false,
          createWithParams: any(named: "createWithParams"),
        ),
      ).thenAnswer(
        (_) => Future.value({"nCreated": 1}),
      );
      final arcadeOrm = await ArcadeOrm.init(
        adapter: mockAdapter,
      );
      final table = arcadeOrm.table(
        "users",
        {},
      );
      final createQuery = table.create()
        ..createWith({"name": "foo", "age": 20})
        ..createWith({"email": "foo@examle.com"});
      final data = await createQuery.exec();
      verify(
        () => mockAdapter.operate(
          operator: TableOperator.create,
          transaction: null,
          isExplain: false,
          whereParams: [],
          havingParams: [],
          selectParams: [],
          includeParams: [],
          groupParams: [],
          sortParams: [],
          updateWithParams: [],
          createWithParams: [
            {"name": "foo", "age": 20},
            {"email": "foo@examle.com"},
          ],
        ),
      ).called(1);
      expect(data, isA<ExecResultData>());
      expect((data as ExecResultData).data, {"nCreated": 1});
    });

    test("create db record - failure", () async {
      when(
        () => mockAdapter.operate(
          operator: TableOperator.create,
          transaction: null,
          isExplain: false,
          createWithParams: any(named: "createWithParams"),
        ),
      ).thenThrow(
        ArcadeOrmException(message: "Create Failed", originalError: null),
      );
      final arcadeOrm = await ArcadeOrm.init(
        adapter: mockAdapter,
      );
      final table = arcadeOrm.table(
        "users",
        {},
      );
      final createQuery = table.create()
        ..createWith({"name": "foo", "age": 20})
        ..createWith({"email": "foo@examle.com"});
      final data = await createQuery.exec();
      verify(
        () => mockAdapter.operate(
          operator: TableOperator.create,
          transaction: null,
          isExplain: false,
          whereParams: [],
          havingParams: [],
          selectParams: [],
          includeParams: [],
          groupParams: [],
          sortParams: [],
          updateWithParams: [],
          createWithParams: [
            {"name": "foo", "age": 20},
            {"email": "foo@examle.com"},
          ],
        ),
      ).called(1);
      expect(data, isA<ExecResultFailure>());
      expect((data as ExecResultFailure).exception.message, "Create Failed");
    });

    test("create db record with Transaction", () async {
      when(() => mockTransaction.start())
          .thenAnswer((_) async => Future.value());
      final arcadeOrm = await ArcadeOrm.init(
        adapter: mockAdapter,
      );
      final table = arcadeOrm.table(
        "users",
        {},
      );
      final trx = table.transaction();
      await trx.start();
      final createQuery = table.create(transaction: trx)
        ..createWith({"name": "foo", "age": 20});
      await createQuery.exec();
      verify(
        () => mockAdapter.operate(
          operator: TableOperator.create,
          transaction: trx,
          isExplain: false,
          whereParams: [],
          havingParams: [],
          selectParams: [],
          includeParams: [],
          groupParams: [],
          sortParams: [],
          updateWithParams: [],
          createWithParams: [
            {"name": "foo", "age": 20},
          ],
        ),
      ).called(1);
    });
  });
}
