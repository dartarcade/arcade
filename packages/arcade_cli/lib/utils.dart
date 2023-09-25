import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

Future<String> getPubspecContents() async {
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
