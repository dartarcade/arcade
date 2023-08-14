import 'dart:async';
import 'dart:io';

import 'package:dartseid/dartseid.dart';
import 'package:dartseid/src/helpers/response_helpers.dart';
import 'package:uuid/uuid.dart';

final wsMap = <String, WebSocket>{};

typedef Emit = FutureOr<void> Function(dynamic message);
typedef Close = FutureOr<void> Function();
typedef WebSocketManager = ({
  String id,
  Emit emit,
  Close close,
});

typedef WebSocketHandler<T extends RequestContext> = FutureOr<void> Function(
  T context,
  dynamic message,
  WebSocketManager manager,
);

typedef OnConnection<T extends RequestContext> = FutureOr<void> Function(
  T context,
  WebSocketManager manager,
);

Future<void> setupWsConnection<T extends RequestContext>({
  required T context,
  required BaseRoute<RequestContext> route,
}) async {
  final ctx = await runBeforeHooks(context, route);

  final wsId = const Uuid().v4();
  final ws = await WebSocketTransformer.upgrade(context.rawRequest);

  wsMap[wsId] = ws;

  final WebSocketManager manager = (
    id: wsId,
    emit: ws.add,
    close: ws.close,
  );

  route.onWebSocketConnect?.call(ctx, manager);

  ws.listen(
    (dynamic message) {
      route.wsHandler!.call(ctx, message, manager);
    },
    onDone: () {
      wsMap.remove(wsId);
      runAfterWebSocketHooks(ctx, route, null, wsId);
    },
  );
}

void emitTo(String id, dynamic message) {
  wsMap[id]?.add(message);
}
