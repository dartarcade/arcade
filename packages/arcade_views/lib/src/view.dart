import 'dart:io';
import 'dart:isolate';

import 'package:arcade_config/arcade_config.dart';
import 'package:arcade_logger/arcade_logger.dart';
import 'package:jinja/jinja.dart';
import 'package:jinja/loaders.dart';
import 'package:path/path.dart';

typedef PackageViews = ({String packagePath, String viewsPath});

const logger = Logger('arcade_views');

String view(
  String name, [
  Map<String, dynamic>? data,
  PackageViews? packageViews,
]) {
  const isProd = bool.fromEnvironment('dart.vm.product');
  Directory? packageViewsDirectory;
  if (packageViews != null) {
    final uri = Isolate.resolvePackageUriSync(
      Uri.parse(packageViews.packagePath),
    );
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
