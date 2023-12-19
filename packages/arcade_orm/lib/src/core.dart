import 'dart:async';

import 'package:arcade_orm/arcade_orm.dart';

// This will be initialized with dart orm class after init method is called
final Map<String, ArcadeOrm> _orms = {};

ArcadeOrm getArcadeOrmInstance([String? name]) {
  final orm = _orms[name ?? "__default"];
  if (orm == null) {
    throw StateError(
      'Dartseid orm is not initialized. Please run ArcadeOrm.init',
    );
  }
  return orm;
}

class ArcadeOrm with ArcadeOrmTable {
  final ArcadeOrmAdapterBase adapter;

  ArcadeOrm._({required this.adapter, String? name}) {
    this.name = name ?? "__default";
    _orms[this.name] = this;
  }

  ArcadeOrmTransaction transaction() {
    return adapter.transaction();
  }

  static Future<ArcadeOrm> init({
    required ArcadeOrmAdapterBase adapter,
    String? name,
  }) async {
    await adapter.init();
    final orm = ArcadeOrm._(adapter: adapter, name: name);
    adapter.setArcadeOrmInstance(orm);
    return orm;
  }
}

class ArcadeOrmException implements Exception {
  final Object? originalError;
  final String message;

  ArcadeOrmException({required this.message, required this.originalError});
}
