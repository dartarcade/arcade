import 'dart:io';

import 'package:arcade_cli/utils.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('findPackageConfig', () {
    late Directory tempDir;
    late Directory subDir;

    setUp(() {
      // Create a temporary directory structure for testing
      tempDir = Directory.systemTemp.createTempSync('package_config_test');
      subDir = Directory(path.join(tempDir.path, 'subdir'))..createSync();
    });

    tearDown(() {
      // Clean up temporary directory
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should find package_config.json in current directory', () {
      final dartToolDir = Directory(path.join(tempDir.path, '.dart_tool'))
        ..createSync();
      final packageConfigFile =
          File(path.join(dartToolDir.path, 'package_config.json'))
            ..createSync();

      final result = findPackageConfig(tempDir.path);

      expect(result, equals(packageConfigFile.path));
    });

    test('should find package_config.json in parent directory', () {
      final dartToolDir = Directory(path.join(tempDir.path, '.dart_tool'))
        ..createSync();
      final packageConfigFile =
          File(path.join(dartToolDir.path, 'package_config.json'))
            ..createSync();

      final result = findPackageConfig(subDir.path);

      expect(result, equals(packageConfigFile.path));
    });

    test('should return null if package_config.json not found', () {
      final result = findPackageConfig(tempDir.path);

      expect(result, isNull);
    });

    test('should search recursively up to root', () {
      final deepDir = Directory(
        path.join(tempDir.path, 'a', 'b', 'c'),
      )..createSync(recursive: true);

      final dartToolDir = Directory(path.join(tempDir.path, '.dart_tool'))
        ..createSync();
      final packageConfigFile =
          File(path.join(dartToolDir.path, 'package_config.json'))
            ..createSync();

      final result = findPackageConfig(deepDir.path);

      expect(result, equals(packageConfigFile.path));
    });

    test('should use current directory when no start dir provided', () {
      // This test verifies that findPackageConfig works with no arguments
      // It should find the actual package_config.json in the project
      final result = findPackageConfig();

      // The result should be non-null for a valid Dart project
      expect(result, isNotNull);
      expect(result, endsWith('package_config.json'));
    });
  });
}
