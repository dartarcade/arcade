---
title: Basic Routing Guide
description: Practical guide to building routes in Arcade
---

This guide provides practical examples and patterns for implementing routing in your Arcade applications.

## RESTful API Example

Here's a complete example of a RESTful API for managing tasks:

```dart
import 'package:arcade/arcade.dart';

// In-memory storage for demo
final tasks = <String, Map<String, dynamic>>{};
int nextId = 1;

void defineTaskRoutes() {
  route.group<RequestContext>('/api/tasks', defineRoutes: (route) {
    // GET /api/tasks - List all tasks
    route().get('/').handle((context) {
      return {
        'tasks': tasks.values.toList(),
        'count': tasks.length,
      };
    });
    
    // GET /api/tasks/:id - Get single task
    route().get('/:id').handle((context) {
      final taskId = context.pathParameters['id']!;
      final task = tasks[taskId];
      
      if (task == null) {
        throw NotFoundException(message: 'Task not found');
      }
      
      return task;
    });
    
    // POST /api/tasks - Create new task
    route().post('/').handle((context) async {
      final result = await context.jsonMap();
      
      if (result case BodyParseSuccess(:final value)) {
        final id = nextId++.toString();
        final task = {
          'id': id,
          'title': value['title'],
          'completed': false,
          'createdAt': DateTime.now().toIso8601String(),
        };
        
        tasks[id] = task;
        context.statusCode = 201;
        return task;
      }
      
      throw BadRequestException(message: 'Invalid task data');
    });
    
    // PUT /api/tasks/:id - Update task
    route().put('/:id').handle((context) async {
      final taskId = context.pathParameters['id']!;
      final task = tasks[taskId];
      
      if (task == null) {
        throw NotFoundException(message: 'Task not found');
      }
      
      final result = await context.jsonMap();
      
      if (result case BodyParseSuccess(:final value)) {
        task['title'] = value['title'] ?? task['title'];
        task['completed'] = value['completed'] ?? task['completed'];
        task['updatedAt'] = DateTime.now().toIso8601String();
        
        return task;
      }
      
      throw BadRequestException(message: 'Invalid update data');
    });
    
    // DELETE /api/tasks/:id - Delete task
    route().delete('/:id').handle((context) {
      final taskId = context.pathParameters['id']!;
      final task = tasks.remove(taskId);
      
      if (task == null) {
        throw NotFoundException(message: 'Task not found');
      }
      
      context.statusCode = 204;
      return null;
    });
  });
}
```

## Query Parameters and Filtering

Implement search and filtering with query parameters:

```dart
route.get('/api/products').handle((context) {
  final query = context.queryParameters;
  
  // Pagination
  final page = int.tryParse(query['page'] ?? '1') ?? 1;
  final limit = int.tryParse(query['limit'] ?? '10') ?? 10;
  final offset = (page - 1) * limit;
  
  // Filtering
  final category = query['category'];
  final minPrice = double.tryParse(query['minPrice'] ?? '0') ?? 0;
  final maxPrice = double.tryParse(query['maxPrice'] ?? '999999') ?? 999999;
  
  // Sorting
  final sortBy = query['sortBy'] ?? 'name';
  final sortOrder = query['sortOrder'] ?? 'asc';
  
  // Apply filters to your data
  var products = getAllProducts();
  
  if (category != null) {
    products = products.where((p) => p['category'] == category).toList();
  }
  
  products = products.where((p) {
    final price = p['price'] as double;
    return price >= minPrice && price <= maxPrice;
  }).toList();
  
  // Sort
  products.sort((a, b) {
    final aVal = a[sortBy];
    final bVal = b[sortBy];
    final compare = aVal.compareTo(bVal);
    return sortOrder == 'asc' ? compare : -compare;
  });
  
  // Paginate
  final total = products.length;
  products = products.skip(offset).take(limit).toList();
  
  return {
    'products': products,
    'pagination': {
      'page': page,
      'limit': limit,
      'total': total,
      'pages': (total / limit).ceil(),
    },
  };
});
```

## File Upload Routes

Handle file uploads with multipart form data:

```dart
route.post('/api/upload').handle((context) async {
  final result = await context.formData();
  
  if (result case BodyParseSuccess(:final value)) {
    final uploadedFiles = <Map<String, String>>[];
    
    for (final file in value.files) {
      // Move file to permanent location
      final fileName = 'upload_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final permanentPath = 'uploads/$fileName';
      
      await file.rename(permanentPath);
      
      uploadedFiles.add({
        'filename': fileName,
        'path': permanentPath,
        'size': file.lengthSync().toString(),
      });
    }
    
    return {
      'message': 'Files uploaded successfully',
      'files': uploadedFiles,
    };
  }
  
  throw BadRequestException(message: 'No files uploaded');
});

// Serve uploaded files
route.get('/uploads/:filename').handle((context) async {
  final filename = context.pathParameters['filename']!;
  final file = File('uploads/$filename');
  
  if (!await file.exists()) {
    throw NotFoundException(message: 'File not found');
  }
  
  // Set appropriate content type
  final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
  context.responseHeaders.contentType = ContentType.parse(mimeType);
  
  // Stream file to response
  await file.openRead().pipe(context.rawRequest.response);
  throw ResponseSentException();
});
```

## API Versioning

Implement API versioning using route groups:

```dart
void defineVersionedApi() {
  // Version 1
  route.group<RequestContext>('/api/v1', defineRoutes: (route) {
    route().get('/users').handle((context) {
      return {
        'version': 1,
        'users': getUsersV1(),
      };
    });
    
    route().get('/users/:id').handle((context) {
      final user = getUserByIdV1(context.pathParameters['id']!);
      return user;
    });
  });
  
  // Version 2 with breaking changes
  route.group<RequestContext>('/api/v2', defineRoutes: (route) {
    route().get('/users').handle((context) {
      return {
        'version': 2,
        'data': {
          'users': getUsersV2(), // Different structure
          'total': getTotalUsers(),
        },
      };
    });
    
    route().get('/users/:id').handle((context) {
      final user = getUserByIdV2(context.pathParameters['id']!);
      // V2 includes additional fields
      return {
        ...user,
        'profile': getUserProfile(user['id']),
      };
    });
  });
}
```

## Health Check and Status Routes

Implement standard health check endpoints:

```dart
route.get('/health').handle((context) {
  return {
    'status': 'healthy',
    'timestamp': DateTime.now().toIso8601String(),
  };
});

route.get('/health/detailed').handle((context) async {
  final checks = <String, dynamic>{};
  
  // Check database
  try {
    await checkDatabase();
    checks['database'] = {'status': 'up'};
  } catch (e) {
    checks['database'] = {'status': 'down', 'error': e.toString()};
  }
  
  // Check external services
  try {
    await checkExternalApi();
    checks['externalApi'] = {'status': 'up'};
  } catch (e) {
    checks['externalApi'] = {'status': 'down', 'error': e.toString()};
  }
  
  final allHealthy = checks.values.every((c) => c['status'] == 'up');
  
  context.statusCode = allHealthy ? 200 : 503;
  
  return {
    'status': allHealthy ? 'healthy' : 'unhealthy',
    'checks': checks,
    'timestamp': DateTime.now().toIso8601String(),
  };
});
```

## Content Negotiation

Handle different response formats based on Accept header:

```dart
route.get('/api/data').handle((context) {
  final data = {'name': 'Arcade', 'version': '0.3.1'};
  
  final acceptHeader = context.requestHeaders.value('accept') ?? 'application/json';
  
  if (acceptHeader.contains('application/xml')) {
    context.responseHeaders.contentType = ContentType.parse('application/xml');
    return '''
      <?xml version="1.0"?>
      <data>
        <name>${data['name']}</name>
        <version>${data['version']}</version>
      </data>
    ''';
  }
  
  if (acceptHeader.contains('text/plain')) {
    context.responseHeaders.contentType = ContentType.text;
    return 'Name: ${data['name']}\nVersion: ${data['version']}';
  }
  
  // Default to JSON
  context.responseHeaders.contentType = ContentType.json;
  return data;
});
```

## Route Documentation

Document your routes with metadata:

```dart
route.get(
  '/api/users',
  extra: {
    'summary': 'List all users',
    'description': 'Returns a paginated list of users',
    'parameters': {
      'page': 'Page number (default: 1)',
      'limit': 'Items per page (default: 20)',
      'search': 'Search query',
    },
    'responses': {
      '200': 'Success with user list',
      '401': 'Unauthorized',
    },
  },
).handle(listUsers);

// Generate API documentation
route.get('/api/docs').handle((context) {
  final docs = <Map<String, dynamic>>[];
  
  for (final route in routes) {
    if (route.metadata?.extra != null) {
      docs.add({
        'method': route.method?.name,
        'path': route.path,
        ...route.metadata!.extra!,
      });
    }
  }
  
  return {'endpoints': docs};
});
```

## Rate Limiting

Implement basic rate limiting:

```dart
final rateLimits = <String, List<DateTime>>{};

BeforeHookHandler rateLimit({
  required int requests,
  required Duration window,
}) {
  return (context) {
    final clientIp = context.rawRequest.connectionInfo?.remoteAddress.address ?? 'unknown';
    final now = DateTime.now();
    
    // Clean old entries
    rateLimits[clientIp]?.removeWhere((time) {
      return now.difference(time) > window;
    });
    
    // Check limit
    final clientRequests = rateLimits[clientIp] ?? [];
    if (clientRequests.length >= requests) {
      throw ArcadeHttpException(
        statusCode: 429,
        message: 'Too many requests',
      );
    }
    
    // Record request
    clientRequests.add(now);
    rateLimits[clientIp] = clientRequests;
    
    return context;
  };
}

// Usage
route.get('/api/limited')
  .before(rateLimit(requests: 10, window: Duration(minutes: 1)))
  .handle((context) => {'data': 'rate limited'});
```

## Best Practices Summary

1. **Use route groups** for organization and shared functionality
2. **Implement proper HTTP methods** for RESTful design
3. **Handle errors consistently** across all routes
4. **Add metadata** for documentation and tooling
5. **Validate input early** in the request pipeline
6. **Use appropriate status codes** for different scenarios
7. **Version your APIs** when making breaking changes

## Next Steps

- Learn about [Request Handling](/guides/request-handling/) for advanced patterns
- Explore [WebSockets](/guides/websockets/) for real-time features
- See [Dependency Injection](/guides/dependency-injection/) for larger applications