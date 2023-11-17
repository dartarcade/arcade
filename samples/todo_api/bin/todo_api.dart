import 'package:arcade/arcade.dart';
import 'package:todo_api/config/injection.dart';

Future<void> main() async {
  return runServer(port: 8080, init: configureDependencies);
}
