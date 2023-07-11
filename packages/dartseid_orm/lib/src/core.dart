import 'dart:async';

import 'package:dartseid_orm/src/adapter.dart';
import 'package:dartseid_orm/src/table.dart';

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

  DormTransaction transaction() {
    return adapter.transaction();
  }

  static Future<Dorm> init({
    required DormAdapterBase adapter,
    String? name,
  }) async {
    await adapter.init();
    final dorm = Dorm._(adapter: adapter, name: name);
    adapter.setDormInstance(dorm);
    return dorm;
  }
}

class DormException implements Exception {
  final Object? originalError;
  final String message;

  DormException({required this.message, required this.originalError});
}
