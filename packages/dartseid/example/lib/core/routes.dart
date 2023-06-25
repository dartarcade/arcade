import 'package:dartseid/dartseid.dart';
import 'package:dartseid_example/app/controllers/example_controller.dart';
import 'package:dartseid_example/core/middlewares.dart';

const exampleController = ExampleController();

void defineRoutes() {
  Route.get('/', exampleController.index);

  Route.get('/get', exampleController.get).middleware(checkAuthMiddleware);
  Route.get('/get/:message', exampleController.get)
      .middleware(checkAuthMiddleware);

  Route.post('/', exampleController.post)
      .middleware(checkAuthMiddleware)
      .middleware(printUserIdMiddleware);

  Route.get('/hello/:name', exampleController.hello);

  Route.post('/print-body', exampleController.printBodyAsString);

  Route.notFound((context) => {'message': 'Not found'});
}
