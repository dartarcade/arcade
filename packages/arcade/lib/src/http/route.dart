import 'dart:async';

import 'package:arcade/src/core/hooks.dart';
import 'package:arcade/src/core/metadata.dart';
import 'package:arcade/src/helpers/route_helpers.dart';
import 'package:arcade/src/http/request_context.dart';
import 'package:arcade/src/ws/ws.dart';
import 'package:meta/meta.dart';

@internal
final List<BaseRoute> routes = [];

typedef RouteHandler<T extends RequestContext> =
    FutureOr<dynamic> Function(
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

  RouteMetadata? get metadata;

  @override
  String toString() {
    return '$runtimeType(method: $method, path: $path, metadata: $metadata)';
  }
}

@internal
String routeGroupPrefix = '';

class _Route<T extends RequestContext> extends BaseRoute<T> {
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

  @override
  RouteMetadata? metadata;

  _Route._(
    this.method,
    this.path, {
    this.notFoundHandler,
    required this.metadata,
  });
}

class _BeforeRoute<T extends RequestContext> extends _Route<T> {
  _BeforeRoute._(
    super.method,
    super.path,
    List<BeforeHookHandler> beforeHooks, {
    required super.metadata,
  }) : super._() {
    this.beforeHooks.addAll(beforeHooks);
  }

  _BeforeRoute<U> before<U extends RequestContext>(
    BeforeHookHandler<T, U> hook,
  ) {
    beforeHooks.add((context) => hook(context as T));
    currentProcessingRoute =
        _BeforeRoute<U>._(method, path, beforeHooks, metadata: metadata)
          ..handler = handler as RouteHandler<RequestContext>?
          ..wsHandler = wsHandler as WebSocketHandler<RequestContext>?
          ..notFoundHandler = notFoundHandler as RouteHandler<RequestContext>?;
    return currentProcessingRoute! as _BeforeRoute<U>;
  }

  _BeforeRoute<U> beforeAll<U extends RequestContext>(
    List<BeforeHookHandler> hooks,
  ) {
    beforeHooks.addAll(hooks);
    currentProcessingRoute =
        _BeforeRoute<U>._(method, path, beforeHooks, metadata: metadata)
          ..handler = handler as RouteHandler<RequestContext>?
          ..wsHandler = wsHandler as WebSocketHandler<RequestContext>?
          ..notFoundHandler = notFoundHandler as RouteHandler<RequestContext>?;
    return currentProcessingRoute! as _BeforeRoute<U>;
  }

  _AfterRoute<T> handle(RouteHandler<T> handler) {
    this.handler = handler;
    currentProcessingRoute =
        _AfterRoute<T>._(
            method,
            path,
            beforeHooks,
            [],
            metadata: metadata,
          )
          ..handler = handler as RouteHandler<RequestContext>?
          ..wsHandler = wsHandler
          ..notFoundHandler = notFoundHandler as RouteHandler<RequestContext>?;
    return currentProcessingRoute! as _AfterRoute<T>;
  }

  _AfterWebSocketRoute<T> handleWebSocket(
    WebSocketHandler<T> wsHandler, {
    OnConnection<T>? onConnect,
  }) {
    this.wsHandler = wsHandler;
    currentProcessingRoute =
        _AfterWebSocketRoute<T>._(
            method,
            path,
            beforeHooks,
            [],
            metadata: metadata,
          )
          ..wsHandler = wsHandler
          ..onWebSocketConnect = onConnect
          ..notFoundHandler = notFoundHandler as RouteHandler<RequestContext>?;
    return currentProcessingRoute! as _AfterWebSocketRoute<T>;
  }
}

class _AfterRoute<T extends RequestContext> extends _Route<T> {
  _AfterRoute._(
    super.method,
    super.path,
    List<BeforeHookHandler> beforeHooks,
    List<AfterHookHandler> afterHooks, {
    required super.metadata,
  }) : super._() {
    this.beforeHooks.addAll(beforeHooks);
    this.afterHooks.addAll(afterHooks);
  }

  _AfterRoute<U> after<U extends RequestContext, V, W>(
    AfterHookHandler<T, U, V, W> hook,
  ) {
    afterHooks.add(
      (context, handleResult) => hook(context as T, handleResult as V),
    );
    currentProcessingRoute =
        _AfterRoute<U>._(
            method,
            path,
            beforeHooks,
            afterHooks,
            metadata: metadata,
          )
          ..handler = handler as RouteHandler<RequestContext>?
          ..wsHandler = wsHandler as WebSocketHandler<RequestContext>?
          ..notFoundHandler = notFoundHandler as RouteHandler<RequestContext>?;
    return currentProcessingRoute! as _AfterRoute<U>;
  }

  _AfterRoute<U> afterAll<U extends RequestContext>(
    List<AfterHookHandler> hooks,
  ) {
    afterHooks.addAll(hooks);
    currentProcessingRoute =
        _AfterRoute<U>._(
            method,
            path,
            beforeHooks,
            afterHooks,
            metadata: metadata,
          )
          ..handler = handler as RouteHandler<RequestContext>?
          ..wsHandler = wsHandler as WebSocketHandler<RequestContext>?
          ..notFoundHandler = notFoundHandler as RouteHandler<RequestContext>?;
    return currentProcessingRoute! as _AfterRoute<U>;
  }
}

class _AfterWebSocketRoute<T extends RequestContext> extends _Route<T> {
  _AfterWebSocketRoute._(
    super.method,
    super.path,
    List<BeforeHookHandler> beforeHooks,
    List<AfterWebSocketHookHandler> afterWebSocketHooks, {
    required super.metadata,
  }) : super._() {
    this.beforeHooks.addAll(beforeHooks);
    this.afterWebSocketHooks.addAll(afterWebSocketHooks);
  }

  _AfterWebSocketRoute<U> after<U extends RequestContext, V, W>(
    AfterWebSocketHookHandler<T, U, V, W> hook,
  ) {
    afterWebSocketHooks.add(
      (context, handleResult, id) => hook(context as T, handleResult as V, id),
    );
    currentProcessingRoute =
        _AfterWebSocketRoute<U>._(
            method,
            path,
            beforeHooks,
            afterWebSocketHooks,
            metadata: metadata,
          )
          ..handler = handler as RouteHandler<RequestContext>?
          ..wsHandler = wsHandler as WebSocketHandler<RequestContext>?
          ..onWebSocketConnect = onWebSocketConnect as OnConnection<U>?
          ..notFoundHandler = notFoundHandler as RouteHandler<RequestContext>?;
    return currentProcessingRoute! as _AfterWebSocketRoute<U>;
  }

  _AfterRoute<U> afterAll<U extends RequestContext>(
    List<AfterWebSocketHookHandler> hooks,
  ) {
    afterWebSocketHooks.addAll(hooks);
    currentProcessingRoute =
        _AfterRoute<U>._(
            method,
            path,
            beforeHooks,
            afterHooks,
            metadata: metadata,
          )
          ..handler = handler as RouteHandler<RequestContext>?
          ..wsHandler = wsHandler as WebSocketHandler<RequestContext>?
          ..onWebSocketConnect = onWebSocketConnect as OnConnection<U>?
          ..notFoundHandler = notFoundHandler as RouteHandler<RequestContext>?;
    return currentProcessingRoute! as _AfterRoute<U>;
  }
}

final class RouteBuilder<T extends RequestContext> {
  RouteBuilder._();

  @internal
  final Map<String, dynamic> extra = {};

  void registerGlobalBeforeHook(BeforeHookHandler hook) {
    globalBeforeHooks.add(hook);
  }

  void registerAllGlobalBeforeHooks(List<BeforeHookHandler> hooks) {
    globalBeforeHooks.addAll(hooks);
  }

  void registerGlobalAfterHook(AfterHookHandler hook) {
    globalAfterHooks.add(hook);
  }

  void registerAllGlobalAfterHooks(List<AfterHookHandler> hooks) {
    globalAfterHooks.addAll(hooks);
  }

  void registerGlobalAfterWebSocketHook(AfterWebSocketHookHandler hook) {
    globalAfterWebSocketHooks.add(hook);
  }

  void registerAllGlobalAfterWebSocketHooks(
    List<AfterWebSocketHookHandler> hooks,
  ) {
    globalAfterWebSocketHooks.addAll(hooks);
  }

  void addBeforeHookForPath(String path, BeforeHookHandler hook) {
    validatePreviousRouteHasHandler();
    final route = routes.firstWhere((route) => route.path == path);
    route.beforeHooks.add(hook);
  }

  void addAfterHookForPath(String path, AfterHookHandler hook) {
    validatePreviousRouteHasHandler();
    final route = routes.firstWhere((route) => route.path == path);
    route.afterHooks.add(hook);
  }

  void addAfterWebSocketHookForPath(
    String path,
    AfterWebSocketHookHandler hook,
  ) {
    final route = routes.firstWhere((route) => route.path == path);
    route.afterWebSocketHooks.add(hook);
  }

  RouteBuilder<T> withExtra(Map<String, dynamic> extra, {bool merge = true}) {
    if (!merge) {
      this.extra.clear();
    }
    this.extra.addAll(extra);
    return this;
  }

  void group<R extends RequestContext>(
    String path, {
    required FutureOr<void> Function(RouteBuilder<R> Function() route)
    defineRoutes,
    List<BeforeHookHandler> before = const [],
    List<AfterHookHandler> after = const [],
  }) {
    validatePreviousRouteHasHandler();
    final lastRouteIndex = routes.length - 1;
    final previousRouteGroupPrefix = routeGroupPrefix;
    routeGroupPrefix = previousRouteGroupPrefix + path;
    defineRoutes(() => RouteBuilder<R>._());
    routeGroupPrefix = previousRouteGroupPrefix;
    validatePreviousRouteHasHandler();
    routes.sublist(lastRouteIndex + 1).forEach((route) {
      route.beforeHooks.addAll(before);
      route.afterHooks.addAll(after);
    });
  }

  _BeforeRoute<T> any(String path, {Map<String, dynamic>? extra}) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute = _BeforeRoute<T>._(
      HttpMethod.any,
      routeGroupPrefix + path,
      [],
      metadata: RouteMetadata(
        type: 'handler',
        path: routeGroupPrefix + path,
        method: HttpMethod.any,
        extra: _makeExtra(extra),
      ),
    );
    return currentProcessingRoute! as _BeforeRoute<T>;
  }

  _BeforeRoute<T> get(String path, {Map<String, dynamic>? extra}) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute = _BeforeRoute<T>._(
      HttpMethod.get,
      routeGroupPrefix + path,
      [],
      metadata: RouteMetadata(
        type: 'handler',
        path: routeGroupPrefix + path,
        method: HttpMethod.get,
        extra: _makeExtra(extra),
      ),
    );
    return currentProcessingRoute! as _BeforeRoute<T>;
  }

  _BeforeRoute<T> post(String path, {Map<String, dynamic>? extra}) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute = _BeforeRoute<T>._(
      HttpMethod.post,
      routeGroupPrefix + path,
      [],
      metadata: RouteMetadata(
        type: 'handler',
        path: routeGroupPrefix + path,
        method: HttpMethod.post,
        extra: _makeExtra(extra),
      ),
    );
    return currentProcessingRoute! as _BeforeRoute<T>;
  }

  _BeforeRoute<T> put(String path, {Map<String, dynamic>? extra}) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute = _BeforeRoute<T>._(
      HttpMethod.put,
      routeGroupPrefix + path,
      [],
      metadata: RouteMetadata(
        type: 'handler',
        path: routeGroupPrefix + path,
        method: HttpMethod.put,
        extra: _makeExtra(extra),
      ),
    );
    return currentProcessingRoute! as _BeforeRoute<T>;
  }

  _BeforeRoute<T> delete(String path, {Map<String, dynamic>? extra}) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute = _BeforeRoute<T>._(
      HttpMethod.delete,
      routeGroupPrefix + path,
      [],
      metadata: RouteMetadata(
        type: 'handler',
        path: routeGroupPrefix + path,
        method: HttpMethod.delete,
        extra: _makeExtra(extra),
      ),
    );
    return currentProcessingRoute! as _BeforeRoute<T>;
  }

  _BeforeRoute<T> patch(String path, {Map<String, dynamic>? extra}) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute = _BeforeRoute<T>._(
      HttpMethod.patch,
      routeGroupPrefix + path,
      [],
      metadata: RouteMetadata(
        type: 'handler',
        path: routeGroupPrefix + path,
        method: HttpMethod.patch,
        extra: _makeExtra(extra),
      ),
    );
    return currentProcessingRoute! as _BeforeRoute<T>;
  }

  _BeforeRoute<T> head(String path, {Map<String, dynamic>? extra}) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute = _BeforeRoute<T>._(
      HttpMethod.head,
      routeGroupPrefix + path,
      [],
      metadata: RouteMetadata(
        type: 'handler',
        path: routeGroupPrefix + path,
        method: HttpMethod.head,
        extra: _makeExtra(extra),
      ),
    );
    return currentProcessingRoute! as _BeforeRoute<T>;
  }

  _BeforeRoute<T> options(String path, {Map<String, dynamic>? extra}) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute = _BeforeRoute<T>._(
      HttpMethod.options,
      routeGroupPrefix + path,
      [],
      metadata: RouteMetadata(
        type: 'handler',
        path: routeGroupPrefix + path,
        method: HttpMethod.options,
        extra: _makeExtra(extra),
      ),
    );
    return currentProcessingRoute! as _BeforeRoute<T>;
  }

  _AfterRoute notFound(RouteHandler handler, {Map<String, dynamic>? extra}) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute = _AfterRoute<T>._(
      null,
      '',
      [],
      [],
      metadata: RouteMetadata(
        type: 'notFound',
        path: '',
        method: HttpMethod.any,
        extra: _makeExtra(extra),
      ),
    )..notFoundHandler = handler;
    return currentProcessingRoute! as _AfterRoute;
  }

  Map<String, dynamic>? _makeExtra(Map<String, dynamic>? extraParam) {
    if (extraParam == null && extra.isEmpty) {
      return null;
    }
    return {...extra, ...?extraParam};
  }
}

RouteBuilder<RequestContext> get route => RouteBuilder._();
