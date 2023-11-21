import 'dart:async';

import 'package:arcade_orm/arcade_orm.dart';
import 'package:meta/meta.dart';

abstract interface class ArcadeOrmAdapterBase<T extends Record, U> {
  @protected
  final U connection;
  @protected
  final T? options;
  @protected
  late ArcadeOrm orm;

  ArcadeOrmAdapterBase({
    required this.connection,
    this.options,
  });

  FutureOr<void> init();
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
  });

  void setArcadeOrmInstance(ArcadeOrm orm);

  ArcadeOrmTransaction transaction();

  FutureOr<void> close();
}

abstract class ArcadeOrmTransaction {
  bool isStarted = false;
  bool isCommitted = false;
  bool isRolledBack = false;

  Future<void> _commit() async {
    _checkPrecondition("Commit");
    await commit();
    isCommitted = true;
  }

  Future<void> _rollback() async {
    _checkPrecondition("Rollback");
    await rollback();
    isRolledBack = true;
  }

  Future<T?> start<T>([
    FutureOr<T> Function(ArcadeOrmTransaction trx)? callback,
  ]) async {
    try {
      _checkStartPreCondition();
      await startTransaction();
      isStarted = true;
      if (callback == null) {
        return null;
      }
      final data = await callback(this);
      await _commit();
      return data;
    } catch (e) {
      if (callback != null) {
        await _rollback();
      }
      rethrow;
    }
  }

  Future<void> commit();

  Future<void> rollback();

  /// Use [ArcadeOrmTransaction.start] instead
  @protected
  Future<void> startTransaction();

  void _checkStartPreCondition() {
    if (isCommitted) {
      throw ArcadeOrmException(
        message: "Cannot Start a transaction that is already committed",
        originalError: null,
      );
    }
    if (isRolledBack) {
      throw ArcadeOrmException(
        message: "Cannot Start a transaction that is already rolled back",
        originalError: null,
      );
    }
  }

  void _checkPrecondition(String op) {
    if (!isStarted) {
      throw ArcadeOrmException(
        message: "Cannot $op a transaction that has not been started",
        originalError: null,
      );
    }
    if (isCommitted) {
      throw ArcadeOrmException(
        message: "Cannot $op a transaction that is already committed",
        originalError: null,
      );
    }
    if (isRolledBack) {
      throw ArcadeOrmException(
        message: "Cannot $op a transaction that has been rolled back",
        originalError: null,
      );
    }
  }
}
