import 'dart:async';
import 'dart:convert';

import 'package:arcade_cache/arcade_cache.dart';
import 'package:redis/redis.dart';

typedef RedisConnectionInfo = ({String host, int port, bool secure});

class RedisCacheManager implements BaseCacheManager<RedisConnectionInfo> {
  late RedisConnection _connection;
  late Command _command;

  @override
  Future<void> init(RedisConnectionInfo connectionInfo) async {
    final (:host, :port, :secure) = connectionInfo;
    _connection = RedisConnection();

    if (secure) {
      _command = await _connection.connectSecure(
        host,
        port,
      );
    } else {
      _command = await _connection.connect(
        host,
        port,
      );
    }
  }

  @override
  Future<void> dispose() async {
    await _connection.close();
  }

  @override
  Future<void> clear() async {
    await _command.send_object(['FLUSHDB']);
  }

  @override
  Future<T?> get<T extends Object>(String key) {
    return _command.get(key).then((value) => value as T?);
  }

  @override
  Future<String?> getString(String key) => get(key);

  @override
  Future<List<T>?> getList<T>(String key) {
    return get(key)
        .then((value) =>
            value != null ? jsonDecode(value.toString()) as List : null)
        .then((value) => value?.cast());
  }

  @override
  FutureOr<Map<String, dynamic>?> getJson(String key) {
    return get(key).then(
      (value) => value != null
          ? jsonDecode(value.toString()) as Map<String, dynamic>
          : null,
    );
  }

  @override
  Future<bool> contains<T>(String key) {
    return _command.send_object(['EXISTS', key]).then((value) => value != 0);
  }

  @override
  Future<void> set(String key, dynamic value) async {
    dynamic _value = value;
    if (_value is Map) {
      _value = jsonEncode(_value);
    } else if (_value is Iterable) {
      _value = jsonEncode(_value);
    }
    await _command.send_object(['SET', key, _value]);
  }

  @override
  Future<void> setWithTtl(String key, dynamic value, Duration ttl) async {
    await _command.send_object(['SET', key, value, 'EX', ttl.inSeconds]);
  }

  @override
  Future<void> remove<T>(String key) async {
    await _command.send_object(['DEL', key]);
  }
}
