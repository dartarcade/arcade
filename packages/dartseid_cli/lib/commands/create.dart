import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

class CreateCommand extends Command {
  static const _gitUrl = 'git-url';

  CreateCommand() {
    const starterGitUrl = 'https://github.com/dartseid/start.git';
    argParser.addOption(
      _gitUrl,
      abbr: 'g',
      help: 'Git URL to clone from',
      defaultsTo: starterGitUrl,
    );
  }

  @override
  String get name => 'create';

  @override
  String get description => 'Create a new project';

  @override
  FutureOr? run() {
    if (argResults!.rest.isEmpty) {
      print('Please specify a project name');
      return null;
    }

    final name = argResults!.rest.first;
    final gitUrl = argResults![_gitUrl] as String;
    _validateUrl(gitUrl);

    final dir = Directory(name);
    if (dir.existsSync()) {
      print('Directory $name already exists');
      exit(1);
    }

    print('Creating $name from $gitUrl');
    _cloneAndSetup(gitUrl, name);

    print('-----------------------------------');
    print('To run the project:');
    print('cd $name');
    print('dartseid serve');
  }

  void _cloneAndSetup(String gitUrl, String name) {
    final result = Process.runSync(
      'git',
      ['clone', gitUrl, name],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    if (result.exitCode != 0) {
      print(result.stderr);
      return;
    }

    _setup(name);

    print('Running pub get...');
    Process.runSync(
      'dart',
      ['pub', 'get'],
      workingDirectory: name,
    );
  }

  void _setup(String name) {
    final pubspec = File('$name/pubspec.yaml');
    final lines = pubspec.readAsLinesSync();
    final newLines = <String>[];
    for (final line in lines) {
      if (line.contains('name:')) {
        newLines.add(line.replaceFirst('start', name));
      } else {
        newLines.add(line);
      }
    }
    pubspec.writeAsStringSync(newLines.join('\n'));

    final readme = File('$name/README.md');
    readme.writeAsStringSync('# $name');

    final gitDir = Directory('$name/.git');
    gitDir.deleteSync(recursive: true);

    final start = File('$name/bin/start.dart');
    start.renameSync('$name/bin/$name.dart');
  }

  void _validateUrl(String url) {
    if (!url.startsWith('https://')) {
      throw UsageException(
        'Git URL must start with https://',
        _gitUrl,
      );
    }
  }
}
