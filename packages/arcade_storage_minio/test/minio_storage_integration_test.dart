import 'dart:async';
import 'dart:io';

import 'package:arcade_storage_minio/arcade_storage_minio.dart';
import 'package:test/test.dart';

void main() {
  group('MinIO Storage Integration Tests', () {
    late MinioStorageManager storage;

    setUpAll(() async {
      try {
        final result = await Process.run('docker', ['ps']);
        if (!result.stdout.toString().contains('minio')) {
          fail(
            'MinIO container is not running. Please run: docker-compose up -d',
          );
        }
      } catch (e) {
        fail('Docker is not available or MinIO is not running: $e');
      }
    });

    setUp(() async {
      storage = MinioStorageManager();
      await storage.init((
        endPoint: 'localhost:9000',
        accessKey: 'minioadmin',
        secretKey: 'minioadmin',
        useSSL: false,
        region: null,
      ));
    });

    tearDown(() async {
      await storage.dispose();
    });

    group('Bucket Operations', () {
      test('init connects to MinIO successfully', () async {
        await storage.createBucket('test-bucket');
        expect(await storage.bucketExists('test-bucket'), isTrue);
        await storage.deleteBucket('test-bucket');
      });

      test('createBucket creates a new bucket', () async {
        await storage.createBucket('new-bucket');
        expect(await storage.bucketExists('new-bucket'), isTrue);
        await storage.deleteBucket('new-bucket');
      });

      test('bucketExists returns false for non-existent bucket', () async {
        expect(await storage.bucketExists('non-existent-bucket'), isFalse);
      });

      test('listBuckets returns all buckets', () async {
        await storage.createBucket('list-bucket-1');
        await storage.createBucket('list-bucket-2');

        final buckets = await storage.listBuckets();
        expect(buckets.length, greaterThanOrEqualTo(2));

        final bucketNames = buckets.map((b) => b.name).toList();
        expect(bucketNames, contains('list-bucket-1'));
        expect(bucketNames, contains('list-bucket-2'));

        await storage.deleteBucket('list-bucket-1');
        await storage.deleteBucket('list-bucket-2');
      });

      test('deleteBucket removes a bucket', () async {
        await storage.createBucket('delete-bucket');
        expect(await storage.bucketExists('delete-bucket'), isTrue);

        await storage.deleteBucket('delete-bucket');
        expect(await storage.bucketExists('delete-bucket'), isFalse);
      });
    });

    group('Object Operations', () {
      const testBucket = 'test-objects';

      setUp(() async {
        if (!await storage.bucketExists(testBucket)) {
          await storage.createBucket(testBucket);
        }
      });

      tearDown(() async {
        final objects = await storage.listObjects(testBucket);
        if (objects.isNotEmpty) {
          final objectNames = objects.map((o) => o.name).toList();
          await storage.deleteObjects(testBucket, objectNames);
        }
      });

      test('putObject and getObject work correctly', () async {
        const testData = 'Hello, MinIO!';
        final dataStream = Stream.value(testData.codeUnits);

        await storage.putObject(
          testBucket,
          'test-object.txt',
          dataStream,
          length: testData.length,
        );

        final stream = await storage.getObject(testBucket, 'test-object.txt');
        final chunks = await stream.toList();
        final retrievedData = String.fromCharCodes(
          chunks.expand((chunk) => chunk),
        );

        expect(retrievedData, equals(testData));
      });

      test('putObject handles large data streams', () async {
        final largeData = 'x' * 100000;
        final dataStream = Stream.value(largeData.codeUnits);

        await storage.putObject(
          testBucket,
          'large-object.txt',
          dataStream,
          length: largeData.length,
        );

        final stream = await storage.getObject(testBucket, 'large-object.txt');
        final chunks = await stream.toList();
        final retrievedData = String.fromCharCodes(
          chunks.expand((chunk) => chunk),
        );

        expect(retrievedData.length, equals(largeData.length));
        expect(retrievedData, equals(largeData));
      });

      test('deleteObject removes an object', () async {
        const testData = 'Test data';
        final dataStream = Stream.value(testData.codeUnits);

        await storage.putObject(
          testBucket,
          'delete-me.txt',
          dataStream,
          length: testData.length,
        );

        final objects = await storage.listObjects(testBucket);
        expect(objects.any((o) => o.name == 'delete-me.txt'), isTrue);

        await storage.deleteObject(testBucket, 'delete-me.txt');

        final objectsAfter = await storage.listObjects(testBucket);
        expect(objectsAfter.any((o) => o.name == 'delete-me.txt'), isFalse);
      });

      test('deleteObjects removes multiple objects', () async {
        const testData = 'Test';
        final dataStream1 = Stream.value(testData.codeUnits);
        final dataStream2 = Stream.value(testData.codeUnits);
        final dataStream3 = Stream.value(testData.codeUnits);

        await storage.putObject(
          testBucket,
          'obj1.txt',
          dataStream1,
          length: testData.length,
        );
        await storage.putObject(
          testBucket,
          'obj2.txt',
          dataStream2,
          length: testData.length,
        );
        await storage.putObject(
          testBucket,
          'obj3.txt',
          dataStream3,
          length: testData.length,
        );

        final objectsBefore = await storage.listObjects(testBucket);
        expect(objectsBefore.length, greaterThanOrEqualTo(3));

        await storage.deleteObjects(
          testBucket,
          ['obj1.txt', 'obj2.txt', 'obj3.txt'],
        );

        final objectsAfter = await storage.listObjects(testBucket);
        expect(objectsAfter.any((o) => o.name == 'obj1.txt'), isFalse);
        expect(objectsAfter.any((o) => o.name == 'obj2.txt'), isFalse);
        expect(objectsAfter.any((o) => o.name == 'obj3.txt'), isFalse);
      });

      test('statObject returns object metadata', () async {
        const testData = 'Metadata test';
        final dataStream = Stream.value(testData.codeUnits);

        await storage.putObject(
          testBucket,
          'metadata-object.txt',
          dataStream,
          length: testData.length,
        );

        final metadata = await storage.statObject(
          testBucket,
          'metadata-object.txt',
        );

        expect(metadata.size, equals(testData.length));
        expect(metadata.etag, isNotNull);
        expect(metadata.lastModified, isNotNull);
      });

      test('statObject returns metadata with metaData field', () async {
        const testData = 'Metadata with custom data';
        final dataStream = Stream.value(testData.codeUnits);

        await storage.putObject(
          testBucket,
          'custom-metadata-object.txt',
          dataStream,
          length: testData.length,
        );

        final metadata = await storage.statObject(
          testBucket,
          'custom-metadata-object.txt',
        );

        expect(metadata.size, equals(testData.length));
        expect(metadata.etag, isNotNull);
        expect(metadata.lastModified, isNotNull);
        expect(metadata.metaData, isNotNull);
        expect(metadata.metaData, isA<Map<String, String?>>());
      });

      test('statObject metadata contains all expected fields', () async {
        const testData = 'Complete metadata test';
        const objectName = 'metadata-complete.json';
        final dataStream = Stream.value(testData.codeUnits);

        await storage.putObject(
          testBucket,
          objectName,
          dataStream,
          length: testData.length,
        );

        final metadata = await storage.statObject(testBucket, objectName);

        expect(metadata.size, equals(testData.length));
        expect(metadata.etag, isNotNull);
        expect(metadata.etag, isNotEmpty);
        expect(metadata.lastModified, isNotNull);
        expect(
          metadata.lastModified!.isBefore(
            DateTime.now().add(const Duration(seconds: 1)),
          ),
          isTrue,
        );
        expect(metadata.metaData, isNotNull);

        final metaDataMap = metadata.metaData!;
        expect(metaDataMap, isA<Map<String, String?>>());
        expect(metaDataMap.isNotEmpty, isTrue);

        if (metadata.contentType != null) {
          expect(metadata.contentType, isNotEmpty);
          final contentTypeFromMeta =
              metaDataMap['Content-Type'] ?? metaDataMap['content-type'];
          expect(contentTypeFromMeta, equals(metadata.contentType));
        }
      });

      test('statObject metadata fields are consistent', () async {
        const testData = 'Consistency test';
        final dataStream = Stream.value(testData.codeUnits);

        await storage.putObject(
          testBucket,
          'consistency-test.txt',
          dataStream,
          length: testData.length,
        );

        final metadata1 = await storage.statObject(
          testBucket,
          'consistency-test.txt',
        );
        final metadata2 = await storage.statObject(
          testBucket,
          'consistency-test.txt',
        );

        expect(metadata1.size, equals(metadata2.size));
        expect(metadata1.etag, equals(metadata2.etag));
        expect(metadata1.lastModified, equals(metadata2.lastModified));
        expect(metadata1.contentType, equals(metadata2.contentType));
        expect(metadata1.metaData, isNotNull);
        expect(metadata2.metaData, isNotNull);
        expect(metadata1.metaData, equals(metadata2.metaData));
      });

      test('listObjects returns all objects in bucket', () async {
        const testData = 'Test';
        final dataStream1 = Stream.value(testData.codeUnits);
        final dataStream2 = Stream.value(testData.codeUnits);
        final dataStream3 = Stream.value(testData.codeUnits);

        await storage.putObject(
          testBucket,
          'list-obj1.txt',
          dataStream1,
          length: testData.length,
        );
        await storage.putObject(
          testBucket,
          'list-obj2.txt',
          dataStream2,
          length: testData.length,
        );
        await storage.putObject(
          testBucket,
          'list-obj3.txt',
          dataStream3,
          length: testData.length,
        );

        final objects = await storage.listObjects(testBucket);
        expect(objects.length, greaterThanOrEqualTo(3));

        final objectNames = objects.map((o) => o.name).toList();
        expect(objectNames, contains('list-obj1.txt'));
        expect(objectNames, contains('list-obj2.txt'));
        expect(objectNames, contains('list-obj3.txt'));
      });

      test('listObjects filters by prefix', () async {
        const testData = 'Test';
        final dataStream1 = Stream.value(testData.codeUnits);
        final dataStream2 = Stream.value(testData.codeUnits);
        final dataStream3 = Stream.value(testData.codeUnits);

        await storage.putObject(
          testBucket,
          'prefix-obj1.txt',
          dataStream1,
          length: testData.length,
        );
        await storage.putObject(
          testBucket,
          'prefix-obj2.txt',
          dataStream2,
          length: testData.length,
        );
        await storage.putObject(
          testBucket,
          'other-obj.txt',
          dataStream3,
          length: testData.length,
        );

        final prefixedObjects = await storage.listObjects(
          testBucket,
          prefix: 'prefix-',
        );

        final prefixedNames = prefixedObjects.map((o) => o.name).toList();
        expect(prefixedNames, contains('prefix-obj1.txt'));
        expect(prefixedNames, contains('prefix-obj2.txt'));
        expect(prefixedNames, isNot(contains('other-obj.txt')));
      });

      test('copyObject copies object within bucket', () async {
        const testData = 'Original content';
        final dataStream = Stream.value(testData.codeUnits);

        await storage.putObject(
          testBucket,
          'source.txt',
          dataStream,
          length: testData.length,
        );

        await storage.copyObject(
          testBucket,
          'source.txt',
          'destination.txt',
        );

        final sourceStream = await storage.getObject(testBucket, 'source.txt');
        final destStream = await storage.getObject(
          testBucket,
          'destination.txt',
        );

        final sourceChunks = await sourceStream.toList();
        final destChunks = await destStream.toList();

        final sourceContent = String.fromCharCodes(
          sourceChunks.expand((chunk) => chunk),
        );
        final destContent = String.fromCharCodes(
          destChunks.expand((chunk) => chunk),
        );

        expect(sourceContent, equals(testData));
        expect(destContent, equals(testData));
        expect(sourceContent, equals(destContent));
      });
    });

    group('File Operations', () {
      const testBucket = 'test-files';

      setUp(() async {
        if (!await storage.bucketExists(testBucket)) {
          await storage.createBucket(testBucket);
        }
      });

      tearDown(() async {
        final objects = await storage.listObjects(testBucket);
        if (objects.isNotEmpty) {
          final objectNames = objects.map((o) => o.name).toList();
          await storage.deleteObjects(testBucket, objectNames);
        }
      });

      test(
        'fPutObject uploads file from filesystem',
        () async {
          final tempFile = File('${Directory.systemTemp.path}/test_upload.txt');
          await tempFile.writeAsString('File content for upload');

          await storage.fPutObject(
            testBucket,
            'uploaded-file.txt',
            tempFile.path,
          );

          final stream = await storage.getObject(
            testBucket,
            'uploaded-file.txt',
          );
          final chunks = await stream.toList();
          final content = String.fromCharCodes(
            chunks.expand((chunk) => chunk),
          );

          expect(content, equals('File content for upload'));

          await tempFile.delete();
        },
        skip: !Platform.isLinux && !Platform.isMacOS && !Platform.isWindows,
      );

      test(
        'fGetObject downloads file to filesystem',
        () async {
          const testData = 'File content for download';
          final dataStream = Stream.value(testData.codeUnits);

          await storage.putObject(
            testBucket,
            'download-source.txt',
            dataStream,
            length: testData.length,
          );

          final tempFile = File(
            '${Directory.systemTemp.path}/test_download.txt',
          );
          await storage.fGetObject(
            testBucket,
            'download-source.txt',
            tempFile.path,
          );

          expect(await tempFile.exists(), isTrue);
          final content = await tempFile.readAsString();
          expect(content, equals(testData));

          await tempFile.delete();
        },
        skip: !Platform.isLinux && !Platform.isMacOS && !Platform.isWindows,
      );
    });

    group('Error Handling', () {
      test('handles non-existent bucket gracefully', () {
        expect(
          () => storage.getObject('non-existent', 'object'),
          throwsA(isA<Exception>()),
        );
      });

      test('handles non-existent object gracefully', () async {
        const testBucket = 'error-test';
        if (!await storage.bucketExists(testBucket)) {
          await storage.createBucket(testBucket);
        }

        expect(
          () => storage.getObject(testBucket, 'non-existent'),
          throwsA(isA<Exception>()),
        );

        await storage.deleteBucket(testBucket);
      });

      test('handles empty bucket name', () {
        expect(
          () => storage.createBucket(''),
          throwsA(isA<Exception>()),
        );
      });

      test('handles special characters in object names', () async {
        const testBucket = 'special-char-test';
        if (!await storage.bucketExists(testBucket)) {
          await storage.createBucket(testBucket);
        }

        const testData = 'Special chars test';
        final dataStream = Stream.value(testData.codeUnits);

        await storage.putObject(
          testBucket,
          'obj with spaces.txt',
          dataStream,
          length: testData.length,
        );

        final objects = await storage.listObjects(testBucket);
        expect(objects.any((o) => o.name == 'obj with spaces.txt'), isTrue);

        await storage.deleteObjects(testBucket, ['obj with spaces.txt']);
        await storage.deleteBucket(testBucket);
      });
    });

    group('Resource Management', () {
      test('dispose works without errors', () async {
        await storage.dispose();
        expect(storage, isNotNull);
      });

      test('multiple init calls handled gracefully', () async {
        await storage.init((
          endPoint: 'localhost:9000',
          accessKey: 'minioadmin',
          secretKey: 'minioadmin',
          useSSL: false,
          region: null,
        ));

        await storage.createBucket('reinit-test');
        expect(await storage.bucketExists('reinit-test'), isTrue);
        await storage.deleteBucket('reinit-test');
      });
    });
  });
}
