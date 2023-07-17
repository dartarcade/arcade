import 'dart:async';

import 'package:dartseid/src/helpers/route_helpers.dart';
import 'package:dartseid/src/http/hooks.dart';
import 'package:dartseid/src/http/request_context.dart';

// ignore: library_private_types_in_public_api
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

  String? get path;

  RouteHandler<T>? get handler;

  RouteHandler<T>? get notFoundHandler;

  List<BeforeHookHandler> get beforeHooks;

  List<AfterHookHandler> get afterHooks;

  @override
  String toString() {
    return '$runtimeType(method: $method, path: $path)';
  }
}

class Route<T extends RequestContext> extends BaseRoute<T> {
  @override
  final HttpMethod? method;
  @override
  final String? path;
  @override
  RouteHandler<T>? handler;
  @override
  RouteHandler<T>? notFoundHandler;
  @override
  final List<BeforeHookHandler> beforeHooks = [];
  @override
  final List<AfterHookHandler> afterHooks = [];

  Route._(this.method, this.path, {this.notFoundHandler});

  static BeforeRoute any(String path) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute = BeforeRoute._(HttpMethod.any, path, []);
    return currentProcessingRoute! as BeforeRoute;
  }

  static BeforeRoute get(String path) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute = BeforeRoute._(HttpMethod.get, path, []);
    return currentProcessingRoute! as BeforeRoute;
  }

  static BeforeRoute post(String path) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute = BeforeRoute._(HttpMethod.post, path, []);
    return currentProcessingRoute! as BeforeRoute;
  }

  static BeforeRoute put(String path) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute = BeforeRoute._(HttpMethod.put, path, []);
    return currentProcessingRoute! as BeforeRoute;
  }

  static BeforeRoute delete(String path) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute = BeforeRoute._(HttpMethod.delete, path, []);
    return currentProcessingRoute! as BeforeRoute;
  }

  static BeforeRoute patch(String path) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute = BeforeRoute._(HttpMethod.patch, path, []);
    return currentProcessingRoute! as BeforeRoute;
  }

  static BeforeRoute head(String path) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute = BeforeRoute._(HttpMethod.head, path, []);
    return currentProcessingRoute! as BeforeRoute;
  }

  static BeforeRoute options(String path) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute = BeforeRoute._(HttpMethod.options, path, []);
    return currentProcessingRoute! as BeforeRoute;
  }

  static AfterRoute notFound<T extends RequestContext>(
    RouteHandler<T> handler,
  ) {
    validatePreviousRouteHasHandler();
    currentProcessingRoute = AfterRoute<T>._(null, null, [], [])
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
      ..notFoundHandler = notFoundHandler as RouteHandler<RequestContext>?;
    return currentProcessingRoute! as BeforeRoute<U>;
  }

  BeforeRoute<U> beforeAll<U extends RequestContext>(
    List<BeforeHookHandler> hooks,
  ) {
    beforeHooks.addAll(hooks);
    currentProcessingRoute = BeforeRoute<U>._(method, path, beforeHooks)
      ..handler = handler as RouteHandler<RequestContext>?
      ..notFoundHandler = notFoundHandler as RouteHandler<RequestContext>?;
    return currentProcessingRoute! as BeforeRoute<U>;
  }

  AfterRoute<T> handle(RouteHandler<T> handler) {
    this.handler = handler;
    currentProcessingRoute = AfterRoute<T>._(method, path, beforeHooks, [])
      ..handler = handler as RouteHandler<RequestContext>?
      ..notFoundHandler = notFoundHandler as RouteHandler<RequestContext>?;
    return currentProcessingRoute! as AfterRoute<T>;
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
          ..notFoundHandler = notFoundHandler as RouteHandler<RequestContext>?;
    return currentProcessingRoute! as AfterRoute<U>;
  }
}
