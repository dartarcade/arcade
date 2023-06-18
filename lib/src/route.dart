import 'package:dartseid/src/request_context.dart';

// ignore: library_private_types_in_public_api
final List<BaseRoute> routes = [];

typedef RouteHandler<T> = T Function(RequestContext context);

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

abstract class BaseRoute {
  HttpMethod? get method;

  String? get path;

  RouteHandler? get handler;

  RouteHandler? get notFoundHandler;

  List<RouteHandler> get middlewares;

  BaseRoute() {
    routes.add(this);
  }
}

class Route extends BaseRoute {
  @override
  final HttpMethod? method;
  @override
  final String? path;
  @override
  final RouteHandler? handler;
  @override
  final RouteHandler? notFoundHandler;
  @override
  final List<RouteHandler> middlewares = [];

  Route._(this.method, this.path, this.handler, [this.notFoundHandler])
      : super();

  factory Route.get(String path, RouteHandler handler) =>
      Route._(HttpMethod.get, path, handler);

  factory Route.post(String path, RouteHandler handler) =>
      Route._(HttpMethod.post, path, handler);

  factory Route.put(String path, RouteHandler handler) =>
      Route._(HttpMethod.put, path, handler);

  factory Route.delete(String path, RouteHandler handler) =>
      Route._(HttpMethod.delete, path, handler);

  factory Route.patch(String path, RouteHandler handler) =>
      Route._(HttpMethod.patch, path, handler);

  factory Route.head(String path, RouteHandler handler) =>
      Route._(HttpMethod.head, path, handler);

  factory Route.options(String path, RouteHandler handler) =>
      Route._(HttpMethod.options, path, handler);

  factory Route.notFound(RouteHandler handler) =>
      Route._(null, null, null, handler);

  Route middleware(RouteHandler middleware) {
    middlewares.add(middleware);
    return this;
  }
}
