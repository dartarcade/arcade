---
title: Arcade Storage
description: Storage abstraction for object storage in Arcade applications
---

The `arcade_storage` package provides a flexible storage abstraction for Arcade applications, allowing you to implement various object storage backends with a consistent API. It defines the standard interface that all storage implementations must follow.

## Installation

Add `arcade_storage` to your `pubspec.yaml`:

```yaml
dependencies:
  arcade_storage: ^<latest-version>
```

## Core Concepts

### BaseStorageManager

The `BaseStorageManager<C>` abstract interface defines the standard interface that all storage implementations must follow:

```dart
abstract interface class BaseStorageManager<C> {
  // Initialize the storage connection
  Future<void> init(C connectionInfo);

  // Dispose the storage connection
  Future<void> dispose();

  // Bucket operations
  Future<void> createBucket(String bucketName);
  Future<bool> bucketExists(String bucketName);
  Future<List<BucketInfo>> listBuckets();
  Future<void> deleteBucket(String bucketName);

  // Object operations
  Future<void> putObject(
    String bucket,
    String objectName,
    Stream<List<int>> data, {
    int? length,
  });
  Future<Stream<List<int>>> getObject(String bucket, String objectName);
  Future<void> deleteObject(String bucket, String objectName);
  Future<void> deleteObjects(String bucket, List<String> objectNames);
  Future<ObjectMetadata> statObject(String bucket, String objectName);
  Future<List<ObjectInfo>> listObjects(String bucket, {String? prefix});

  // Copy and file operations
  Future<void> copyObject(String bucket, String source, String destination);
  Future<void> fPutObject(String bucket, String objectName, String filePath);
  Future<void> fGetObject(String bucket, String objectName, String filePath);
}
```

### Data Models

The package defines several data models:

#### BucketInfo

```dart
class BucketInfo {
  final String name;
  final DateTime? creationDate;
}
```

#### ObjectInfo

```dart
class ObjectInfo {
  final String name;
  final int size;
  final DateTime? lastModified;
  final String? etag;
}
```

#### ObjectMetadata

```dart
class ObjectMetadata {
  final int size;
  final String? etag;
  final DateTime? lastModified;
  final String? contentType;
  final Map<String, String?>? metaData;
}
```

## Quick Start

### Basic Usage

```dart
import 'package:arcade_storage/arcade_storage.dart';

// Use any BaseStorageManager implementation
void main() async {
  final storage = MinioStorageManager(); // or any other implementation

  await storage.init(connectionInfo);

  // Create a bucket
  if (!await storage.bucketExists('my-bucket')) {
    await storage.createBucket('my-bucket');
  }

  // Upload an object
  final dataStream = Stream.value('Hello, Storage!'.codeUnits);
  await storage.putObject(
    'my-bucket',
    'my-object.txt',
    dataStream,
    length: 'Hello, Storage!'.length,
  );

  // Download an object
  final downloadStream = await storage.getObject('my-bucket', 'my-object.txt');
  final chunks = await downloadStream.toList();
  final content = String.fromCharCodes(chunks.expand((chunk) => chunk));

  // Get object metadata
  final metadata = await storage.statObject('my-bucket', 'my-object.txt');
  print('Size: ${metadata.size}');
  print('Content-Type: ${metadata.contentType}');

  // List objects
  final objects = await storage.listObjects('my-bucket', prefix: 'my-');

  // Delete object
  await storage.deleteObject('my-bucket', 'my-object.txt');

  // Clean up
  await storage.dispose();
}
```

## Implementing Your Own Storage Backend

To create a custom storage implementation, implement the `BaseStorageManager` interface:

```dart
class MyCustomStorageManager implements BaseStorageManager<MyConnectionInfo> {
  @override
  Future<void> init(MyConnectionInfo connectionInfo) async {
    // Initialize your storage connection
  }

  @override
  Future<void> dispose() async {
    // Clean up resources
  }

  @override
  Future<void> createBucket(String bucketName) async {
    // Implement bucket creation
  }

  // Implement all other required methods...
}
```

## Integration with Arcade

### Setup with get_it

```dart
import 'package:arcade/arcade.dart';
import 'package:arcade_storage/arcade_storage.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void main() async {
  // Initialize storage
  final storage = MinioStorageManager();
  await storage.init((
    endPoint: 'localhost:9000',
    accessKey: 'minioadmin',
    secretKey: 'minioadmin',
    useSSL: false,
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

    await for (final file in multipart.files) {
      final fileName = file.filename ?? 'upload-${DateTime.now().millisecondsSinceEpoch}';
      await storage.putObject(
        'uploads',
        fileName,
        file.data,
        length: file.contentLength,
      );
    }

    return {'status': 'uploaded'};
  });
```

### File Download Handler

```dart
route.get('/download/:fileName')
  .handle((context) async {
    final storage = getIt<BaseStorageManager>();
    final fileName = context.pathParameters['fileName']!;

    // Get metadata first
    final metadata = await storage.statObject('uploads', fileName);

    // Set response headers
    context.responseHeaders.set('content-type', metadata.contentType ?? 'application/octet-stream');
    context.responseHeaders.set('content-length', metadata.size.toString());

    // Stream the file
    final stream = await storage.getObject('uploads', fileName);
    return stream;
  });
```

## Available Implementations

- **[Arcade Storage MinIO](/packages/arcade-storage-minio/)** - MinIO/S3 compatible storage implementation

## Best Practices

1. **Connection Management**: Always dispose storage managers when done
2. **Error Handling**: Handle storage errors gracefully
3. **Stream Handling**: For large files, use streams to avoid memory issues
4. **Bucket Naming**: Use consistent naming conventions for buckets
5. **Metadata**: Leverage metadata for content-type detection and validation
6. **Prefix Filtering**: Use prefix filtering when listing large numbers of objects

## Next Steps

- Learn about [Arcade Storage MinIO](/packages/arcade-storage-minio/) implementation
- Explore [File Upload Handling](/guides/request-handling/) patterns
- See [Static Files](/guides/static-files/) for serving files
