import 'dart:convert';
import 'dart:io';

import 'package:dartseid/dartseid.dart';
import 'package:dartseid_example/app/controllers/example_controller.dart';
import 'package:dartseid_example/core/middlewares.dart';

const exampleController = ExampleController();

void defineRoutes() {
  Route.any('*').handle((context) {
    return 'Hello from DartSeid!';
  });

  Route.get('/').handle(exampleController.index);

  Route.get('/get').before(checkAuthMiddleware).handle(exampleController.get);
  Route.get('/get/:message')
      .before(checkAuthMiddleware)
      .handle(exampleController.get);

  Route.post('/')
      .before(checkAuthMiddleware)
      .before(printUserIdMiddleware)
      .handle(exampleController.post)
      .after(
        (context, handleResult) => (
          context,
          {...handleResult! as Map, 'time': DateTime.now().toIso8601String()},
        ),
      );

  Route.get('/hello/:name').handle(exampleController.hello);

  Route.post('/print-body').handle(exampleController.printBodyAsString);

  Route.notFound((RequestContext context) {
    context.responseHeaders.contentType = ContentType.json;
    return jsonEncode({'message': 'Not found'});
  });
}
