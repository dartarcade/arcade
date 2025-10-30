#!/usr/bin/env dart

import 'dart:io';
import 'package:args/args.dart';
import 'package:prompts/prompts.dart' as prompts;
import '../lib/workspace_utils.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'package',
      abbr: 'p',
      help: 'Specific package to update (e.g., arcade, arcade_test)',
    )
    ..addOption(
      'type',
      abbr: 't',
      help:
          'Entry type (feat, fix, docs, style, refactor, perf, test, build, ci, chore)',
      allowed: [
        'feat',
        'fix',
        'docs',
        'style',
        'refactor',
        'perf',
        'test',
        'build',
        'ci',
        'chore'
      ],
    )
    ..addOption(
      'message',
      abbr: 'm',
      help: 'Changelog entry message',
    )
    ..addFlag(
      'default',
      abbr: 'd',
      help: 'Add default "Updated dependencies" entry',
      negatable: false,
    )
    ..addFlag(
      'interactive',
      abbr: 'i',
      help: 'Run in interactive mode (default if no arguments provided)',
      negatable: false,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show usage information',
      negatable: false,
    );

  final argResults = parser.parse(arguments);

  if (argResults['help'] as bool) {
    print('Update changelog entries for arcade packages\n');
    print('Usage: dart update_changelogs.dart [options]\n');
    print(parser.usage);
    return;
  }

  // Determine if we should run in interactive mode
  final interactive = argResults['interactive'] as bool ||
      (argResults['type'] == null && argResults['default'] == false);

  // Get all package information
  final packages = await getWorkspacePackages();
  final arcadePackages =
      packages.where((p) => p.name.startsWith('arcade')).toList();

  if (arcadePackages.isEmpty) {
    print('No arcade packages found.');
    return;
  }

  // Filter packages if specific package requested
  List<PackageInfo> targetPackages = arcadePackages;
  if (argResults['package'] != null) {
    final packageName = argResults['package'] as String;
    targetPackages =
        arcadePackages.where((p) => p.name == packageName).toList();

    if (targetPackages.isEmpty) {
      stderr.writeln('Error: Package "$packageName" not found.');
      stderr.writeln(
          'Available packages: ${arcadePackages.map((p) => p.name).join(', ')}');
      exit(1);
    }
  }

  if (interactive) {
    // Interactive mode
    print('Updating changelogs for all packages...\n');

    final changelogEntries = <String, List<String>>{};

    for (final package in targetPackages) {
      print('\n${'-' * 50}');
      print('Package: ${package.name} (${package.version})');
      print('Path: ${package.path}');

      final entries = await collectEntriesInteractive(package);
      if (entries.isNotEmpty) {
        changelogEntries[package.name] = entries;
      }
    }

    // Update changelogs
    print('\n${'-' * 50}');
    print('Updating CHANGELOG.md files...\n');

    for (final package in targetPackages) {
      final entries = changelogEntries[package.name];

      if (entries != null && entries.isNotEmpty) {
        await updateChangelog(package, entries);
        print('✓ Updated ${package.path}/CHANGELOG.md');
      }
    }
  } else {
    // Non-interactive mode
    final entries = <String>[];

    if (argResults['default'] as bool) {
      entries.add('- Updated dependencies');
    } else if (argResults['type'] != null && argResults['message'] != null) {
      final type = argResults['type'] as String;
      final message = argResults['message'] as String;
      final prefix = _getPrefix(type);
      entries.add('- $prefix: $message');
    } else {
      stderr
          .writeln('Error: In non-interactive mode, you must provide either:');
      stderr.writeln('  --default flag for default entry');
      stderr.writeln('  --type and --message for custom entry');
      exit(1);
    }

    // Update changelogs for all target packages
    for (final package in targetPackages) {
      await updateChangelog(package, entries);
      print('✓ Updated ${package.path}/CHANGELOG.md');
    }
  }

  print('\nDone! Changelogs have been updated.');
}

Future<List<String>> collectEntriesInteractive(PackageInfo package) async {
  final entries = <String>[];

  while (true) {
    final choice = prompts.choose(
      'Select changelog entry type:',
      [
        'default',
        'feat',
        'fix',
        'docs',
        'style',
        'refactor',
        'perf',
        'test',
        'build',
        'ci',
        'chore',
        'skip',
      ],
      defaultsTo: 'default',
    );

    if (choice == 'skip') {
      break;
    }

    if (choice == 'default') {
      entries.add('- Updated dependencies');

      final addMore = prompts.getBool(
        'Add another entry for this package?',
        defaultsTo: false,
      );

      if (!addMore) {
        break;
      }
      continue;
    }

    // Get the actual changelog entry with validation
    final message = prompts.get(
      'Enter the changelog message:',
      validate: (String input) {
        if (input.trim().isEmpty) {
          return false;
        }
        return true;
      },
    );

    // Format the entry
    final prefix = _getPrefix(choice as String);
    final trimmedMessage = message.trim();
    entries.add('- $prefix: $trimmedMessage');

    final addMore = prompts.getBool(
      'Add another entry for this package?',
      defaultsTo: false,
    );

    if (!addMore) {
      break;
    }
  }

  return entries;
}

String _getPrefix(String type) {
  switch (type) {
    case 'feat':
      return '**FEAT**';
    case 'fix':
      return '**FIX**';
    case 'docs':
      return '**DOCS**';
    case 'style':
      return '**STYLE**';
    case 'refactor':
      return '**REFACTOR**';
    case 'perf':
      return '**PERF**';
    case 'test':
      return '**TEST**';
    case 'build':
      return '**BUILD**';
    case 'ci':
      return '**CI**';
    case 'chore':
      return '**CHORE**';
    default:
      return type.toUpperCase();
  }
}

Future<void> updateChangelog(
  PackageInfo package,
  List<String> entries,
) async {
  final changelogPath = '${package.path}/CHANGELOG.md';
  final changelogFile = File(changelogPath);

  String content;
  if (await changelogFile.exists()) {
    content = await changelogFile.readAsString();
  } else {
    // Create new changelog with header
    content = '''# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

''';
  }

  // Check if current version already exists
  final versionRegex =
      RegExp('^## ${RegExp.escape(package.version)}\$', multiLine: true);

  if (versionRegex.hasMatch(content)) {
    // Version already exists, append entries to it
    final match = versionRegex.firstMatch(content)!;
    final versionIndex = match.end;

    // Find the end of this version's section (next ## or end of file)
    final nextVersionRegex = RegExp(r'^##\s', multiLine: true);
    final nextMatch =
        nextVersionRegex.firstMatch(content.substring(versionIndex));
    final sectionEnd =
        nextMatch != null ? versionIndex + nextMatch.start : content.length;

    // Extract existing entries
    final existingSection = content.substring(versionIndex, sectionEnd).trim();

    // Combine with new entries
    final updatedSection = existingSection.isEmpty
        ? '\n\n${entries.join('\n')}'
        : '\n\n$existingSection\n${entries.join('\n')}';

    // Replace the section
    content = content.substring(0, versionIndex) +
        updatedSection +
        (nextMatch != null ? '\n\n' : '\n') +
        content.substring(sectionEnd);
  } else {
    // Version doesn't exist, create new section
    final versionSection = '''
## ${package.version}

${entries.join('\n')}
''';

    // Insert after the header but before any existing versions
    if (content.contains('##')) {
      // Find the first version header
      final firstVersionIndex = content.indexOf('##');
      content = content.substring(0, firstVersionIndex) +
          versionSection +
          '\n' +
          content.substring(firstVersionIndex);
    } else {
      // No existing versions, just append
      content += versionSection;
    }
  }

  await changelogFile.writeAsString(content);
}
