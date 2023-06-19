/*
|--------------------------------------------------------------------------
| Server entry point
|--------------------------------------------------------------------------
|
| This is the entry point for the server. It will be used to start the
| server and run the application.
*/

import 'package:dartseid/dartseid.dart';
import 'package:dartseid_example/core/routes.dart';

Future<void> main(List<String> arguments) {
  defineRoutes();
  return runServer(port: 8080);
}
