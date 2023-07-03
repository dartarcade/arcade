import 'dart:async';

import 'package:dartseid/src/http/request_context.dart';

typedef BeforeHookHandler<T extends RequestContext, U extends RequestContext>
    = FutureOr<U> Function(T context);

class BeforeHook<T extends RequestContext, U extends RequestContext> {
  final BeforeHookHandler<T, U> handler;

  const BeforeHook(this.handler);

  FutureOr<U> call(T context) {
    return handler(context);
  }
}

typedef AfterHookHandler<T extends RequestContext, U extends RequestContext, V,
        W>
    = FutureOr<(U, W)> Function(T context, V handleResult);

class AfterHook<T extends RequestContext, U extends RequestContext, V, W> {
  final AfterHookHandler<T, U, V, W> handler;

  const AfterHook(this.handler);

  FutureOr<(U, W)> call(T context, V handleResult) {
    return handler(context, handleResult);
  }
}
