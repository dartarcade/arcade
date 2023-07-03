import 'dart:async';
import 'dart:io';

import 'package:dartseid/dartseid.dart';
import 'package:dartseid/src/helpers/request_helpers.dart';
import 'package:dartseid/src/helpers/response_helpers.dart';
import 'package:dartseid/src/helpers/route_helpers.dart';
import 'package:dartseid/src/helpers/server_helpers.dart';
import 'package:dartseid/src/http/route.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';

typedef InitApplication = FutureOr<void> Function();

late bool _canServeStaticFiles;

Future<void> runServer({
  required int port,
  required InitApplication init,
}) async {
  await Logger.init();

  _canServeStaticFiles =
      await DartseidConfiguration.staticFilesDirectory.exists();

  await init();
  validatePreviousRouteHasHandler();

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

  final hotreloader = await createHotReloader(init);

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

  Logger.root.info('Request: $methodString ${request.uri.path}');

  if (route == null) {
    if (_canServeStaticFiles) {
      final pathSegments = uri.pathSegments;
      final file = File(
        joinAll([
          DartseidConfiguration.staticFilesDirectory.path,
          ...pathSegments,
        ]),
      );
      if (await file.exists()) {
        return serveStaticFile(
          file: file,
          response: response,
        );
      }
    }

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

Future<void> serveStaticFile({
  required File file,
  required HttpResponse response,
}) async {
  final mime = lookupMimeType(file.path) ?? 'text/plain';
  response.headers.contentType = ContentType.parse(mime);

  final length = await file.length();
  response.headers.contentLength = length;

  await file.openRead().pipe(response);
  response.close();
}
