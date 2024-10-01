import 'package:arcade/arcade.dart';
import 'package:todo_api/core/env.dart';
import 'package:todo_api/core/init.dart';

Future<void> main() async {
  return runServer(port: Env.port, init: init);
}
