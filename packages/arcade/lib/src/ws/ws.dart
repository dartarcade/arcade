import 'dart:async';
import 'dart:io';

import 'package:arcade/src/helpers/response_helpers.dart';
import 'package:arcade/src/http/request_context.dart';
import 'package:arcade/src/http/route.dart';
import 'package:arcade/src/ws/ws_connection_info.dart';
import 'package:arcade/src/ws/ws_storage_manager.dart';
import 'package:arcade_cache/arcade_cache.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

// Global WebSocket storage manager
@internal
late final WebSocketStorageManager wsStorageManager;

// Initialize the storage manager with optional cache provider
void initializeWebSocketStorage([BaseCacheManager? cacheManager]) {
  wsStorageManager = WebSocketStorageManager(cacheManager);
  wsStorageManager.init();
}

// Dispose the storage manager
Future<void> disposeWebSocketStorage() async {
  await wsStorageManager.dispose();
}

// Backward compatibility: maintain the old global map approach for existing APIs
@internal
final Map<String, WebSocket> wsMap = <String, WebSocket>{};

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

  // Maintain backward compatibility with the old map
  wsMap[wsId] = ws;

  // Use new storage system if initialized
  try {
    await wsStorageManager.registerConnection(
      connectionId: wsId,
      webSocket: ws,
      metadata: _extractMetadata(ctx),
    );
  } catch (e) {
    // If storage manager not initialized, fallback to old behavior
  }

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
    onDone: () async {
      // Clean up from both old and new systems
      wsMap.remove(wsId);
      try {
        await wsStorageManager.unregisterConnection(wsId);
      } catch (e) {
        // If storage manager not initialized, ignore
      }
      runAfterWebSocketHooks(ctx, route, null, wsId);
    },
  );
}

// Helper function to extract metadata from context
Map<String, dynamic>? _extractMetadata(RequestContext context) {
  // Extract any relevant metadata from the request context
  return {
    'userAgent': context.rawRequest.headers['user-agent']?.first,
    'remoteAddress': context.rawRequest.connectionInfo?.remoteAddress.address,
  };
}

void emitTo(String id, dynamic message) {
  wsMap[id]?.add(message);
}

void emitToAll(dynamic message) {
  for (final ws in wsMap.values) {
    ws.add(message);
  }
}

// New enhanced WebSocket API functions

/// Join a WebSocket connection to a room
Future<void> joinRoom(String connectionId, String room) async {
  try {
    await wsStorageManager.joinRoom(connectionId, room);
  } catch (e) {
    // If storage manager not initialized, ignore
  }
}

/// Remove a WebSocket connection from a room
Future<void> leaveRoom(String connectionId, String room) async {
  try {
    await wsStorageManager.leaveRoom(connectionId, room);
  } catch (e) {
    // If storage manager not initialized, ignore
  }
}

/// Emit message to all connections in a room
Future<void> emitToRoom(String room, dynamic message) async {
  try {
    final members = await wsStorageManager.getRoomMembers(room);
    for (final connectionId in members) {
      final ws = wsStorageManager.getLocalWebSocket(connectionId);
      ws?.add(message);

      // Also check the old map for backward compatibility
      if (ws == null) {
        wsMap[connectionId]?.add(message);
      }
    }
  } catch (e) {
    // If storage manager not initialized, ignore
  }
}

/// Get all active WebSocket connections
Future<List<WebSocketConnectionInfo>> getAllConnections() async {
  try {
    return await wsStorageManager.getAllConnections();
  } catch (e) {
    // If storage manager not initialized, return empty list
    return [];
  }
}

/// Get WebSocket connections for the current server instance
Future<List<WebSocketConnectionInfo>> getLocalConnections() async {
  try {
    return await wsStorageManager.getLocalConnections();
  } catch (e) {
    // If storage manager not initialized, return empty list
    return [];
  }
}

/// Get connection information by ID
Future<WebSocketConnectionInfo?> getConnectionInfo(String connectionId) async {
  try {
    return await wsStorageManager.getConnectionInfo(connectionId);
  } catch (e) {
    // If storage manager not initialized, return null
    return null;
  }
}

/// Update connection metadata
Future<void> updateConnectionMetadata(
    String connectionId, Map<String, dynamic> metadata) async {
  try {
    await wsStorageManager.updateConnectionMetadata(connectionId, metadata);
  } catch (e) {
    // If storage manager not initialized, ignore
  }
}

/// Get room members
Future<List<String>> getRoomMembers(String room) async {
  try {
    return await wsStorageManager.getRoomMembers(room);
  } catch (e) {
    // If storage manager not initialized, return empty list
    return [];
  }
}

/// Check if there are any local connections
bool get hasLocalConnections {
  try {
    return wsStorageManager.hasLocalConnection;
  } catch (e) {
    // If storage manager not initialized, fallback to old map
    return wsMap.isNotEmpty;
  }
}

/// Get local connection IDs
Iterable<String> get localConnectionIds {
  try {
    return wsStorageManager.localConnectionIds;
  } catch (e) {
    // If storage manager not initialized, fallback to old map
    return wsMap.keys;
  }
}

/// Get server instance ID
String? get serverInstanceId {
  try {
    return wsStorageManager.serverInstanceId;
  } catch (e) {
    // If storage manager not initialized, return null
    return null;
  }
}
