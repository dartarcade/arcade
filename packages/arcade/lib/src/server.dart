import 'dart:async';
import 'dart:io';

import 'package:arcade/arcade.dart';
import 'package:arcade/src/helpers/request_helpers.dart';
import 'package:arcade/src/helpers/response_helpers.dart';
import 'package:arcade/src/helpers/route_helpers.dart';
import 'package:arcade/src/helpers/server_helpers.dart';
import 'package:arcade/src/ws/ws.dart';
import 'package:arcade_config/arcade_config.dart';
import 'package:arcade_logger/arcade_logger.dart';
import 'package:meta/meta.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';

@internal
const isDev = !bool.fromEnvironment('dart.vm.product');
typedef InitApplication = FutureOr<void> Function();

@internal
bool canServeStaticFiles = false;

@internal
HttpServer? serverInstance;

Future<void> runServer({
  required int port,
  required InitApplication init,
  LogLevel? logLevel,
  bool closeServerAfterRoutesSetUp = false,
}) async {
  if (isDev) {
    ArcadeConfiguration.override(logLevel: logLevel ?? LogLevel.debug);
  } else {
    ArcadeConfiguration.override(logLevel: logLevel ?? LogLevel.info);
  }

  await Logger.init();

  canServeStaticFiles = await ArcadeConfiguration.staticFilesDirectory.exists();

  await init();
  validatePreviousRouteHasHandler();

  if (closeServerAfterRoutesSetUp) {
    return;
  }

  final server = await HttpServer.bind(
    InternetAddress.anyIPv6,
    port,
  );

  // Store server instance for testing purposes
  serverInstance = server;

  server.listen(_handleRequest);
  // ignore: avoid_print
  print('Server running on port $port');

  setupProcessSignalWatchers(server);
}

Future<void> _handleRequest(HttpRequest request) async {
  final HttpRequest(response: response, uri: uri, method: methodString) =
      request;

  final method = getHttpMethod(methodString);

  Logger.root.info('Request: $methodString ${request.uri.path}');

  if (method == null) {
    Logger.root.debug('Unknown method: $methodString');
    return writeErrorResponse(
      null,
      response,
      const MethodNotAllowedException(),
      stackTrace: isDev ? StackTrace.current : null,
    );
  }

  if (canServeStaticFiles) {
    Logger.root.debug('Checking static files: ${uri.pathSegments}');
    final pathSegments = uri.pathSegments;
    final file = File(
      joinAll([
        ArcadeConfiguration.staticFilesDirectory.path,
        ...pathSegments,
      ]),
    );
    if (await file.exists()) {
      Logger.root.debug('Serving static file: $file');
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

  if (route == null) {
    Logger.root.debug('No route found for: $methodString ${request.uri.path}');
    if (notFoundRoute == null) {
      Logger.root.debug(
        'No not found route found for: $methodString ${request.uri.path}',
      );
      return writeErrorResponse(
        null,
        response,
        const NotFoundException(),
        stackTrace: isDev ? StackTrace.current : null,
      );
    }

    final context = RequestContext(request: request, route: notFoundRoute);

    Logger.root.debug('Writing not found response');
    return writeNotFoundResponse(
      context: context,
      response: response,
      notFoundRoute: notFoundRoute,
    );
  }

  final context = RequestContext(request: request, route: route);

  try {
    if (route.wsHandler != null) {
      Logger.root.debug('Setting up WS connection');
      await setupWsConnection(
        context: context,
        route: route,
      );
      return;
    }

    if (route.handler != null) {
      Logger.root.debug('Writing response');
      await writeResponse(
        context: context,
        route: route,
        response: response,
      );
      return;
    }

    Logger.root.debug('Writing error response');
    writeErrorResponse(
      context,
      response,
      const InternalServerErrorException(),
      stackTrace: isDev ? StackTrace.current : null,
      notFoundRoute: notFoundRoute,
    );
  } on ArcadeHttpException catch (e, s) {
    Logger.root.error('$e\n$s');
    return writeErrorResponse(
      context,
      response,
      e,
      stackTrace: isDev ? s : null,
      notFoundRoute: notFoundRoute,
    );
  } catch (e, s) {
    Logger.root.error('$e\n$s');
    return writeErrorResponse(
      context,
      response,
      const InternalServerErrorException(),
      stackTrace: isDev ? s : null,
      notFoundRoute: notFoundRoute,
    );
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

  for (final MapEntry(:key, :value)
      in ArcadeConfiguration.staticFilesHeaders.entries) {
    response.headers.add(key, value);
  }

  await file.openRead().pipe(response);
  response.close();
}
