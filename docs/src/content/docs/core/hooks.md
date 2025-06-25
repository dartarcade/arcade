---
title: Hooks
description: Understanding before and after hooks in Arcade
---

Hooks in Arcade provide a powerful way to intercept and modify requests and responses. They allow you to add authentication, logging, validation, and other cross-cutting concerns to your routes.

## Before Hooks

Before hooks run before the route handler and can transform the request context:

```dart
route.get('/api/users')
  .before((context) {
    print('Before handler: ${context.path}');
    // Must return a context
    return context;
  })
  .handle((context) => {'users': []});
```

### Authentication Example

```dart
route.get('/api/profile')
  .before((context) {
    final token = context.requestHeaders.value('authorization');
    
    if (token == null || !isValidToken(token)) {
      throw UnauthorizedException();
    }
    
    return context;
  })
  .handle((context) => {'profile': 'data'});
```

### Multiple Before Hooks

Chain multiple before hooks - they run in order:

```dart
route.post('/api/users')
  .before((context) {
    print('First hook: Authentication');
    return context;
  })
  .before((context) {
    print('Second hook: Validation');
    return context;
  })
  .handle((context) => 'User created');
```

## After Hooks

After hooks run after the handler and can transform the response:

```dart
route.get('/api/data')
  .handle((context) => {'data': 'value'})
  .after((context, result) {
    print('After handler: ${context.path}');
    // Add metadata to response
    final enhanced = {
      ...result as Map,
      'timestamp': DateTime.now().toIso8601String(),
    };
    return (context, enhanced);
  });
```

### Response Transformation

```dart
route.get('/api/users')
  .handle((context) => fetchUsers())
  .after((context, users) {
    // Wrap response in standard format
    return (context, {
      'success': true,
      'data': users,
      'count': (users as List).length,
    });
  });
```

## Context Transformation

Before hooks can return a different context type, enabling type-safe request handling:

```dart
class AuthContext extends RequestContext {
  final User user;
  
  AuthContext({
    required super.request,
    required super.route,
    required this.user,
  });
}

BeforeHookHandler<RequestContext, AuthContext> requireAuth() {
  return (context) async {
    final token = context.requestHeaders.value('authorization');
    
    if (token == null) {
      throw UnauthorizedException(message: 'Missing token');
    }
    
    final user = await validateTokenAndGetUser(token);
    
    return AuthContext(
      request: context.rawRequest,
      route: context.route,
      user: user,
    );
  };
}

// Usage
route.get('/api/me')
  .before(requireAuth())
  .handle((AuthContext context) {
    // Now we have typed access to context.user
    return context.user.toJson();
  });
```

## Global Hooks

Register hooks that run for all routes:

```dart
void main() async {
  await runServer(
    port: 3000,
    init: () {
      // Global before hook
      route.registerGlobalBeforeHook((context) {
        print('Request: ${context.method.name} ${context.path}');
        return context;
      });
      
      // Global after hook
      route.registerGlobalAfterHook((context, result) {
        print('Response sent for ${context.path}');
        return (context, result);
      });
      
      // Define routes
      route.get('/').handle((context) => 'Home');
      route.get('/api').handle((context) => {'api': 'v1'});
    },
  );
}
```

### Multiple Global Hooks

```dart
route.registerAllGlobalBeforeHooks([
  loggingHook,
  corsHook,
  rateLimitHook,
]);

route.registerAllGlobalAfterHooks([
  responseTimeHook,
  compressionHook,
]);
```

## Group Hooks

Apply hooks to all routes in a group:

```dart
route.group<RequestContext>(
  '/api',
  before: [
    (context) {
      // Check API key for all API routes
      final apiKey = context.requestHeaders.value('x-api-key');
      if (apiKey != 'valid-key') {
        throw UnauthorizedException();
      }
      return context;
    },
  ],
  after: [
    (context, result) {
      // Add API version to all responses
      return (context, {
        ...result as Map,
        'apiVersion': '1.0',
      });
    },
  ],
  defineRoutes: (route) {
    route().get('/users').handle((context) => []);
    route().get('/posts').handle((context) => []);
  },
);
```

## WebSocket Hooks

Special hooks for WebSocket connections:

```dart
route.get('/ws')
  .before((context) {
    // Runs before WebSocket upgrade
    print('WebSocket connection attempt');
    return context;
  })
  .handleWebSocket(
    (context, websocket, id) {
      // Handle WebSocket messages
    },
    onConnect: (context, websocket, id) {
      // Called when connection is established
      print('WebSocket connected: $id');
    },
  )
  .after((context, result, id) {
    // Runs after WebSocket connection closes
    print('WebSocket disconnected: $id');
    return (context, result, id);
  });
```

## Path-Specific Hooks

Add hooks to existing routes by path:

```dart
// Define routes first
route.get('/api/users').handle(listUsers);
route.post('/api/users').handle(createUser);

// Add hooks to specific paths later
route.addBeforeHookForPath('/api/users', authHook);
route.addAfterHookForPath('/api/users', loggingHook);
```

## Hook Execution Order

Understanding the execution order is crucial:

1. Global before hooks (in registration order)
2. Group before hooks (in registration order)
3. Route-specific before hooks (in chaining order)
4. **Route handler**
5. Route-specific after hooks (in chaining order)
6. Group after hooks (in registration order)
7. Global after hooks (in registration order)

```dart
route.registerGlobalBeforeHook((ctx) {
  print('1. Global before');
  return ctx;
});

route.group<RequestContext>('/api', 
  before: [(ctx) {
    print('2. Group before');
    return ctx;
  }],
  defineRoutes: (route) {
    route().get('/test')
      .before((ctx) {
        print('3. Route before');
        return ctx;
      })
      .handle((ctx) {
        print('4. Handler');
        return 'OK';
      })
      .after((ctx, result) {
        print('5. Route after');
        return (ctx, result);
      });
  },
  after: [(ctx, result) {
    print('6. Group after');
    return (ctx, result);
  }],
);

route.registerGlobalAfterHook((ctx, result) {
  print('7. Global after');
  return (ctx, result);
});
```

## Common Hook Patterns

### CORS Hook

```dart
BeforeHookHandler corsHook() {
  return (context) {
    context.responseHeaders
      ..add('Access-Control-Allow-Origin', '*')
      ..add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
      ..add('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    
    if (context.method == HttpMethod.options) {
      throw ResponseSentException();
    }
    
    return context;
  };
}
```

### Logging Hook

```dart
AfterHookHandler loggingHook() {
  return (context, result) {
    final duration = DateTime.now().difference(context.startTime);
    Logger.root.info('${context.method.name} ${context.path} - ${duration.inMilliseconds}ms');
    return (context, result);
  };
}
```

### Validation Hook

```dart
BeforeHookHandler validateJson(Map<String, dynamic> Function(Map<String, dynamic>) validator) {
  return (context) async {
    final result = await context.jsonMap();
    
    if (result case BodyParseSuccess(:final value)) {
      try {
        validator(value);
        return context;
      } catch (e) {
        throw BadRequestException(message: e.toString());
      }
    }
    
    throw BadRequestException(message: 'Invalid JSON');
  };
}
```

## Best Practices

1. **Keep hooks focused** - Each hook should have a single responsibility
2. **Handle errors appropriately** - Thrown exceptions stop the chain
3. **Return transformed contexts** - Enable type safety
4. **Order matters** - Be mindful of hook execution order
5. **Reuse common hooks** - Create hook factories for common patterns

## Next Steps

- Learn about [Error Handling](/core/error-handling/) in hooks
- See [Request Handling Guide](/guides/request-handling/) for practical examples
- Explore [Dependency Injection](/guides/dependency-injection/) for advanced patterns