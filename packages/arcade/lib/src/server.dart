import 'dart:async';
import 'dart:io';

import 'package:arcade/arcade.dart';
import 'package:arcade/src/helpers/request_helpers.dart';
import 'package:arcade/src/helpers/response_helpers.dart';
import 'package:arcade/src/helpers/route_helpers.dart';
import 'package:arcade/src/helpers/server_helpers.dart';
import 'package:arcade/src/http/route.dart';
import 'package:arcade/src/ws/ws.dart';
import 'package:arcade_config/arcade_config.dart';
import 'package:arcade_logger/arcade_logger.dart';
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
      await ArcadeConfiguration.staticFilesDirectory.exists();

  await init();
  validatePreviousRouteHasHandler();

  final server = await HttpServer.bind(
    InternetAddress.anyIPv6,
    port,
  );

  server.listen(handleRequest);
  Logger.root.log(
    LogRecord(
      level: LogLevel.none,
      message: 'Server running on port $port',
    ),
  );

  setupProcessSignalWatchers(server);
}

Future<void> handleRequest(HttpRequest request) async {
  final HttpRequest(response: response, uri: uri, method: methodString) =
      request;

  final method = getHttpMethod(methodString);

  if (method == null) {
    return sendErrorResponse(response, const MethodNotAllowedException());
  }

  if (_canServeStaticFiles) {
    final pathSegments = uri.pathSegments;
    final file = File(
      joinAll([
        ArcadeConfiguration.staticFilesDirectory.path,
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
          ArcadeConfiguration.staticFilesDirectory.path,
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

  try {
    if (route.wsHandler != null) {
      await setupWsConnection(
        context: context,
        route: route,
      );
      return;
    }

    if (route.handler != null) {
      await writeResponse(
        context: context,
        route: route,
        response: response,
      );
      return;
    }

    sendErrorResponse(response, const InternalServerErrorException());
  } on ArcadeHttpException catch (e, s) {
    Logger.root.error('$e\n$s');
    return sendErrorResponse(response, e);
  } catch (e, s) {
    Logger.root.error('$e\n$s');
    return sendErrorResponse(response, const InternalServerErrorException());
  }
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
