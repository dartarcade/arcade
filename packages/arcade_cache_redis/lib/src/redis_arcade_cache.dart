import 'dart:async';
import 'dart:convert';

import 'package:arcade_cache/arcade_cache.dart';
import 'package:redis/redis.dart';

typedef RedisConnectionInfo = ({String host, int port, bool secure});

class RedisCacheManager implements BaseCacheManager<RedisConnectionInfo> {
  late RedisConnection _connection;
  late Command _command;
  late RedisConnectionInfo _connectionInfo;
  final Map<String, StreamController<PubSubEvent>> _channelControllers = {};
  final Map<String, PubSub> _channelPubSubs = {};
  final Map<String, RedisConnection> _channelConnections = {};

  @override
  Future<void> init(RedisConnectionInfo connectionInfo) async {
    _connectionInfo = connectionInfo;
    final (:host, :port, :secure) = connectionInfo;
    _connection = RedisConnection();

    if (secure) {
      _command = await _connection.connectSecure(host, port);
    } else {
      _command = await _connection.connect(host, port);
    }
  }

  @override
  Future<void> dispose() async {
    await _connection.close();

    // Close all channel-specific connections and controllers
    for (final controller in _channelControllers.values) {
      await controller.close();
    }
    for (final connection in _channelConnections.values) {
      await connection.close();
    }

    _channelControllers.clear();
    _channelPubSubs.clear();
    _channelConnections.clear();
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
        .then(
          (value) =>
              value != null ? jsonDecode(value.toString()) as List : null,
        )
        .then((value) => value?.cast());
  }

  @override
  FutureOr<Map<String, dynamic>?> getJson(String key) {
    return get(key).then((value) {
      if (value == null) return null;
      try {
        final decoded = jsonDecode(value.toString());
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        return null;
      } catch (_) {
        return null;
      }
    });
  }

  @override
  Future<bool> contains<T>(String key) {
    return _command.send_object(['EXISTS', key]).then((value) => value != 0);
  }

  @override
  Future<void> set(String key, dynamic value) async {
    dynamic v = value;
    if (v is Map) {
      v = jsonEncode(v);
    } else if (v is Iterable) {
      v = jsonEncode(v);
    } else if (v is double) {
      v = v.toString();
    }
    await _command.send_object(['SET', key, v]);
  }

  @override
  Future<void> setWithTtl(String key, dynamic value, Duration ttl) async {
    dynamic v = value;
    if (v is Map) {
      v = jsonEncode(v);
    } else if (v is Iterable) {
      v = jsonEncode(v);
    } else if (v is double) {
      v = v.toString();
    }
    await _command.send_object(['SET', key, v, 'EX', ttl.inSeconds]);
  }

  @override
  Future<void> remove<T>(String key) async {
    await _command.send_object(['DEL', key]);
  }

  @override
  Stream<PubSubEvent<T>> subscribe<T>(
    List<String> channels, {
    T Function(dynamic data)? messageMapper,
  }) {
    final controller = StreamController<PubSubEvent<T>>.broadcast();

    // Create a combined key for the channels
    final channelKey = channels.join(',');

    // Store the controller for cleanup
    _channelControllers[channelKey] =
        controller as StreamController<PubSubEvent>;

    // Initialize pub-sub for these channels
    _initPubSubForChannels(channels, controller, messageMapper);

    return controller.stream;
  }

  Future<void> _initPubSubForChannels<T>(
    List<String> channels,
    StreamController<PubSubEvent<T>> controller,
    T Function(dynamic data)? messageMapper,
  ) async {
    final channelKey = channels.join(',');

    try {
      // Create a new connection for this subscription
      final connection = RedisConnection();
      final (:host, :port, :secure) = _connectionInfo;

      late Command command;
      if (secure) {
        command = await connection.connectSecure(host, port);
      } else {
        command = await connection.connect(host, port);
      }

      // Create PubSub instance
      final pubSub = PubSub(command);

      // Store references for cleanup
      _channelConnections[channelKey] = connection;
      _channelPubSubs[channelKey] = pubSub;

      // Subscribe to channels
      pubSub.subscribe(channels);

      // Listen to the pub-sub stream
      pubSub.getStream().listen(
        (data) {
          if (data is List && data.length >= 3) {
            final kind = data[0];
            final channel = data[1];

            switch (kind) {
              case 'subscribe':
                final count = data[2] as int;
                controller.add(
                  PubSubSubscribed(channel.toString(), count) as PubSubEvent<T>,
                );

              case 'unsubscribe':
                final count = data[2] as int;
                controller.add(
                  PubSubUnsubscribed(channel.toString(), count)
                      as PubSubEvent<T>,
                );

              case 'message':
                final rawData = data[2];
                final messageData = _parseMessageData(rawData);

                final mappedData = messageMapper != null
                    ? messageMapper(messageData)
                    : messageData as T;

                controller.add(
                  PubSubMessage<T>(channel.toString(), mappedData),
                );
            }
          }
        },
        onError: (error) {
          if (error is Object && !controller.isClosed) {
            controller.addError(error);
          }
        },
        onDone: () {
          if (!controller.isClosed) {
            controller.close();
          }
        },
      );
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
        await controller.close();
      }
    }
  }

  dynamic _parseMessageData(dynamic data) {
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  @override
  Future<void> unsubscribe(List<String> channels) async {
    final channelKey = channels.join(',');

    // Unsubscribe if we have an active subscription
    final pubSub = _channelPubSubs[channelKey];
    if (pubSub != null) {
      pubSub.unsubscribe(channels);
    }

    // Clean up resources
    final controller = _channelControllers.remove(channelKey);
    await controller?.close();

    final connection = _channelConnections.remove(channelKey);
    await connection?.close();

    _channelPubSubs.remove(channelKey);
  }

  @override
  Future<int> publish(String channel, dynamic message) async {
    dynamic value = message;
    if (value is Map || value is Iterable) {
      value = jsonEncode(value);
    }
    final result = await _command.send_object(['PUBLISH', channel, value]);
    return result as int;
  }
}
