import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

class CreateCommand extends Command {
  static const _gitUrl = 'git-url';

  CreateCommand() {
    const starterGitUrl = 'https://github.com/dartarcade/start.git';
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
    print('arcade serve');
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
    Process.runSync('dart', ['pub', 'get'], workingDirectory: name);
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

    final binDir = Directory('$name/bin');
    final libDir = Directory('$name/lib');
    final dartFiles = (findFilesInDir(binDir) + findFilesInDir(libDir)).where(
      (f) => f.path.endsWith('.dart'),
    );
    for (final file in dartFiles) {
      final lines = file.readAsLinesSync();
      final newLines = <String>[];
      for (final line in lines) {
        if (line.startsWith('import') && line.contains('start')) {
          newLines.add(line.replaceFirst('start', name));
        } else {
          newLines.add(line);
        }
      }
      file.writeAsStringSync(newLines.join('\n'));
    }

    Process.runSync('dart', ['fix', '--apply'], workingDirectory: name);
    Process.runSync('dart', ['format', 'bin'], workingDirectory: name);
    Process.runSync('dart', ['format', 'lib'], workingDirectory: name);
  }

  List<File> findFilesInDir(Directory dir) {
    final files = <File>[];
    for (final entity in dir.listSync()) {
      if (entity is File) {
        files.add(entity);
      } else if (entity is Directory) {
        files.addAll(findFilesInDir(entity));
      }
    }
    return files;
  }

  void _validateUrl(String url) {
    if (!url.startsWith('https://')) {
      throw UsageException('Git URL must start with https://', _gitUrl);
    }
  }
}
