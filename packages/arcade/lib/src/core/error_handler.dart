import 'dart:async';

import 'package:arcade/arcade.dart';

typedef RouteErrorHandler<T extends RequestContext> = FutureOr<dynamic>
    Function(
  T context,
  ArcadeHttpException error,
  StackTrace stackTrace,
);

RouteErrorHandler? errorHandler;

void overrideErrorHandler(RouteErrorHandler handler) {
  errorHandler = handler;
}
