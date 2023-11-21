import 'dart:async';

import 'package:arcade_orm/arcade_orm.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockAdapter extends Mock implements ArcadeOrmAdapterBase {}

class Transaction extends ArcadeOrmTransaction {
  int commitCount = 0;
  int rollbackCount = 0;
  int startCount = 0;

  @override
  Future<void> $commit() async {
    commitCount++;
  }

  @override
  Future<void> $rollback() async {
    rollbackCount++;
  }

  @override
  Future<void> $startTransaction() async {
    startCount++;
  }
}

void main() {
  final mockAdapter = MockAdapter();
  group('transaction', () {
    setUp(() {
      when(() => mockAdapter.transaction()).thenReturn(Transaction());
    });
    tearDown(clearOrms);
    test("commit flow", () async {
      final arcadeOrm = await ArcadeOrm.init(
        adapter: mockAdapter,
      );
      final trx = arcadeOrm.transaction() as Transaction;
      await trx.start();
      await trx.commit();
      final Transaction(:startCount, :commitCount, :rollbackCount) = trx;
      expect(startCount, 1);
      expect(commitCount, 1);
      expect(rollbackCount, 0);
    });
    test("rollback flow", () async {
      final arcadeOrm = await ArcadeOrm.init(
        adapter: mockAdapter,
      );
      final trx = arcadeOrm.transaction() as Transaction;
      await trx.start();
      await trx.rollback();
      final Transaction(:startCount, :commitCount, :rollbackCount) = trx;
      expect(startCount, 1);
      expect(commitCount, 0);
      expect(rollbackCount, 1);
    });
    test("callback commit flow", () async {
      final arcadeOrm = await ArcadeOrm.init(
        adapter: mockAdapter,
      );
      final trx = arcadeOrm.transaction() as Transaction;
      final data = await trx.start((trx) async {
        return {"key": "value"};
      });
      expect(data, {"key": "value"});
      final Transaction(:startCount, :commitCount, :rollbackCount) = trx;
      expect(startCount, 1);
      expect(commitCount, 1);
      expect(rollbackCount, 0);
    });
    test("callback rollback flow", () async {
      final arcadeOrm = await ArcadeOrm.init(
        adapter: mockAdapter,
      );
      final trx = arcadeOrm.transaction() as Transaction;
      try {
        await trx.start((trx) async {
          throw Exception();
        });
      } catch (_) {
        final Transaction(:startCount, :commitCount, :rollbackCount) = trx;
        expect(startCount, 1);
        expect(commitCount, 0);
        expect(rollbackCount, 1);
        return;
      }
      throw Exception("Expected Exception");
    });
    test("early commit", () async {
      try {
        final arcadeOrm = await ArcadeOrm.init(
          adapter: mockAdapter,
        );
        final trx = arcadeOrm.transaction() as Transaction;
        await trx.commit();
        fail("Expected an Exception");
      } catch (e) {
        if (e is! ArcadeOrmException) {
          fail("Expected ArcadeOrmException");
        }
        expect(
          e.message,
          "Cannot Commit a transaction that has not been started",
        );
      }
    });
    test("callback early commit", () async {
      try {
        final arcadeOrm = await ArcadeOrm.init(
          adapter: mockAdapter,
        );
        final trx = arcadeOrm.transaction() as Transaction;
        await trx.start((trx) async {
          await trx.commit();
        });
      } on ArcadeOrmException catch (e) {
        expect(
          e.message,
          "Cannot Rollback a transaction that is already committed",
        );
        return;
      }
      fail("Expected ArcadeOrmException");
    });
    test("early rollback", () async {
      try {
        final arcadeOrm = await ArcadeOrm.init(
          adapter: mockAdapter,
        );
        final trx = arcadeOrm.transaction() as Transaction;
        await trx.rollback();
      } on ArcadeOrmException catch (e) {
        expect(
          e.message,
          "Cannot Rollback a transaction that has not been started",
        );
        return;
      }
      throw Exception("Expected ArcadeOrmException");
    });
    test("callback - early rollback", () async {
      try {
        final arcadeOrm = await ArcadeOrm.init(
          adapter: mockAdapter,
        );
        final trx = arcadeOrm.transaction() as Transaction;
        await trx.start((trx) async {
          await trx.rollback();
        });
      } on ArcadeOrmException catch (e) {
        expect(
          e.message,
          "Cannot Rollback a transaction that has been rolled back",
        );
        return;
      }
      throw Exception("Expected ArcadeOrmException");
    });
    test("late start after commit", () async {
      try {
        final arcadeOrm = await ArcadeOrm.init(
          adapter: mockAdapter,
        );
        final trx = arcadeOrm.transaction() as Transaction;
        await trx.start();
        await trx.commit();
        await trx.start();
      } on ArcadeOrmException catch (e) {
        expect(
          e.message,
          "Cannot Start a transaction that is already committed",
        );
        return;
      }
      throw Exception("Expected ArcadeOrmException");
    });
    test("callback - late start after commit", () async {
      try {
        final arcadeOrm = await ArcadeOrm.init(
          adapter: mockAdapter,
        );
        final trx = arcadeOrm.transaction() as Transaction;
        await trx.start((trx) async {});
        await trx.start();
      } on ArcadeOrmException catch (e) {
        expect(
          e.message,
          "Cannot Start a transaction that is already committed",
        );
        return;
      }
      throw Exception("Expected ArcadeOrmException");
    });
    test("late start after rollback", () async {
      try {
        final arcadeOrm = await ArcadeOrm.init(
          adapter: mockAdapter,
        );
        final trx = arcadeOrm.transaction() as Transaction;
        await trx.start();
        await trx.rollback();
        await trx.start();
      } on ArcadeOrmException catch (e) {
        expect(
          e.message,
          "Cannot Start a transaction that is already rolled back",
        );
        return;
      }
      throw Exception("Expected ArcadeOrmException");
    });
    test("callback - late start after rollback", () async {
      try {
        final arcadeOrm = await ArcadeOrm.init(
          adapter: mockAdapter,
        );
        final trx = arcadeOrm.transaction() as Transaction;
        try {
          await trx.start((trx) async {
            throw Exception();
          });
        } catch (_) {}
        await trx.start();
      } on ArcadeOrmException catch (e) {
        expect(
          e.message,
          "Cannot Start a transaction that is already rolled back",
        );
        return;
      }
      throw Exception("Expected ArcadeOrmException");
    });
    test("commit after rollback", () async {
      try {
        final arcadeOrm = await ArcadeOrm.init(
          adapter: mockAdapter,
        );
        final trx = arcadeOrm.transaction() as Transaction;
        await trx.start();
        await trx.rollback();
        await trx.commit();
      } on ArcadeOrmException catch (e) {
        expect(
          e.message,
          "Cannot Commit a transaction that has been rolled back",
        );
        return;
      }
      throw Exception("Expected ArcadeOrmException");
    });
    test("callback - commit after rollback", () async {
      try {
        final arcadeOrm = await ArcadeOrm.init(
          adapter: mockAdapter,
        );
        final trx = arcadeOrm.transaction() as Transaction;
        try {
          await trx.start((trx) async {
            throw Exception();
          });
        } catch (_) {}
        await trx.commit();
      } on ArcadeOrmException catch (e) {
        expect(
          e.message,
          "Cannot Commit a transaction that has been rolled back",
        );
        return;
      }
      throw Exception("Expected ArcadeOrmException");
    });
    test("rollback after commit", () async {
      try {
        final arcadeOrm = await ArcadeOrm.init(
          adapter: mockAdapter,
        );
        final trx = arcadeOrm.transaction() as Transaction;
        await trx.start();
        await trx.commit();
        await trx.rollback();
      } on ArcadeOrmException catch (e) {
        expect(
          e.message,
          "Cannot Rollback a transaction that is already committed",
        );
        return;
      }
      throw Exception("Expected ArcadeOrmException");
    });
    test("callback - rollback after commit", () async {
      try {
        final arcadeOrm = await ArcadeOrm.init(
          adapter: mockAdapter,
        );
        final trx = arcadeOrm.transaction() as Transaction;
        await trx.start((trx) async {});
        await trx.rollback();
      } on ArcadeOrmException catch (e) {
        expect(
          e.message,
          "Cannot Rollback a transaction that is already committed",
        );
        return;
      }
      throw Exception("Expected ArcadeOrmException");
    });
  });
}
