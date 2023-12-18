import 'dart:convert';
import 'dart:io';

import 'package:arcade/arcade.dart';
import 'package:arcade_example/app/controllers/example_controller.dart';
import 'package:arcade_example/core/middlewares.dart';

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

  Route.get('/any/*').handle((context) => 'Any route');

  Route.group(
    '/group',
    before: [
      (context) {
        print('Before group: ${context.path}');
        return context;
      },
    ],
    defineRoutes: () {
      Route.get('/').handle((context) => 'Group route');
      Route.get('/hello/:name').handle(
        (context) =>
            'Group route with path parameter: ${context.pathParameters['name']}',
      );
    },
    after: [
      (context, handleResult) {
        print('After group: ${context.path}');
        return (context, handleResult);
      },
    ],
  );

  Route.notFound((RequestContext context) {
    context.responseHeaders.contentType = ContentType.json;
    return jsonEncode({'message': 'Not found'});
  });
}
