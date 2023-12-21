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

  ArcadeOrmTableSchema getTable(String name) {
    try {
      return _tables.firstWhere((element) => element.tableName == name);
    } catch (e) {
      throw StateError(
        "Table ($name) not found. Please make sure table schema is initialized",
      );
    }
  }
}

typedef ArcadeTableIndexRecord = (int direction, {bool? unique});

typedef ArcadeOrmRelationshipRecord = ({
  ArcadeOrmRelationshipType type,
  String table,
  String localKey,
  String foreignKey,
});

enum ArcadeOrmRelationshipType {
  hasOne,
  hasMany,
  belongsTo,
  belongsToMany,
}

abstract class ArcadeOrmTableSchema {
  late final ArcadeOrm $orm;
  String get tableName;

  Map<String, ColumnMeta> get schema;
  Map<String, ArcadeTableIndexRecord> get index => {};
  Map<String, dynamic> get relations => {};

  ArcadeOrmTableSchema(ArcadeOrm orm) {
    $orm = orm;
    orm._tables.add(this);
  }

  ArcadeOrmTransaction transaction() {
    return $orm.transaction();
  }

  ArcadeOrmTableRawOperator raw({ArcadeOrmTransaction? transaction}) {
    return ArcadeOrmTableRawOperator(
      orm: $orm,
      operator: TableOperator.raw,
      transaction: transaction,
    );
  }

  ArcadeOrmTableFindOperator count({ArcadeOrmTransaction? transaction}) {
    return ArcadeOrmTableFindOperator(
      orm: $orm,
      operator: TableOperator.count,
      transaction: transaction,
    );
  }

  ArcadeOrmTableFindOperator findOne({ArcadeOrmTransaction? transaction}) {
    return ArcadeOrmTableFindOperator(
      orm: $orm,
      operator: TableOperator.findOne,
      transaction: transaction,
    );
  }

  ArcadeOrmTableFindOperator findMany({ArcadeOrmTransaction? transaction}) {
    return ArcadeOrmTableFindOperator(
      orm: $orm,
      operator: TableOperator.findMany,
      transaction: transaction,
    );
  }

  ArcadeOrmTableInsertOperator insert({ArcadeOrmTransaction? transaction}) {
    return ArcadeOrmTableInsertOperator(
      orm: $orm,
      operator: TableOperator.insert,
      transaction: transaction,
    );
  }

  ArcadeOrmTableUpdateOperator update({ArcadeOrmTransaction? transaction}) {
    return ArcadeOrmTableUpdateOperator(
      orm: $orm,
      operator: TableOperator.update,
      transaction: transaction,
    );
  }

  ArcadeOrmTableDeleteOperator delete({ArcadeOrmTransaction? transaction}) {
    return ArcadeOrmTableDeleteOperator(
      orm: $orm,
      operator: TableOperator.delete,
      transaction: transaction,
    );
  }
}

abstract class ColumnMeta {
  final bool isNullable;
  const ColumnMeta({this.isNullable = false});
}

class ColumnInt extends ColumnMeta {
  const ColumnInt({super.isNullable});
}

class ColumnIntRange extends ColumnMeta {
  const ColumnIntRange();
}

class ColumnFloat extends ColumnMeta {
  const ColumnFloat();
}

class ColumnBool extends ColumnMeta {
  const ColumnBool();
}

class ColumnString extends ColumnMeta {
  final dynamic search;

  const ColumnString({this.search});
}

class ColumnStringEnum extends ColumnMeta {
  const ColumnStringEnum();
}

class ColumnStringSet extends ColumnMeta {
  const ColumnStringSet();
}

class ColumnBinary extends ColumnMeta {
  const ColumnBinary();
}

class ColumnDate extends ColumnMeta {
  const ColumnDate();
}

class ColumnDateRange extends ColumnMeta {
  const ColumnDateRange();
}

class ColumnJson extends ColumnMeta {
  const ColumnJson();
}

class ColumnComposite extends ColumnMeta {
  const ColumnComposite();
}

class ColumnGeoJson extends ColumnMeta {
  const ColumnGeoJson();
}

class ColumnObjectId extends ColumnMeta {
  const ColumnObjectId();
}

class ColumnArray extends ColumnMeta {
  const ColumnArray();
}

abstract interface class ColumnCustomDomain extends ColumnMeta {}

class ColumnCustom extends ColumnMeta {
  final String raw;

  const ColumnCustom({required this.raw});
}
