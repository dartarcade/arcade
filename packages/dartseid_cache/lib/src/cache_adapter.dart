import 'dart:async';

abstract interface class CacheAdapter {
  /// Initializes the cache. E.g. opens the database connection.
  FutureOr<void> init();

  /// Disposes the cache. E.g. closes the database connection.
  FutureOr<void> dispose();

  /// Clears the entire cache
  FutureOr<void> clear();

  /// Get the value associated with the given key.
  FutureOr<T?> get<T>(String key);

  /// Checks if the cache contains the given key.
  FutureOr<bool> contains<T>(String key);

  /// Sets the value associated with the given key.
  FutureOr<void> set(String key, dynamic value);

  /// Sets the value associated with the given key and a ttl.
  FutureOr<void> setWithTtl(String key, dynamic value, Duration ttl);

  /// Removes the value associated with the given key.
  FutureOr<void> remove<T>(String key);
}
