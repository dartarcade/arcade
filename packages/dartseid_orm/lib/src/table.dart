import 'dart:async';

import 'package:dartseid_orm/src/adapter.dart';
import 'package:dartseid_orm/src/core.dart';
import 'package:dartseid_orm/src/query.dart';

typedef DormTableConverter<T> = ({
  FutureOr<T> Function(Map<String, dynamic> json) fromJson,
  FutureOr<Map<String, dynamic>> Function() toJson,
});

typedef DormTableFromConverter<T> = ({
  FutureOr<T> Function(Map<String, dynamic> json) fromJson,
});

mixin DormTable {
  late String name;
  final List<DormTableSchema> _tables = [];

  late final Dorm _dorm = getDormInstance(name);

  DormTableSchema table(
    String name,
    Map<String, ColumnMeta> schema, {
    required DormTableConverter converter,
  }) {
    final schema =
        DormTableSchema(dorm: _dorm, name: name, baseConverter: converter);
    _dorm._tables.add(schema);
    return schema;
  }

  DormTableSchema getTable(String name) {
    try {
      return _tables.firstWhere((element) => element.name == name);
    } catch (e) {
      throw StateError(
        "Table ($name) not found. Please make sure table schema is initialized",
      );
    }
  }
}

class DormTableSchema {
  final Dorm dorm;
  final String name;
  final DormTableConverter baseConverter;

  DormTableSchema({
    required this.dorm,
    required this.name,
    required this.baseConverter,
  });

  DormTransaction transaction() {
    return dorm.transaction();
  }

  void index(Map<String, dynamic> config, {({bool? unique})? options}) {}

  DormTableRawOperator raw({DormTransaction? transaction}) {
    return DormTableRawOperator(
      dorm: dorm,
      operator: TableOperator.raw,
      baseConverter: baseConverter,
      transaction: transaction,
    );
  }

  DormTableFindOperator count({DormTransaction? transaction}) {
    return DormTableFindOperator(
      dorm: dorm,
      operator: TableOperator.count,
      baseConverter: baseConverter,
      transaction: transaction,
    );
  }

  DormTableFindOperator findOne({DormTransaction? transaction}) {
    return DormTableFindOperator(
      dorm: dorm,
      operator: TableOperator.findOne,
      baseConverter: baseConverter,
      transaction: transaction,
    );
  }

  DormTableFindOperator findMany({DormTransaction? transaction}) {
    return DormTableFindOperator(
      dorm: dorm,
      operator: TableOperator.findMany,
      baseConverter: baseConverter,
      transaction: transaction,
    );
  }

  DormTableCreateOperator create({DormTransaction? transaction}) {
    return DormTableCreateOperator(
      dorm: dorm,
      operator: TableOperator.create,
      baseConverter: baseConverter,
      transaction: transaction,
    );
  }

  DormTableUpdateOperator update({DormTransaction? transaction}) {
    return DormTableUpdateOperator(
      dorm: dorm,
      operator: TableOperator.update,
      baseConverter: baseConverter,
      transaction: transaction,
    );
  }

  DormTableDeleteOperator delete({DormTransaction? transaction}) {
    return DormTableDeleteOperator(
      dorm: dorm,
      operator: TableOperator.delete,
      baseConverter: baseConverter,
      transaction: transaction,
    );
  }
}

abstract class ColumnMeta {}

class ColumnInt implements ColumnMeta {}

class ColumnIntRange implements ColumnMeta {}

class ColumnFloat implements ColumnMeta {}

class ColumnBool implements ColumnMeta {}

class ColumnString implements ColumnMeta {
  final dynamic search;

  ColumnString({this.search});
}

class ColumnStringEnum implements ColumnMeta {}

class ColumnStringSet implements ColumnMeta {}

class ColumnBinary implements ColumnMeta {}

class ColumnDate implements ColumnMeta {}

class ColumnDateRange implements ColumnMeta {}

class ColumnJson implements ColumnMeta {}

class ColumnComposite implements ColumnMeta {}

class ColumnGeoJson implements ColumnMeta {}

class ColumnArray implements ColumnMeta {}

abstract interface class ColumnCustomDomain implements ColumnMeta {}

class ColumnCustom implements ColumnMeta {
  final String raw;

  ColumnCustom({required this.raw});
}
