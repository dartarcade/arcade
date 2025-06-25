---
title: Routing
description: Understanding Arcade's routing system
---

Routing is at the heart of any web framework. Arcade provides a clean, Express-like routing API that's both powerful and easy to use.

## Basic Routing

Routes in Arcade are defined using the global `route` object:

```dart
route.<method>(path).handle(handler);
```

### HTTP Methods

Arcade supports all standard HTTP methods:

```dart
route.get('/users').handle((context) => 'GET users');
route.post('/users').handle((context) => 'POST user');
route.put('/users/:id').handle((context) => 'PUT user');
route.delete('/users/:id').handle((context) => 'DELETE user');
route.patch('/users/:id').handle((context) => 'PATCH user');
route.head('/users').handle((context) => 'HEAD users');
route.options('/users').handle((context) => 'OPTIONS users');
```

There's also a special `any` method that matches all HTTP methods:

```dart
route.any('/api/*').handle((context) => 'Matches any method');
```

## Path Parameters

Capture dynamic segments in your URLs using the `:param` syntax:

```dart
route.get('/users/:id').handle((context) {
  final userId = context.pathParameters['id'];
  return {'userId': userId};
});

// Multiple parameters
route.get('/posts/:postId/comments/:commentId').handle((context) {
  final postId = context.pathParameters['postId'];
  final commentId = context.pathParameters['commentId'];
  return {
    'postId': postId,
    'commentId': commentId,
  };
});
```

## Wildcards

Use wildcards to match multiple path segments:

```dart
// Matches /files/image.jpg, /files/docs/report.pdf, etc.
route.get('/files/*').handle((context) {
  final path = context.path;
  return {'requestedFile': path};
});
```

## Query Parameters

Access query string parameters through the context:

```dart
// GET /search?q=arcade&limit=10
route.get('/search').handle((context) {
  final query = context.queryParameters['q'] ?? '';
  final limit = int.tryParse(context.queryParameters['limit'] ?? '20') ?? 20;
  
  return {
    'query': query,
    'limit': limit,
  };
});
```

## Route Groups

Organize related routes using groups:

```dart
route.group('/api/v1', defineRoutes: (route) {
  // All routes in this group will be prefixed with /api/v1
  
  route().get('/users').handle((context) => 'List users');
  route().post('/users').handle((context) => 'Create user');
  
  // Nested groups
  route().group('/admin', defineRoutes: (route) {
    // This will be /api/v1/admin/dashboard
    route().get('/dashboard').handle((context) => 'Admin dashboard');
  });
});
```

### Groups with Hooks

Apply hooks to all routes in a group:

```dart
route.group(
  '/api',
  before: [
    (context) {
      // This runs before all routes in the group
      print('API request: ${context.path}');
      return context;
    },
  ],
  after: [
    (context, result) {
      // This runs after all routes in the group
      print('API response sent');
      return (context, result);
    },
  ],
  defineRoutes: (route) {
    route().get('/users').handle((context) => []);
    route().get('/posts').handle((context) => []);
  },
);
```

## Route Order

Routes are matched in the order they are defined. More specific routes should be defined before generic ones:

```dart
// Define specific routes first
route.get('/users/me').handle((context) => 'Current user');
route.get('/users/:id').handle((context) => 'User by ID');

// Generic wildcard routes last
route.get('/users/*').handle((context) => 'Other user routes');
```

## Not Found Handler

Define a custom handler for 404 errors:

```dart
route.notFound((context) {
  context.statusCode = 404;
  return {
    'error': 'Not Found',
    'path': context.path,
    'timestamp': DateTime.now().toIso8601String(),
  };
});
```

## Route Metadata

Attach metadata to routes for documentation or other purposes:

```dart
route.get(
  '/api/users',
  extra: {
    'description': 'List all users',
    'auth': true,
    'roles': ['admin', 'user'],
  },
).handle((context) {
  // Access metadata
  final metadata = context.route.metadata?.extra;
  return {'users': []};
});
```

## Route Builder Pattern

For complex applications, organize routes in separate functions:

```dart
void defineUserRoutes() {
  route.group('/users', defineRoutes: (route) {
    route().get('/').handle(listUsers);
    route().get('/:id').handle(getUser);
    route().post('/').handle(createUser);
    route().put('/:id').handle(updateUser);
    route().delete('/:id').handle(deleteUser);
  });
}

void defineAuthRoutes() {
  route.post('/login').handle(login);
  route.post('/logout').handle(logout);
  route.post('/register').handle(register);
}

// In your main function
await runServer(
  port: 3000,
  init: () {
    defineUserRoutes();
    defineAuthRoutes();
  },
);
```

## Dynamic Route Registration

Routes can be registered dynamically based on configuration:

```dart
final features = ['users', 'posts', 'comments'];

for (final feature in features) {
  route.get('/$feature').handle((context) => 'List $feature');
  route.post('/$feature').handle((context) => 'Create $feature');
}
```

## Route Validation

Arcade validates routes at startup:

- Duplicate route definitions are allowed (last one wins)
- Routes without handlers will cause an error
- Invalid path patterns will be caught early

## Best Practices

1. **Organize routes logically** - Use groups and separate functions
2. **Be consistent with naming** - Use RESTful conventions
3. **Define specific routes first** - More generic patterns last
4. **Use meaningful path parameters** - `:userId` instead of `:id`
5. **Handle errors appropriately** - Define not found and error handlers

## Next Steps

- Learn about [Request Context](/core/request-context/) to handle requests
- Explore [Hooks](/core/hooks/) to add pre/post processing
- Understand [Error Handling](/core/error-handling/) for robust applications