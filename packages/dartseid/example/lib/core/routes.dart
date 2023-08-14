import 'dart:convert';
import 'dart:io';

import 'package:dartseid/dartseid.dart';
import 'package:dartseid_example/app/controllers/example_controller.dart';
import 'package:dartseid_example/core/middlewares.dart';

final exampleController = ExampleController();

void defineRoutes() {
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

  Route.get('/ws')
      .before(checkAuthMiddleware)
      .handleWebSocket(
        exampleController.ws,
        onConnect: exampleController.onWsConnect,
      )
      .after(
    (context, handleResult, id) {
      print('After websocket handler for $id');
      return (context, handleResult, id);
    },
  );

  Route.notFound((RequestContext context) {
    context.responseHeaders.contentType = ContentType.json;
    return jsonEncode({'message': 'Not found'});
  });
}
