---
title: Error Handling
description: Managing errors and exceptions in Arcade applications
---

Arcade provides comprehensive error handling capabilities to help you build robust applications. Errors can be handled at multiple levels - globally, per route, or in hooks.

## Built-in Exceptions

Arcade includes several built-in HTTP exceptions:

```dart
// 400 Bad Request
throw BadRequestException(message: 'Invalid input');

// 401 Unauthorized
throw UnauthorizedException(message: 'Invalid token');

// 403 Forbidden
throw ForbiddenException(message: 'Access denied');

// 404 Not Found
throw NotFoundException(message: 'Resource not found');

// 405 Method Not Allowed
throw MethodNotAllowedException(message: 'Method not supported');

// 500 Internal Server Error
throw InternalServerErrorException(message: 'Something went wrong');
```

## Basic Error Handling

Throw exceptions in your handlers to return error responses:

```dart
route.get('/api/users/:id').handle((context) {
  final userId = context.pathParameters['id'];
  final user = getUserById(userId);
  
  if (user == null) {
    throw NotFoundException(message: 'User not found');
  }
  
  return user;
});
```

## Custom Error Handler

Override the default error handler for custom error responses:

```dart
await runServer(
  port: 3000,
  init: () {
    // Define custom error handler
    overrideErrorHandler((context, error, stackTrace) {
      // Log the error
      Logger.root.error('Error: $error', error, stackTrace);
      
      // Handle specific exceptions
      if (error is UnauthorizedException) {
        context.statusCode = 401;
        return {
          'error': 'Unauthorized',
          'message': error.message,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
      
      if (error is ValidationException) {
        context.statusCode = 400;
        return {
          'error': 'Validation failed',
          'errors': error.errors,
        };
      }
      
      // Default error response
      context.statusCode = 500;
      return {
        'error': 'Internal server error',
        'message': 'An unexpected error occurred',
      };
    });
    
    // Define routes
    route.get('/').handle((context) => 'Hello');
  },
);
```

## Custom Exceptions

Create your own exception types:

```dart
class ValidationException extends ArcadeHttpException {
  final Map<String, List<String>> errors;
  
  ValidationException({required this.errors})
    : super(statusCode: 400, message: 'Validation failed');
}

class RateLimitException extends ArcadeHttpException {
  final int retryAfter;
  
  RateLimitException({required this.retryAfter})
    : super(statusCode: 429, message: 'Too many requests');
}

// Usage
route.post('/api/users').handle((context) async {
  final body = await context.jsonMap();
  
  if (body case BodyParseSuccess(:final value)) {
    final errors = validateUserInput(value);
    
    if (errors.isNotEmpty) {
      throw ValidationException(errors: errors);
    }
    
    return createUser(value);
  }
  
  throw BadRequestException(message: 'Invalid JSON');
});
```

## Error Handling in Hooks

Errors thrown in hooks are handled the same way:

```dart
route.get('/api/protected')
  .before((context) {
    final token = context.requestHeaders.value('authorization');
    
    if (token == null) {
      throw UnauthorizedException(message: 'Missing auth token');
    }
    
    if (!isValidToken(token)) {
      throw UnauthorizedException(message: 'Invalid token');
    }
    
    return context;
  })
  .handle((context) => {'data': 'secret'});
```

## Not Found Handling

Define a custom 404 handler:

```dart
route.notFound((context) {
  context.statusCode = 404;
  
  // Return JSON for API routes
  if (context.path.startsWith('/api')) {
    return {
      'error': 'Not Found',
      'message': 'The requested endpoint does not exist',
      'path': context.path,
    };
  }
  
  // Return HTML for web routes
  context.responseHeaders.contentType = ContentType.html;
  return '''
    <!DOCTYPE html>
    <html>
      <body>
        <h1>404 - Page Not Found</h1>
        <p>The page ${context.path} does not exist.</p>
      </body>
    </html>
  ''';
});
```

## Development vs Production

Arcade automatically adjusts error handling based on the environment:

```dart
// In development (debug mode)
// - Stack traces are included in error responses
// - Detailed error messages are shown

// In production (release mode)
// - Stack traces are hidden
// - Generic error messages for security

const isDev = !bool.fromEnvironment('dart.vm.product');

overrideErrorHandler((context, error, stackTrace) {
  if (isDev) {
    // Include stack trace in development
    return {
      'error': error.toString(),
      'stack': stackTrace?.toString(),
    };
  }
  
  // Hide details in production
  return {
    'error': 'Internal server error',
  };
});
```

## Error Recovery

Handle errors gracefully with fallbacks:

```dart
route.get('/api/data').handle((context) async {
  try {
    // Try to get data from primary source
    return await fetchFromDatabase();
  } catch (e) {
    // Fall back to cache
    try {
      final cached = await fetchFromCache();
      context.responseHeaders.add('X-Cache', 'HIT');
      return cached;
    } catch (_) {
      // Final fallback
      throw InternalServerErrorException(
        message: 'Unable to retrieve data',
      );
    }
  }
});
```

## Validation Errors

Handle validation errors with detailed feedback:

```dart
class UserValidator {
  static Map<String, List<String>> validate(Map<String, dynamic> data) {
    final errors = <String, List<String>>{};
    
    final name = data['name'] as String?;
    if (name == null || name.isEmpty) {
      errors['name'] = ['Name is required'];
    } else if (name.length < 2) {
      errors['name'] = ['Name must be at least 2 characters'];
    }
    
    final email = data['email'] as String?;
    if (email == null || email.isEmpty) {
      errors['email'] = ['Email is required'];
    } else if (!email.contains('@')) {
      errors['email'] = ['Invalid email format'];
    }
    
    return errors;
  }
}

route.post('/api/users').handle((context) async {
  final result = await context.jsonMap();
  
  if (result case BodyParseSuccess(:final value)) {
    final errors = UserValidator.validate(value);
    
    if (errors.isNotEmpty) {
      context.statusCode = 422;
      return {
        'error': 'Validation failed',
        'errors': errors,
      };
    }
    
    return createUser(value);
  }
  
  throw BadRequestException(message: 'Invalid request body');
});
```

## Async Error Handling

Errors in async operations are automatically caught:

```dart
route.get('/api/async').handle((context) async {
  // These errors are caught automatically
  final data = await riskyAsyncOperation();
  
  // You can also use try-catch for specific handling
  try {
    final processed = await processData(data);
    return processed;
  } on ProcessingException catch (e) {
    context.statusCode = 422;
    return {'error': 'Processing failed', 'reason': e.reason};
  }
});
```

## Best Practices

1. **Use appropriate status codes** - Match HTTP semantics
2. **Provide helpful error messages** - But don't leak sensitive info
3. **Log errors server-side** - For debugging and monitoring
4. **Handle errors at the right level** - Global vs route-specific
5. **Validate early** - Catch errors before processing
6. **Use typed exceptions** - For better error handling

## Common Patterns

### API Error Response Format

```dart
class ApiError {
  static Map<String, dynamic> format({
    required String error,
    String? message,
    Map<String, dynamic>? details,
  }) {
    return {
      'error': error,
      if (message != null) 'message': message,
      if (details != null) 'details': details,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

overrideErrorHandler((context, error, stackTrace) {
  if (error is BadRequestException) {
    context.statusCode = 400;
    return ApiError.format(
      error: 'BAD_REQUEST',
      message: error.message,
    );
  }
  
  // ... handle other errors
});
```

### Request ID Tracking

```dart
route.registerGlobalBeforeHook((context) {
  final requestId = Uuid().v4();
  context.responseHeaders.add('X-Request-ID', requestId);
  
  // Store for error handler
  context.extra['requestId'] = requestId;
  return context;
});

overrideErrorHandler((context, error, stackTrace) {
  final requestId = context.extra['requestId'];
  
  Logger.root.error(
    'Request $requestId failed: $error',
    error,
    stackTrace,
  );
  
  return {
    'error': 'Internal error',
    'requestId': requestId,
  };
});
```

## Next Steps

- Explore [Hooks](/core/hooks/) for error handling in middleware
- See [Request Handling](/guides/request-handling/) for validation patterns
- Learn about [Dependency Injection](/guides/dependency-injection/) for service errors