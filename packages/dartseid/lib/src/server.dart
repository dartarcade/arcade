import 'dart:io';

import 'package:dartseid/dartseid.dart';
import 'package:dartseid/src/helpers/request_helpers.dart';
import 'package:dartseid/src/helpers/response_helpers.dart';
import 'package:dartseid/src/helpers/route_helpers.dart';
import 'package:dartseid/src/helpers/server_helpers.dart';
import 'package:dartseid/src/http/route.dart';

Future<void> runServer({required int port}) async {
  await Logger.init();

  final server = await HttpServer.bind(
    InternetAddress.anyIPv6,
    port,
  );

  server.listen(handleRequest);
  Logger.root.log(
    const LogRecord(
      level: LogLevel.none,
      message: 'Server running',
    ),
  );

  // Close server and hot reloader when exiting
  setupProcessSignalWatchers(server);
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

  Logger.root.info('Request: $methodString ${request.uri.path}');

  if (route == null) {
    if (notFoundRoute == null) {
      return sendErrorResponse(response, const NotFoundException());
    }

    final context = RequestContext(request: request, route: notFoundRoute);

    return writeNotFoundResponse(
      context: context,
      response: response,
      notFoundRouteHandler: notFoundRoute.notFoundHandler,
    );
  }

  final context = RequestContext(request: request, route: route);

  await writeResponse(
    context: context,
    route: route,
    response: response,
  );
}
