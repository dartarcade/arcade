import 'package:arcade_config/arcade_config.dart';
import 'package:jinja/jinja.dart';
import 'package:jinja/loaders.dart';

String view(String name, [Map<String, dynamic>? data]) {
  const isProd = bool.fromEnvironment('dart.vm.product');
  final environment = Environment(
    // ignore: avoid_redundant_argument_values
    autoReload: !isProd,
    loader: FileSystemLoader(paths: [ArcadeConfiguration.viewsDirectory.path]),
  );
  final templateName = '$name${ArcadeConfiguration.viewsExtension}';
  final template = environment.getTemplate(templateName);
  return template.render(data);
}
