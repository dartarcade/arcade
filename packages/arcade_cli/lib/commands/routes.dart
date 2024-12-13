import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arcade/arcade.dart';
import 'package:arcade_cli/formatters/table_formatter.dart';
import 'package:arcade_cli/utils.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart';

Future<String> _makeRouteExportSource() async {
  return '''
import 'dart:convert';
import 'package:arcade/arcade.dart';
import './${await getAppName()}.dart' as app;

Future<void> main() async {
  await app.main(['--export-routes']);
  // ignore: avoid_print
  print(jsonEncode(getRouteMetadata()));
}
''';
}

class RoutesCommand extends Command {
  RoutesCommand() {
    argParser.addFlag(
      'json',
      help: 'Output in JSON format',
    );

    argParser.addOption(
      'output',
      help: 'Output file',
      defaultsTo: 'stdout',
    );

    argParser.addOption(
      'route-export-path',
      abbr: 'r',
      help: 'Path to export routes dir',
      defaultsTo: 'routes.dart',
    );

    argParser.addFlag(
      'create-route-export-file',
      abbr: 'c',
      help: 'Create route export file if it does not exist',
    );
  }

  @override
  String get name => 'routes';

  @override
  String get description => 'List all routes';

  @override
  Future run() async {
    final (json, output, routeExportPath, createRouteExportFile) = (
      argResults!.flag('json'),
      argResults!.option('output'),
      argResults!.option('route-export-path'),
      argResults!.flag('create-route-export-file'),
    );
    final binDir = join(Directory.current.path, 'bin');
    final routeExportFile = File(join(binDir, routeExportPath));

    if (!routeExportFile.existsSync() && !createRouteExportFile) {
      throw UsageException(
        'Route export file not found: $routeExportFile',
        usage,
      );
    }

    if (createRouteExportFile) {
      routeExportFile.createSync(recursive: true);
      routeExportFile.writeAsStringSync(await _makeRouteExportSource());
    }

    final routeExportResult = Process.runSync(
      'dart',
      ['run', routeExportFile.path],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (routeExportResult.exitCode != 0) {
      throw UsageException(
        'Failed to export routes: ${routeExportResult.stderr}',
        usage,
      );
    }

    final routeExportOutput = routeExportResult.stdout as String;
    final data = jsonDecode(routeExportOutput) as List;

    if (json) {
      print(
        const JsonEncoder.withIndent('  ').convert(data),
      );
    } else {
      final formatter = TableFormatter(
        data.cast<Map<String, dynamic>>().map(RouteMetadata.fromJson).toList(),
      );
      print('\n${formatter.format()}');
    }
  }
}
