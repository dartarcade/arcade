import 'dart:async';

import 'package:arcade/src/http/request_context.dart';

typedef BeforeHookHandler<T extends RequestContext, U extends RequestContext>
    = FutureOr<U> Function(T context);

typedef AfterHookHandler<T extends RequestContext, U extends RequestContext, V,
        W>
    = FutureOr<(U, W)> Function(T context, V handleResult);

typedef AfterWebSocketHookHandler<T extends RequestContext,
        U extends RequestContext, V, W>
    = FutureOr<(U, W, String)> Function(T context, V handleResult, String id);
