
import 'package:dartseid/dartseid.dart';
import 'package:todo_api/core/routes.dart';

Future<void> main() async {
  defineRoutes();
  return runServer(port: 8080);
}
