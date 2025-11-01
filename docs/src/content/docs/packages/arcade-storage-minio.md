---
title: Arcade Storage MinIO
description: MinIO/S3 storage implementation for Arcade applications
---

The `arcade_storage_minio` package provides a MinIO/S3-compatible implementation of the Arcade Storage interface, enabling object storage capabilities in your Arcade applications.

## Installation

Add `arcade_storage_minio` to your `pubspec.yaml`:

```yaml
dependencies:
  arcade_storage_minio: ^<latest-version>
  arcade_storage: ^<latest-version>
```

## Features

- **S3 Compatible**: Works with MinIO and any S3-compatible storage service
- **Stream Support**: Efficient handling of large files using streams
- **Full API Coverage**: Implements all BaseStorageManager methods
- **Metadata Support**: Complete object metadata retrieval
- **Robust Endpoint Parsing**: Handles various endpoint formats using `Uri.parse`
- **Secure Connections**: Support for SSL/TLS connections
- **Region Support**: Configurable regions for AWS S3

## Quick Start

```dart
import 'package:arcade_storage_minio/arcade_storage_minio.dart';

void main() async {
  // Create MinIO storage instance
  final storage = MinioStorageManager();

  // Initialize with connection info
  await storage.init((
    endPoint: 'localhost:9000',
    accessKey: 'minioadmin',
    secretKey: 'minioadmin',
    useSSL: false,
  ));

  // Create a bucket
  if (!await storage.bucketExists('my-bucket')) {
    await storage.createBucket('my-bucket');
  }

  // Upload an object
  final dataStream = Stream.value('Hello, MinIO!'.codeUnits);
  await storage.putObject(
    'my-bucket',
    'my-object.txt',
    dataStream,
    length: 'Hello, MinIO!'.length,
  );

  // Download an object
  final downloadStream = await storage.getObject('my-bucket', 'my-object.txt');
  final chunks = await downloadStream.toList();
  final content = String.fromCharCodes(chunks.expand((chunk) => chunk));
  print(content); // Hello, MinIO!

  // Get object metadata
  final metadata = await storage.statObject('my-bucket', 'my-object.txt');
  print('Size: ${metadata.size}');
  print('ETag: ${metadata.etag}');
  print('Content-Type: ${metadata.contentType}');

  // Clean up
  await storage.dispose();
}
```

## Configuration

### Basic Configuration (MinIO)

```dart
final storage = MinioStorageManager();
await storage.init((
  endPoint: 'localhost:9000',
  accessKey: 'minioadmin',
  secretKey: 'minioadmin',
  useSSL: false,
));
```

### SSL/TLS Configuration

```dart
final storage = MinioStorageManager();
await storage.init((
  endPoint: 's3.example.com',
  accessKey: 'your-access-key',
  secretKey: 'your-secret-key',
  useSSL: true,
));
```

### AWS S3 Configuration

```dart
final storage = MinioStorageManager();
await storage.init((
  endPoint: 's3.amazonaws.com',
  accessKey: Platform.environment['AWS_ACCESS_KEY_ID']!,
  secretKey: Platform.environment['AWS_SECRET_ACCESS_KEY']!,
  useSSL: true,
  region: 'us-east-1',
));
```

### Endpoint Formats

The implementation supports various endpoint formats:

```dart
// Host and port
endPoint: 'localhost:9000'

// Full URL
endPoint: 'https://s3.example.com'

// URL with path
endPoint: 'https://storage.example.com:9000'
```

## Integration with Arcade

### Setup with get_it

```dart
import 'package:arcade/arcade.dart';
import 'package:arcade_storage/arcade_storage.dart';
import 'package:arcade_storage_minio/arcade_storage_minio.dart';
import 'package:get_it/get_it.dart';
import 'dart:io';

final getIt = GetIt.instance;

void main() async {
  // Initialize MinIO storage
  final storage = MinioStorageManager();
  await storage.init((
    endPoint: Platform.environment['MINIO_ENDPOINT'] ?? 'localhost:9000',
    accessKey: Platform.environment['MINIO_ACCESS_KEY'] ?? 'minioadmin',
    secretKey: Platform.environment['MINIO_SECRET_KEY'] ?? 'minioadmin',
    useSSL: Platform.environment['MINIO_USE_SSL'] == 'true',
  ));

  // Register with get_it
  getIt.registerSingleton<BaseStorageManager>(storage);

  await runServer(
    port: 3000,
    init: () {
      // Your routes can now use getIt<BaseStorageManager>()
    },
  );
}
```

### File Upload Handler

```dart
route.post('/upload')
  .handle((context) async {
    final storage = getIt<BaseStorageManager>();
    final multipart = await context.multipart();

    final uploads = <String>[];

    await for (final file in multipart.files) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}-${file.filename ?? 'file'}';

      await storage.putObject(
        'uploads',
        fileName,
        file.data,
        length: file.contentLength,
      );

      uploads.add(fileName);
    }

    return {'uploaded': uploads};
  });
```

### File Download Handler

```dart
route.get('/files/:fileName')
  .handle((context) async {
    final storage = getIt<BaseStorageManager>();
    final fileName = context.pathParameters['fileName']!;

    // Check if object exists
    if (!await storage.bucketExists('uploads')) {
      throw NotFoundException('Bucket not found');
    }

    // Get metadata
    try {
      final metadata = await storage.statObject('uploads', fileName);

      // Set response headers
      context.responseHeaders.set('content-type', metadata.contentType ?? 'application/octet-stream');
      context.responseHeaders.set('content-length', metadata.size.toString());
      context.responseHeaders.set('etag', metadata.etag ?? '');

      // Stream the file
      final stream = await storage.getObject('uploads', fileName);
      return stream;
    } catch (e) {
      throw NotFoundException('File not found');
    }
  });
```

### Image Serving

```dart
route.get('/images/:imageName')
  .handle((context) async {
    final storage = getIt<BaseStorageManager>();
    final imageName = context.pathParameters['imageName']!;

    final metadata = await storage.statObject('images', imageName);

    context.responseHeaders.set('content-type', metadata.contentType ?? 'image/jpeg');
    context.responseHeaders.set('cache-control', 'public, max-age=31536000');

    return await storage.getObject('images', imageName);
  });
```

## Advanced Usage

### Copying Objects

```dart
// Copy an object within the same bucket
await storage.copyObject('my-bucket', 'source.txt', 'destination.txt');

// This creates a copy at 'destination.txt' while keeping the original
```

### Batch Operations

```dart
class StorageBatchOperations {
  final BaseStorageManager storage;

  StorageBatchOperations(this.storage);

  Future<void> uploadMultipleFiles(String bucket, Map<String, Stream<List<int>>> files) async {
    await Future.wait(files.entries.map((entry) =>
      storage.putObject(bucket, entry.key, entry.value)
    ));
  }

  Future<void> deleteMultipleFiles(String bucket, List<String> objectNames) async {
    await storage.deleteObjects(bucket, objectNames);
  }

  Future<Map<String, ObjectMetadata>> getMultipleMetadata(
    String bucket,
    List<String> objectNames,
  ) async {
    final results = <String, ObjectMetadata>{};

    await Future.wait(objectNames.map((name) async {
      try {
        final metadata = await storage.statObject(bucket, name);
        results[name] = metadata;
      } catch (e) {
        // Handle missing objects
      }
    }));

    return results;
  }
}
```

### File System Operations

```dart
// Upload from file system
await storage.fPutObject('my-bucket', 'remote-file.txt', '/local/path/to/file.txt');

// Download to file system
await storage.fGetObject('my-bucket', 'remote-file.txt', '/local/path/to/download.txt');
```

### Listing with Prefix

```dart
// List all objects in a bucket
final allObjects = await storage.listObjects('my-bucket');

// List objects with a prefix
final images = await storage.listObjects('my-bucket', prefix: 'images/');
final thumbnails = await storage.listObjects('my-bucket', prefix: 'images/thumbnails/');
```

### Metadata Usage

```dart
final metadata = await storage.statObject('my-bucket', 'document.pdf');

print('Size: ${metadata.size} bytes');
print('ETag: ${metadata.etag}');
print('Last Modified: ${metadata.lastModified}');
print('Content-Type: ${metadata.contentType}');

// Access custom metadata
if (metadata.metaData != null) {
  final customValue = metadata.metaData!['custom-header'];
  print('Custom Header: $customValue');
}
```

## Docker Setup

Add MinIO to your `docker-compose.yml`:

```yaml
services:
  minio:
    image: minio/minio:latest
    restart: unless-stopped
    ports:
      - '9000:9000'
      - '9001:9001'
    volumes:
      - minio_data:/data
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    command: server /data --console-address ":9001"
    healthcheck:
      test: ['CMD', 'curl', '-f', 'http://localhost:9000/minio/health/live']
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  minio_data:
```

Start MinIO:

```bash
docker-compose up -d minio
```

Access MinIO Console at `http://localhost:9001` (default credentials: minioadmin/minioadmin)

## Best Practices

1. **Connection Pooling**: Reuse storage manager instances rather than creating new ones
2. **Stream Handling**: Use streams for large files to avoid memory issues
3. **Error Handling**: Always handle storage errors gracefully
4. **Bucket Organization**: Use meaningful bucket names and organize objects with prefixes
5. **Metadata**: Leverage metadata for content-type detection
6. **Security**: Use secure connections (SSL/TLS) in production
7. **Environment Variables**: Store credentials in environment variables

## Migration from Direct MinIO Client

If you're using the MinIO client directly, migrating to `MinioStorageManager` is straightforward:

```dart
// Before
final minio = Minio(
  endPoint: 'localhost',
  port: 9000,
  accessKey: 'minioadmin',
  secretKey: 'minioadmin',
);
await minio.putObject('bucket', 'object', stream, size: length);

// After
final storage = MinioStorageManager();
await storage.init((
  endPoint: 'localhost:9000',
  accessKey: 'minioadmin',
  secretKey: 'minioadmin',
));
await storage.putObject('bucket', 'object', stream, length: length);

// All other operations follow the same pattern!
```

## Troubleshooting

### Connection Issues

```dart
try {
  await storage.init((
    endPoint: 'localhost:9000',
    accessKey: 'minioadmin',
    secretKey: 'minioadmin',
    useSSL: false,
  ));
} catch (e) {
  print('MinIO connection failed: $e');
  // Handle connection failure
}
```

### Endpoint Parsing

The implementation handles various endpoint formats automatically:

- `localhost:9000` → parsed correctly
- `http://localhost:9000` → parsed correctly
- `https://s3.example.com` → parsed correctly with SSL

## Next Steps

- Learn about [Arcade Storage](/packages/arcade-storage/) base functionality
- Explore [File Upload Handling](/guides/request-handling/) patterns
- See [Static Files](/guides/static-files/) for serving files
