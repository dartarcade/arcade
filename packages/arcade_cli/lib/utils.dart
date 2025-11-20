import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

Future<String> getPubspecContents() {
  final file = File('pubspec.yaml');
  if (!file.existsSync()) {
    throw StateError('pubspec.yaml does not exist');
  }
  return file.readAsString();
}

Future<String> getAppName() async {
  final pubspecContents = await getPubspecContents();
  final yaml = loadYaml(pubspecContents) as Map;
  final name = yaml['name'];
  if (name is! String) {
    throw StateError('Invalid name property in pubspec.yaml');
  }
  return name;
}

Future<File> getServerFile() async {
  final appName = await getAppName();
  final path = join('bin', '$appName.dart');
  final file = File(path);
  if (!file.existsSync()) {
    throw StateError(
      'Server file does not exist. Please create a bin/$appName.dart file.',
    );
  }
  return file;
}

/// Finds the package_config.json file by recursively searching parent
/// directories. This supports Dart workspaces where the package_config.json
/// may be in a parent directory.
///
/// Returns the path to the package_config.json file, or null if not found.
String? findPackageConfig([String? startDir]) {
  var dir = Directory(startDir ?? Directory.current.path);

  // Search up to the root directory
  while (true) {
    final packageConfigPath = join(
      dir.path,
      '.dart_tool',
      'package_config.json',
    );
    final packageConfigFile = File(packageConfigPath);

    if (packageConfigFile.existsSync()) {
      return packageConfigPath;
    }

    // Check if we've reached the root directory
    final parent = dir.parent;
    if (parent.path == dir.path) {
      // We've reached the root
      return null;
    }

    dir = parent;
  }
}
