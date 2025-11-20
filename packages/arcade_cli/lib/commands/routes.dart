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
import 'dart:io';
import 'dart:convert';
import 'package:arcade/arcade.dart';
import './${await getAppName()}.dart' as app;

Future<void> main() async {
  await app.main(['--export-routes']);
  // ignore: avoid_print
  print(jsonEncode(getRouteMetadata()));
  exit(0);
}
''';
}

class RoutesCommand extends Command {
  RoutesCommand() {
    argParser.addFlag('json', help: 'Output in JSON format');

    argParser.addOption('output', help: 'Output file', defaultsTo: 'stdout');

    argParser.addOption(
      'route-export-path',
      abbr: 'r',
      help: 'Path to export routes dir',
    );
  }

  @override
  String get name => 'routes';

  @override
  String get description => 'List all routes';

  @override
  Future run() async {
    var (json, output, routeExportPath) = (
      argResults!.flag('json'),
      argResults!.option('output'),
      argResults!.option('route-export-path'),
    );
    routeExportPath ??= _randomFileName();
    final binDir = join(Directory.current.path, 'bin');
    final routeExportFile = File(join(binDir, routeExportPath));

    routeExportFile.createSync(recursive: true);
    routeExportFile.writeAsStringSync(await _makeRouteExportSource());

    final routeExportResult = Process.runSync(
      'dart',
      ['run', routeExportFile.path],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    routeExportFile.deleteSync();

    if (routeExportResult.exitCode != 0) {
      throw UsageException(
        'Failed to export routes: ${routeExportResult.stderr}',
        usage,
      );
    }

    final routeExportOutput = routeExportResult.stdout as String;
    final data = jsonDecode(routeExportOutput) as List;

    if (json) {
      print(const JsonEncoder.withIndent('  ').convert(data));
    } else {
      final formatter = TableFormatter(
        data.cast<Map<String, dynamic>>().map(RouteMetadata.fromJson).toList(),
      );
      print('\n${formatter.format()}');
    }
  }

  String _randomFileName() {
    return 'routes_${DateTime.now().millisecondsSinceEpoch}.dart';
  }
}
