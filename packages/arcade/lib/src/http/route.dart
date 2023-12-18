import 'dart:async';

import 'package:arcade/src/core/hooks.dart';
import 'package:arcade/src/helpers/route_helpers.dart';
import 'package:arcade/src/http/request_context.dart';
import 'package:arcade/src/ws/ws.dart';

final List<BaseRoute> routes = [];

typedef RouteHandler<T extends RequestContext> = FutureOr<dynamic> Function(
  T context,
);

enum HttpMethod {
  any('ANY'),
  get('GET'),
  post('POST'),
  put('PUT'),
  delete('DELETE'),
  patch('PATCH'),
  head('HEAD'),
  options('OPTIONS');

  final String methodString;

  const HttpMethod(this.methodString);
}

abstract class BaseRoute<T extends RequestContext> {
  HttpMethod? get method;

  String get path;

  RouteHandler<T>? get handler;

  WebSocketHandler<T>? get wsHandler;

  RouteHandler<T>? get notFoundHandler;

  List<BeforeHookHandler> get beforeHooks;

  List<AfterHookHandler> get afterHooks;

  List<AfterWebSocketHookHandler> get afterWebSocketHooks;

  OnConnection<T>? get onWebSocketConnect;

  @override
  String toString() {
    return '$runtimeType(method: $method, path: $path)';
  }
}

String _routeGroupPrefix = '';

class Route<T extends RequestContext> extends BaseRoute<T> {
  @override
  final HttpMethod? method;

  @override
  final String path;

  @override
  RouteHandler<T>? handler;

  @override
  WebSocketHandler<T>? wsHandler;

  @override
  RouteHandler<T>? notFoundHandler;

  @override
  final List<BeforeHookHandler> beforeHooks = [];

  @override
  final List<AfterHookHandler> afterHooks = [];

  @override
  final List<AfterWebSocketHookHandler> afterWebSocketHooks = [];

  @override
  OnConnection<T>? onWebSocketConnect;

  Route._(this.method, this.path, {this.notFoundHandler});

  static void group(
    String path, {
    required FutureOr<void> Function() routes,
    List<BeforeHookHandler> before = const [],
    List<AfterHookHandler> after = const [],
  }) {
    validatePreviousRouteHasHandler();
    final lastRouteIndex = routes.length - 1;
    final previousRouteGroupPrefix = _routeGroupPrefix;
    _routeGroupPrefix = previousRouteGroupPrefix + path;
    callback();
    _routeGroupPrefix = previousRouteGroupPrefix;
    validatePreviousRouteHasHandler();
    routes.sublist(lastRouteIndex + 1).forEach((route) {
      route.beforeHooks.addAll(before);
      route.afterHooks.addAll(after);
    });
  }

  static BeforeRoute any(String path) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute =
        BeforeRoute._(HttpMethod.any, _routeGroupPrefix + path, []);
    return currentProcessingRoute! as BeforeRoute;
  }

  static BeforeRoute get(String path) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute =
        BeforeRoute._(HttpMethod.get, _routeGroupPrefix + path, []);
    return currentProcessingRoute! as BeforeRoute;
  }

  static BeforeRoute post(String path) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute =
        BeforeRoute._(HttpMethod.post, _routeGroupPrefix + path, []);
    return currentProcessingRoute! as BeforeRoute;
  }

  static BeforeRoute put(String path) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute =
        BeforeRoute._(HttpMethod.put, _routeGroupPrefix + path, []);
    return currentProcessingRoute! as BeforeRoute;
  }

  static BeforeRoute delete(String path) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute =
        BeforeRoute._(HttpMethod.delete, _routeGroupPrefix + path, []);
    return currentProcessingRoute! as BeforeRoute;
  }

  static BeforeRoute patch(String path) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute =
        BeforeRoute._(HttpMethod.patch, _routeGroupPrefix + path, []);
    return currentProcessingRoute! as BeforeRoute;
  }

  static BeforeRoute head(String path) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute =
        BeforeRoute._(HttpMethod.head, _routeGroupPrefix + path, []);
    return currentProcessingRoute! as BeforeRoute;
  }

  static BeforeRoute options(String path) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute =
        BeforeRoute._(HttpMethod.options, _routeGroupPrefix + path, []);
    return currentProcessingRoute! as BeforeRoute;
  }

  static AfterRoute notFound<T extends RequestContext>(
    RouteHandler<T> handler,
  ) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute = AfterRoute<T>._(null, '', [], [])
      ..notFoundHandler = handler;
    return currentProcessingRoute! as AfterRoute;
  }
}

class BeforeRoute<T extends RequestContext> extends Route<T> {
  BeforeRoute._(super.method, super.path, List<BeforeHookHandler> beforeHooks)
      : super._() {
    this.beforeHooks.addAll(beforeHooks);
  }

  BeforeRoute<U> before<U extends RequestContext>(
    BeforeHookHandler<T, U> hook,
  ) {
    beforeHooks.add((context) => hook(context as T));
    currentProcessingRoute = BeforeRoute<U>._(method, path, beforeHooks)
      ..handler = handler as RouteHandler<RequestContext>?
      ..wsHandler = wsHandler as WebSocketHandler<RequestContext>?
      ..notFoundHandler = notFoundHandler as RouteHandler<RequestContext>?;
    return currentProcessingRoute! as BeforeRoute<U>;
  }

  BeforeRoute<U> beforeAll<U extends RequestContext>(
    List<BeforeHookHandler> hooks,
  ) {
    beforeHooks.addAll(hooks);
    currentProcessingRoute = BeforeRoute<U>._(method, path, beforeHooks)
      ..handler = handler as RouteHandler<RequestContext>?
      ..wsHandler = wsHandler as WebSocketHandler<RequestContext>?
      ..notFoundHandler = notFoundHandler as RouteHandler<RequestContext>?;
    return currentProcessingRoute! as BeforeRoute<U>;
  }

  AfterRoute<T> handle(RouteHandler<T> handler) {
    this.handler = handler;
    currentProcessingRoute = AfterRoute<T>._(method, path, beforeHooks, [])
      ..handler = handler as RouteHandler<RequestContext>?
      ..wsHandler = wsHandler
      ..notFoundHandler = notFoundHandler as RouteHandler<RequestContext>?;
    return currentProcessingRoute! as AfterRoute<T>;
  }

  AfterWebSocketRoute<T> handleWebSocket(
    WebSocketHandler<T> wsHandler, {
    OnConnection<T>? onConnect,
  }) {
    this.wsHandler = wsHandler;
    currentProcessingRoute =
        AfterWebSocketRoute<T>._(method, path, beforeHooks, [])
          ..wsHandler = wsHandler
          ..onWebSocketConnect = onConnect
          ..notFoundHandler = notFoundHandler as RouteHandler<RequestContext>?;
    return currentProcessingRoute! as AfterWebSocketRoute<T>;
  }
}

class AfterRoute<T extends RequestContext> extends Route<T> {
  AfterRoute._(
    super.method,
    super.path,
    List<BeforeHookHandler> beforeHooks,
    List<AfterHookHandler> afterHooks,
  ) : super._() {
    this.beforeHooks.addAll(beforeHooks);
    this.afterHooks.addAll(afterHooks);
  }

  AfterRoute<U> after<U extends RequestContext, V, W>(
    AfterHookHandler<T, U, V, W> hook,
  ) {
    afterHooks
        .add((context, handleResult) => hook(context as T, handleResult as V));
    currentProcessingRoute =
        AfterRoute<U>._(method, path, beforeHooks, afterHooks)
          ..handler = handler as RouteHandler<RequestContext>?
          ..wsHandler = wsHandler as WebSocketHandler<RequestContext>?
          ..notFoundHandler = notFoundHandler as RouteHandler<RequestContext>?;
    return currentProcessingRoute! as AfterRoute<U>;
  }

  AfterRoute<U> afterAll<U extends RequestContext>(
    List<AfterHookHandler> hooks,
  ) {
    afterHooks.addAll(hooks);
    currentProcessingRoute =
        AfterRoute<U>._(method, path, beforeHooks, afterHooks)
          ..handler = handler as RouteHandler<RequestContext>?
          ..wsHandler = wsHandler as WebSocketHandler<RequestContext>?
          ..notFoundHandler = notFoundHandler as RouteHandler<RequestContext>?;
    return currentProcessingRoute! as AfterRoute<U>;
  }
}

class AfterWebSocketRoute<T extends RequestContext> extends Route<T> {
  AfterWebSocketRoute._(
    super.method,
    super.path,
    List<BeforeHookHandler> beforeHooks,
    List<AfterWebSocketHookHandler> afterWebSocketHooks,
  ) : super._() {
    this.beforeHooks.addAll(beforeHooks);
    this.afterWebSocketHooks.addAll(afterWebSocketHooks);
  }

  AfterWebSocketRoute<U> after<U extends RequestContext, V, W>(
    AfterWebSocketHookHandler<T, U, V, W> hook,
  ) {
    afterWebSocketHooks.add(
      (context, handleResult, id) => hook(context as T, handleResult as V, id),
    );
    currentProcessingRoute =
        AfterWebSocketRoute<U>._(method, path, beforeHooks, afterWebSocketHooks)
          ..handler = handler as RouteHandler<RequestContext>?
          ..wsHandler = wsHandler as WebSocketHandler<RequestContext>?
          ..onWebSocketConnect = onWebSocketConnect as OnConnection<U>?
          ..notFoundHandler = notFoundHandler as RouteHandler<RequestContext>?;
    return currentProcessingRoute! as AfterWebSocketRoute<U>;
  }

  AfterRoute<U> afterAll<U extends RequestContext>(
    List<AfterWebSocketHookHandler> hooks,
  ) {
    afterWebSocketHooks.addAll(hooks);
    currentProcessingRoute =
        AfterRoute<U>._(method, path, beforeHooks, afterHooks)
          ..handler = handler as RouteHandler<RequestContext>?
          ..wsHandler = wsHandler as WebSocketHandler<RequestContext>?
          ..onWebSocketConnect = onWebSocketConnect as OnConnection<U>?
          ..notFoundHandler = notFoundHandler as RouteHandler<RequestContext>?;
    return currentProcessingRoute! as AfterRoute<U>;
  }
}
