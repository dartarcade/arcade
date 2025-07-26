#!/usr/bin/env dart

import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';
import '../lib/workspace_utils.dart';

void main() async {
  print('Updating arcade dependencies across workspace...\n');

  // First, get all package versions
  final packageVersions = await getArcadePackageVersions();
  print('Found arcade packages:');
  packageVersions.forEach((name, version) {
    print('  $name: $version');
  });
  print('');

  // Then update all dependencies
  await updateAllDependencies(packageVersions);

  print(
      '\nDone! Run "dart pub get" in each package to fetch the updated dependencies.');
}

Future<void> updateAllDependencies(Map<String, String> packageVersions) async {
  final packages = await getWorkspacePackages();
  
  for (final package in packages) {
    final pubspecPath = '${package.path}/pubspec.yaml';
    final pubspecFile = File(pubspecPath);
    
    if (!pubspecFile.existsSync()) {
      continue;
    }
    
    print('Updating $pubspecPath...');
    
    final content = await pubspecFile.readAsString();
    final editor = YamlEditor(content);
    
    // Update dependencies
    updateDependencySection(editor, ['dependencies'], packageVersions);
    updateDependencySection(editor, ['dev_dependencies'], packageVersions);
    
    // Write back the updated content
    await pubspecFile.writeAsString(editor.toString());
  }
}

void updateDependencySection(
  YamlEditor editor,
  List<String> path,
  Map<String, String> packageVersions,
) {
  try {
    final deps = editor.parseAt(path);

    // Handle YamlMap
    if (deps is YamlMap) {
      for (final entry in deps.entries) {
        final depName = entry.key.toString();
        if (depName.startsWith('arcade') &&
            packageVersions.containsKey(depName)) {
          final newVersion = '^${packageVersions[depName]}';
          final currentValue = entry.value;

          // Handle different dependency formats
          if (currentValue is String) {
            // Simple version string
            editor.update([...path, depName], newVersion);
            print('  Updated $depName to $newVersion');
          } else if (currentValue is YamlMap) {
            // Complex dependency with path, git, etc.
            // Only update if it has a version field
            if (currentValue.containsKey('version')) {
              editor.update([...path, depName, 'version'], newVersion);
              print('  Updated $depName to $newVersion');
            }
          }
        }
      }
    }
  } catch (e) {
    // Section might not exist, that's okay
  }
}