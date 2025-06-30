import 'package:arcade/arcade.dart';
import 'package:meta/meta.dart';

/// Cache for normalized paths to avoid repeated regex operations
@internal
final Map<String, String> normalizedPathCache = {};

/// Pre-compiled regex patterns for better performance
final RegExp _leadingSlashPattern = RegExp('^/+');
final RegExp _trailingSlashPattern = RegExp(r'/+$');

String _normalizePath(String path) {
  // Check cache first
  final cached = normalizedPathCache[path];
  if (cached != null) return cached;

  // Fast path for already normalized paths
  if (path.isEmpty ||
      (path != '/' && !path.startsWith('/') && !path.endsWith('/'))) {
    normalizedPathCache[path] = path;
    return path;
  }

  // Normalize and cache
  String normalized = path;
  normalized = normalized.replaceAll(_leadingSlashPattern, '');
  normalized = normalized.replaceAll(_trailingSlashPattern, '');

  // Limit cache size to prevent memory leaks
  if (normalizedPathCache.length > 1000) {
    normalizedPathCache.clear();
  }

  normalizedPathCache[path] = normalized;
  return normalized;
}

@internal
class TrieNode {
  final Map<String, TrieNode> children = {};
  final Map<String, TrieNode> paramChildren = {};
  TrieNode? wildcardChild;
  BaseRoute? route;
  String? paramName;

  bool get isLeaf => route != null;
}

@internal
class RadixTrie {
  final TrieNode _root = TrieNode();

  void insert(BaseRoute route) {
    final segments = _normalizePath(route.path).split('/');
    TrieNode current = _root;

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];

      if (segment == '*') {
        current.wildcardChild ??= TrieNode();
        current = current.wildcardChild!;
        break;
      } else if (segment.startsWith(':')) {
        final paramName = segment.substring(1);
        current.paramChildren[paramName] ??= TrieNode()..paramName = paramName;
        current = current.paramChildren[paramName]!;
      } else {
        current.children[segment] ??= TrieNode();
        current = current.children[segment]!;
      }
    }

    current.route = route;
  }

  BaseRoute? search(String path) {
    final segments = _normalizePath(path).split('/');
    final result = _searchRecursive(_root, segments, 0, {});
    return result.$1;
  }

  (BaseRoute?, Map<String, String>) searchWithParams(String path) {
    final segments = _normalizePath(path).split('/');
    return _searchRecursive(_root, segments, 0, {});
  }

  (BaseRoute?, Map<String, String>) _searchRecursive(
    TrieNode node,
    List<String> segments,
    int index,
    Map<String, String> params,
  ) {
    if (index >= segments.length) {
      return (node.route, params);
    }

    final segment = segments[index];

    // Try exact match first
    final exactChild = node.children[segment];
    if (exactChild != null) {
      final result = _searchRecursive(exactChild, segments, index + 1, params);
      if (result.$1 != null) return result;
    }

    // Try parameter match
    for (final paramChild in node.paramChildren.values) {
      final newParams = Map<String, String>.from(params);
      newParams[paramChild.paramName!] = Uri.decodeFull(segment);
      final result =
          _searchRecursive(paramChild, segments, index + 1, newParams);
      if (result.$1 != null) return result;
    }

    // Try wildcard match
    if (node.wildcardChild != null) {
      return (node.wildcardChild!.route, params);
    }

    return (null, {});
  }

  void clear() {
    _root.children.clear();
    _root.paramChildren.clear();
    _root.wildcardChild = null;
    _root.route = null;
  }
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

/// Optimized path parameter extraction using pre-computed parameters from route matching
Map<String, String> makePathParameters(BaseRoute? route, Uri uri) {
  // Try to get parameters from optimized route matching first
  final result = optimizedRouter.findRouteWithParams(
    method: route?.method ?? HttpMethod.any,
    uri: uri,
  );

  if (result.$1 == route && result.$3.isNotEmpty) {
    return result.$3;
  }

  // Fallback to original implementation for backward compatibility
  final Map<String, String> pathParameters = {};

  if (route != null) {
    final routePathSegments = _normalizePath(route.path).split('/');
    final pathSegments = _normalizePath(uri.path).split('/');

    for (var i = 0;
        i < routePathSegments.length && i < pathSegments.length;
        i++) {
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
  return optimizedRouter.findRoute(method: method, uri: uri);
}

/// Invalidates the route cache when routes are modified.
/// Call this whenever routes are added, removed, or changed.
@internal
void invalidateRouteCache() {
  optimizedRouter.invalidate();
  normalizedPathCache.clear();
}

/// Exposes optimized route finding with path parameters for external use
(BaseRoute? route, BaseRoute? notFoundRoute, Map<String, String> pathParams)
    findRouteWithPathParams({
  required HttpMethod method,
  required Uri uri,
}) {
  return optimizedRouter.findRouteWithParams(method: method, uri: uri);
}

@internal
class OptimizedRouter {
  final Map<HttpMethod, RadixTrie> _triesByMethod = {};
  BaseRoute? _cachedNotFoundRoute;
  bool _isBuilt = false;

  void _buildIndex() {
    if (_isBuilt) return;

    _triesByMethod.clear();
    _cachedNotFoundRoute = null;

    for (final route in routes) {
      final method = route.method ?? HttpMethod.any;

      // Cache the first notFoundHandler we find
      _cachedNotFoundRoute ??= route.notFoundHandler != null ? route : null;

      // Add all routes to trie (handles both static and dynamic)
      _triesByMethod.putIfAbsent(method, () => RadixTrie()).insert(route);

      // Also add to 'any' method for routes that accept any method
      if (method != HttpMethod.any) {
        _triesByMethod
            .putIfAbsent(HttpMethod.any, () => RadixTrie())
            .insert(route);
      }
    }

    _isBuilt = true;
  }

  void invalidate() {
    _isBuilt = false;
    _cachedNotFoundRoute = null;
    for (final trie in _triesByMethod.values) {
      trie.clear();
    }
    _triesByMethod.clear();
  }

  (BaseRoute? route, BaseRoute? notFoundRoute, Map<String, String> pathParams)
      findRouteWithParams({
    required HttpMethod method,
    required Uri uri,
  }) {
    _buildIndex();

    // Try method-specific trie first
    final methodTrie = _triesByMethod[method];
    if (methodTrie != null) {
      final result = methodTrie.searchWithParams(uri.path);
      if (result.$1 != null) {
        return (result.$1, null, result.$2);
      }
    }

    // Try 'any' method trie if not found
    if (method != HttpMethod.any) {
      final anyTrie = _triesByMethod[HttpMethod.any];
      if (anyTrie != null) {
        final result = anyTrie.searchWithParams(uri.path);
        if (result.$1 != null) {
          return (result.$1, null, result.$2);
        }
      }
    }

    return (null, _cachedNotFoundRoute, {});
  }

  // Backward compatibility method
  (BaseRoute? route, BaseRoute? notFoundRoute) findRoute({
    required HttpMethod method,
    required Uri uri,
  }) {
    final result = findRouteWithParams(method: method, uri: uri);
    return (result.$1, result.$2);
  }
}

@internal
final optimizedRouter = OptimizedRouter();

@internal
final List<BeforeHookHandler> globalBeforeHooks = [];
@internal
final List<AfterHookHandler> globalAfterHooks = [];
@internal
final List<AfterWebSocketHookHandler> globalAfterWebSocketHooks = [];

@internal
BaseRoute? currentProcessingRoute;

void validatePreviousRouteHasHandler() {
  if (currentProcessingRoute != null) {
    routes.add(currentProcessingRoute!);
    invalidateRouteCache();
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
