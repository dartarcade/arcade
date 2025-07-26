import 'dart:io';
import 'package:pubspec_parse/pubspec_parse.dart';

class PackageInfo {
  final String name;
  final String version;
  final String path;

  PackageInfo({
    required this.name,
    required this.version,
    required this.path,
  });
}

/// Gets all packages in the workspace
Future<List<PackageInfo>> getWorkspacePackages() async {
  final packages = <PackageInfo>[];
  
  // Read the root pubspec.yaml to find workspace packages
  final rootPubspec = File('pubspec.yaml');
  if (!rootPubspec.existsSync()) {
    throw Exception('Error: pubspec.yaml not found in current directory');
  }
  
  final rootContent = await rootPubspec.readAsString();
  final rootPubspecParsed = Pubspec.parse(rootContent);
  final workspace = rootPubspecParsed.workspace;
  
  if (workspace == null || workspace.isEmpty) {
    throw Exception('Error: No workspace configuration found');
  }
  
  for (final packagePath in workspace) {
    final pubspecPath = '$packagePath/pubspec.yaml';
    final pubspecFile = File(pubspecPath);
    
    if (!pubspecFile.existsSync()) {
      print('Warning: $pubspecPath not found, skipping...');
      continue;
    }
    
    final content = await pubspecFile.readAsString();
    try {
      final pubspec = Pubspec.parse(content);
      packages.add(PackageInfo(
        name: pubspec.name,
        version: pubspec.version?.toString() ?? '0.0.0',
        path: packagePath,
      ));
    } catch (e) {
      print('Warning: Failed to parse $pubspecPath: $e');
    }
  }
  
  return packages;
}

/// Gets all arcade packages with their versions
Future<Map<String, String>> getArcadePackageVersions() async {
  final packages = await getWorkspacePackages();
  final versions = <String, String>{};
  
  for (final package in packages) {
    if (package.name.startsWith('arcade')) {
      versions[package.name] = package.version;
    }
  }
  
  return versions;
}