import 'dart:async';
import 'dart:io';

import 'package:arcade_cli/utils.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:stream_transform/stream_transform.dart';
import 'package:watcher/watcher.dart';

class ServeCommand extends Command {
  @override
  String get name => 'serve';

  @override
  String get description => 'Locally serve your app';

  @override
  Future<void> run() async {
    Process? process;
    final serverFile = await getServerFile();
    final cwd = Directory.current.path;

    bool shouldReload(WatchEvent event) {
      return path.isWithin(path.join(cwd, 'bin'), event.path) ||
          path.isWithin(path.join(cwd, 'lib'), event.path);
    }

    Process.runSync('dart', ['compilation-server', 'start']);

    process = await Process.start(
      'dart',
      ['run', '-r', serverFile.path],
      workingDirectory: cwd,
    );

    var stdoutSubscription = process.stdout.listen((event) {
      stdout.add(event);
    });
    var stderrSubscription = process.stderr.listen((event) {
      stderr.add(event);
    });

    bool isReloading = false;
    DirectoryWatcher(cwd)
        .events
        .where(shouldReload)
        .debounceBuffer(const Duration(milliseconds: 500))
        .listen(
      (_) async {
        if (!isReloading) {
          print('Restarting server...');
          isReloading = true;
        }
        stdoutSubscription.cancel();
        stderrSubscription.cancel();
        process?.kill();
        process = null;
        final now = DateTime.now();
        process = await Process.start(
          'dart',
          ['run', '-r', serverFile.path],
          workingDirectory: cwd,
        );
        stdoutSubscription = process!.stdout.listen((event) {
          final data = String.fromCharCodes(event);

          if (data.contains('Server running on port')) {
            final time = DateTime.now().difference(now).inMilliseconds;
            print('Restarted server in $time ms');
            isReloading = false;
            return;
          }

          stdout.add(event);
        });
        stderrSubscription = process!.stderr.listen((event) {
          stderr.add(event);
        });
      },
    );

    ProcessSignal.sigint.watch().listen((_) async {
      process?.kill();
      Process.runSync('dart', ['compilation-server', 'shutdown']);
      exit(0);
    });
    if (!Platform.isWindows) {
      ProcessSignal.sigterm.watch().listen((_) async {
        process?.kill();
        exit(0);
      });
    }
  }
}
