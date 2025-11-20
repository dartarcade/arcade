import 'dart:async';
import 'dart:typed_data';

import 'package:arcade_storage/arcade_storage.dart';
import 'package:minio/io.dart';
import 'package:minio/minio.dart';

typedef MinioConnectionInfo = ({
  String endPoint,
  String accessKey,
  String secretKey,
  bool? useSSL,
  String? region,
});

class MinioStorageManager implements BaseStorageManager<MinioConnectionInfo> {
  late Minio _minio;

  @override
  Future<void> init(MinioConnectionInfo connectionInfo) async {
    final (:endPoint, :accessKey, :secretKey, :useSSL, :region) =
        connectionInfo;

    final uri = Uri.parse(
      endPoint.contains('://') ? endPoint : 'http://$endPoint',
    );

    _minio = Minio(
      endPoint: uri.host.isEmpty ? uri.path : uri.host,
      port: uri.hasPort ? uri.port : null,
      accessKey: accessKey,
      secretKey: secretKey,
      useSSL: useSSL ?? false,
      region: region,
    );
  }

  @override
  Future<void> dispose() async {
    // MinIO client doesn't require explicit disposal
  }

  @override
  Future<void> createBucket(String bucketName) async {
    await _minio.makeBucket(bucketName);
  }

  @override
  Future<bool> bucketExists(String bucketName) async {
    return await _minio.bucketExists(bucketName);
  }

  @override
  Future<List<BucketInfo>> listBuckets() async {
    final buckets = await _minio.listBuckets();
    return buckets.map((bucket) {
      return BucketInfo(
        name: bucket.name,
        creationDate: bucket.creationDate,
      );
    }).toList();
  }

  @override
  Future<void> deleteBucket(String bucketName) async {
    await _minio.removeBucket(bucketName);
  }

  @override
  Future<void> putObject(
    String bucket,
    String objectName,
    Stream<List<int>> data, {
    int? length,
  }) async {
    final uint8ListStream = data.map((chunk) => Uint8List.fromList(chunk));
    await _minio.putObject(
      bucket,
      objectName,
      uint8ListStream,
      size: length,
    );
  }

  @override
  Future<Stream<List<int>>> getObject(String bucket, String objectName) async {
    final stream = await _minio.getObject(bucket, objectName);
    return stream;
  }

  @override
  Future<void> deleteObject(String bucket, String objectName) async {
    await _minio.removeObject(bucket, objectName);
  }

  @override
  Future<void> deleteObjects(String bucket, List<String> objectNames) async {
    await _minio.removeObjects(bucket, objectNames);
  }

  @override
  Future<ObjectMetadata> statObject(String bucket, String objectName) async {
    final stat = await _minio.statObject(bucket, objectName);
    final contentType =
        stat.metaData?['Content-Type'] ?? stat.metaData?['content-type'];
    return ObjectMetadata(
      size: stat.size ?? 0,
      etag: stat.etag,
      lastModified: stat.lastModified,
      contentType: contentType,
      metaData: stat.metaData,
    );
  }

  @override
  Future<List<ObjectInfo>> listObjects(
    String bucket, {
    String? prefix,
  }) async {
    final results = _minio.listObjects(
      bucket,
      prefix: prefix ?? '',
    );
    final allObjects = <ObjectInfo>[];
    await for (final result in results) {
      for (final object in result.objects) {
        allObjects.add(
          ObjectInfo(
            name: object.key ?? '',
            size: object.size ?? 0,
            lastModified: object.lastModified,
            etag: object.eTag,
          ),
        );
      }
    }
    return allObjects;
  }

  @override
  Future<void> copyObject(
    String bucket,
    String source,
    String destination,
  ) async {
    await _minio.copyObject(
      bucket,
      destination,
      '$bucket/$source',
    );
  }

  @override
  Future<void> fPutObject(
    String bucket,
    String objectName,
    String filePath,
  ) async {
    await _minio.fPutObject(bucket, objectName, filePath);
  }

  @override
  Future<void> fGetObject(
    String bucket,
    String objectName,
    String filePath,
  ) async {
    await _minio.fGetObject(bucket, objectName, filePath);
  }
}
