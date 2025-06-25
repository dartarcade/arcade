---
title: Getting Started
description: Get up and running with Arcade in minutes
---

This guide will walk you through creating your first Arcade application, from installation to deployment.

## Prerequisites

Before you begin, make sure you have:

- [Dart SDK](https://dart.dev/get-dart) (3.0 or higher)
- A code editor (VS Code with Dart extension recommended)
- Basic knowledge of Dart programming

## Installation

### Create a new Dart project

```bash
dart create -t console my_arcade_app
cd my_arcade_app
```

### Add Arcade dependency

Add Arcade to your `pubspec.yaml`:

```yaml
dependencies:
  arcade: ^0.3.1
```

Then install the dependencies:

```bash
dart pub get
```

## Your First Server

Create a simple server in `bin/server.dart`:

```dart
import 'package:arcade/arcade.dart';

Future<void> main() async {
  await runServer(
    port: 3000,
    init: () {
      // Define your routes here
      route.get('/').handle((context) => 'Hello, Arcade!');
      
      route.get('/api/health').handle((context) {
        return {'status': 'ok', 'timestamp': DateTime.now().toIso8601String()};
      });
    },
  );
}
```

### Run the server

```bash
dart run bin/server.dart
```

You should see:
```
Server running on port 3000
```

Visit [http://localhost:3000](http://localhost:3000) to see your server in action!

## Understanding the Basics

### The `runServer` function

The `runServer` function is the entry point for your Arcade application:

```dart
await runServer(
  port: 3000,              // Port to listen on
  init: () {               // Initialization function
    // Define routes, configure services, etc.
  },
  logLevel: LogLevel.info, // Optional: Set log level
);
```

### Routes

Routes in Arcade follow a simple pattern:

```dart
route.<method>(path).<hooks>?.handle(handler);
```

For example:
```dart
// Simple GET route
route.get('/users').handle((context) => 'List of users');

// POST route with before hook
route.post('/users')
  .before((context) {
    // Validate request
    return context;
  })
  .handle((context) async {
    final body = await context.jsonMap();
    // Create user
    return {'created': true};
  });
```

### Request Context

Every handler receives a `RequestContext` object that provides access to:

- Request data (headers, body, parameters)
- Response utilities
- Route information

```dart
route.get('/users/:id').handle((context) {
  final userId = context.pathParameters['id'];
  final filter = context.queryParameters['filter'];
  
  return {
    'userId': userId,
    'filter': filter,
    'requestedAt': DateTime.now().toIso8601String(),
  };
});
```

## Adding More Features

### Handling JSON bodies

```dart
route.post('/api/users').handle((context) async {
  final result = await context.jsonMap();
  
  if (result case BodyParseSuccess(:final value)) {
    // Process the JSON data
    final name = value['name'];
    final email = value['email'];
    
    return {'id': 123, 'name': name, 'email': email};
  } else {
    context.statusCode = 400;
    return {'error': 'Invalid JSON body'};
  }
});
```

### Error handling

```dart
route.get('/api/protected').handle((context) {
  final token = context.requestHeaders.value('authorization');
  
  if (token == null) {
    throw UnauthorizedException();
  }
  
  return {'secret': 'data'};
});

// Global error handler
overrideErrorHandler((context, error, stackTrace) {
  if (error is UnauthorizedException) {
    context.statusCode = 401;
    return {'error': 'Unauthorized'};
  }
  
  context.statusCode = 500;
  return {'error': 'Internal server error'};
});
```

### Static files

To serve static files, create a `public` directory in your project root:

```
my_arcade_app/
├── bin/
│   └── server.dart
├── public/
│   ├── index.html
│   └── style.css
└── pubspec.yaml
```

Arcade will automatically serve files from the `public` directory.

## Project Structure

Here's a recommended project structure for Arcade applications:

```
my_arcade_app/
├── bin/
│   └── server.dart          # Entry point
├── lib/
│   ├── controllers/         # Route handlers
│   ├── services/           # Business logic
│   ├── models/             # Data models
│   └── hooks/              # Reusable hooks
├── public/                 # Static files
├── test/                   # Tests
└── pubspec.yaml
```

## Environment Configuration

Use environment variables for configuration:

```dart
import 'dart:io';

Future<void> main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '3000');
  final dbUrl = Platform.environment['DATABASE_URL'] ?? 'localhost';
  
  await runServer(
    port: port,
    init: () {
      // Use dbUrl to connect to database
      route.get('/').handle((context) => 'Server running on port $port');
    },
  );
}
```

## Next Steps

Now that you have a basic Arcade server running, explore these topics:

- [Core Concepts](/core/routing/) - Deep dive into routing
- [Request Handling](/guides/request-handling/) - Working with requests and responses
- [Hooks](/core/hooks/) - Adding before/after hooks
- [WebSockets](/guides/websockets/) - Real-time communication
- [Dependency Injection](/guides/dependency-injection/) - Structuring larger applications

## Getting Help

If you run into issues:

1. Check the [API Reference](/reference/)
2. Look at the [example applications](https://github.com/dartarcade/arcade/tree/main/samples)
3. Open an issue on [GitHub](https://github.com/dartarcade/arcade/issues)

Happy coding with Arcade!