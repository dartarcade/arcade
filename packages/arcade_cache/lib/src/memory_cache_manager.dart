import 'dart:async';
import 'dart:convert';

import 'package:arcade_cache/arcade_cache.dart';

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
  final Map<String, StreamController<PubSubEvent>> _channelControllers = {};
  final Map<String, Set<String>> _activeSubscriptions = {};
  final Map<String, Function(dynamic)> _messageMappers = {};

  @override
  Future<void> init(void connectionInfo) async {
    _startCleanupTimer();
  }

  @override
  Future<void> dispose() async {
    _cleanupTimer?.cancel();
    _cache.clear();

    for (final controller in _channelControllers.values) {
      await controller.close();
    }
    _channelControllers.clear();
    _activeSubscriptions.clear();
  }

  @override
  Future<void> clear() async {
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
  Future<void> set(String key, dynamic value) async {
    final serializedValue = _serializeValue(value);
    _cache[key] = _CacheEntry(serializedValue, null);
  }

  @override
  Future<void> setWithTtl(String key, dynamic value, Duration ttl) async {
    final serializedValue = _serializeValue(value);
    final expiresAt = DateTime.now().add(ttl);
    _cache[key] = _CacheEntry(serializedValue, expiresAt);
  }

  @override
  Future<void> remove<T>(String key) async {
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

  @override
  Stream<PubSubEvent<T>> subscribe<T>(
    List<String> channels, {
    T Function(dynamic data)? messageMapper,
  }) {
    final controller = StreamController<PubSubEvent<T>>.broadcast();
    final channelKey = channels.join(',');

    // Store the controller and mapper
    _channelControllers[channelKey] =
        controller as StreamController<PubSubEvent>;
    if (messageMapper != null) {
      _messageMappers[channelKey] = messageMapper;
    }

    // Track subscriptions
    for (final channel in channels) {
      _activeSubscriptions.putIfAbsent(channel, () => {}).add(channelKey);

      // Emit subscribe event
      controller.add(
          PubSubSubscribed(channel, _activeSubscriptions[channel]!.length)
              as PubSubEvent<T>);
    }

    return controller.stream;
  }

  @override
  Future<void> unsubscribe(List<String> channels) async {
    final channelKey = channels.join(',');

    // Clean up subscriptions
    for (final channel in channels) {
      final subscriptions = _activeSubscriptions[channel];
      if (subscriptions != null) {
        subscriptions.remove(channelKey);
        if (subscriptions.isEmpty) {
          _activeSubscriptions.remove(channel);
        }
      }
    }

    // Close and remove controller
    final controller = _channelControllers.remove(channelKey);
    if (controller != null) {
      // Emit unsubscribe events before closing
      for (final channel in channels) {
        controller.add(PubSubUnsubscribed(channel, 0));
      }
      await controller.close();
    }

    // Clean up mapper
    _messageMappers.remove(channelKey);
  }

  @override
  Future<int> publish(String channel, dynamic message) async {
    var subscriberCount = 0;

    // Find all controllers that are subscribed to this channel
    final subscriptions = _activeSubscriptions[channel];
    if (subscriptions != null) {
      for (final channelKey in subscriptions) {
        final controller = _channelControllers[channelKey];
        if (controller != null && !controller.isClosed) {
          // Apply mapper if available
          final mapper = _messageMappers[channelKey];
          final mappedData = mapper != null ? mapper(message) : message;

          // The controller is typed, so we need to handle this generically
          controller.add(PubSubMessage(channel, mappedData));
          subscriberCount++;
        }
      }
    }

    return subscriberCount;
  }
}
