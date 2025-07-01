---
title: Arcade Cache
description: Caching abstraction and in-memory implementation for Arcade applications
---

The `arcade_cache` package provides a flexible caching abstraction for Arcade applications, allowing you to implement various caching strategies with a consistent API. It includes a built-in in-memory cache implementation and serves as the foundation for other cache adapters like Redis.

## Installation

Add `arcade_cache` to your `pubspec.yaml`:

```yaml
dependencies:
  arcade_cache: ^<latest-version>
```

## Core Concepts

### BaseCacheManager

The `BaseCacheManager<C>` abstract class defines the standard interface that all cache implementations must follow:

```dart
abstract interface class BaseCacheManager<C> {
  // Initialize the cache
  Future<void> init(C connectionInfo);

  // Core operations
  Future<void> set(String key, dynamic value);
  Future<void> setWithTtl(String key, dynamic value, Duration ttl);
  FutureOr<T?> get<T extends Object>(String key);
  Future<void> remove<T>(String key);
  Future<void> clear();
  FutureOr<bool> contains<T>(String key);

  // Type-specific getters
  FutureOr<String?> getString(String key);
  FutureOr<List<T>?> getList<T>(String key);
  FutureOr<Map<String, dynamic>?> getJson(String key);

  // Pub-Sub operations
  Stream<PubSubEvent<T>> subscribe<T>(
    List<String> channels, {
    T Function(dynamic data)? messageMapper,
  });
  Future<void> unsubscribe(List<String> channels);
  Future<int> publish(String channel, dynamic message);

  // Cleanup
  Future<void> dispose();
}
```

### MemoryCacheManager

The package includes a production-ready in-memory cache implementation:

- **TTL Support**: Automatic expiration of cache entries
- **Automatic Cleanup**: Removes expired entries every minute
- **Type Safety**: Preserves types for stored values
- **JSON Serialization**: Automatic encoding/decoding for complex objects

## Quick Start

### Basic Usage

```dart
import 'package:arcade_cache/arcade_cache.dart';

void main() async {
  // Create cache instance
  final cache = MemoryCacheManager();
  await cache.init(null);

  // Store simple values
  await cache.set('user:123', 'John Doe');
  await cache.set('count', 42);

  // Store with TTL
  await cache.setWithTtl('session:abc', 'active', Duration(hours: 1));

  // Retrieve values
  final userName = await cache.getString('user:123'); // 'John Doe'
  final count = await cache.get<int>('count'); // 42

  // Store complex objects
  await cache.set('user:profile', {
    'id': 123,
    'name': 'John Doe',
    'email': 'john@example.com',
  });

  // Retrieve as JSON
  final profile = await cache.getJson('user:profile');
  print(profile?['email']); // 'john@example.com'

  // Check existence
  if (await cache.contains('session:abc')) {
    print('Session is active');
  }

  // Remove specific key
  await cache.remove('session:abc');

  // Clear all cache
  await cache.clear();

  // Clean up when done
  await cache.dispose();
}
```

### Storing Lists

```dart
// Store list of strings
await cache.set('tags', ['dart', 'flutter', 'arcade']);
final tags = await cache.getList<String>('tags');

// Store list of numbers
await cache.set('scores', [95, 87, 92]);
final scores = await cache.getList<int>('scores');

// Store list of objects (automatically JSON encoded)
await cache.set('users', [
  {'id': 1, 'name': 'Alice'},
  {'id': 2, 'name': 'Bob'},
]);
final users = await cache.getList<Map<String, dynamic>>('users');
```

### Pub-Sub Support

The cache interface includes pub-sub (publish-subscribe) functionality for real-time messaging between different parts of your application:

```dart
// Subscribe to channels
final subscription = cache.subscribe<String>(['notifications', 'updates']);

subscription.listen((event) {
  switch (event) {
    case PubSubMessage<String>(:final channel, :final data):
      print('Received on $channel: $data');
    case PubSubSubscribed(:final channel, :final subscriberCount):
      print('Subscribed to $channel');
    case PubSubUnsubscribed(:final channel):
      print('Unsubscribed from $channel');
  }
});

// Publish messages
await cache.publish('notifications', 'New message!');
await cache.publish('updates', 'System updated');

// With typed messages
final jsonSubscription = cache.subscribe<Map<String, dynamic>>(
  ['events'],
  messageMapper: (data) => data as Map<String, dynamic>,
);

jsonSubscription.listen((event) {
  if (event is PubSubMessage<Map<String, dynamic>>) {
    print('Event: ${event.data}');
  }
});

await cache.publish('events', {'type': 'user_login', 'userId': 123});

// Unsubscribe when done
await cache.unsubscribe(['notifications', 'updates']);
```

## Integration with Arcade

### Using with get_it

```dart
import 'package:arcade/arcade.dart';
import 'package:arcade_cache/arcade_cache.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void main() async {
  // Register cache with get_it
  final cache = MemoryCacheManager();
  await cache.init(null);
  getIt.registerSingleton<BaseCacheManager>(cache);

  await runServer(
    port: 3000,
    init: () {
      route.get('/user/:id').handle((context) async {
        final cache = getIt<BaseCacheManager>();
        final userId = context.pathParameters['id']!;
        final cacheKey = 'user:$userId';

        // Try cache first
        var user = await cache.getJson(cacheKey);

        if (user == null) {
          // Fetch from database
          user = await fetchUserFromDatabase(userId);

          // Cache for 5 minutes
          await cache.setWithTtl(cacheKey, user, Duration(minutes: 5));
        }

        return user;
      });
    },
  );
}
```

### Request Caching Hooks

```dart
class CacheHooks {
  final BaseCacheManager cache;
  final Duration ttl;

  CacheHooks({required this.cache, this.ttl = const Duration(minutes: 5)});

  BeforeHook<RequestContext> createBeforeHook() {
    return (context) async {
      final cacheKey = _getCacheKey(context);
      final cached = await cache.getString(cacheKey);

      if (cached != null) {
        // Return cached response
        context.responseHeaders.contentType = ContentType.json;
        context.response.write(cached);
        await context.response.close();

        // Skip route handler
        throw CachedResponseException();
      }

      return context;
    };
  }

  AfterHook<RequestContext, dynamic> createAfterHook() {
    return (context, result) async {
      if (result != null) {
        final cacheKey = _getCacheKey(context);
        final json = jsonEncode(result);
        await cache.setWithTtl(cacheKey, json, ttl);
      }
      return result;
    };
  }

  String _getCacheKey(RequestContext context) {
    return 'response:${context.request.method}:${context.request.uri.path}';
  }
}

// Usage
final cacheHooks = CacheHooks(cache: cache);

route.get('/api/products')
  .before(cacheHooks.createBeforeHook())
  .handle((context) async {
    // Expensive operation
    return await fetchAllProducts();
  })
  .after(cacheHooks.createAfterHook());
```

## Advanced Usage

### Custom Cache Keys

```dart
class CacheKeyBuilder {
  static String user(String id) => 'user:$id';
  static String session(String token) => 'session:$token';
  static String apiResponse(String endpoint) => 'api:$endpoint';
  static String list(String type, {int? page, int? limit}) {
    final parts = ['list', type];
    if (page != null) parts.add('page:$page');
    if (limit != null) parts.add('limit:$limit');
    return parts.join(':');
  }
}

// Usage
await cache.set(CacheKeyBuilder.user('123'), userData);
await cache.set(CacheKeyBuilder.list('products', page: 1, limit: 20), products);
```

### Cache Warming

```dart
class CacheWarmer {
  final BaseCacheManager cache;

  CacheWarmer(this.cache);

  Future<void> warmCache() async {
    // Pre-load frequently accessed data
    final popularProducts = await fetchPopularProducts();
    await cache.setWithTtl('products:popular', popularProducts, Duration(hours: 1));

    final categories = await fetchAllCategories();
    await cache.setWithTtl('categories:all', categories, Duration(hours: 6));

    // Pre-compute expensive calculations
    final statistics = await calculateDailyStatistics();
    await cache.setWithTtl('stats:daily', statistics, Duration(hours: 24));
  }
}

// Run on startup
void main() async {
  final cache = MemoryCacheManager();
  await cache.init(null);

  final warmer = CacheWarmer(cache);
  await warmer.warmCache();

  // Start server...
}
```

### Cache Statistics

```dart
extension CacheStats on MemoryCacheManager {
  Map<String, dynamic> getStatistics() {
    return {
      'totalKeys': cache.length,
      'memoryUsage': _estimateMemoryUsage(),
      'oldestEntry': _getOldestEntry(),
      'newestEntry': _getNewestEntry(),
    };
  }

  void logStatistics() {
    final stats = getStatistics();
    Logger.root.info('Cache statistics', stats);
  }
}
```

## Creating Custom Cache Adapters

To create your own cache adapter (e.g., for DynamoDB, MongoDB, etc.):

```dart
class CustomCacheManager implements BaseCacheManager<CustomConfig> {
  late final CustomClient client;

  @override
  FutureOr<void> init(CustomConfig connectionInfo) async {
    client = CustomClient(connectionInfo);
    await client.connect();
  }

  @override
  FutureOr<void> set(String key, dynamic value) async {
    final encoded = jsonEncode(value);
    await client.put(key, encoded);
  }

  @override
  FutureOr<void> setWithTtl(String key, dynamic value, Duration ttl) async {
    final encoded = jsonEncode(value);
    final expiry = DateTime.now().add(ttl).millisecondsSinceEpoch;
    await client.put(key, encoded, expiry: expiry);
  }

  @override
  FutureOr<T?> get<T extends Object>(String key) async {
    final data = await client.get(key);
    if (data == null) return null;

    // Check expiry
    if (data.expiry != null && data.expiry < DateTime.now().millisecondsSinceEpoch) {
      await remove(key);
      return null;
    }

    return jsonDecode(data.value) as T?;
  }

  @override
  FutureOr<void> remove<T>(String key) async {
    await client.delete(key);
  }

  @override
  FutureOr<void> clear() async {
    await client.deleteAll();
  }

  @override
  FutureOr<bool> contains<T>(String key) async {
    return await client.exists(key);
  }

  @override
  FutureOr<void> dispose() async {
    await client.disconnect();
  }

  @override
  FutureOr<String?> getString(String key) async {
    return await get<String>(key);
  }

  @override
  FutureOr<List<T>?> getList<T>(String key) async {
    final result = await get<List>(key);
    return result?.cast<T>();
  }

  @override
  FutureOr<Map<String, dynamic>?> getJson(String key) async {
    return await get<Map<String, dynamic>>(key);
  }
}
```

## Best Practices

1. **Use Consistent Key Patterns**: Develop a naming convention for cache keys
2. **Set Appropriate TTLs**: Balance between performance and data freshness
3. **Handle Cache Misses**: Always have a fallback when cache is empty
4. **Monitor Memory Usage**: For in-memory cache, watch memory consumption
5. **Implement Cache Warming**: Pre-load critical data on startup
6. **Use Type-Specific Methods**: Prefer `getString()`, `getList()`, etc. over generic `get()`
7. **Clean Up Resources**: Always call `dispose()` when shutting down

## Performance Considerations

### Memory Management

The `MemoryCacheManager` stores all data in memory. For large applications:

- Monitor memory usage
- Set appropriate TTLs
- Consider using external cache stores (Redis, etc.)
- Implement cache eviction policies if needed

### Serialization Overhead

- JSON encoding/decoding has overhead
- For performance-critical paths, consider storing pre-serialized data
- Use primitive types when possible

## Next Steps

- Explore [Arcade Cache Redis](/packages/arcade-cache-redis/) for distributed caching
- Learn about [WebSocket integration](/guides/websockets/) for real-time features
- See [Configuration Management](/packages/arcade-config/) for cache configuration
