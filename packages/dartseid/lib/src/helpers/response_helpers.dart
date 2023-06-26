import 'dart:convert';
import 'dart:io';

import 'package:dartseid/dartseid.dart';

void sendErrorResponse(HttpResponse response, DartseidHttpException error) {
  response.statusCode = error.statusCode;
  response.headers.contentType = ContentType.json;
  response.writeln(jsonEncode(error.toJson()));
  response.close();
}

Future<dynamic> runMiddleware(
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
      response.write(notFoundRouteHandler(context));
      response.close();
      return;
    } on DartseidHttpException catch (e, s) {
      logger.error('$e\n$s');
      return sendErrorResponse(response, e);
    } catch (e, s) {
      logger.error('$e\n$s');
      return sendErrorResponse(response, const InternalServerErrorException());
    }
  }
}

Future<void> writeResponse({
  required RequestContext context,
  required BaseRoute route,
  required HttpResponse response,
}) async {
  try {
    final ctx = await runMiddleware(context, route);

    // ignore: argument_type_not_assignable
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
  } on DartseidHttpException catch (e, s) {
    logger.error('$e\n$s');
    return sendErrorResponse(response, e);
  } catch (e, s) {
    logger.error('$e\n$s');
    return sendErrorResponse(response, const InternalServerErrorException());
  }
}
