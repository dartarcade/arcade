import 'dart:async';

import 'package:dartseid/src/http/request_context.dart';

typedef BeforeHookHandler<T extends RequestContext, U extends RequestContext>
    = FutureOr<U> Function(T context);

typedef AfterHookHandler<T extends RequestContext, U extends RequestContext, V,
        W>
    = FutureOr<(U, W)> Function(T context, V handleResult);
