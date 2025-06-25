---
title: Request Handling Guide
description: Advanced patterns for handling requests in Arcade
---

This guide covers advanced patterns and best practices for handling various types of requests in your Arcade applications.

## JSON Request Validation

Create reusable validation patterns for JSON requests:

```dart
// Define DTOs with validation
class CreateUserDto {
  final String email;
  final String name;
  final int? age;
  
  CreateUserDto({
    required this.email,
    required this.name,
    this.age,
  });
  
  factory CreateUserDto.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    final email = json['email'] as String?;
    if (email == null || email.isEmpty) {
      throw BadRequestException(message: 'Email is required');
    }
    
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      throw BadRequestException(message: 'Invalid email format');
    }
    
    final name = json['name'] as String?;
    if (name == null || name.isEmpty) {
      throw BadRequestException(message: 'Name is required');
    }
    
    final age = json['age'] as int?;
    if (age != null && (age < 0 || age > 150)) {
      throw BadRequestException(message: 'Invalid age');
    }
    
    return CreateUserDto(
      email: email,
      name: name,
      age: age,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'email': email,
    'name': name,
    if (age != null) 'age': age,
  };
}

// Use in route handler
route.post('/api/users').handle((context) async {
  final result = await context.parseJsonAs(CreateUserDto.fromJson);
  
  switch (result) {
    case BodyParseSuccess(:final value):
      // value is now typed as CreateUserDto
      final user = await createUser(value);
      context.statusCode = 201;
      return user.toJson();
      
    case BodyParseFailure(:final error):
      // Error is already a BadRequestException with message
      throw error;
  }
});
```

## Request Streaming

Handle large file uploads with streaming:

```dart
route.post('/api/upload/stream').handle((context) async {
  final contentLength = context.requestHeaders.contentLength ?? 0;
  
  if (contentLength > 100 * 1024 * 1024) { // 100MB limit
    throw BadRequestException(message: 'File too large');
  }
  
  final filename = 'upload_${DateTime.now().millisecondsSinceEpoch}.bin';
  final file = File('uploads/$filename');
  await file.create(recursive: true);
  
  final sink = file.openWrite();
  var bytesReceived = 0;
  
  try {
    await for (final chunk in context.rawRequest) {
      bytesReceived += chunk.length;
      sink.add(chunk);
      
      // Progress tracking
      final progress = (bytesReceived / contentLength * 100).round();
      print('Upload progress: $progress%');
    }
    
    await sink.close();
    
    return {
      'filename': filename,
      'size': bytesReceived,
      'path': '/uploads/$filename',
    };
  } catch (e) {
    await sink.close();
    await file.delete();
    throw InternalServerErrorException(message: 'Upload failed');
  }
});
```

## Custom Body Parsers

Create custom body parsers for specific content types:

```dart
// CSV parser example
Future<List<Map<String, String>>> parseCsv(RequestContext context) async {
  final body = await context.body();
  final lines = body.split('\n').where((line) => line.isNotEmpty).toList();
  
  if (lines.isEmpty) {
    return [];
  }
  
  final headers = lines.first.split(',').map((h) => h.trim()).toList();
  final data = <Map<String, String>>[];
  
  for (var i = 1; i < lines.length; i++) {
    final values = lines[i].split(',').map((v) => v.trim()).toList();
    final row = <String, String>{};
    
    for (var j = 0; j < headers.length && j < values.length; j++) {
      row[headers[j]] = values[j];
    }
    
    data.add(row);
  }
  
  return data;
}

route.post('/api/import/csv').handle((context) async {
  final contentType = context.requestHeaders.contentType;
  
  if (contentType?.mimeType != 'text/csv') {
    throw BadRequestException(message: 'Expected CSV content');
  }
  
  final data = await parseCsv(context);
  
  return {
    'imported': data.length,
    'records': data,
  };
});
```

## Request Transformation Hooks

Create reusable hooks for common transformations:

```dart
// Pagination hook
class PaginatedContext extends RequestContext {
  final int page;
  final int limit;
  final int offset;
  
  PaginatedContext({
    required super.request,
    required super.route,
    required this.page,
    required this.limit,
  }) : offset = (page - 1) * limit;
}

BeforeHookHandler<RequestContext, PaginatedContext> withPagination({
  int defaultLimit = 20,
  int maxLimit = 100,
}) {
  return (context) {
    final page = int.tryParse(context.queryParameters['page'] ?? '1') ?? 1;
    var limit = int.tryParse(context.queryParameters['limit'] ?? '$defaultLimit') ?? defaultLimit;
    
    // Enforce limits
    if (limit > maxLimit) limit = maxLimit;
    if (limit < 1) limit = 1;
    if (page < 1) throw BadRequestException(message: 'Invalid page number');
    
    return PaginatedContext(
      request: context.rawRequest,
      route: context.route,
      page: page,
      limit: limit,
    );
  };
}

// Usage
route.get('/api/products')
  .before(withPagination(defaultLimit: 25))
  .handle((PaginatedContext context) {
    final products = getProducts(
      offset: context.offset,
      limit: context.limit,
    );
    
    return {
      'data': products,
      'pagination': {
        'page': context.page,
        'limit': context.limit,
        'total': getTotalProducts(),
      },
    };
  });
```

## Content Type Negotiation

Handle multiple request/response formats:

```dart
abstract class ResponseFormatter {
  String get contentType;
  String format(dynamic data);
}

class JsonFormatter implements ResponseFormatter {
  @override
  String get contentType => 'application/json';
  
  @override
  String format(dynamic data) => jsonEncode(data);
}

class XmlFormatter implements ResponseFormatter {
  @override
  String get contentType => 'application/xml';
  
  @override
  String format(dynamic data) {
    // Simple XML conversion
    final buffer = StringBuffer('<?xml version="1.0"?>\n<response>\n');
    
    void writeElement(String key, dynamic value, {String indent = '  '}) {
      if (value is Map) {
        buffer.write('$indent<$key>\n');
        value.forEach((k, v) => writeElement(k.toString(), v, indent: '$indent  '));
        buffer.write('$indent</$key>\n');
      } else if (value is List) {
        buffer.write('$indent<$key>\n');
        for (final item in value) {
          writeElement('item', item, indent: '$indent  ');
        }
        buffer.write('$indent</$key>\n');
      } else {
        buffer.write('$indent<$key>$value</$key>\n');
      }
    }
    
    if (data is Map) {
      data.forEach((key, value) => writeElement(key.toString(), value));
    } else {
      writeElement('data', data);
    }
    
    buffer.write('</response>');
    return buffer.toString();
  }
}

// Content negotiation hook
AfterHookHandler negotiateContent() {
  final formatters = {
    'application/json': JsonFormatter(),
    'application/xml': XmlFormatter(),
  };
  
  return (context, result) {
    final accept = context.requestHeaders.value('accept') ?? 'application/json';
    
    // Find matching formatter
    ResponseFormatter? formatter;
    for (final type in accept.split(',')) {
      final mediaType = type.split(';').first.trim();
      formatter = formatters[mediaType];
      if (formatter != null) break;
    }
    
    formatter ??= formatters['application/json']!;
    
    context.responseHeaders.contentType = ContentType.parse(formatter.contentType);
    return (context, formatter.format(result));
  };
}

// Usage
route.get('/api/data')
  .handle((context) => {'message': 'Hello', 'timestamp': DateTime.now().toIso8601String()})
  .after(negotiateContent());
```

## Multipart Form Handling

Advanced multipart form processing:

```dart
class FileUploadValidator {
  final Set<String> allowedExtensions;
  final int maxFileSize;
  
  FileUploadValidator({
    required this.allowedExtensions,
    required this.maxFileSize,
  });
  
  Future<Map<String, dynamic>> validateAndProcess(File file) async {
    final filename = file.path.split('/').last;
    final extension = filename.split('.').last.toLowerCase();
    
    if (!allowedExtensions.contains(extension)) {
      await file.delete();
      throw BadRequestException(
        message: 'File type .$extension not allowed',
      );
    }
    
    final size = await file.length();
    if (size > maxFileSize) {
      await file.delete();
      throw BadRequestException(
        message: 'File size exceeds limit of ${maxFileSize ~/ 1024 / 1024}MB',
      );
    }
    
    // Generate safe filename
    final safeFilename = '${DateTime.now().millisecondsSinceEpoch}_${filename.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';
    final permanentPath = 'uploads/$safeFilename';
    
    await File(permanentPath).parent.create(recursive: true);
    await file.rename(permanentPath);
    
    return {
      'originalName': filename,
      'filename': safeFilename,
      'size': size,
      'extension': extension,
      'path': permanentPath,
    };
  }
}

route.post('/api/upload/images').handle((context) async {
  final validator = FileUploadValidator(
    allowedExtensions: {'jpg', 'jpeg', 'png', 'gif'},
    maxFileSize: 5 * 1024 * 1024, // 5MB
  );
  
  final result = await context.formData();
  
  if (result case BodyParseSuccess(:final value)) {
    final uploadedFiles = <Map<String, dynamic>>[];
    
    for (final file in value.files) {
      try {
        final processed = await validator.validateAndProcess(file);
        uploadedFiles.add(processed);
      } catch (e) {
        // Continue processing other files
        print('Failed to process file: $e');
      }
    }
    
    if (uploadedFiles.isEmpty) {
      throw BadRequestException(message: 'No valid files uploaded');
    }
    
    return {
      'uploaded': uploadedFiles.length,
      'files': uploadedFiles,
    };
  }
  
  throw BadRequestException(message: 'Invalid form data');
});
```

## Request Caching

Implement request caching for expensive operations:

```dart
class RequestCache {
  final Map<String, CacheEntry> _cache = {};
  final Duration ttl;
  
  RequestCache({required this.ttl});
  
  dynamic get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    if (DateTime.now().isAfter(entry.expiry)) {
      _cache.remove(key);
      return null;
    }
    
    return entry.value;
  }
  
  void set(String key, dynamic value) {
    _cache[key] = CacheEntry(
      value: value,
      expiry: DateTime.now().add(ttl),
    );
  }
  
  String generateKey(RequestContext context) {
    final method = context.method.name;
    final path = context.path;
    final query = context.queryParameters.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    return '$method:$path?$query';
  }
}

class CacheEntry {
  final dynamic value;
  final DateTime expiry;
  
  CacheEntry({required this.value, required this.expiry});
}

// Usage
final cache = RequestCache(ttl: Duration(minutes: 5));

route.get('/api/expensive-data')
  .before((context) {
    final cacheKey = cache.generateKey(context);
    final cached = cache.get(cacheKey);
    
    if (cached != null) {
      context.responseHeaders.add('X-Cache', 'HIT');
      throw ResponseSentException(cached);
    }
    
    context.responseHeaders.add('X-Cache', 'MISS');
    return context;
  })
  .handle((context) async {
    final data = await performExpensiveOperation();
    return data;
  })
  .after((context, result) {
    final cacheKey = cache.generateKey(context);
    cache.set(cacheKey, result);
    return (context, result);
  });
```

## Request Logging

Comprehensive request logging:

```dart
class RequestLogger {
  final Logger logger;
  
  RequestLogger(this.logger);
  
  BeforeHookHandler logRequest() {
    return (context) {
      final requestId = Uuid().v4();
      context.extra['requestId'] = requestId;
      context.extra['startTime'] = DateTime.now();
      
      logger.info('Request started', {
        'requestId': requestId,
        'method': context.method.name,
        'path': context.path,
        'query': context.queryParameters,
        'headers': _sanitizeHeaders(context.requestHeaders),
        'ip': context.rawRequest.connectionInfo?.remoteAddress.address,
      });
      
      return context;
    };
  }
  
  AfterHookHandler logResponse() {
    return (context, result) {
      final requestId = context.extra['requestId'];
      final startTime = context.extra['startTime'] as DateTime;
      final duration = DateTime.now().difference(startTime);
      
      logger.info('Request completed', {
        'requestId': requestId,
        'status': context.statusCode,
        'duration': duration.inMilliseconds,
        'responseSize': _estimateSize(result),
      });
      
      return (context, result);
    };
  }
  
  Map<String, String> _sanitizeHeaders(HttpHeaders headers) {
    final sanitized = <String, String>{};
    headers.forEach((name, values) {
      // Don't log sensitive headers
      if (!['authorization', 'cookie'].contains(name.toLowerCase())) {
        sanitized[name] = values.join(', ');
      }
    });
    return sanitized;
  }
  
  int _estimateSize(dynamic result) {
    if (result == null) return 0;
    if (result is String) return result.length;
    if (result is List || result is Map) {
      return jsonEncode(result).length;
    }
    return 0;
  }
}
```

## Best Practices

1. **Validate early** - Check request validity before processing
2. **Use DTOs** - Create data transfer objects for type safety
3. **Handle all content types** - Don't assume JSON
4. **Stream large requests** - Don't load everything into memory
5. **Cache when appropriate** - Reduce server load
6. **Log comprehensively** - But sanitize sensitive data
7. **Set proper timeouts** - Prevent hanging requests

## Next Steps

- Explore [WebSockets](/guides/websockets/) for real-time features
- Learn about [Static Files](/guides/static-files/) serving
- See [Dependency Injection](/guides/dependency-injection/) for complex apps