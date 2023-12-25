import 'dart:async';

import 'package:arcade_orm/arcade_orm.dart';
import 'package:arcade_orm/src/query/include.dart';
import 'package:arcade_orm/src/query/mixins/sort.dart';
import 'package:arcade_orm/src/query/select.dart';
import 'package:arcade_orm/src/query/where.dart';
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
    WhereExpressionNode? whereParams,
    WhereExpressionNode? havingParams,
    List<Map<String, SelectParam>> selectParams = const [],
    List<IncludeParam> includeParams = const [],
    List<String> groupParams = const [],
    List<Map<String, SortDirection>> sortParams = const [],
    Map<String, dynamic> updateWithParams = const {},
    List<Map<String, dynamic>> insertWithParams = const [],
    int? limit,
    int? skip,
  });

  void setArcadeOrmInstance(ArcadeOrm orm);

  ArcadeOrmTransaction transaction();

  FutureOr<void> close();
}

abstract class ArcadeOrmTransaction {
  bool _isStarted = false;
  bool _isCommitted = false;
  bool _isRolledBack = false;

  bool get isStarted => _isStarted;
  bool get isComitted => _isCommitted;
  bool get isRolledBack => _isRolledBack;

  Future<void> commit() async {
    _checkPrecondition("Commit");
    await $commit();
    _isCommitted = true;
  }

  Future<void> rollback() async {
    _checkPrecondition("Rollback");
    await $rollback();
    _isRolledBack = true;
  }

  Future<T?> start<T>([
    FutureOr<T> Function(ArcadeOrmTransaction trx)? callback,
  ]) async {
    try {
      _checkStartPreCondition();
      await $startTransaction();
      _isStarted = true;
      if (callback == null) {
        return null;
      }
      final data = await callback(this);
      await commit();
      return data;
    } catch (e) {
      if (callback != null) {
        await rollback();
      }
      rethrow;
    }
  }

  @protected
  Future<void> $commit();

  @protected
  Future<void> $rollback();

  @protected
  Future<void> $startTransaction();

  void _checkStartPreCondition() {
    if (_isCommitted) {
      throw ArcadeOrmException(
        message: "Cannot Start a transaction that is already committed",
        originalError: null,
      );
    }
    if (_isRolledBack) {
      throw ArcadeOrmException(
        message: "Cannot Start a transaction that is already rolled back",
        originalError: null,
      );
    }
  }

  void _checkPrecondition(String op) {
    if (!_isStarted) {
      throw ArcadeOrmException(
        message: "Cannot $op a transaction that has not been started",
        originalError: null,
      );
    }
    if (_isCommitted) {
      throw ArcadeOrmException(
        message: "Cannot $op a transaction that is already committed",
        originalError: null,
      );
    }
    if (_isRolledBack) {
      throw ArcadeOrmException(
        message: "Cannot $op a transaction that has been rolled back",
        originalError: null,
      );
    }
  }
}
