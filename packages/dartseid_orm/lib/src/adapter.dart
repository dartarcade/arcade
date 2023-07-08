import 'dart:async';

import 'package:dartseid_orm/src/core.dart';
import 'package:dartseid_orm/src/query.dart';

abstract interface class DormAdapterBase {
  final dynamic _connection;

  DormAdapterBase({
    required dynamic connection,
  }) : _connection = connection;

  Future<void> init();
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
  });
  DormTransaction transaction();
}

abstract class DormTransaction {
  bool isStarted = false;
  bool isCommitted = false;
  bool isRolledBack = false;

  Future<void> commit() async {
    if (!isStarted) {
      throw DormException(
        message: "Cannot Commit a transaction that has not been started",
        originalError: null,
      );
    }
    if (isCommitted) {
      throw DormException(
        message: "Cannot Commit a transaction that is already committed",
        originalError: null,
      );
    }
    if (isRolledBack) {
      throw DormException(
        message: "Cannot Commit a transaction that has been rolled back",
        originalError: null,
      );
    }
    await _commit();
    isCommitted = true;
  }

  Future<void> rollback() async {
    if (!isStarted) {
      throw DormException(
        message: "Cannot Rollback a transaction that has not been started",
        originalError: null,
      );
    }
    if (isCommitted) {
      throw DormException(
        message: "Cannot Rollback a transaction that is already committed",
        originalError: null,
      );
    }
    if (isRolledBack) {
      throw DormException(
        message: "Cannot Rollback a transaction that is already rolled back",
        originalError: null,
      );
    }
    await _rollback();
    isRolledBack = true;
  }

  Future<T?> start<T>([
    FutureOr<T> Function(DormTransaction trx)? callback,
  ]) async {
    try {
      await _start();
      isStarted = true;
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

  Future<void> _commit();

  Future<void> _rollback();

  Future<void> _start();
}
