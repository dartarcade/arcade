import 'package:dartseid/dartseid.dart';
import 'package:dartseid_example/app/controllers/example_controller.dart';
import 'package:dartseid_example/core/middlewares.dart';

const exampleController = ExampleController();

void defineRoutes() {
  Route.get('/', exampleController.index);

  Route.get('/get', exampleController.get);
  Route.get('/get/:message', exampleController.get);

  Route.post('/', exampleController.post)
      .middleware(checkAuthMiddleware)
      .middleware(printUserIdMiddleware);

  Route.get('/hello/:name', exampleController.hello);
}
