import 'dart:async';

import 'package:arcade_orm/arcade_orm.dart';
import 'package:meta/meta.dart';

@visibleForTesting
void clearOrms() {
  _orms.clear();
}

// This will be initialized with dart orm class after init method is called
final Map<String, ArcadeOrm> _orms = {};

/// This will return an instance of ArcadeOrm provided `init` was called
ArcadeOrm getArcadeOrmInstance([String? name]) {
  final orm = _orms[name ?? "__default"];
  if (orm == null) {
    throw StateError(
      'Arcade orm is not initialized. '
      'Please run ArcadeOrm.init(adapter: ExampleAdapter()${name != null ? ', name: "$name"' : ''})',
    );
  }
  return orm;
}

class ArcadeOrm with ArcadeOrmTable {
  final ArcadeOrmAdapterBase adapter;

  ArcadeOrm._({required this.adapter, String? name}) {
    this.name = name ?? "__default";
    if (_orms.containsKey(this.name)) {
      throw StateError(
        'Arcade ORM with name "${this.name}" is already initialized. Please use another name',
      );
    }
    _orms[this.name] = this;
  }

  ArcadeOrmTransaction transaction() {
    return adapter.transaction();
  }

  static FutureOr<ArcadeOrm> init({
    required ArcadeOrmAdapterBase adapter,
    String? name,
  }) async {
    final orm = ArcadeOrm._(adapter: adapter, name: name);
    await adapter.init();
    adapter.setArcadeOrmInstance(orm);
    return orm;
  }

  FutureOr<void> close() async {
    await adapter.close();
  }
}

class ArcadeOrmException implements Exception {
  final Object? originalError;
  final String message;

  ArcadeOrmException({required this.message, required this.originalError});
}
