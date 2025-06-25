---
title: Static Files Guide
description: Serving static files and assets with Arcade
---

Arcade provides built-in support for serving static files, making it easy to serve images, CSS, JavaScript, and other assets alongside your API routes.

## Basic Static File Serving

By default, Arcade serves static files from the `public` directory in your project root:

```
my-app/
├── bin/
│   └── server.dart
├── public/           # Static files directory
│   ├── index.html
│   ├── style.css
│   └── script.js
└── pubspec.yaml
```

Files in the `public` directory are automatically served at their respective paths:
- `public/index.html` → `http://localhost:3000/index.html`
- `public/style.css` → `http://localhost:3000/style.css`
- `public/images/logo.png` → `http://localhost:3000/images/logo.png`

## Configuration

Configure static file serving using `ArcadeConfiguration`:

```dart
import 'package:arcade/arcade.dart';
import 'package:arcade_config/arcade_config.dart';

void main() async {
  // Configure before starting server
  ArcadeConfiguration.override(
    staticFilesDirectory: Directory('assets'), // Change from 'public' to 'assets'
    staticFilesHeaders: {
      'Cache-Control': 'public, max-age=3600', // 1 hour cache
      'X-Content-Type-Options': 'nosniff',
    },
  );
  
  await runServer(
    port: 3000,
    init: () {
      route.get('/api/hello').handle((context) => 'Hello API');
    },
  );
}
```

## Custom Static File Handler

For more control, implement custom static file handling:

```dart
route.get('/static/*').handle((context) async {
  // Extract the file path from the URL
  final path = context.path.substring('/static/'.length);
  
  // Security: Prevent directory traversal
  if (path.contains('..')) {
    throw ForbiddenException();
  }
  
  final file = File('custom-static-dir/$path');
  
  if (!await file.exists()) {
    throw NotFoundException();
  }
  
  // Set content type based on file extension
  final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
  context.responseHeaders.contentType = ContentType.parse(mimeType);
  
  // Set caching headers
  context.responseHeaders
    ..add('Cache-Control', 'public, max-age=86400') // 24 hours
    ..add('ETag', '"${file.lastModifiedSync().millisecondsSinceEpoch}"');
  
  // Check if-none-match header for caching
  final ifNoneMatch = context.requestHeaders.value('if-none-match');
  final etag = '"${file.lastModifiedSync().millisecondsSinceEpoch}"';
  
  if (ifNoneMatch == etag) {
    context.statusCode = 304; // Not Modified
    return null;
  }
  
  // Stream file to response
  await file.openRead().pipe(context.rawRequest.response);
  throw ResponseSentException();
});
```

## Single Page Application (SPA) Support

Serve SPAs with client-side routing:

```dart
void configureSPA() {
  // API routes first
  route.group<RequestContext>('/api', defineRoutes: (route) {
    route().get('/users').handle((context) => []);
    route().post('/login').handle((context) => {'token': 'xxx'});
  });
  
  // Serve static assets
  route.get('/assets/*').handle((context) async {
    final path = context.path.substring('/assets/'.length);
    final file = File('public/assets/$path');
    
    if (!await file.exists()) {
      throw NotFoundException();
    }
    
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    context.responseHeaders.contentType = ContentType.parse(mimeType);
    
    await file.openRead().pipe(context.rawRequest.response);
    throw ResponseSentException();
  });
  
  // Catch-all route for SPA
  route.any('/*').handle((context) async {
    final indexFile = File('public/index.html');
    
    context.responseHeaders.contentType = ContentType.html;
    
    await indexFile.openRead().pipe(context.rawRequest.response);
    throw ResponseSentException();
  });
}
```

## Asset Preprocessing

Implement asset preprocessing for optimization:

```dart
class AssetProcessor {
  final Map<String, ProcessedAsset> _cache = {};
  
  Future<ProcessedAsset> processAsset(File file) async {
    final path = file.path;
    final lastModified = file.lastModifiedSync();
    
    // Check cache
    final cached = _cache[path];
    if (cached != null && cached.lastModified == lastModified) {
      return cached;
    }
    
    // Process based on file type
    final extension = path.split('.').last.toLowerCase();
    late final ProcessedAsset processed;
    
    switch (extension) {
      case 'css':
        processed = await _processCss(file);
        break;
      case 'js':
        processed = await _processJavaScript(file);
        break;
      case 'png':
      case 'jpg':
      case 'jpeg':
        processed = await _processImage(file);
        break;
      default:
        processed = ProcessedAsset(
          content: await file.readAsBytes(),
          contentType: lookupMimeType(path) ?? 'application/octet-stream',
          lastModified: lastModified,
        );
    }
    
    _cache[path] = processed;
    return processed;
  }
  
  Future<ProcessedAsset> _processCss(File file) async {
    var content = await file.readAsString();
    
    // Minify CSS (simple example)
    content = content
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'/\*.*?\*/'), '')
        .trim();
    
    return ProcessedAsset(
      content: utf8.encode(content),
      contentType: 'text/css',
      lastModified: file.lastModifiedSync(),
    );
  }
  
  Future<ProcessedAsset> _processJavaScript(File file) async {
    var content = await file.readAsString();
    
    // Add source map comment
    content += '\n//# sourceMappingURL=${file.path}.map';
    
    return ProcessedAsset(
      content: utf8.encode(content),
      contentType: 'application/javascript',
      lastModified: file.lastModifiedSync(),
    );
  }
  
  Future<ProcessedAsset> _processImage(File file) async {
    // In a real app, you might resize or optimize images
    return ProcessedAsset(
      content: await file.readAsBytes(),
      contentType: lookupMimeType(file.path) ?? 'image/jpeg',
      lastModified: file.lastModifiedSync(),
    );
  }
}

class ProcessedAsset {
  final List<int> content;
  final String contentType;
  final DateTime lastModified;
  
  ProcessedAsset({
    required this.content,
    required this.contentType,
    required this.lastModified,
  });
}

// Use in route
final assetProcessor = AssetProcessor();

route.get('/optimized/*').handle((context) async {
  final path = context.path.substring('/optimized/'.length);
  final file = File('assets/$path');
  
  if (!await file.exists()) {
    throw NotFoundException();
  }
  
  final processed = await assetProcessor.processAsset(file);
  
  context.responseHeaders
    ..contentType = ContentType.parse(processed.contentType)
    ..contentLength = processed.content.length
    ..add('Last-Modified', HttpDate.format(processed.lastModified));
  
  context.rawRequest.response.add(processed.content);
  await context.rawRequest.response.close();
  throw ResponseSentException();
});
```

## File Upload Directory

Create a dedicated upload directory with proper permissions:

```dart
class UploadManager {
  final String uploadDir;
  final int maxFileSize;
  final Set<String> allowedExtensions;
  
  UploadManager({
    required this.uploadDir,
    required this.maxFileSize,
    required this.allowedExtensions,
  });
  
  Future<void> init() async {
    final dir = Directory(uploadDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }
  
  String generateFilePath(String originalName) {
    final extension = originalName.split('.').last.toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return '$uploadDir/${timestamp}_${random}.$extension';
  }
  
  bool isAllowed(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension);
  }
}

final uploadManager = UploadManager(
  uploadDir: 'uploads',
  maxFileSize: 10 * 1024 * 1024, // 10MB
  allowedExtensions: {'jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'},
);

// Initialize in main
await uploadManager.init();

// Serve uploaded files with access control
route.get('/uploads/:filename')
  .before((context) {
    // Check if user has permission to access file
    final token = context.requestHeaders.value('authorization');
    if (token == null || !isValidToken(token)) {
      throw UnauthorizedException();
    }
    return context;
  })
  .handle((context) async {
    final filename = context.pathParameters['filename']!;
    final file = File('${uploadManager.uploadDir}/$filename');
    
    if (!await file.exists()) {
      throw NotFoundException();
    }
    
    // Set appropriate headers
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    context.responseHeaders
      ..contentType = ContentType.parse(mimeType)
      ..add('Content-Disposition', 'inline; filename="$filename"');
    
    await file.openRead().pipe(context.rawRequest.response);
    throw ResponseSentException();
  });
```

## Compression

Implement response compression for static files:

```dart
import 'dart:io' show gzip;

route.get('/compressed/*').handle((context) async {
  final path = context.path.substring('/compressed/'.length);
  final file = File('public/$path');
  
  if (!await file.exists()) {
    throw NotFoundException();
  }
  
  // Check if client accepts gzip
  final acceptEncoding = context.requestHeaders.value('accept-encoding') ?? '';
  final supportsGzip = acceptEncoding.contains('gzip');
  
  final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
  context.responseHeaders.contentType = ContentType.parse(mimeType);
  
  // Compress text-based files
  final shouldCompress = supportsGzip && 
    ['text/', 'application/javascript', 'application/json'].any(
      (type) => mimeType.startsWith(type)
    );
  
  if (shouldCompress) {
    context.responseHeaders.add('Content-Encoding', 'gzip');
    
    final content = await file.readAsBytes();
    final compressed = gzip.encode(content);
    
    context.responseHeaders.contentLength = compressed.length;
    context.rawRequest.response.add(compressed);
  } else {
    context.responseHeaders.contentLength = await file.length();
    await file.openRead().pipe(context.rawRequest.response);
  }
  
  await context.rawRequest.response.close();
  throw ResponseSentException();
});
```

## Security Headers

Add security headers for static files:

```dart
BeforeHookHandler secureStaticFiles() {
  return (context) {
    // Only apply to static file requests
    if (context.path.startsWith('/static/') || 
        context.path.contains('.')) {
      context.responseHeaders
        ..add('X-Content-Type-Options', 'nosniff')
        ..add('X-Frame-Options', 'SAMEORIGIN')
        ..add('X-XSS-Protection', '1; mode=block')
        ..add('Referrer-Policy', 'strict-origin-when-cross-origin');
      
      // CSP for HTML files
      if (context.path.endsWith('.html')) {
        context.responseHeaders.add(
          'Content-Security-Policy',
          "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'",
        );
      }
    }
    
    return context;
  };
}

// Register globally
route.registerGlobalBeforeHook(secureStaticFiles());
```

## Directory Listing

Create a simple directory listing for development:

```dart
route.get('/browse/*').handle((context) async {
  if (!isDev) {
    throw ForbiddenException();
  }
  
  final path = context.path.substring('/browse/'.length);
  final dir = Directory('public/$path');
  
  if (!await dir.exists()) {
    throw NotFoundException();
  }
  
  final entries = await dir.list().toList();
  final items = <Map<String, dynamic>>[];
  
  for (final entry in entries) {
    final stat = await entry.stat();
    items.add({
      'name': entry.path.split('/').last,
      'type': stat.type.toString(),
      'size': stat.size,
      'modified': stat.modified.toIso8601String(),
    });
  }
  
  context.responseHeaders.contentType = ContentType.html;
  
  return '''
    <!DOCTYPE html>
    <html>
    <head><title>Directory: /$path</title></head>
    <body>
      <h1>Directory: /$path</h1>
      <ul>
        ${items.map((item) => '<li>${item['name']} (${item['type']})</li>').join('\n')}
      </ul>
    </body>
    </html>
  ''';
});
```

## Best Practices

1. **Use a CDN in production** - Serve static files from a CDN for better performance
2. **Set appropriate cache headers** - Reduce server load and improve performance
3. **Compress files** - Use gzip for text-based files
4. **Validate file paths** - Prevent directory traversal attacks
5. **Limit file sizes** - Prevent DoS attacks
6. **Use versioned filenames** - For cache busting (e.g., `style-v1.2.3.css`)
7. **Separate static and dynamic content** - Consider different domains/subdomains

## Next Steps

- Learn about [Dependency Injection](/guides/dependency-injection/) for larger applications
- Explore [Request Handling](/guides/request-handling/) for file uploads
- See [Error Handling](/core/error-handling/) for handling file-related errors