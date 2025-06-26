---
title: Arcade Cache Redis
description: Redis adapter for the Arcade Cache system
---

The `arcade_cache_redis` package provides a Redis-based implementation of the Arcade Cache interface, enabling distributed caching across multiple server instances with persistence and advanced features.

## Installation

Add `arcade_cache_redis` to your `pubspec.yaml`:

```yaml
dependencies:
  arcade_cache_redis: ^0.0.2
```

## Features

- **Distributed Caching**: Share cache across multiple server instances
- **Persistence**: Data survives server restarts
- **TTL Support**: Native Redis expiration handling
- **High Performance**: Leverages Redis's speed and efficiency
- **Secure Connections**: Support for SSL/TLS connections
- **Compatible API**: Drop-in replacement for MemoryCacheManager

## Quick Start

```dart
import 'package:arcade_cache_redis/arcade_cache_redis.dart';

void main() async {
  // Create Redis cache instance
  final cache = RedisCacheManager();
  
  // Initialize with connection info
  await cache.init((
    host: 'localhost',
    port: 6379,
    secure: false,
  ));
  
  // Use exactly like MemoryCacheManager
  await cache.set('user:123', {'name': 'John Doe'});
  final user = await cache.getJson('user:123');
  
  // Clean up
  await cache.dispose();
}
```

## Configuration

### Basic Configuration

```dart
final cache = RedisCacheManager();
await cache.init((
  host: 'localhost',
  port: 6379,
  secure: false,
));
```

### Secure Connection

```dart
final cache = RedisCacheManager();
await cache.init((
  host: 'redis.example.com',
  port: 6380,
  secure: true,  // Enable SSL/TLS
));
```

## Integration with Arcade

### Setup with get_it

```dart
import 'package:arcade/arcade.dart';
import 'package:arcade_cache/arcade_cache.dart';
import 'package:arcade_cache_redis/arcade_cache_redis.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void main() async {
  // Initialize Redis cache
  final cache = RedisCacheManager();
  await cache.init((
    host: Platform.environment['REDIS_HOST'] ?? 'localhost',
    port: int.parse(Platform.environment['REDIS_PORT'] ?? '6379'),
    secure: Platform.environment['REDIS_SECURE'] == 'true',
  ));
  
  // Register with get_it
  getIt.registerSingleton<BaseCacheManager>(cache);
  
  await runServer(
    port: 3000,
    init: () {
      // Your routes can now use getIt<BaseCacheManager>()
    },
  );
}
```

### Session Storage

```dart
class RedisSessionStore {
  final BaseCacheManager cache;
  final Duration sessionTtl;
  
  RedisSessionStore({
    required this.cache,
    this.sessionTtl = const Duration(hours: 24),
  });
  
  Future<void> saveSession(String sessionId, Map<String, dynamic> data) async {
    await cache.set('session:$sessionId', data, ttl: sessionTtl);
  }
  
  Future<Map<String, dynamic>?> getSession(String sessionId) async {
    return await cache.getJson('session:$sessionId');
  }
  
  Future<void> destroySession(String sessionId) async {
    await cache.remove('session:$sessionId');
  }
  
  Future<void> refreshSession(String sessionId) async {
    final data = await getSession(sessionId);
    if (data != null) {
      await saveSession(sessionId, data);  // Reset TTL
    }
  }
}

// Usage in hooks
route.before((context) async {
  final sessionId = context.requestHeaders.cookie
    ?.firstWhere((c) => c.name == 'session_id', orElse: () => null)
    ?.value;
    
  if (sessionId != null) {
    final cache = getIt<BaseCacheManager>();
    final sessionStore = RedisSessionStore(cache: cache);
    final session = await sessionStore.getSession(sessionId);
    
    if (session != null) {
      context.session = session;
      await sessionStore.refreshSession(sessionId);
    }
  }
  
  return context;
});
```

### Rate Limiting

```dart
class RedisRateLimiter {
  final BaseCacheManager cache;
  
  RedisRateLimiter(this.cache);
  
  Future<bool> checkRateLimit({
    required String key,
    required int maxRequests,
    required Duration window,
  }) async {
    final windowKey = '$key:${DateTime.now().millisecondsSinceEpoch ~/ window.inMilliseconds}';
    
    // Get current count
    final currentCount = await cache.get<int>(windowKey) ?? 0;
    
    if (currentCount >= maxRequests) {
      return false;  // Rate limit exceeded
    }
    
    // Increment counter
    await cache.set(windowKey, currentCount + 1, ttl: window);
    return true;
  }
}

// Usage
route.before((context) async {
  final cache = getIt<BaseCacheManager>();
  final rateLimiter = RedisRateLimiter(cache);
  final clientIp = context.requestHeaders.value('x-forwarded-for') ?? 
                   context.rawRequest.connectionInfo?.remoteAddress.address ?? 
                   'unknown';
  
  final allowed = await rateLimiter.checkRateLimit(
    key: 'rate_limit:$clientIp',
    maxRequests: 100,
    window: Duration(minutes: 1),
  );
  
  if (!allowed) {
    throw TooManyRequestsException('Rate limit exceeded');
  }
  
  return context;
});
```

## Advanced Usage


### Distributed Locking

```dart
class RedisLock {
  final RedisCacheManager cache;
  
  RedisLock(this.cache);
  
  Future<bool> acquire(
    String lockKey, 
    String lockId,
    Duration ttl,
  ) async {
    final key = 'lock:$lockKey';
    final existing = await cache.getString(key);
    
    if (existing != null) {
      return false;  // Lock already held
    }
    
    await cache.setWithTtl(key, lockId, ttl);
    
    // Verify we got the lock (handle race condition)
    final verify = await cache.getString(key);
    return verify == lockId;
  }
  
  Future<bool> release(String lockKey, String lockId) async {
    final key = 'lock:$lockKey';
    final existing = await cache.getString(key);
    
    if (existing == lockId) {
      await cache.remove(key);
      return true;
    }
    
    return false;  // Lock not held by this ID
  }
  
  Future<T> withLock<T>(
    String lockKey,
    Future<T> Function() action,
    {Duration timeout = const Duration(seconds: 30)}
  ) async {
    final lockId = Uuid().v4();
    final acquired = await acquire(lockKey, lockId, timeout);
    
    if (!acquired) {
      throw Exception('Could not acquire lock: $lockKey');
    }
    
    try {
      return await action();
    } finally {
      await release(lockKey, lockId);
    }
  }
}

// Usage
final lock = RedisLock(redisCache);

await lock.withLock('process:important-task', () async {
  // Only one server can run this at a time
  await performImportantTask();
});
```


## Performance Optimization

### Batch Operations

```dart
class CacheBatchOperations {
  final BaseCacheManager cache;
  
  CacheBatchOperations(this.cache);
  
  Future<Map<String, dynamic>> multiGet(List<String> keys) async {
    final results = <String, dynamic>{};
    
    // Execute all gets concurrently
    await Future.wait(keys.map((key) async {
      final value = await cache.get(key);
      if (value != null) {
        results[key] = value;
      }
    }));
    
    return results;
  }
  
  Future<void> multiSet(Map<String, dynamic> items, {Duration? ttl}) async {
    // Execute all sets concurrently
    if (ttl != null) {
      await Future.wait(items.entries.map((entry) => 
        cache.setWithTtl(entry.key, entry.value, ttl)
      ));
    } else {
      await Future.wait(items.entries.map((entry) => 
        cache.set(entry.key, entry.value)
      ));
    }
  }
  
  Future<void> multiRemove(List<String> keys) async {
    // Execute all removes concurrently
    await Future.wait(keys.map((key) => cache.remove(key)));
  }
}
```


## Monitoring and Debugging

### Debug Logging

```dart
class LoggingRedisCache implements BaseCacheManager<RedisConnectionInfo> {
  final RedisCacheManager _cache;
  final Logger logger;
  
  LoggingRedisCache(this._cache, this.logger);
  
  @override
  Future<void> init(RedisConnectionInfo connectionInfo) async {
    await _cache.init(connectionInfo);
  }
  
  @override
  Future<void> set(String key, dynamic value) async {
    final start = DateTime.now();
    try {
      await _cache.set(key, value);
      final duration = DateTime.now().difference(start);
      logger.debug('Cache SET $key (${duration.inMilliseconds}ms)');
    } catch (e) {
      logger.error('Cache SET failed for $key', e);
      rethrow;
    }
  }
  
  @override
  Future<void> setWithTtl(String key, dynamic value, Duration ttl) async {
    final start = DateTime.now();
    try {
      await _cache.setWithTtl(key, value, ttl);
      final duration = DateTime.now().difference(start);
      logger.debug('Cache SET_TTL $key (${duration.inMilliseconds}ms, ttl: ${ttl.inSeconds}s)');
    } catch (e) {
      logger.error('Cache SET_TTL failed for $key', e);
      rethrow;
    }
  }
  
  @override
  Future<T?> get<T extends Object>(String key) async {
    final start = DateTime.now();
    try {
      final result = await _cache.get<T>(key);
      final duration = DateTime.now().difference(start);
      logger.debug('Cache GET $key: ${result != null ? 'HIT' : 'MISS'} (${duration.inMilliseconds}ms)');
      return result;
    } catch (e) {
      logger.error('Cache GET failed for $key', e);
      rethrow;
    }
  }
  
  // Delegate other methods
  @override
  Future<void> dispose() => _cache.dispose();
  
  @override
  Future<void> clear() => _cache.clear();
  
  @override
  Future<void> remove<T>(String key) => _cache.remove(key);
  
  @override
  Future<bool> contains<T>(String key) => _cache.contains(key);
  
  @override
  Future<String?> getString(String key) => _cache.getString(key);
  
  @override
  Future<List<T>?> getList<T>(String key) => _cache.getList<T>(key);
  
  @override
  Future<Map<String, dynamic>?> getJson(String key) => _cache.getJson(key);
}
```

## Migration from MemoryCacheManager

Migrating from `MemoryCacheManager` to `RedisCacheManager` is straightforward:

```dart
// Before
final cache = MemoryCacheManager();
await cache.init(null);

// After
final cache = RedisCacheManager();
await cache.init(RedisConnectionInfo(
  host: 'localhost',
  port: 6379,
));

// All other code remains the same!
```

## Best Practices

1. **Connection Management**: Use connection pooling for better performance
2. **Key Naming**: Use consistent prefixes and separators (e.g., `user:123:profile`)
3. **TTL Strategy**: Set appropriate TTLs to prevent memory bloat
4. **Error Handling**: Always handle connection failures gracefully
5. **Monitoring**: Track hit rates and performance metrics
6. **Security**: Use SSL/TLS for production deployments
7. **Persistence**: Configure Redis persistence based on your needs

## Troubleshooting

### Connection Issues

```dart
try {
  await cache.init((
    host: 'localhost',
    port: 6379,
    secure: false,
  ));
} catch (e) {
  print('Redis connection failed: $e');
  // Fall back to memory cache
  final fallbackCache = MemoryCacheManager();
  fallbackCache.init(null);
}
```

### Performance Issues

- Monitor cache hit/miss rates using debug logging
- Use batch operations for multiple cache operations
- Consider using TTL to prevent memory bloat
- Check network latency between application and Redis server

## Next Steps

- Learn about [Arcade Cache](/packages/arcade-cache/) base functionality
- Explore [WebSocket Integration](/guides/websockets/) for real-time features
- See [Configuration Management](/packages/arcade-config/) for Redis configuration