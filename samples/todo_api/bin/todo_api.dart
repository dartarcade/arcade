import 'package:dartseid/dartseid.dart';
import 'package:todo_api/config/injection.dart';

Future<void> main() async {
  configureDependencies();
  return runServer(port: 8080);
}
