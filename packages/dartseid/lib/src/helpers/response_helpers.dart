import 'dart:convert';
import 'dart:io';

import 'package:dartseid/dartseid.dart';

void methodNotAllowed(HttpResponse response) {
  response.statusCode = HttpStatus.methodNotAllowed;
  response.writeln('Method not allowed');
  response.close();
}

void notFound(HttpResponse response) {
  response.statusCode = HttpStatus.notFound;
  response.writeln('Not found');
  response.close();
}

void internalServerError(HttpResponse response) {
  response.statusCode = HttpStatus.internalServerError;
  response.writeln('Internal server error');
  response.close();
}

Future runMiddleware(
  RequestContext context,
  BaseRoute route,
) async {
  var ctx = context;

  for (final middleware in route.middlewares) {
    ctx = await middleware(ctx);
  }

  return ctx;
}

void writeNotFoundResponse({
  required RequestContext context,
  required HttpResponse response,
  required RouteHandler? notFoundRouteHandler,
}) {
  response.statusCode = HttpStatus.notFound;

  if (notFoundRouteHandler != null) {
    try {
      return response.write(notFoundRouteHandler(context));
    } catch (e, s) {
      print('$e\n$s');
      return internalServerError(response);
    }
  }

  return notFound(response);
}

Future<void> writeResponse({
  required RequestContext context,
  required BaseRoute route,
  required HttpResponse response,
}) async {
  try {
    final ctx = await runMiddleware(context, route);

    var result = route.handler!(ctx);

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
    return internalServerError(response);
  }
}
