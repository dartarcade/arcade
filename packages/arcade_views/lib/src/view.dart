import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:arcade_config/arcade_config.dart';
import 'package:arcade_logger/arcade_logger.dart';
import 'package:jinja/jinja.dart';
import 'package:jinja/loaders.dart';
import 'package:path/path.dart';

typedef PackageViews = ({String packagePath, String viewsPath});

const logger = Logger('arcade_views');

/// Resolves a package URI to a file system path.
/// First tries Isolate.resolvePackageUriSync, then falls back to reading package_config.json.
Uri? _resolvePackageUri(Uri packageUri) {
  // Try the standard method first
  final uri = Isolate.resolvePackageUriSync(packageUri);
  if (uri != null) return uri;

  // Fallback: read package_config.json directly
  // Walk up from current directory to find .dart_tool/package_config.json
  var dir = Directory.current;
  while (dir.path != dir.parent.path) {
    final configFile = File(join(dir.path, '.dart_tool', 'package_config.json'));
    if (configFile.existsSync()) {
      try {
        final config = jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
        final packages = config['packages'] as List<dynamic>?;
        if (packages != null) {
          final packageName = packageUri.pathSegments.first;
          for (final pkg in packages) {
            if (pkg is Map<String, dynamic> && pkg['name'] == packageName) {
              final rootUri = pkg['rootUri'] as String?;
              final packageUriStr = pkg['packageUri'] as String? ?? 'lib/';
              if (rootUri != null) {
                Uri resolvedRoot;
                if (rootUri.startsWith('file://')) {
                  resolvedRoot = Uri.parse(rootUri);
                } else {
                  // Relative path - resolve relative to package_config.json location
                  resolvedRoot = Uri.file(normalize(join(dir.path, '.dart_tool', rootUri)));
                }
                // Combine root with packageUri (usually 'lib/')
                final libPath = join(resolvedRoot.toFilePath(), packageUriStr);
                return Uri.file(libPath);
              }
            }
          }
        }
      } catch (e) {
        logger.debug('Failed to read package_config.json: $e');
      }
      break;
    }
    dir = dir.parent;
  }
  return null;
}

String view(
  String name, [
  Map<String, dynamic>? data,
  PackageViews? packageViews,
]) {
  const isProd = bool.fromEnvironment('dart.vm.product');
  Directory? packageViewsDirectory;
  if (packageViews != null) {
    final uri = _resolvePackageUri(Uri.parse(packageViews.packagePath));
    if (uri == null) {
      throw StateError('Package path not found: ${packageViews.packagePath}');
    }
    // By default, this will point to lib. We need to go up one level to get the root.
    final dir = Directory.fromUri(uri).parent;
    packageViewsDirectory = Directory(join(dir.path, packageViews.viewsPath));

    if (!packageViewsDirectory.existsSync()) {
      throw StateError(
        'Package views directory not found: ${packageViewsDirectory.path}',
      );
    }
  }

  final paths = [
    if (packageViewsDirectory != null) packageViewsDirectory.path,
    ArcadeConfiguration.viewsDirectory.path,
  ];
  logger.debug('Loading views from: $paths');
  final environment = Environment(
    // ignore: avoid_redundant_argument_values
    autoReload: !isProd,
    loader: FileSystemLoader(
      paths: paths,
    ),
  );
  final templateName = '$name${ArcadeConfiguration.viewsExtension}';
  final template = environment.getTemplate(templateName);
  return template.render(data);
}
