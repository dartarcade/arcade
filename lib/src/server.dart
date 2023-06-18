import 'dart:convert';
import 'dart:io';

import 'package:ansi_styles/extension.dart';
import 'package:collection/collection.dart';
import 'package:dartseid/dartseid.dart';
import 'package:dartseid/src/route.dart';
import 'package:hotreloader/hotreloader.dart';
import 'package:vm_service/vm_service.dart';

Future<void> runServer({required int port}) async {
  // Set up hot reloader
  final hotreloader = await HotReloader.create(
    onBeforeReload: (ctx) {
      print(
        '----------------------------------------------------------------------',
      );
      print('Reloading server...');
      return true;
    },
    onAfterReload: (ctx) {
      switch (ctx.result) {
        case HotReloadResult.Succeeded:
          print('Reload succeeded'.green);
        case HotReloadResult.PartiallySucceeded:
          print('Reload partially succeeded'.yellow);
          _printReloadReports(ctx.reloadReports);
        case HotReloadResult.Skipped:
          print('Reload skipped'.yellow);
          _printReloadReports(ctx.reloadReports);
        case HotReloadResult.Failed:
          print('Reload failed'.red);
          _printReloadReports(ctx.reloadReports);
      }

      print(
        '----------------------------------------------------------------------',
      );
    },
  );

  // Set up server
  final server = await HttpServer.bind(
    InternetAddress.anyIPv6,
    port,
  );

  // Close server and hot reloader when exiting
  ProcessSignal.sigint.watch().listen((_) async {
    await _closeServerExit(server, hotreloader);
  });

  ProcessSignal.sigterm.watch().listen((_) async {
    await _closeServerExit(server, hotreloader);
  });

  print('Server running');

  // Start listening
  await for (final request in server) {
    final HttpRequest(response: response, uri: uri) = request;
    final methodString = request.method;

    final method = HttpMethod.values.firstWhereOrNull(
      (method) => method.methodString == methodString,
    );

    if (method == null) {
      response.statusCode = HttpStatus.methodNotAllowed;
      response.writeln('Method not allowed');
      response.close();
      continue;
    }

    final route = routes.firstWhereOrNull(
      (route) =>
          route.method == method &&
          _routeMatchesPath(route.path ?? '', uri.path),
    );

    final context = _makeRequestContext(request, route as Route?);

    print('Request: $methodString ${context.path}');

    if (route == null) {
      final notFoundRoute = routes.firstWhereOrNull(
        (route) => route.notFoundHandler != null,
      );

      response.statusCode = HttpStatus.notFound;

      if (notFoundRoute != null) {
        try {
          response.write(notFoundRoute.notFoundHandler!(context));
        } catch (e, s) {
          print('$e\n$s');
          response.writeln('Not found');
        }
      } else {
        response.writeln('Not found');
      }

      response.close();
      continue;
    }

    try {
      var result = route.handler!(context);

      if (result is Future) {
        result = await result;
      }

      if (result is String) {
        response.headers.contentType = ContentType.html;
      } else {
        result = jsonEncode(result);
        response.headers.contentType = ContentType.json;
      }

      response.write(result);

      response.close();
    } catch (e, s) {
      print('$e\n$s');

      response.statusCode = HttpStatus.internalServerError;
      response.writeln('Internal server error');
      response.close();
      continue;
    }
  }
}

bool _routeMatchesPath(String routePath, String path) {
  final routePathSegments = routePath.split('/');
  final pathSegments = path.split('/');

  if (routePathSegments.length != pathSegments.length) {
    return false;
  }

  for (var i = 0; i < routePathSegments.length; i++) {
    final routePathSegment = routePathSegments[i];
    final pathSegment = pathSegments[i];

    if (routePathSegment.startsWith(':')) {
      continue;
    }

    if (routePathSegment != pathSegment) {
      return false;
    }
  }

  return true;
}

RequestContext _makeRequestContext(HttpRequest request, Route? route) {
  final HttpRequest(uri: uri, method: methodString) = request;

  final method = HttpMethod.values.firstWhere(
    (method) => method.methodString == methodString,
  );

  Map<String, String> pathParameters = {};

  if (route != null) {
    final routePathSegments = route.path?.split('/') ?? [];
    final pathSegments = uri.path.split('/');

    for (var i = 0; i < routePathSegments.length; i++) {
      final routePathSegment = routePathSegments[i];
      final pathSegment = pathSegments[i];

      if (routePathSegment.startsWith(':')) {
        final key = routePathSegment.substring(1);
        pathParameters[key] = pathSegment;
      }
    }
  }

  final rawBody = request.toList();

  return RequestContext(
    path: uri.path,
    method: method,
    headers: request.headers,
    pathParameters: pathParameters,
    queryParameters: uri.queryParameters,
    body: rawBody,
  );
}

void _printReloadReports(Map<IsolateRef, ReloadReport> reloadReports) {
  final failedReports = reloadReports.values.where(
    (report) => report.success == false,
  );
  if (failedReports.isEmpty) return;

  final List<String> messages = [];

  for (final report in failedReports) {
    final json = report.json;
    final notices = json?['notices'];
    if (json == null || notices is! List) continue;

    final message = notices.firstWhereOrNull(
      (notice) => notice['message'] != null,
    )?['message'];

    if (message == null) continue;

    messages.add(message);
  }

  if (messages.isEmpty) return;
  print('\n${messages.join('\n')}'.red);
}

Future<void> _closeServerExit(
    HttpServer server, HotReloader hotreloader) async {
  print('Shutting down');
  await server.close();
  await hotreloader.stop();
  exit(0);
}
