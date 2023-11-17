import 'package:arcade_cli/commands/create.dart';
import 'package:arcade_cli/commands/serve.dart';
import 'package:args/command_runner.dart';

Future<void> main(List<String> args) async {
  final runner = CommandRunner('arcade', 'Official CLI for Arcade')
    ..addCommand(ServeCommand())
    ..addCommand(CreateCommand());

  await runner.run(args);
}
