import 'dart:convert';
import 'dart:io';

import 'package:arcade/arcade.dart';
import 'package:arcade_example/app/controllers/example_controller.dart';
import 'package:arcade_example/core/middlewares.dart';

final exampleController = ExampleController();

void defineRoutes() {
  route.registerGlobalBeforeHook((context) {
    print('Global before hook');
    return context;
  });

  route.registerGlobalAfterHook((context, handleResult) {
    print('Global after hook');
    return (context, handleResult);
  });

  route.registerGlobalAfterWebSocketHook((context, handleResult, id) {
    print('Global after websocket hook for $id');
    return (context, handleResult, id);
  });

  route.get('/').handle(exampleController.index);

  route.get('/get').before(checkAuthMiddleware).handle(exampleController.get);
  route.get('/get/:message')
      .before(checkAuthMiddleware)
      .handle(exampleController.get);

  route.post('/')
      .before(checkAuthMiddleware)
      .before(printUserIdMiddleware)
      .handle(exampleController.post)
      .after(
        (context, handleResult) => (
          context,
          {...handleResult! as Map, 'time': DateTime.now().toIso8601String()},
        ),
      );

  route.get('/hello/:name').handle(exampleController.hello);

  route.post('/print-body').handle(exampleController.printBodyAsString);

  route.get('/ws')
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

  route.get('/any/*').handle((context) => 'Any route');

  route.group<RequestContext>(
    '/group',
    before: [
      (context) {
        print('Before group: ${context.path}');
        return context;
      },
    ],
    defineRoutes: (route) {
      route.get('/').handle((context) => 'Group route');
      route.get('/hello/:name').handle(
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

  route.notFound((RequestContext context) {
    context.responseHeaders.contentType = ContentType.json;
    return jsonEncode({'message': 'Not found'});
  });
}
