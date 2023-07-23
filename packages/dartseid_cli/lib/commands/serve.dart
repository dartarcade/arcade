import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dartseid_cli/utils.dart';

class ServeCommand extends Command {
  @override
  String get name => 'serve';

  @override
  String get description => 'Locally serve your app';

  @override
  Future<void> run() async {
    final serverFile = await getServerFile();
    final runProcess = await Process.start(
      'dart',
      ['run', '--enable-vm-service', serverFile.path],
    );
    runProcess.stdout.pipe(stdout);
    runProcess.stderr.pipe(stderr);
  }
}
