import 'package:dartseid/dartseid.dart';
import 'package:dartseid_example/app/controllers/example_controller.dart';

void defineRoutes() {
  const exampleController = ExampleController();

  Route.get('/', exampleController.index);
}
