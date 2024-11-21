import 'dart:async';
import 'dart:io';

import 'package:arcade/arcade.dart';
import 'package:arcade/src/helpers/response_helpers.dart';
import 'package:uuid/uuid.dart';

final _wsMap = <String, WebSocket>{};

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
  final wsHandler = route.wsHandler;
  if (wsHandler == null) {
    throw Exception('No WebSocket handler found');
  }

  final ctx = await runBeforeHooks(context, route);

  final wsId = const Uuid().v4();
  final ws = await WebSocketTransformer.upgrade(context.rawRequest);

  _wsMap[wsId] = ws;

  final WebSocketManager manager = (
    id: wsId,
    emit: ws.add,
    close: ws.close,
  );

  route.onWebSocketConnect?.call(ctx, manager);

  ws.listen(
    (dynamic message) {
      wsHandler(ctx, message, manager);
    },
    onDone: () {
      _wsMap.remove(wsId);
      runAfterWebSocketHooks(ctx, route, null, wsId);
    },
  );
}

void emitTo(String id, dynamic message) {
  _wsMap[id]?.add(message);
}

void emitToAll(dynamic message) {
  for (final ws in _wsMap.values) {
    ws.add(message);
  }
}
