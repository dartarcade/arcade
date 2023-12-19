import 'dart:async';

import 'package:arcade_orm/arcade_orm.dart';

typedef ArcadeOrmTableConverter<T> = ({
  FutureOr<T> Function(Map<String, dynamic> json) fromJson,
  FutureOr<Map<String, dynamic>> Function() toJson,
});

typedef ArcadeOrmTableFromConverter<T> = ({
  FutureOr<T> Function(Map<String, dynamic> json) fromJson,
});

mixin ArcadeOrmTable {
  late String name;
  final List<ArcadeOrmTableSchema> _tables = [];

  late final ArcadeOrm _orm = getArcadeOrmInstance(name);

  ArcadeOrmTableSchema table(
    String name,
    Map<String, ColumnMeta> schema, {
    required ArcadeOrmTableConverter converter,
  }) {
    final schema =
        ArcadeOrmTableSchema(orm: _orm, name: name, baseConverter: converter);
    _orm._tables.add(schema);
    return schema;
  }

  ArcadeOrmTableSchema getTable(String name) {
    try {
      return _tables.firstWhere((element) => element.name == name);
    } catch (e) {
      throw StateError(
        "Table ($name) not found. Please make sure table schema is initialized",
      );
    }
  }
}

class ArcadeOrmTableSchema {
  final ArcadeOrm orm;
  final String name;
  final ArcadeOrmTableConverter baseConverter;

  ArcadeOrmTableSchema({
    required this.orm,
    required this.name,
    required this.baseConverter,
  });

  ArcadeOrmTransaction transaction() {
    return orm.transaction();
  }

  void index(Map<String, dynamic> config, {({bool? unique})? options}) {}

  ArcadeOrmTableRawOperator raw({ArcadeOrmTransaction? transaction}) {
    return ArcadeOrmTableRawOperator(
      orm: orm,
      operator: TableOperator.raw,
      baseConverter: baseConverter,
      transaction: transaction,
    );
  }

  ArcadeOrmTableFindOperator count({ArcadeOrmTransaction? transaction}) {
    return ArcadeOrmTableFindOperator(
      orm: orm,
      operator: TableOperator.count,
      baseConverter: baseConverter,
      transaction: transaction,
    );
  }

  ArcadeOrmTableFindOperator findOne({ArcadeOrmTransaction? transaction}) {
    return ArcadeOrmTableFindOperator(
      orm: orm,
      operator: TableOperator.findOne,
      baseConverter: baseConverter,
      transaction: transaction,
    );
  }

  ArcadeOrmTableFindOperator findMany({ArcadeOrmTransaction? transaction}) {
    return ArcadeOrmTableFindOperator(
      orm: orm,
      operator: TableOperator.findMany,
      baseConverter: baseConverter,
      transaction: transaction,
    );
  }

  ArcadeOrmTableCreateOperator create({ArcadeOrmTransaction? transaction}) {
    return ArcadeOrmTableCreateOperator(
      orm: orm,
      operator: TableOperator.create,
      baseConverter: baseConverter,
      transaction: transaction,
    );
  }

  ArcadeOrmTableUpdateOperator update({ArcadeOrmTransaction? transaction}) {
    return ArcadeOrmTableUpdateOperator(
      orm: orm,
      operator: TableOperator.update,
      baseConverter: baseConverter,
      transaction: transaction,
    );
  }

  ArcadeOrmTableDeleteOperator delete({ArcadeOrmTransaction? transaction}) {
    return ArcadeOrmTableDeleteOperator(
      orm: orm,
      operator: TableOperator.delete,
      baseConverter: baseConverter,
      transaction: transaction,
    );
  }
}

class ColumnMeta {
  void nullable() {
    // do something
  }
}

class ColumnInt extends ColumnMeta {}

class ColumnIntRange extends ColumnMeta {}

class ColumnFloat extends ColumnMeta {}

class ColumnBool extends ColumnMeta {}

class ColumnString extends ColumnMeta {
  final dynamic search;

  ColumnString({this.search});
}

class ColumnStringEnum extends ColumnMeta {}

class ColumnStringSet extends ColumnMeta {}

class ColumnBinary extends ColumnMeta {}

class ColumnDate extends ColumnMeta {}

class ColumnDateRange extends ColumnMeta {}

class ColumnJson extends ColumnMeta {}

class ColumnComposite extends ColumnMeta {}

class ColumnGeoJson extends ColumnMeta {}

class ColumnObjectId extends ColumnMeta {}

class ColumnArray extends ColumnMeta {}

abstract interface class ColumnCustomDomain extends ColumnMeta {}

class ColumnCustom extends ColumnMeta {
  final String raw;

  ColumnCustom({required this.raw});
}
