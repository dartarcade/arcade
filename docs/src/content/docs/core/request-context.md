---
title: Request Context
description: Working with the RequestContext object in Arcade
---

The `RequestContext` is the central object that provides access to all request and response data in Arcade. Every route handler receives a context object as its parameter.

## Basic Usage

```dart
route.get('/example').handle((RequestContext context) {
  // Access request data
  final path = context.path;
  final method = context.method;
  
  // Set response data
  context.statusCode = 200;
  
  return {'path': path, 'method': method.name};
});
```

## Request Properties

### Path and Method

```dart
route.get('/api/users').handle((context) {
  print(context.path);    // "/api/users"
  print(context.method);  // HttpMethod.get
  
  return 'OK';
});
```

### Headers

Access request headers:

```dart
route.get('/api/data').handle((context) {
  // Get a specific header
  final authHeader = context.requestHeaders.value('authorization');
  final contentType = context.requestHeaders.contentType;
  
  // Check if header exists
  if (authHeader == null) {
    throw UnauthorizedException();
  }
  
  return {'authorized': true};
});
```

### Path Parameters

Extract dynamic segments from the URL:

```dart
route.get('/users/:userId/posts/:postId').handle((context) {
  final userId = context.pathParameters['userId'];
  final postId = context.pathParameters['postId'];
  
  return {
    'userId': userId,
    'postId': postId,
  };
});
```

### Query Parameters

Access URL query string parameters:

```dart
// GET /search?q=arcade&page=2&limit=20
route.get('/search').handle((context) {
  final query = context.queryParameters['q'] ?? '';
  final page = int.tryParse(context.queryParameters['page'] ?? '1') ?? 1;
  final limit = int.tryParse(context.queryParameters['limit'] ?? '10') ?? 10;
  
  return {
    'query': query,
    'page': page,
    'limit': limit,
  };
});
```

## Request Body

### Raw Body

Get the raw request body as bytes:

```dart
route.post('/upload').handle((context) async {
  final rawBody = await context.rawBody;
  // rawBody is List<Uint8List>
  
  return {'bytes': rawBody.length};
});
```

### String Body

Get the body as a string:

```dart
route.post('/text').handle((context) async {
  final text = await context.body();
  print('Received: $text');
  
  return 'Text received';
});
```

### JSON Parsing

Parse JSON bodies with error handling:

```dart
route.post('/api/users').handle((context) async {
  final result = await context.jsonMap();
  
  switch (result) {
    case BodyParseSuccess(:final value):
      // Successfully parsed JSON
      final name = value['name'] as String?;
      final email = value['email'] as String?;
      
      if (name == null || email == null) {
        context.statusCode = 400;
        return {'error': 'Name and email are required'};
      }
      
      return {'id': 1, 'name': name, 'email': email};
      
    case BodyParseFailure(:final error):
      // Failed to parse JSON
      context.statusCode = 400;
      return {'error': 'Invalid JSON: ${error.toString()}'};
  }
});
```

### JSON Lists

Parse JSON arrays:

```dart
route.post('/api/bulk').handle((context) async {
  final result = await context.jsonList();
  
  if (result case BodyParseSuccess(:final value)) {
    return {
      'count': value.length,
      'items': value,
    };
  }
  
  context.statusCode = 400;
  return {'error': 'Expected JSON array'};
});
```

### Type-safe JSON Parsing

Convert JSON to typed objects:

```dart
class CreateUserDto {
  final String name;
  final String email;
  
  CreateUserDto.fromJson(Map<String, dynamic> json)
    : name = json['name'],
      email = json['email'];
}

route.post('/api/users').handle((context) async {
  final result = await context.parseJsonAs(CreateUserDto.fromJson);
  
  if (result case BodyParseSuccess(:final value)) {
    // value is CreateUserDto
    return {'created': value.name};
  }
  
  context.statusCode = 400;
  return {'error': 'Invalid user data'};
});
```

### Form Data

Handle multipart form data with file uploads:

```dart
route.post('/upload').handle((context) async {
  final result = await context.formData();
  
  if (result case BodyParseSuccess(:final value)) {
    // Access form fields
    final title = value.data['title'];
    
    // Access uploaded files
    for (final file in value.files) {
      print('Uploaded: ${file.path}');
      // Process file...
    }
    
    return {'uploaded': value.files.length};
  }
  
  context.statusCode = 400;
  return {'error': 'Invalid form data'};
});
```

## Response Control

### Status Code

Set the HTTP status code:

```dart
route.get('/api/secret').handle((context) {
  if (!isAuthorized(context)) {
    context.statusCode = 401;
    return {'error': 'Unauthorized'};
  }
  
  context.statusCode = 200; // Default
  return {'secret': 'data'};
});
```

### Response Headers

Set response headers:

```dart
route.get('/api/data').handle((context) {
  // Set content type
  context.responseHeaders.contentType = ContentType.json;
  
  // Set custom headers
  context.responseHeaders.add('X-API-Version', '1.0');
  context.responseHeaders.add('Cache-Control', 'no-cache');
  
  return {'data': 'value'};
});
```

## Route Information

Access information about the matched route:

```dart
route.get('/api/info', extra: {'version': '1.0'}).handle((context) {
  final route = context.route;
  
  return {
    'path': route.path,
    'method': route.method?.name,
    'metadata': route.metadata?.extra,
  };
});
```

## Raw Request Access

For advanced use cases, access the underlying Dart HttpRequest:

```dart
route.get('/advanced').handle((context) {
  final rawRequest = context.rawRequest;
  
  // Access low-level request properties
  final remoteAddress = rawRequest.connectionInfo?.remoteAddress;
  final remotePort = rawRequest.connectionInfo?.remotePort;
  
  return {
    'remote': '${remoteAddress?.address}:$remotePort',
  };
});
```

## Context Extensions

Create custom context classes for type-safe access to additional data:

```dart
class AuthenticatedContext extends RequestContext {
  final User user;
  
  AuthenticatedContext({
    required super.request,
    required super.route,
    required this.user,
  });
}

// Use in before hook
route.get('/profile')
  .before<AuthenticatedContext>((context) async {
    final token = context.requestHeaders.value('authorization');
    final user = await validateToken(token);
    
    return AuthenticatedContext(
      request: context.rawRequest,
      route: context.route,
      user: user,
    );
  })
  .handle((AuthenticatedContext context) {
    return {
      'user': context.user.toJson(),
    };
  });
```

## Best Practices

1. **Always handle parse failures** - JSON/form parsing can fail
2. **Set appropriate status codes** - Don't rely on defaults
3. **Use type-safe parsing** - Convert to DTOs when possible
4. **Validate input early** - Check required fields
5. **Set content types** - Especially for non-JSON responses

## Next Steps

- Learn about [Hooks](/core/hooks/) to process requests
- Explore [Error Handling](/core/error-handling/) for robust apps
- See [Request Handling Guide](/guides/request-handling/) for advanced patterns