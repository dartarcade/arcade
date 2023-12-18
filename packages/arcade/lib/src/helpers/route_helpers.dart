import 'package:arcade/src/http/route.dart';

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
    
    if (routePathSegment == '*') {
      return true;
    }

    if (routePathSegment.startsWith(':')) {
      continue;
    }

    if (routePathSegment != pathSegment) {
      return false;
    }
  }

  return true;
}

Map<String, String> makePathParameters(BaseRoute? route, Uri uri) {
  final Map<String, String> pathParameters = {};

  if (route != null) {
    final routePathSegments = _normalizePath(route.path).split('/') ?? [];
    final pathSegments = _normalizePath(uri.path).split('/');

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

      final methodMatches =
          route.method == method || route.method == HttpMethod.any;

      if (route.path == '*' && methodMatches) {
        previousValue = (route, previousValue.$2);
      }

      if (previousValue.$1 == null &&
          methodMatches &&
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

BaseRoute? currentProcessingRoute;

void validatePreviousRouteHasHandler() {
  if (currentProcessingRoute != null) {
    routes.add(currentProcessingRoute!);
    currentProcessingRoute = null;
  }

  final previousRoute = routes.lastOrNull;
  if (previousRoute == null || previousRoute.notFoundHandler != null) return;

  if (previousRoute.handler == null && previousRoute.wsHandler == null) {
    throw StateError(
      '${previousRoute.method!.name} ${previousRoute.path} must have a handler or wsHandler',
    );
  }
}
