---
title: Arcade Config
description: Central configuration management for Arcade applications
---

The `arcade_config` package provides a centralized configuration system for Arcade applications, managing settings for logging, static files, views, environment variables, and more.

## Installation

Add `arcade_config` to your `pubspec.yaml`:

```yaml
dependencies:
  arcade_config: ^0.1.3
```

## Configuration Options

### Available Settings

```dart
class ArcadeConfig {
  // Logger configuration
  static String rootLoggerName = 'Arcade';

  // Static files configuration
  static String staticFilesDirectory = 'public';
  static Map<String, String> staticFilesHeaders = {
    'cache-control': 'public, max-age=3600',
  };

  // View template configuration
  static String viewsDirectory = 'views';
  static String viewsExtension = '.jinja';

  // Environment configuration (Not currently used)
  static String? envFile;

  // Logging level
  static LogLevel logLevel = LogLevel.info;
}
```

## Quick Start

### Basic Configuration

```dart
import 'package:arcade/arcade.dart';
import 'package:arcade_config/arcade_config.dart';

void main() async {
  // Configure before starting server
  ArcadeConfig.rootLoggerName = 'MyApp';
  ArcadeConfig.staticFilesDirectory = 'assets';
  ArcadeConfig.viewsDirectory = 'templates';
  ArcadeConfig.logLevel = LogLevel.debug;

  await runServer(
    port: 3000,
    init: () {
      // Your routes...
    },
  );
}
```

### Environment-Based Configuration

```dart
void configureApp() {
  final env = Platform.environment['APP_ENV'] ?? 'development';

  switch (env) {
    case 'production':
      ArcadeConfig.logLevel = LogLevel.warning;
      ArcadeConfig.staticFilesHeaders = {
        'cache-control': 'public, max-age=86400', // 24 hours
        'x-content-type-options': 'nosniff',
      };

    case 'development':
      ArcadeConfig.logLevel = LogLevel.debug;
      ArcadeConfig.staticFilesHeaders = {
        'cache-control': 'no-cache',
      };
  }
}
```

## Configuration Patterns

### Configuration Class

Create a dedicated configuration class:

```dart
class AppConfig {
  // Server configuration
  static late final int port;
  static late final String host;

  // Database configuration
  static late final String dbHost;
  static late final int dbPort;
  static late final String dbName;

  // API configuration
  static late final String apiKey;
  static late final String apiSecret;

  // Feature flags
  static late final bool enableCache;
  static late final bool enableMetrics;

  static void load() {
    // Load from environment
    port = int.parse(env.get('PORT', '3000'));
    host = env.get('HOST', '0.0.0.0');

    dbHost = env.get('DB_HOST', 'localhost');
    dbPort = int.parse(env.get('DB_PORT', '5432'));
    dbName = env.get('DB_NAME', 'myapp');

    apiKey = env.get('API_KEY', required: true);
    apiSecret = env.get('API_SECRET', required: true);

    enableCache = env.getBool('ENABLE_CACHE', true);
    enableMetrics = env.getBool('ENABLE_METRICS', false);

    // Configure Arcade
    ArcadeConfig.logLevel = LogLevel.values.firstWhere(
      (level) => level.name == env.get('LOG_LEVEL', 'info'),
      orElse: () => LogLevel.info,
    );
  }
}

void main() async {
  // Load configuration
  AppConfig.load();

  await runServer(
    port: AppConfig.port,
    host: AppConfig.host,
    init: () {
      // Your routes...
    },
  );
}
```

### JSON Configuration

Load configuration from JSON files:

```dart
class JsonConfig {
  static late Map<String, dynamic> _config;

  static Future<void> load(String environment) async {
    final file = File('config/$environment.json');
    final content = await file.readAsString();
    _config = jsonDecode(content);

    // Apply to ArcadeConfig
    ArcadeConfig.rootLoggerName = _config['logger']['name'] ?? 'Arcade';
    ArcadeConfig.logLevel = LogLevel.values.firstWhere(
      (level) => level.name == _config['logger']['level'],
      orElse: () => LogLevel.info,
    );

    ArcadeConfig.staticFilesDirectory = _config['static']['directory'] ?? 'public';
    ArcadeConfig.staticFilesHeaders = Map<String, String>.from(
      _config['static']['headers'] ?? {},
    );

    ArcadeConfig.viewsDirectory = _config['views']['directory'] ?? 'views';
    ArcadeConfig.viewsExtension = _config['views']['extension'] ?? '.jinja';
  }

  static T get<T>(String key, {T? defaultValue}) {
    final keys = key.split('.');
    dynamic value = _config;

    for (final k in keys) {
      if (value is Map && value.containsKey(k)) {
        value = value[k];
      } else {
        return defaultValue as T;
      }
    }

    return value as T;
  }
}

// config/development.json
{
  "logger": {
    "name": "MyApp",
    "level": "debug"
  },
  "static": {
    "directory": "public",
    "headers": {
      "cache-control": "no-cache"
    }
  },
  "views": {
    "directory": "templates",
    "extension": ".html"
  },
  "database": {
    "host": "localhost",
    "port": 5432,
    "name": "myapp_dev"
  }
}
```

## Integration with Other Packages

### With arcade_logger

The config package integrates seamlessly with arcade_logger:

```dart
import 'package:arcade_logger/arcade_logger.dart';
import 'package:arcade_config/arcade_config.dart';

void configureLogging() {
  // Set logger name
  ArcadeConfig.rootLoggerName = 'MyAPI';

  // Set log level
  ArcadeConfig.logLevel = LogLevel.debug;

  // Logger automatically uses these settings
  final logger = Logger('MyAPI.Service');
  logger.debug('Debug logging enabled');
}
```

### With arcade_views

Configure view rendering settings:

```dart
void configureViews() {
  // Set views directory
  ArcadeConfig.viewsDirectory = 'resources/views';

  // Change template extension
  ArcadeConfig.viewsExtension = '.html';

  // Views will be loaded from resources/views/*.html
}

// In your route
route.get('/').handle((context) async {
  return view('home'); // Loads resources/views/home.html
});
```

### With Static Files

Configure static file serving:

```dart
void configureStaticFiles() {
  // Set static directory
  ArcadeConfig.staticFilesDirectory = 'assets';

  // Configure headers
  ArcadeConfig.staticFilesHeaders = {
    'cache-control': 'public, max-age=3600',
    'x-content-type-options': 'nosniff',
    'x-frame-options': 'DENY',
    'x-xss-protection': '1; mode=block',
  };
}

// Static files will be served from /assets
```

## Next Steps

- Explore [Arcade Logger](/packages/arcade-logger/) for logging configuration
- Learn about [Static Files](/guides/static-files/) serving
- See [Views](/packages/arcade-views/) for template configuration
- Read about [Environment Variables](/guides/environment/) best practices
