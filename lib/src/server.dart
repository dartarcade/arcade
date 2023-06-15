import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dartseid/src/route.dart';

Future<void> runServer() async {
  final server = await HttpServer.bind(
    InternetAddress.anyIPv6,
    8080,
  );

  print('Server running');

  await for (final request in server) {
    final HttpRequest(response: response, method: methodString, uri: uri) =
        request;

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
      (route) => route.method == method && route.path == uri.path,
    );

    if (route == null) {
      final notFoundRoute = routes.firstWhereOrNull(
        (route) => route.notFoundHandler != null,
      );

      response.statusCode = HttpStatus.notFound;

      if (notFoundRoute != null) {
        response.write(notFoundRoute.notFoundHandler!(request));
      } else {
        response.writeln('Not found');
      }

      response.close();
      continue;
    }

    print('Request: $methodString $uri');

    final result = route.handler!(request);
    response.write(result);

    response.close();
  }
}
