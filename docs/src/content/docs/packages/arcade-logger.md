---
title: Arcade Logger
description: Asynchronous logging system for Arcade applications
---

The `arcade_logger` package provides a high-performance, asynchronous logging system for Arcade applications. It runs in a separate isolate to ensure logging operations never block your main application thread.

## Installation

Add `arcade_logger` to your `pubspec.yaml`:

```yaml
dependencies:
  arcade_logger: ^0.0.5+5
```

## Features

- **Asynchronous Logging**: Runs in separate isolate for non-blocking operations
- **Colored Output**: ANSI-styled console output for better readability
- **Log Levels**: Support for debug, info, warning, and error levels
- **Named Loggers**: Create hierarchical loggers for different components
- **Thread-Safe**: Safe to use from multiple isolates
- **Integration**: Works seamlessly with arcade_config

## Quick Start

```dart
import 'package:arcade_logger/arcade_logger.dart';

void main() async {
  // Initialize the logger
  await Logger.init();

  // Get the root logger
  final logger = Logger.root;

  // Log messages
  logger.debug('Debug message');
  logger.info('Info message');
  logger.warning('Warning message');
  logger.error('Error message');

  // Log with additional data
  logger.info('User logged in');
}
```

## Named Loggers

Create loggers for different parts of your application:

```dart
// Create named loggers
final dbLogger = Logger('Database');
final apiLogger = Logger('API');
final authLogger = Logger('API.Auth');

// Log with component context
dbLogger.info('Connected to database');
apiLogger.debug('Processing request');
authLogger.warning('Failed login attempt');
```

## Log Levels

### Available Levels

```dart
enum LogLevel {
  debug,    // Detailed diagnostic information
  info,     // General informational messages
  warning,  // Warning messages
  error,    // Error messages
  none,     // Disable logging
}
```

### Setting Log Level

```dart
import 'package:arcade_config/arcade_config.dart';

// Set global log level
ArcadeConfig.logLevel = LogLevel.warning;

// Only warning and error messages will be logged
logger.debug('This will not appear');
logger.info('This will not appear');
logger.warning('This will appear');
logger.error('This will appear');
```

### Dynamic Log Level

```dart
// Change log level at runtime
void setLogLevel(String level) {
  switch (level.toLowerCase()) {
    case 'debug':
      ArcadeConfig.logLevel = LogLevel.debug;
      break;
    case 'info':
      ArcadeConfig.logLevel = LogLevel.info;
      break;
    case 'warning':
      ArcadeConfig.logLevel = LogLevel.warning;
      break;
    case 'error':
      ArcadeConfig.logLevel = LogLevel.error;
      break;
  }
}
```

## Integration with Arcade

### Request Logging Hooks

```dart
class LoggingHooks {
  final Logger logger = Logger('HTTP');

  BeforeHook<RequestContext> createBeforeHook() {
    return (context) async {
      final requestId = Uuid().v4();
      context.extra['requestId'] = requestId;

      logger.info('Request started', {
        'id': requestId,
        'method': context.request.method,
        'path': context.request.uri.path,
        'ip': context.request.connectionInfo?.remoteAddress.address,
        'userAgent': context.request.headers['user-agent']?.first,
      });

      return context;
    };
  }

  AfterHook<RequestContext, dynamic> createAfterHook() {
    return (context, result) async {
      final requestId = context.extra['requestId'];
      final duration = DateTime.now().difference(
        context.extra['startTime'] as DateTime
      );

      logger.info('Request completed', {
        'id': requestId,
        'duration': duration.inMilliseconds,
        'status': context.response.statusCode,
      });

      return result;
    };
  }
}

// Apply to routes
final logging = LoggingHooks();

route.group('/api')
  .before(logging.createBeforeHook())
  .after(logging.createAfterHook());
```

### Error Logging

```dart
class ErrorLogger {
  static final logger = Logger('Error');

  static void logError(
    dynamic error,
    StackTrace? stackTrace, {
    Map<String, dynamic>? context,
  }) {
    final errorData = {
      'error': error.toString(),
      'type': error.runtimeType.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      if (context != null) ...context,
    };

    if (error is HttpException) {
      logger.warning('HTTP Exception', errorData);
    } else {
      logger.error('Unhandled error', errorData);
    }
  }
}

// Global error handler
route.onError((context, error, stackTrace) async {
  ErrorLogger.logError(error, stackTrace, context: {
    'path': context.request.uri.path,
    'method': context.request.method,
  });

  return ErrorResponse(
    statusCode: 500,
    message: 'Internal server error',
  );
});
```

### Database Query Logging

```dart
class DatabaseLogger {
  static final logger = Logger('Database');

  static Future<T> logQuery<T>(
    String query,
    Future<T> Function() execute, {
    Map<String, dynamic>? params,
  }) async {
    final start = DateTime.now();

    logger.debug('Executing query', {
      'query': query,
      if (params != null) 'params': params,
    });

    try {
      final result = await execute();
      final duration = DateTime.now().difference(start);

      logger.debug('Query completed', {
        'query': query,
        'duration': duration.inMilliseconds,
      });

      return result;
    } catch (error, stackTrace) {
      logger.error('Query failed', {
        'query': query,
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
      });
      rethrow;
    }
  }
}

// Usage
final users = await DatabaseLogger.logQuery(
  'SELECT * FROM users WHERE active = ?',
  () => db.query('SELECT * FROM users WHERE active = ?', [true]),
  params: {'active': true},
);
```

## Advanced Usage

### Structured Logging

```dart
class StructuredLogger {
  final Logger logger;
  final Map<String, dynamic> defaultFields;

  StructuredLogger(String name, {Map<String, dynamic>? defaults})
    : logger = Logger(name),
      defaultFields = defaults ?? {};

  void log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? fields,
    String? correlationId,
  }) {
    final data = {
      ...defaultFields,
      if (fields != null) ...fields,
      'timestamp': DateTime.now().toIso8601String(),
      if (correlationId != null) 'correlationId': correlationId,
    };

    switch (level) {
      case LogLevel.debug:
        logger.debug(message, data);
        break;
      case LogLevel.info:
        logger.info(message, data);
        break;
      case LogLevel.warning:
        logger.warning(message, data);
        break;
      case LogLevel.error:
        logger.error(message, data);
        break;
      case LogLevel.none:
        break;
    }
  }
}

// Usage
final apiLogger = StructuredLogger('API', defaults: {
  'service': 'user-service',
  'version': '1.0.0',
  'environment': 'production',
});

apiLogger.log(
  LogLevel.info,
  'User created',
  fields: {'userId': 123, 'email': 'user@example.com'},
  correlationId: 'req-123',
);
```

### Performance Logging

```dart
class PerformanceLogger {
  static final logger = Logger('Performance');

  static Future<T> measure<T>(
    String operation,
    Future<T> Function() action, {
    Map<String, dynamic>? metadata,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await action();
      stopwatch.stop();

      logger.info('Operation completed', {
        'operation': operation,
        'duration': stopwatch.elapsedMilliseconds,
        'success': true,
        if (metadata != null) ...metadata,
      });

      return result;
    } catch (error) {
      stopwatch.stop();

      logger.error('Operation failed', {
        'operation': operation,
        'duration': stopwatch.elapsedMilliseconds,
        'success': false,
        'error': error.toString(),
        if (metadata != null) ...metadata,
      });

      rethrow;
    }
  }
}

// Usage
final result = await PerformanceLogger.measure(
  'fetch_user_profile',
  () async => await userService.getProfile(userId),
  metadata: {'userId': userId},
);
```

### Audit Logging

```dart
class AuditLogger {
  static final logger = Logger('Audit');

  static void logAction({
    required String action,
    required String userId,
    required String resource,
    String? resourceId,
    Map<String, dynamic>? changes,
    String? ipAddress,
  }) {
    logger.info('Audit event', {
      'action': action,
      'userId': userId,
      'resource': resource,
      if (resourceId != null) 'resourceId': resourceId,
      if (changes != null) 'changes': changes,
      if (ipAddress != null) 'ipAddress': ipAddress,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}

// Usage in routes
route.put('/users/:id').handle((context) async {
  final userId = context.pathParameters['id']!;
  final updates = await context.jsonMap();

  final oldUser = await userService.getUser(userId);
  final newUser = await userService.updateUser(userId, updates);

  AuditLogger.logAction(
    action: 'update_user',
    userId: context.currentUser.id,
    resource: 'user',
    resourceId: userId,
    changes: {
      'before': oldUser.toJson(),
      'after': newUser.toJson(),
    },
    ipAddress: context.request.connectionInfo?.remoteAddress.address,
  );

  return newUser;
});
```

### Log Aggregation

```dart
class LogAggregator {
  static final _metrics = <String, int>{};
  static Timer? _reportTimer;

  static void init() {
    _reportTimer = Timer.periodic(Duration(minutes: 1), (_) {
      _reportMetrics();
    });
  }

  static void increment(String metric) {
    _metrics[metric] = (_metrics[metric] ?? 0) + 1;
  }

  static void _reportMetrics() {
    if (_metrics.isEmpty) return;

    Logger.root.info('Metrics report', Map.from(_metrics));
    _metrics.clear();
  }

  static void dispose() {
    _reportTimer?.cancel();
    _reportMetrics(); // Final report
  }
}

// Usage
route.before((context) async {
  LogAggregator.increment('requests.total');
  LogAggregator.increment('requests.${context.request.method}');
  return context;
});
```

## Output Formatting

### Console Output

The logger produces colored console output:

```console
2024-01-15 10:30:45 [DEBUG] MyApp: Debug message
2024-01-15 10:30:45 [INFO] MyApp: Info message
2024-01-15 10:30:45 [WARNING] MyApp: Warning message
2024-01-15 10:30:45 [ERROR] MyApp: Error message
```

Colors:

- Debug: Gray
- Info: Blue
- Warning: Yellow
- Error: Red

### JSON Output

For production environments, consider JSON output:

```dart
class JsonLogger {
  static void log(LogRecord record) {
    final json = jsonEncode({
      'timestamp': record.time.toIso8601String(),
      'level': record.level.name,
      'logger': record.loggerName,
      'message': record.message,
      'data': record.data,
    });

    print(json);
  }
}
```

## Best Practices

1. **Use Named Loggers**: Create loggers for each component
2. **Structured Data**: Pass data as Map instead of string interpolation
3. **Appropriate Levels**: Use correct log levels for different scenarios
4. **Avoid Blocking**: Don't perform expensive operations in log calls
5. **Correlation IDs**: Use request/correlation IDs for tracing
6. **Sensitive Data**: Never log passwords, tokens, or PII
7. **Performance**: Check log level before expensive operations

## Testing with Logger

```dart
import 'package:test/test.dart';
import 'package:arcade_logger/arcade_logger.dart';

void main() {
  setUpAll(() async {
    await Logger.init();
    ArcadeConfig.logLevel = LogLevel.debug;
  });

  test('logs messages correctly', () async {
    final logger = Logger('Test');

    logger.info('Test message');

    // Logger runs asynchronously in isolate
    await Future.delayed(Duration(milliseconds: 10));
  });
}
```

## Performance Considerations

- Logging runs in separate isolate - no main thread blocking
- Excessive logging can still impact performance
- Use appropriate log levels in production
- Consider log sampling for high-traffic endpoints
- Implement log rotation for file outputs

## Next Steps

- Learn about [Configuration](/packages/arcade-config/) for log level management
- Explore [Error Handling](/core/error-handling/) patterns
- See [Hooks](/core/hooks/) for request logging
