import 'dart:io';

import 'package:dartseid/dartseid.dart';
import 'package:dartseid/src/helpers/request_helpers.dart';
import 'package:dartseid/src/helpers/response_helpers.dart';
import 'package:dartseid/src/helpers/route_helpers.dart';
import 'package:dartseid/src/helpers/server_helpers.dart';
import 'package:dartseid/src/route.dart';

Future<void> runServer({required int port}) async {
  final server = await HttpServer.bind(
    InternetAddress.anyIPv6,
    port,
  );

  server.listen(handleRequest);
  print('Server running');

  final hotreloader = await createHotReloader();

  // Close server and hot reloader when exiting
  setupProcessSignalWatchers(server, hotreloader);
}

Future<void> handleRequest(HttpRequest request) async {
  final HttpRequest(response: response, uri: uri, method: methodString) =
      request;

  final method = getHttpMethod(methodString);

  if (method == null) {
    return sendErrorResponse(response, const MethodNotAllowedException());
  }

  final (route, notFoundRoute) = findMatchingRouteAndNotFoundRoute(
    routes: routes,
    method: method,
    uri: uri,
  );

  final context = RequestContext(request: request, route: route);

  print('Request: $methodString ${context.path}');

  if (route == null) {
    print('No matching route found');
    return writeNotFoundResponse(
      context: context,
      response: response,
      notFoundRouteHandler: notFoundRoute?.notFoundHandler,
    );
  }

  await writeResponse(
    context: context,
    route: route,
    response: response,
  );
}
