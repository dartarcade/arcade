import 'dart:io';

import 'package:dartseid/dartseid.dart';
import 'package:dartseid/src/helpers/request_helpers.dart';

String _normalizePath(String path) {
  String p = path;

  p = p.replaceAll(RegExp('^/+'), '');
  p = p.replaceAll(RegExp(r'/+$'), '');
  return p;
}

bool routeMatchesPath(String routePath, String path) {
  final routePathSegments = _normalizePath(routePath).split('/');
  final pathSegments = _normalizePath(path).split('/');

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

RequestContext makeRequestContext(HttpRequest request, BaseRoute? route) {
  final HttpRequest(uri: uri, method: methodString) = request;

  final method = getHttpMethod(methodString)!;

  final pathParameters = makePathParameters(route, uri);

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

Map<String, String> makePathParameters(BaseRoute? route, Uri uri) {
  final Map<String, String> pathParameters = {};

  if (route != null) {
    final routePathSegments = route.path?.split('/') ?? [];
    final pathSegments = uri.path.split('/');

    for (var i = 0; i < routePathSegments.length; i++) {
      final routePathSegment = routePathSegments[i];
      final pathSegment = pathSegments[i];

      if (routePathSegment.startsWith(':')) {
        final key = routePathSegment.substring(1);
        pathParameters[key] = Uri.decodeFull(pathSegment);
      }
    }
  }

  return pathParameters;
}

(BaseRoute? route, BaseRoute? notFoundRoute) findMatchingRouteAndNotFoundRoute({
  required List<BaseRoute> routes,
  required HttpMethod method,
  required Uri uri,
}) {
  return routes.fold(
    (null, null),
    (previousValue, route) {
      if (previousValue.$1 != null && previousValue.$2 != null) {
        return previousValue;
      }

      if (previousValue.$1 == null &&
          route.method == method &&
          routeMatchesPath(route.path ?? '', uri.path)) {
        previousValue = (route, previousValue.$2);
      }

      if (previousValue.$2 == null && route.notFoundHandler != null) {
        previousValue = (previousValue.$1, route);
      }

      return previousValue;
    },
  );
}
