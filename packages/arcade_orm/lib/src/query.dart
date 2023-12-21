import 'dart:async';

import 'package:arcade_orm/arcade_orm.dart';

const dAnd = r'$__AND';
const dOr = r'$__OR';

Map<String, MultipleWhereParam> and(List<Map<String, SingleWhereParam>> value) {
  final List<Map<String, WhereParam>> whereParamList = [];
  for (final element in value) {
    element.forEach((key, _) {
      if (element[key] != null) {
        element[key]!.param.isAnd = true;
        element[key]!.param.isOr = false;
        whereParamList.add({key: element[key]!.param});
      }
    });
  }
  return {dAnd: MultipleWhereParam(whereParamList)};
}

Map<String, MultipleWhereParam> or(List<Map<String, SingleWhereParam>> value) {
  final List<Map<String, WhereParam>> whereParamList = [];
  for (final element in value) {
    element.forEach((key, _) {
      if (element[key] != null) {
        element[key]!.param.isAnd = false;
        element[key]!.param.isOr = true;
        whereParamList.add({key: element[key]!.param});
      }
    });
  }
  return {dOr: MultipleWhereParam(whereParamList)};
}

SingleWhereParam array<T>(T value) {
  return SingleWhereParam(
    WhereParam(
      operator: WhereOperator.array,
      value: value,
    ),
  );
}

SingleWhereParam between<T>(T start, T end) {
  return SingleWhereParam(
    WhereParam(
      operator: WhereOperator.between,
      start: start,
      end: end,
    ),
  );
}

SingleWhereParam eq<T>(T value) {
  return SingleWhereParam(
    WhereParam(
      operator: WhereOperator.eq,
      value: value,
    ),
  );
}

SingleWhereParam gt<T>(T value) {
  return SingleWhereParam(
    WhereParam(
      operator: WhereOperator.gt,
      value: value,
    ),
  );
}

SingleWhereParam gte<T>(T value) {
  return SingleWhereParam(
    WhereParam(
      operator: WhereOperator.gte,
      value: value,
    ),
  );
}

SingleWhereParam like(String value) {
  return SingleWhereParam(
    WhereParam(
      operator: WhereOperator.like,
      value: value,
    ),
  );
}

SingleWhereParam lt<T>(T value) {
  return SingleWhereParam(
    WhereParam(
      operator: WhereOperator.lt,
      value: value,
    ),
  );
}

SingleWhereParam lte<T>(T value) {
  return SingleWhereParam(
    WhereParam(
      operator: WhereOperator.lte,
      value: value,
    ),
  );
}

SingleWhereParam notInArray<T>(T value) {
  return SingleWhereParam(
    WhereParam(
      operator: WhereOperator.notInArray,
      value: value,
    ),
  );
}

SingleWhereParam notEq<T>(T value) {
  return SingleWhereParam(
    WhereParam(
      operator: WhereOperator.notEq,
      value: value,
    ),
  );
}

SelectParam avg(String value) {
  return SelectParam(
    operator: SelectAggregationOperator.avg,
    fieldAs: value,
  );
}

SelectParam count(String value) {
  return SelectParam(
    operator: SelectAggregationOperator.count,
    fieldAs: value,
  );
}

SelectParam countDistinct(String value) {
  return SelectParam(
    operator: SelectAggregationOperator.countDistinct,
    fieldAs: value,
  );
}

SelectParam distinct(String value) {
  return SelectParam(
    operator: SelectAggregationOperator.distinct,
    fieldAs: value,
  );
}

SelectParam field(String value) {
  return SelectParam(
    operator: SelectAggregationOperator.show,
    fieldAs: value,
  );
}

SelectParam hide() {
  return SelectParam(
    operator: SelectAggregationOperator.hide,
  );
}

SelectParam max(String value) {
  return SelectParam(
    operator: SelectAggregationOperator.max,
    fieldAs: value,
  );
}

SelectParam min(String value) {
  return SelectParam(
    operator: SelectAggregationOperator.min,
    fieldAs: value,
  );
}

SelectParam show() {
  return SelectParam(
    operator: SelectAggregationOperator.show,
  );
}

SelectParam sum(String value) {
  return SelectParam(
    operator: SelectAggregationOperator.sum,
    fieldAs: value,
  );
}

class ArcadeOrmTableFindOperator {
  final ArcadeOrm _orm;
  final TableOperator _operator;
  final ArcadeOrmTransaction? _transaction;

  final List<Map<String, WhereParam>> _whereParams = [];
  final List<Map<String, WhereParam>> _havingParams = [];
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
        whereParams: _whereParams,
        includeParams: _includeParams,
        selectParams: _selectParams,
        havingParams: _havingParams,
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

  void having(Map<String, WhereParamBuilder> map) {
    _whereParams.add(WhereParam.evaluateWhereParams(map));
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

  void where(Map<String, WhereParamBuilder> map) {
    _whereParams.add(WhereParam.evaluateWhereParams(map));
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

class ArcadeOrmTableDeleteOperator {
  final ArcadeOrm _orm;
  final TableOperator _operator;
  final ArcadeOrmTransaction? _transaction;

  final List<Map<String, WhereParam>> _whereParams = [];
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
        whereParams: _whereParams,
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

  void where(Map<String, WhereParamBuilder> map) {
    _whereParams.add(WhereParam.evaluateWhereParams(map));
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

class ArcadeOrmTableUpdateOperator {
  final ArcadeOrm _orm;
  final TableOperator _operator;
  final ArcadeOrmTransaction? _transaction;

  final List<Map<String, dynamic>> _updateWithParams = [];
  final List<Map<String, WhereParam>> _whereParams = [];

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
        whereParams: _whereParams,
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

  void where(Map<String, WhereParamBuilder> map) {
    _whereParams.add(WhereParam.evaluateWhereParams(map));
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

class IncludeParam {
  final String tableName;
  final String? on;
  final String? as;
  final JoinOperation joinType;
  Map<String, WhereParam>? where;
  IncludeParam(
    this.tableName, {
    this.on,
    this.as,
    this.joinType = JoinOperation.inner,
    Map<String, WhereParamBuilder>? where,
  }) {
    Map<String, WhereParam>? value;
    if (where != null) {
      value = WhereParam.evaluateWhereParams(where);
    }
    this.where = value;
  }
}

enum JoinOperation {
  inner,
  left,
  right,
  cross,
}

enum SelectAggregationOperator {
  show,
  hide,
  count,
  sum,
  avg,
  min,
  max,
  distinct,
  countDistinct,
}

class SelectParam {
  String? fieldAs;
  final SelectAggregationOperator operator;

  SelectParam({
    required this.operator,
    this.fieldAs,
  });
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

enum WhereOperator {
  eq,
  gt,
  gte,
  lt,
  lte,
  between,
  notEq,
  like,
  array,
  notInArray,
  and,
  or,
}

sealed class WhereParamBuilder<T> {}

class SingleWhereParam<T> extends WhereParamBuilder<T> {
  final WhereParam param;

  SingleWhereParam(this.param);
}

class MultipleWhereParam<T> extends WhereParamBuilder<T> {
  final List<Map<String, WhereParam>> param;

  MultipleWhereParam(this.param);
}

class WhereParam<T> {
  final WhereOperator operator;
  final T? value;
  final T? start;
  final T? end;
  bool isAnd = true;
  bool isOr = false;

  WhereParam({
    required this.operator,
    this.value,
    this.start,
    this.end,
  });

  static Map<String, WhereParam> evaluateWhereParams(
    Map<String, WhereParamBuilder> map,
  ) {
    Map<String, WhereParam> value = {};

    if (map.containsKey(dAnd)) {
      final multiple = map[dAnd]! as MultipleWhereParam;
      for (final element in multiple.param) {
        value = element;
      }
    } else if (map.containsKey(dOr)) {
      final multiple = map[dOr]! as MultipleWhereParam;
      for (final element in multiple.param) {
        value = element;
      }
    } else {
      value = map.map(
        (key, v) => MapEntry(key, (v as SingleWhereParam).param),
      );
    }

    return value;
  }
}
