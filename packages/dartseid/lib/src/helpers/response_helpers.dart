import 'dart:convert';
import 'dart:io';

import 'package:dartseid/dartseid.dart';
import 'package:dartseid_logger/dartseid_logger.dart';

void sendErrorResponse(HttpResponse response, DartseidHttpException error) {
  response.statusCode = error.statusCode;
  response.headers.contentType = ContentType.json;
  response.writeln(jsonEncode(error.toJson()));
  response.close();
}

Future<RequestContext> runBeforeHooks(
  RequestContext context,
  BaseRoute route,
) async {
  var ctx = context;

  for (final hook in route.beforeHooks) {
    ctx = await hook(ctx);
  }

  return ctx;
}

Future<({RequestContext context, Object? handleResult})> runAfterHooks(
  RequestContext context,
  BaseRoute route,
  dynamic result,
) async {
  var (ctx, r) = (context, result);

  for (final hook in route.afterHooks) {
    final (newCtx, newR) = await hook(ctx, r);
    ctx = newCtx;
    r = newR;
  }

  return (context: ctx, handleResult: r);
}

Future<({RequestContext context, Object? handleResult, String wsId})>
    runAfterWebSocketHooks(
  RequestContext context,
  BaseRoute route,
  dynamic result,
  String wsId,
) async {
  var (ctx, r, id) = (context, result, wsId);

  for (final hook in route.afterWebSocketHooks) {
    final (newCtx, newR, newId) = await hook(ctx, r, id);
    ctx = newCtx;
    r = newR;
    id = newId;
  }

  return (context: ctx, handleResult: r, wsId: id);
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
      Logger.root.error('$e\n$s');
      return sendErrorResponse(response, e);
    } catch (e, s) {
      Logger.root.error('$e\n$s');
      return sendErrorResponse(response, const InternalServerErrorException());
    }
  }
}

Future<void> writeResponse({
  required RequestContext context,
  required BaseRoute route,
  required HttpResponse response,
}) async {
  var ctx = await runBeforeHooks(context, route);

  var result = route.handler!(ctx);
  if (result is Future) {
    result = await result;
  }

  final (context: newCtx, handleResult: newResult) =
      await runAfterHooks(ctx, route, result);
  ctx = newCtx;
  result = newResult;

  if (result is String) {
    response.headers.contentType = ContentType.html;
  } else {
    result = jsonEncode(result);
    response.headers.contentType = ContentType.json;
  }

  response.write(result);

  response.close();
}
