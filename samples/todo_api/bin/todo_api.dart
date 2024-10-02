import 'dart:io';

import 'package:arcade/arcade.dart';
import 'package:todo_api/core/env.dart';
import 'package:todo_api/core/init.dart';

Future<void> main() async {
  final portFromEnvironment = Platform.environment['PORT'];
  var port = Env.port;
  if (portFromEnvironment != null) {
    port = int.parse(portFromEnvironment);
  }

  if (port == null) {
    throw StateError('port is not defined');
  }

  return runServer(port: port, init: init);
}
