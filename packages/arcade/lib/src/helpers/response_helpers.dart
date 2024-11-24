import 'dart:convert';
import 'dart:io';

import 'package:arcade/arcade.dart';
import 'package:arcade/src/helpers/route_helpers.dart';
import 'package:arcade_logger/arcade_logger.dart';

void _setContentType(HttpResponse response, Object? result) {
  if (response.headers.contentType?.mimeType != ContentType.text.mimeType) {
    return;
  }

  if (result is String) {
    response.headers.set(
      HttpHeaders.contentTypeHeader,
      ContentType.html.mimeType,
    );
  } else {
    response.headers.set(
      HttpHeaders.contentTypeHeader,
      ContentType.json.mimeType,
    );
  }
}

void setResponse(HttpResponse response, Object? result) {
  late String resultStr;

  if (result == null) {
    resultStr = '';
  }

  _setContentType(response, result);

  if (result is! String) {
    resultStr = jsonEncode(result);
  } else {
    resultStr = result;
  }

  response.write(resultStr);
}

Future<void> setErrorResponse(
  RequestContext? context,
  HttpResponse response,
  ArcadeHttpException error, {
  StackTrace? stackTrace,
  BaseRoute? notFoundRoute,
  bool shouldRunErrorHandler = true,
}) async {
  response.statusCode = error.statusCode;

  try {
    late final Object? errorResponse;
    if (error is NotFoundException &&
        notFoundRoute != null &&
        context != null) {
      errorResponse = await notFoundRoute.notFoundHandler!(context);
    } else if (shouldRunErrorHandler &&
        errorHandler != null &&
        context != null) {
      errorResponse = await errorHandler!(
        context,
        error,
        stackTrace ?? StackTrace.current,
      );
    } else {
      errorResponse = {
        'error': error,
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      };
    }

    setResponse(response, errorResponse);
  } on ArcadeHttpException catch (e, s) {
    Logger.root.error('$e\n$s');
    setErrorResponse(
      null,
      response,
      e,
      stackTrace: isDev ? s : null,
      shouldRunErrorHandler: false,
    );
  } catch (e, s) {
    Logger.root.error('$e\n$s');
    setErrorResponse(
      null,
      response,
      const InternalServerErrorException(),
      stackTrace: isDev ? s : null,
      shouldRunErrorHandler: false,
    );
  }
}

Future<RequestContext> runBeforeHooks(
  RequestContext context,
  BaseRoute route,
) async {
  var ctx = context;

  for (final globalHook in globalBeforeHooks) {
    ctx = await globalHook(ctx);
  }

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

  for (final globalHook in globalAfterHooks) {
    final (newCtx, newR) = await globalHook(ctx, r);
    ctx = newCtx;
    r = newR;
  }

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

  for (final globalHook in globalAfterWebSocketHooks) {
    final (newCtx, newR, newId) = await globalHook(ctx, r, id);
    ctx = newCtx;
    r = newR;
    id = newId;
  }

  for (final hook in route.afterWebSocketHooks) {
    final (newCtx, newR, newId) = await hook(ctx, r, id);
    ctx = newCtx;
    r = newR;
    id = newId;
  }

  return (context: ctx, handleResult: r, wsId: id);
}

Future<void> writeNotFoundResponse({
  required RequestContext context,
  required HttpResponse response,
  required BaseRoute? notFoundRoute,
}) async {
  response.statusCode = HttpStatus.notFound;

  if (notFoundRoute != null) {
    try {
      response.write(notFoundRoute.notFoundHandler!(context));
      response.close();
      return;
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

  await response.close();
}

Future<void> writeErrorResponse(
  RequestContext? context,
  HttpResponse response,
  ArcadeHttpException error, {
  StackTrace? stackTrace,
  BaseRoute? notFoundRoute,
}) async {
  await setErrorResponse(
    context,
    response,
    error,
    stackTrace: isDev ? stackTrace : null,
    notFoundRoute: notFoundRoute,
  );
  await response.close();
}
