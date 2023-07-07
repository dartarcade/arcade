import 'dart:async';

// This will be initialized with dart orm class after init method is called
final Map<String, Dorm> _dorms = {};

Dorm getDormInstance([String? name]) {
  final dorm = _dorms[name ?? "__default"];
  if (dorm == null) {
    throw StateError(
      'Dartseid orm is not initialized. Please run Dorm.init',
    );
  }
  return dorm;
}

class Dorm with DormTable {
  final DormAdapterBase adapter;

  Dorm._({required this.adapter, String? name}) {
    this.name = name ?? "__default";
    _dorms[this.name] = this;
  }

  static Future<Dorm> init({
    required DormAdapterBase adapter,
    String? name,
  }) async {
    await adapter.init();
    return Dorm._(adapter: adapter, name: name);
  }

  DormTransaction transaction() {
    return adapter.transaction();
  }
}

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
    Map<String, dynamic> schema, {
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

  DormTableOperator _getTableOperator({
    required TableOperator operator,
    DormTransaction? transaction,
  }) {
    return DormTableOperator(
      dorm: dorm,
      operator: operator,
      baseConverter: baseConverter,
      transaction: transaction,
    );
  }

  DormTableOperator findOne({DormTransaction? transaction}) {
    return _getTableOperator(
      operator: TableOperator.findOne,
      transaction: transaction,
    );
  }

  DormTableOperator findMany({DormTransaction? transaction}) {
    return _getTableOperator(
      operator: TableOperator.findMany,
      transaction: transaction,
    );
  }

  DormTableOperator create({DormTransaction? transaction}) {
    return _getTableOperator(
      operator: TableOperator.create,
      transaction: transaction,
    );
  }

  DormTableOperator update({DormTransaction? transaction}) {
    return _getTableOperator(
      operator: TableOperator.update,
      transaction: transaction,
    );
  }

  DormTableOperator delete({DormTransaction? transaction}) {
    return _getTableOperator(
      operator: TableOperator.delete,
      transaction: transaction,
    );
  }
}

sealed class ExecResult<T> {}

class ExecResultData<T> extends ExecResult<T> {
  final T data;

  ExecResultData(this.data);
}

class ExecResultFailure<T> extends ExecResult<T> {
  final DormException exception;

  ExecResultFailure(this.exception);
}

class DormTableOperator {
  final Dorm _dorm;
  final TableOperator _operator;
  final DormTableConverter _baseConverter;
  final DormTransaction? _transaction;

  final List<Map<String, dynamic>> createWithParams = [];
  final List<Map<String, dynamic>> updateWithParams = [];
  final List<Map<String, dynamic>> whereParams = [];
  final List<Map<String, dynamic>> includeParams = [];
  final List<Map<String, dynamic>> selectParams = [];

  DormTableOperator({
    required Dorm dorm,
    required TableOperator operator,
    required ({
      FutureOr<dynamic> Function(Map<String, dynamic>) fromJson,
      FutureOr<Map<String, dynamic>> Function() toJson
    }) baseConverter,
    DormTransaction? transaction,
  })  : _transaction = transaction,
        _baseConverter = baseConverter,
        _operator = operator,
        _dorm = dorm;

  void createWith() {}
  void updateWith() {}
  void where() {}
  void include() {}
  void select() {}

  Future<ExecResult> exec<T>({
    DormTableFromConverter<T>? converter,
  }) async {
    try {
      final execConverter =
          converter != null ? converter.fromJson : _baseConverter.fromJson;

      final data = await _dorm.adapter.operate(operator: _operator);

      final convertedData = await execConverter(data);

      return ExecResultData(convertedData);
    } on DormException catch (e) {
      return ExecResultFailure(e);
    } catch (e) {
      return ExecResultFailure(
        DormException(originalError: e, message: "Unknown Error"),
      );
    }
  }
}

enum TableOperator {
  findOne,
  findMany,
  create,
  update,
  delete,
}

class DormException implements Exception {
  final Object? originalError;
  final String message;

  DormException({required this.message, required this.originalError});
}

abstract class DormTransaction {
  Future<void> start();
  Future<void> commit();
  Future<void> rollback();
  Future<T> callback<T>(
    FutureOr<T> Function(DormTransaction trx) callback,
  ) async {
    try {
      await start();
      final data = await callback(this);
      await commit();
      return data;
    } catch (e) {
      await rollback();
      rethrow;
    }
  }
}

abstract interface class DormAdapterBase {
  final dynamic connection;

  DormAdapterBase({
    required this.connection,
  });

  Future<void> init();
  Future<Map<String, dynamic>> operate({required TableOperator operator});
  DormTransaction transaction();
}

class DormMockAdapter implements DormAdapterBase {
  @override
  final dynamic connection;

  DormMockAdapter({
    required this.connection,
  });

  @override
  Future<void> init() {
    // TODO: implement init
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> operate({required TableOperator operator}) {
    print(operator);
    throw UnimplementedError();
  }

  @override
  DormTransaction transaction() {
    // TODO: implement transaction
    throw UnimplementedError();
  }

  @override
  String a() {
    // TODO: implement a
    throw UnimplementedError();
  }
}

Future<dynamic> dorming() async {
  final a = await Dorm.init(
    adapter: DormMockAdapter(connection: ""),
  );

  final t = a.table(
    "users",
    {
      "id": "", // Have a columnmeta class object
      "name": "",
    },
    converter: (
      fromJson: (Map<String, dynamic> j) {},
      toJson: () => {},
    ),
  );

  t.index({"id": 1, "name": 1});

  final trx = t.transaction();

  final x = t.create();

  final data = await trx.callback((trx) async {
    final r = t.findOne(transaction: trx)
      ..where()
      ..select()
      ..include();

    Future<String> fromJsonFn(Map<String, dynamic> j) async {
      return "";
    }

    final result = await r.exec(converter: (fromJson: fromJsonFn));

    return switch (result) {
      ExecResultData(data: final data) => data,
      ExecResultFailure(exception: final _) => await () async {
          await trx.rollback();
          throw Exception("I am basic");
        }()
    };
  });

  // more dorming
  return data;
}
