import 'dart:async';

import 'package:arcade_orm/arcade_orm.dart';
import 'package:arcade_orm/src/query/include.dart';
import 'package:arcade_orm/src/query/mixins/where.dart';
import 'package:arcade_orm/src/query/select.dart';
import 'package:arcade_orm/src/query/where.dart';

class ArcadeOrmTableFindOperator with WhereMixin {
  final ArcadeOrm _orm;
  final TableOperator _operator;
  final ArcadeOrmTransaction? _transaction;

  // final List<Map<String, WhereParam>> _havingParams = [];
  final List<IncludeParam> _includeParams = [];
  final List<String> _groupParams = [];
  final List<Map<String, int>> _sortParams = [];
  final List<Map<String, SelectParam>> _selectParams = [];

  int? _limit;
  int? _skip;

  bool _isExplain = false;

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
        isExplain: _isExplain,
        operator: _operator,
        transaction: _transaction,
        whereParams: $whereParams?.simplify(),
        includeParams: _includeParams,
        selectParams: _selectParams,
        // havingParams: _havingParams,
        groupParams: _groupParams,
        sortParams: _sortParams,
        limit: _limit,
        skip: _skip,
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

  void explain() {
    _isExplain = true;
  }

  void group(String column) {
    _groupParams.add(column);
  }

  // void having(Map<String, WhereParamBuilder> map) {
  //   _whereParams.add(WhereParam.evaluateWhereParams(map));
  // }

  void include(
    ArcadeOrmTableSchema table, {
    String? on,
    String? as,
    Map<String, WhereParamBuilder>? where,
    JoinOperation joinType = JoinOperation.inner,
  }) {
    _includeParams.add(
      IncludeParam(
        table.tableName,
        on: on,
        as: as,
        where: where,
        joinType: joinType,
      ),
    );
  }

  /// Set the number of results to return. Cannot be less than 1.
  void limit(int limit) {
    if (limit <= 0) {
      throw ArcadeOrmException(
        message: "limit cannot be less then 1",
        originalError: null,
      );
    }
    _limit = limit;
  }

  void select(Map<String, SelectParam> value) {
    _selectParams.add(value);
  }

  /// Set the number of results skipped. Cannot be less than 0.
  void skip(int skip) {
    if (skip < 0) {
      throw ArcadeOrmException(
        message: "skip cannot be less then 0",
        originalError: null,
      );
    }
    _skip = skip;
  }

  void sort(Map<String, int> sortBy) {
    final Map<String, int> sortValue =
        sortBy.map((key, value) => MapEntry(key, value > 0 ? 1 : -1));
    _sortParams.add(sortValue);
  }
}

class ArcadeOrmTableInsertOperator {
  final ArcadeOrm _orm;
  final TableOperator _operator;
  final ArcadeOrmTransaction? _transaction;

  final List<Map<String, dynamic>> _insertWithParams = [];

  bool _isExplain = false;

  ArcadeOrmTableInsertOperator({
    required ArcadeOrm orm,
    required TableOperator operator,
    ArcadeOrmTransaction? transaction,
  })  : _transaction = transaction,
        _operator = operator,
        _orm = orm;

  void insertWith(Map<String, dynamic> value) {
    _insertWithParams.add(value);
  }

  Future<ExecResult> exec<T>({
    ArcadeOrmTableFromConverter<T>? fromJson,
  }) async {
    try {
      final data = await _orm.adapter.operate(
        isExplain: _isExplain,
        operator: _operator,
        transaction: _transaction,
        insertWithParams: _insertWithParams,
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

  void explain() {
    _isExplain = true;
  }
}

class ArcadeOrmTableDeleteOperator with WhereMixin {
  final ArcadeOrm _orm;
  final TableOperator _operator;
  final ArcadeOrmTransaction? _transaction;

  final List<IncludeParam> _includeParams = [];

  bool _isExplain = false;

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
        isExplain: _isExplain,
        operator: _operator,
        transaction: _transaction,
        whereParams: $whereParams?.simplify(),
        includeParams: _includeParams,
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

  void explain() {
    _isExplain = true;
  }

  void include(
    ArcadeOrmTableSchema table, {
    String? on,
    String? as,
    Map<String, WhereParamBuilder>? where,
    JoinOperation joinType = JoinOperation.inner,
  }) {
    _includeParams.add(
      IncludeParam(
        table.tableName,
        on: on,
        as: as,
        where: where,
        joinType: joinType,
      ),
    );
  }
}

class ArcadeOrmTableRawOperator {
  final ArcadeOrm _orm;
  final TableOperator _operator;
  final ArcadeOrmTransaction? _transaction;

  bool _isExplain = false;

  String? _rawSql;
  Map<String, dynamic>? _rawNoSql;

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
        isExplain: _isExplain,
        rawSql: _rawSql,
        rawNoSql: _rawNoSql,
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

  void explain() {
    _isExplain = true;
  }

  // ignore: use_setters_to_change_properties
  void noSql(Map<String, dynamic> query) {
    _rawNoSql = query;
  }

  // ignore: use_setters_to_change_properties
  void sql(String query) {
    _rawSql = query;
  }
}

class ArcadeOrmTableUpdateOperator with WhereMixin {
  final ArcadeOrm _orm;
  final TableOperator _operator;
  final ArcadeOrmTransaction? _transaction;

  final List<Map<String, dynamic>> _updateWithParams = [];

  bool _isExplain = false;

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
        isExplain: _isExplain,
        operator: _operator,
        transaction: _transaction,
        whereParams: $whereParams?.simplify(),
        updateWithParams: _updateWithParams,
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

  void explain() {
    _isExplain = true;
  }

  void updateWith(Map<String, dynamic> value) {
    _updateWithParams.add(value);
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
