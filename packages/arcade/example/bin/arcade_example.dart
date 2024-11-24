/*
|--------------------------------------------------------------------------
| Server entry point
|--------------------------------------------------------------------------
|
| This is the entry point for the server. It will be used to start the
| server and run the application.
*/

import 'package:arcade/arcade.dart';
import 'package:arcade_example/core/routes.dart';

Future<void> main(List<String> arguments) {
  return runServer(
    port: 8080,
    init: defineRoutes,
    logLevel: LogLevel.debug,
  );
}
