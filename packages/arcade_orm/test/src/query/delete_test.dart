import 'package:arcade_orm/arcade_orm.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockAdapter extends Mock implements ArcadeOrmAdapterBase {}

class MockTransaction extends Mock implements ArcadeOrmTransaction {}

class FakeWhereParam extends Fake implements WhereParam {}

void main() {
  final mockAdapter = MockAdapter();
  final mockTransaction = MockTransaction();

  group('delete', () {
    setUp(() {
      registerFallbackValue(FakeWhereParam());
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
            operator: TableOperator.delete,
            transaction: null,
            isExplain: false,
            whereParams: any(named: "whereParams"),
          ),
        ).thenAnswer(
          (_) => Future.value({"deleted": 1}),
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
        final table = arcadeOrm.table(
          "users",
          {},
        );
        final deleteQuery = table.delete()
          ..where({"id": eq(1)})
          ..include("role", where: {"name": notEq("admin")});

        await deleteQuery.exec();

        final captured = verify(
          () => mockAdapter.operate(
            operator: TableOperator.delete,
            transaction: null,
            isExplain: false,
            whereParams: captureAny(named: "whereParams"),
            havingParams: [],
            selectParams: [],
            includeParams: captureAny(named: "includeParams"),
            groupParams: [],
            sortParams: [],
            updateWithParams: [],
            createWithParams: [],
          ),
        ).captured;
        final capturedWhereParams =
            (captured.first as List<Map<String, WhereParam>>).first['id'];
        expect(
          capturedWhereParams?.value,
          equals(1),
        );
        expect(
          capturedWhereParams?.operator,
          equals(WhereOperator.eq),
        );
        final capturedIncludeParams = (captured[1] as List<IncludeParam>).first;
        expect(capturedIncludeParams.tableName, equals("role"));
        expect(
          capturedIncludeParams.where?["name"]?.operator,
          equals(WhereOperator.notEq),
        );
        expect(
          capturedIncludeParams.where?["name"]?.value,
          equals("admin"),
        );
        expect(capturedIncludeParams.as, equals(null));
        expect(capturedIncludeParams.on, equals(null));
        expect(capturedIncludeParams.joinType, equals(JoinOperation.inner));
      });

      test("data", () async {
        final arcadeOrm = await ArcadeOrm.init(
          adapter: mockAdapter,
        );
        final table = arcadeOrm.table(
          "users",
          {},
        );
        final deleteQuery = table.delete()..where({"id": eq(1)});
        final data = await deleteQuery.exec();
        expect(data, isA<ExecResultData>());
        expect((data as ExecResultData).data, equals({"deleted": 1}));
      });

      test("operate with transaction", () async {
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
        final deleteQuery = table.delete(transaction: trx)
          ..where({"id": eq(1)});
        await deleteQuery.exec();
        final captured = verify(
          () => mockAdapter.operate(
            operator: TableOperator.delete,
            transaction: trx,
            isExplain: false,
            whereParams: captureAny(named: "whereParams"),
            havingParams: [],
            selectParams: [],
            includeParams: [],
            groupParams: [],
            sortParams: [],
            updateWithParams: [],
            createWithParams: [],
          ),
        ).captured;

        final capturedWhereParams =
            (captured.first as List<Map<String, WhereParam>>).first['id'];
        expect(
          capturedWhereParams?.value,
          equals(1),
        );
        expect(
          capturedWhereParams?.operator,
          equals(WhereOperator.eq),
        );
      });
    });

    test("db record - failure", () async {
      when(
        () => mockAdapter.operate(
          operator: TableOperator.delete,
          transaction: null,
          isExplain: false,
          whereParams: any(named: "whereParams"),
        ),
      ).thenThrow(
        ArcadeOrmException(message: "Delete Failed", originalError: null),
      );
      final arcadeOrm = await ArcadeOrm.init(
        adapter: mockAdapter,
      );
      final table = arcadeOrm.table(
        "users",
        {},
      );
      final createQuery = table.delete()..where({"id": eq(1)});
      final data = await createQuery.exec();
      expect(data, isA<ExecResultFailure>());
      expect((data as ExecResultFailure).exception.message, "Delete Failed");
    });
  });
}
