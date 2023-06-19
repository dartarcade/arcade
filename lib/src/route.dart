import 'dart:async';

import 'package:dartseid/src/request_context.dart';

// ignore: library_private_types_in_public_api
final List<BaseRoute> routes = [];

typedef RouteHandler<T extends RequestContext> = FutureOr<dynamic> Function(T context);

typedef MiddlewareHandler<T extends RequestContext, U extends RequestContext>
    = FutureOr<U> Function(T context);

class Middleware<T extends RequestContext, U extends RequestContext> {
  final MiddlewareHandler<T, U> handler;

  const Middleware(this.handler);

  FutureOr<U> call(T context) {
    return handler(context);
  }
}

enum HttpMethod {
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

  RouteHandler? get notFoundHandler;

  List<Middleware> get middlewares;

  BaseRoute() {
    routes.add(this);
  }
}

class Route<T extends RequestContext> extends BaseRoute<T> {
  @override
  final HttpMethod? method;
  @override
  final String? path;
  @override
  final RouteHandler<T>? handler;
  @override
  final RouteHandler? notFoundHandler;
  @override
  final List<Middleware> middlewares = [];

  Route._(this.method, this.path, this.handler, [this.notFoundHandler])
      : super();

  factory Route.get(String path, RouteHandler<T> handler) =>
      Route._(HttpMethod.get, path, handler);

  factory Route.post(String path, RouteHandler<T> handler) =>
      Route._(HttpMethod.post, path, handler);

  factory Route.put(String path, RouteHandler<T> handler) =>
      Route._(HttpMethod.put, path, handler);

  factory Route.delete(String path, RouteHandler<T> handler) =>
      Route._(HttpMethod.delete, path, handler);

  factory Route.patch(String path, RouteHandler<T> handler) =>
      Route._(HttpMethod.patch, path, handler);

  factory Route.head(String path, RouteHandler<T> handler) =>
      Route._(HttpMethod.head, path, handler);

  factory Route.options(String path, RouteHandler<T> handler) =>
      Route._(HttpMethod.options, path, handler);

  factory Route.notFound(RouteHandler handler) =>
      Route._(null, null, null, handler);

  Route middleware(Middleware middleware) {
    middlewares.add(middleware);
    return this;
  }
}
