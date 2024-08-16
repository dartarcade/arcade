import 'dart:async';

abstract interface class BaseCacheManager<C> {
  /// Initializes the cache. E.g. opens the database connection.
  FutureOr<void> init(C connectionInfo);

  /// Disposes the cache. E.g. closes the database connection.
  FutureOr<void> dispose();

  /// Clears the entire cache
  FutureOr<void> clear();

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
  FutureOr<void> set(String key, dynamic value);

  /// Sets the value associated with the given key and a ttl.
  FutureOr<void> setWithTtl(String key, dynamic value, Duration ttl);

  /// Removes the value associated with the given key.
  FutureOr<void> remove<T>(String key);
}
