import 'dart:async';

import 'package:arcade_orm/arcade_orm.dart';

typedef ArcadeOrmTableConverter<T> = ({
  FutureOr<T> Function(Map<String, dynamic> json) fromJson,
  FutureOr<Map<String, dynamic>> Function() toJson,
});

typedef ArcadeOrmTableFromConverter<T> = FutureOr<T> Function(
  Map<String, dynamic> json,
);

mixin ArcadeOrmTable {
  late String name;
  final List<ArcadeOrmTableSchema> _tables = [];

  late final ArcadeOrm _orm = getArcadeOrmInstance(name);

  ArcadeOrmTableSchema table(String name, Map<String, ColumnMeta> schema) {
    final schema = ArcadeOrmTableSchema(orm: _orm, name: name);
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

  ArcadeOrmTableSchema({
    required this.orm,
    required this.name,
  });

  ArcadeOrmTransaction transaction() {
    return orm.transaction();
  }

  void index(Map<String, dynamic> config, {({bool? unique})? options}) {}

  ArcadeOrmTableRawOperator raw({ArcadeOrmTransaction? transaction}) {
    return ArcadeOrmTableRawOperator(
      orm: orm,
      operator: TableOperator.raw,
      transaction: transaction,
    );
  }

  ArcadeOrmTableFindOperator count({ArcadeOrmTransaction? transaction}) {
    return ArcadeOrmTableFindOperator(
      orm: orm,
      operator: TableOperator.count,
      transaction: transaction,
    );
  }

  ArcadeOrmTableFindOperator findOne({ArcadeOrmTransaction? transaction}) {
    return ArcadeOrmTableFindOperator(
      orm: orm,
      operator: TableOperator.findOne,
      transaction: transaction,
    );
  }

  ArcadeOrmTableFindOperator findMany({ArcadeOrmTransaction? transaction}) {
    return ArcadeOrmTableFindOperator(
      orm: orm,
      operator: TableOperator.findMany,
      transaction: transaction,
    );
  }

  ArcadeOrmTableCreateOperator create({ArcadeOrmTransaction? transaction}) {
    return ArcadeOrmTableCreateOperator(
      orm: orm,
      operator: TableOperator.create,
      transaction: transaction,
    );
  }

  ArcadeOrmTableUpdateOperator update({ArcadeOrmTransaction? transaction}) {
    return ArcadeOrmTableUpdateOperator(
      orm: orm,
      operator: TableOperator.update,
      transaction: transaction,
    );
  }

  ArcadeOrmTableDeleteOperator delete({ArcadeOrmTransaction? transaction}) {
    return ArcadeOrmTableDeleteOperator(
      orm: orm,
      operator: TableOperator.delete,
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
