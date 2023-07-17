import 'dart:io';

import 'package:dartseid_config/dartseid_config.dart';
import 'package:mustache_template/mustache_template.dart';
import 'package:path/path.dart';

String view(String name, [Map<String, dynamic>? data]) {
  final template = _partialResolver(name);
  return template.renderString(data ?? {});
}

Template _partialResolver(String name, [Directory? currentDirectory]) {
  print(name);
  final viewsDirectory = name.startsWith('/')
      ? DartseidConfiguration.viewsDirectory
      : currentDirectory ?? DartseidConfiguration.viewsDirectory;
  final viewsDirectoryExists = viewsDirectory.existsSync();
  if (!viewsDirectoryExists) {
    throw Exception('Views directory does not exist.');
  }
  final extension = DartseidConfiguration.viewsExtension;
  final pathSegments = name.split('/')
    ..removeWhere((segment) => segment.isEmpty);
  final fileName = pathSegments.last;
  pathSegments.removeLast();

  final file = File(
    joinAll([viewsDirectory.path, ...pathSegments, '$fileName$extension']),
  );
  final fileExists = file.existsSync();
  if (!fileExists) {
    throw Exception('View file does not exist.');
  }
  final content = file.readAsStringSync();
  return Template(
    content,
    lenient: true,
    partialResolver: (name) => _partialResolver(name, file.parent),
  );
}
