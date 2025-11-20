import 'dart:async';
import 'dart:io';

import 'package:arcade/src/core/exceptions.dart';
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
late WebSocketStorageManager wsStorageManager;

// Initialize the storage manager with optional cache provider and connection limit
Future<void> initializeWebSocketStorage([
  BaseCacheManager? cacheManager,
  int? maxConnectionsPerServer,
]) async {
  wsStorageManager = WebSocketStorageManager(
    cacheManager,
    maxConnectionsPerServer,
  );
  await wsStorageManager.init();
}

// Dispose the storage manager
Future<void> disposeWebSocketStorage() async {
  await wsStorageManager.dispose();
}

typedef Emit = FutureOr<void> Function(dynamic message);
typedef Close = FutureOr<void> Function();
typedef WebSocketManager = ({String id, Emit emit, Close close});

typedef WebSocketHandler<T extends RequestContext> =
    FutureOr<void> Function(
      T context,
      dynamic message,
      WebSocketManager manager,
    );

typedef OnConnection<T extends RequestContext> =
    FutureOr<void> Function(
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

  // Validate that this is a valid WebSocket upgrade request
  if (!WebSocketTransformer.isUpgradeRequest(context.rawRequest)) {
    throw const BadRequestException(
      message: 'Invalid WebSocket upgrade request',
    );
  }

  final ctx = await runBeforeHooks(context, route);

  final wsId = const Uuid().v4();
  final ws = await WebSocketTransformer.upgrade(context.rawRequest);

  // Register connection with storage manager
  await wsStorageManager.registerConnection(
    connectionId: wsId,
    webSocket: ws,
    metadata: _extractMetadata(ctx),
  );

  final WebSocketManager manager = (
    id: wsId,
    emit: ws.add,
    close: ws.close,
  );

  route.onWebSocketConnect?.call(ctx, manager);

  ws.listen(
    (dynamic message) {
      try {
        wsHandler(ctx, message, manager);
      } catch (e) {
        // Log the error but don't close the connection
        // This allows WebSocket handlers to throw exceptions without killing the connection
      }
    },
    onDone: () async {
      await wsStorageManager.unregisterConnection(wsId);
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

Future<void> emitTo(String id, dynamic message) async {
  await wsStorageManager.publish('ws:direct:$id', message);
}

Future<void> emitToAll(dynamic message) async {
  await wsStorageManager.publish('ws:broadcast', message);
}

// New enhanced WebSocket API functions

/// Join a WebSocket connection to a room
Future<void> joinRoom(String connectionId, String room) async {
  await wsStorageManager.joinRoom(connectionId, room);
}

/// Remove a WebSocket connection from a room
Future<void> leaveRoom(String connectionId, String room) async {
  await wsStorageManager.leaveRoom(connectionId, room);
}

/// Emit message to all connections in a room
Future<void> emitToRoom(String room, dynamic message) async {
  await wsStorageManager.publish('ws:room:$room', message);
}

/// Get all active WebSocket connections
Future<List<WebSocketConnectionInfo>> getAllConnections() async {
  return await wsStorageManager.getAllConnections();
}

/// Get WebSocket connections for the current server instance
Future<List<WebSocketConnectionInfo>> getLocalConnections() async {
  return await wsStorageManager.getLocalConnections();
}

/// Get connection information by ID
Future<WebSocketConnectionInfo?> getConnectionInfo(String connectionId) async {
  return await wsStorageManager.getConnectionInfo(connectionId);
}

/// Update connection metadata
Future<void> updateConnectionMetadata(
  String connectionId,
  Map<String, dynamic> metadata,
) async {
  await wsStorageManager.updateConnectionMetadata(connectionId, metadata);
}

/// Get room members
Future<List<String>> getRoomMembers(String room) async {
  return await wsStorageManager.getRoomMembers(room);
}

/// Check if there are any local connections
bool get hasLocalConnections {
  return wsStorageManager.hasLocalConnection;
}

/// Get local connection IDs
Iterable<String> get localConnectionIds {
  return wsStorageManager.localConnectionIds;
}

/// Get server instance ID
String? get serverInstanceId {
  return wsStorageManager.serverInstanceId;
}

/// Validate health of all local WebSocket connections
/// This ensures all connections have active personal channel subscriptions
Future<void> validateConnectionHealth() async {
  return await wsStorageManager.validateConnectionHealth();
}
