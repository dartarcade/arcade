import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dartseid/dartseid.dart';
import 'package:dartseid/src/route.dart';

Future<void> runServer({required int port}) async {
  final server = await HttpServer.bind(
    InternetAddress.anyIPv6,
    port,
  );

  print('Server running');

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
        } catch (e) {
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
      }

      if (result is List || result is Map) {
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
