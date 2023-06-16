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
    final HttpRequest(response: response) = request;
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

    final context = _makeRequestContext(request);

    final route = routes.firstWhereOrNull(
      (route) => route.method == method && route.path == context.path,
    );

    print('Request: $methodString ${context.path}');

    if (route == null) {
      final notFoundRoute = routes.firstWhereOrNull(
        (route) => route.notFoundHandler != null,
      );

      response.statusCode = HttpStatus.notFound;

      if (notFoundRoute != null) {
        response.write(notFoundRoute.notFoundHandler!(context));
      } else {
        response.writeln('Not found');
      }

      response.close();
      continue;
    }

    // TODO: handle exceptions
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
  }
}

RequestContext _makeRequestContext(HttpRequest request) {
  final HttpRequest(uri: uri, method: methodString) = request;

  final method = HttpMethod.values.firstWhere(
    (method) => method.methodString == methodString,
  );

  final rawBody = request.toList();

  return RequestContext(
    path: uri.path,
    method: method,
    headers: request.headers,
    queryParameters: uri.queryParameters,
    body: rawBody,
  );
}
