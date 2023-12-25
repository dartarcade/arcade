import 'dart:async';

import 'package:arcade_orm/arcade_orm.dart';
import 'package:arcade_orm/src/query/mixins/group.dart';
import 'package:arcade_orm/src/query/mixins/include.dart';
import 'package:arcade_orm/src/query/mixins/insert.dart';
import 'package:arcade_orm/src/query/mixins/pagination.dart';
import 'package:arcade_orm/src/query/mixins/raw.dart';
import 'package:arcade_orm/src/query/mixins/select.dart';
import 'package:arcade_orm/src/query/mixins/sort.dart';
import 'package:arcade_orm/src/query/mixins/update.dart';
import 'package:arcade_orm/src/query/mixins/verbose.dart';
import 'package:arcade_orm/src/query/mixins/where.dart';

class ArcadeOrmTableFindOperator
    with
        SelectMixin,
        WhereMixin,
        GroupMixin,
        PaginationMixin,
        SortMixin,
        IncludeMixin,
        VerboseMixin {
  final ArcadeOrm _orm;
  final TableOperator _operator;
  final ArcadeOrmTransaction? _transaction;

  ArcadeOrmTableFindOperator({
    required ArcadeOrm orm,
    required TableOperator operator,
    ArcadeOrmTransaction? transaction,
  })  : _transaction = transaction,
        _operator = operator,
        _orm = orm;

  Future<ExecResult<T>> exec<T>({
    ArcadeOrmTableFromConverter<T>? fromJson,
  }) async {
    try {
      final data = await _orm.adapter.operate(
        isVerbose: $verbose,
        operator: _operator,
        transaction: _transaction,
        whereParams: $whereParams?.simplify(),
        includeParams: $includeParams,
        selectParams: $selectParams,
        // havingParams: _havingParams,
        groupParams: $groupParams,
        sortParams: $sortParams,
        limit: $limit,
        skip: $skip,
      );

      final convertedData = await fromJson?.call(data);

      return ExecResultData(convertedData ?? data as T);
    } on ArcadeOrmException catch (e) {
      return ExecResultFailure(e);
    } catch (e) {
      return ExecResultFailure(
        ArcadeOrmException(originalError: e, message: "Unknown Error"),
      );
    }
  }

  // void having(Map<String, WhereParamBuilder> map) {
  //   _whereParams.add(WhereParam.evaluateWhereParams(map));
  // }
}

class ArcadeOrmTableInsertOperator with InsertMixin, VerboseMixin {
  final ArcadeOrm _orm;
  final TableOperator _operator;
  final ArcadeOrmTransaction? _transaction;

  ArcadeOrmTableInsertOperator({
    required ArcadeOrm orm,
    required TableOperator operator,
    ArcadeOrmTransaction? transaction,
  })  : _transaction = transaction,
        _operator = operator,
        _orm = orm;

  Future<ExecResult> exec<T>({
    ArcadeOrmTableFromConverter<T>? fromJson,
  }) async {
    try {
      final data = await _orm.adapter.operate(
        isVerbose: $verbose,
        operator: _operator,
        transaction: _transaction,
        insertWithParams: $insertWithParams,
      );

      final convertedData = await fromJson?.call(data);

      return ExecResultData(convertedData ?? data);
    } on ArcadeOrmException catch (e) {
      return ExecResultFailure(e);
    } catch (e) {
      return ExecResultFailure(
        ArcadeOrmException(originalError: e, message: "Unknown Error"),
      );
    }
  }
}

class ArcadeOrmTableDeleteOperator with WhereMixin, IncludeMixin, VerboseMixin {
  final ArcadeOrm _orm;
  final TableOperator _operator;
  final ArcadeOrmTransaction? _transaction;

  ArcadeOrmTableDeleteOperator({
    required ArcadeOrm orm,
    required TableOperator operator,
    ArcadeOrmTransaction? transaction,
  })  : _transaction = transaction,
        _operator = operator,
        _orm = orm;

  Future<ExecResult> exec<T>({
    ArcadeOrmTableFromConverter<T>? fromJson,
  }) async {
    try {
      final data = await _orm.adapter.operate(
        operator: _operator,
        transaction: _transaction,
        isVerbose: $verbose,
        whereParams: $whereParams?.simplify(),
        includeParams: $includeParams,
      );

      final convertedData = await fromJson?.call(data);

      return ExecResultData(convertedData ?? data);
    } on ArcadeOrmException catch (e) {
      return ExecResultFailure(e);
    } catch (e) {
      return ExecResultFailure(
        ArcadeOrmException(originalError: e, message: "Unknown Error"),
      );
    }
  }
}

class ArcadeOrmTableRawOperator with VerboseMixin, RawMixin {
  final ArcadeOrm _orm;
  final TableOperator _operator;
  final ArcadeOrmTransaction? _transaction;

  ArcadeOrmTableRawOperator({
    required ArcadeOrm orm,
    required TableOperator operator,
    ArcadeOrmTransaction? transaction,
  })  : _transaction = transaction,
        _operator = operator,
        _orm = orm;

  Future<ExecResult> exec<T>({
    ArcadeOrmTableFromConverter<T>? fromJson,
  }) async {
    try {
      final data = await _orm.adapter.operate(
        rawSql: $rawSql,
        rawParams: $params,
        rawNoSqlAggregate: $rawNoSqlAggregate,
        rawNoSqlAggregateOptions: $rawNoSqlAggregateOptions,
        isVerbose: $verbose,
        operator: _operator,
        transaction: _transaction,
      );

      final convertedData = await fromJson?.call(data);

      return ExecResultData(convertedData ?? data);
    } on ArcadeOrmException catch (e) {
      return ExecResultFailure(e);
    } catch (e) {
      return ExecResultFailure(
        ArcadeOrmException(originalError: e, message: "Unknown Error"),
      );
    }
  }
}

class ArcadeOrmTableUpdateOperator with WhereMixin, UpdateMixin, VerboseMixin {
  final ArcadeOrm _orm;
  final TableOperator _operator;
  final ArcadeOrmTransaction? _transaction;

  ArcadeOrmTableUpdateOperator({
    required ArcadeOrm orm,
    required TableOperator operator,
    ArcadeOrmTransaction? transaction,
  })  : _transaction = transaction,
        _operator = operator,
        _orm = orm;

  Future<ExecResult> exec<T>({
    ArcadeOrmTableFromConverter<T>? fromJson,
  }) async {
    try {
      final data = await _orm.adapter.operate(
        isVerbose: $verbose,
        operator: _operator,
        transaction: _transaction,
        whereParams: $whereParams?.simplify(),
        updateWithParams: $updateWithParams,
      );

      final convertedData = await fromJson?.call(data);

      return ExecResultData(convertedData ?? data);
    } on ArcadeOrmException catch (e) {
      return ExecResultFailure(e);
    } catch (e) {
      return ExecResultFailure(
        ArcadeOrmException(originalError: e, message: "Unknown Error"),
      );
    }
  }
}

sealed class ExecResult<T> {}

class ExecResultData<T> extends ExecResult<T> {
  final T data;

  ExecResultData(this.data);
}

class ExecResultFailure<T> extends ExecResult<T> {
  final ArcadeOrmException exception;

  ExecResultFailure(this.exception);
}

enum TableOperator {
  raw,
  count,
  findOne,
  findMany,
  insert,
  update,
  delete,
}
