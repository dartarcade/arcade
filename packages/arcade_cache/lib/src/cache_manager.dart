import 'dart:async';

import 'package:arcade_cache/src/pubsub_event.dart';

abstract interface class BaseCacheManager<C> {
  /// Initializes the cache. E.g. opens the database connection.
  Future<void> init(C connectionInfo);

  /// Disposes the cache. E.g. closes the database connection.
  Future<void> dispose();

  /// Clears the entire cache
  Future<void> clear();

  /// Get the value associated with the given key.
  FutureOr<T?> get<T extends Object>(String key);

  /// Get the value associated with the given key as a string.
  FutureOr<String?> getString(String key);

  /// Get the value associated with the given key as a list.
  FutureOr<List<T>?> getList<T>(String key);

  /// Get the value associated with the given key as a map.
  FutureOr<Map<String, dynamic>?> getJson(String key);

  /// Checks if the cache contains the given key.
  FutureOr<bool> contains<T>(String key);

  /// Sets the value associated with the given key.
  Future<void> set(String key, dynamic value);

  /// Sets the value associated with the given key and a ttl.
  Future<void> setWithTtl(String key, dynamic value, Duration ttl);

  /// Removes the value associated with the given key.
  Future<void> remove<T>(String key);

  /// Subscribe to one or more channels and receive typed events.
  ///
  /// The optional [messageMapper] can be used to transform raw message data
  /// into a specific type. If not provided, messages will be of type dynamic.
  ///
  /// Returns a stream of [PubSubEvent] that emits:
  /// - [PubSubSubscribed] when successfully subscribed to a channel
  /// - [PubSubMessage] when a message is received on a subscribed channel
  /// - [PubSubUnsubscribed] when unsubscribed from a channel
  Stream<PubSubEvent<T>> subscribe<T>(
    List<String> channels, {
    T Function(dynamic data)? messageMapper,
  });

  /// Unsubscribe from one or more channels
  Future<void> unsubscribe(List<String> channels);

  /// Publish a message to a channel
  /// Returns the number of subscribers that received the message
  Future<int> publish(String channel, dynamic message);
}
