import 'dart:async';
import 'dart:convert';

import 'package:arcade_cache/src/cache_manager.dart';

class _CacheEntry {
  final dynamic value;
  final DateTime? expiresAt;

  _CacheEntry(this.value, this.expiresAt);

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

class MemoryCacheManager implements BaseCacheManager<void> {
  final Map<String, _CacheEntry> _cache = {};
  Timer? _cleanupTimer;

  @override
  void init(void connectionInfo) {
    _startCleanupTimer();
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
  }

  @override
  void clear() {
    _cache.clear();
  }

  @override
  FutureOr<T?> get<T extends Object>(String key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.value as T?;
  }

  @override
  FutureOr<String?> getString(String key) {
    final value = get<String>(key);
    return value;
  }

  @override
  FutureOr<List<T>?> getList<T>(String key) async {
    final value = await get<List<dynamic>>(key);
    if (value == null) return null;
    return value.cast<T>();
  }

  @override
  FutureOr<Map<String, dynamic>?> getJson(String key) {
    final value = get<Map<String, dynamic>>(key);
    return value;
  }

  @override
  FutureOr<bool> contains<T>(String key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  @override
  void set(String key, dynamic value) {
    final serializedValue = _serializeValue(value);
    _cache[key] = _CacheEntry(serializedValue, null);
  }

  @override
  void setWithTtl(String key, dynamic value, Duration ttl) {
    final serializedValue = _serializeValue(value);
    final expiresAt = DateTime.now().add(ttl);
    _cache[key] = _CacheEntry(serializedValue, expiresAt);
  }

  @override
  void remove<T>(String key) {
    _cache.remove(key);
  }

  dynamic _serializeValue(dynamic value) {
    if (value == null ||
        value is String ||
        value is num ||
        value is bool ||
        value is List ||
        value is Map) {
      return value;
    }

    try {
      return jsonDecode(jsonEncode(value));
    } catch (e) {
      throw ArgumentError('Value cannot be serialized to JSON: $value');
    }
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _cleanupExpiredEntries();
    });
  }

  void _cleanupExpiredEntries() {
    final keysToRemove = <String>[];
    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        keysToRemove.add(entry.key);
      }
    }
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }
}
