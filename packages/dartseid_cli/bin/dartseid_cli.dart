import 'package:args/command_runner.dart';
import 'package:dartseid_cli/commands/create.dart';
import 'package:dartseid_cli/commands/serve.dart';

Future<void> main(List<String> args) async {
  final runner = CommandRunner('dartseid', 'Official CLI for Dartsied')
    ..addCommand(ServeCommand())
    ..addCommand(CreateCommand());

  await runner.run(args);
}
