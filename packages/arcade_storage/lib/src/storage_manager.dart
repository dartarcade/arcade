import 'dart:async';

import 'package:arcade_storage/src/bucket_info.dart';
import 'package:arcade_storage/src/object_info.dart';
import 'package:arcade_storage/src/object_metadata.dart';

abstract interface class BaseStorageManager<C> {
  /// Initializes the storage connection. E.g. connects to the storage service.
  Future<void> init(C connectionInfo);

  /// Disposes the storage connection. E.g. closes the connection.
  Future<void> dispose();

  /// Creates a bucket with the given name.
  Future<void> createBucket(String bucketName);

  /// Checks if a bucket exists.
  Future<bool> bucketExists(String bucketName);

  /// Lists all buckets.
  Future<List<BucketInfo>> listBuckets();

  /// Deletes a bucket.
  Future<void> deleteBucket(String bucketName);

  /// Uploads an object from a stream.
  ///
  /// [bucket] is the bucket name.
  /// [objectName] is the object name/key.
  /// [data] is the stream of bytes to upload.
  /// [length] is the optional content length in bytes.
  Future<void> putObject(
    String bucket,
    String objectName,
    Stream<List<int>> data, {
    int? length,
  });

  /// Downloads an object as a stream.
  ///
  /// [bucket] is the bucket name.
  /// [objectName] is the object name/key.
  /// Returns a stream of bytes.
  Future<Stream<List<int>>> getObject(String bucket, String objectName);

  /// Deletes an object.
  Future<void> deleteObject(String bucket, String objectName);

  /// Deletes multiple objects.
  Future<void> deleteObjects(String bucket, List<String> objectNames);

  /// Gets metadata about an object.
  Future<ObjectMetadata> statObject(String bucket, String objectName);

  /// Lists objects in a bucket.
  ///
  /// [bucket] is the bucket name.
  /// [prefix] is an optional prefix to filter objects.
  Future<List<ObjectInfo>> listObjects(
    String bucket, {
    String? prefix,
  });

  /// Copies an object from source to destination within the same bucket.
  Future<void> copyObject(
    String bucket,
    String source,
    String destination,
  );

  /// Uploads an object from a file path.
  Future<void> fPutObject(
    String bucket,
    String objectName,
    String filePath,
  );

  /// Downloads an object to a file path.
  Future<void> fGetObject(
    String bucket,
    String objectName,
    String filePath,
  );
}
