import 'dart:async';
import 'dart:io';

import 'package:arcade/src/ws/ws_connection_info.dart';
import 'package:arcade_cache/arcade_cache.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

enum ConnectionState { connecting, connected, disconnecting, disconnected }

class WebSocketStorageManager {
  late final BaseCacheManager _cache;
  final Map<String, WebSocket> _localWebSockets = {};
  late final String _serverInstanceId;

  // Subscription tracking
  final Map<String, StreamSubscription<PubSubEvent>> _personalSubscriptions =
      {};
  final Map<String, StreamSubscription<PubSubEvent>> _roomSubscriptions = {};
  final Map<String, int> _roomConnectionCounts = {};
  StreamSubscription<PubSubEvent>? _broadcastSubscription;

  // Synchronization for room operations
  final Map<String, Future<void>> _roomOperations = {};

  // Track connections being unregistered to prevent double cleanup
  final Set<String> _unregisteringConnections = {};

  // Connection state tracking
  final Map<String, ConnectionState> _connectionStates = {};

  // Synchronization
  final _initLock = Lock();
  final _connectionLock = Lock();

  // Initialization state
  bool _initialized = false;
  bool _disposed = false;

  // Connection limits (optional)
  final int? maxConnectionsPerServer;

  // Room name validation
  static final _validRoomName = RegExp(r'^[a-zA-Z0-9_-]+$');

  WebSocketStorageManager([
    BaseCacheManager? cacheManager,
    this.maxConnectionsPerServer,
  ]) {
    _cache = cacheManager ?? MemoryCacheManager();
    _serverInstanceId = const Uuid().v4();
  }

  Future<void> init() async {
    await _initLock.synchronized(() async {
      if (_initialized) return;
      if (_disposed) {
        throw StateError('WebSocketStorageManager has been disposed');
      }

      await _cache.init(null);

      // Subscribe to broadcast channel
      final broadcastStream = _cache.subscribe<dynamic>(['ws:broadcast']);
      _broadcastSubscription = broadcastStream.listen((event) {
        switch (event) {
          case PubSubMessage(:final data):
            // Send to all local WebSocket connections with error handling
            for (final entry in _localWebSockets.entries.toList()) {
              try {
                entry.value.add(data);
              } catch (e) {
                // WebSocket error - close it to trigger proper cleanup
                try {
                  entry.value.close(1011, 'WebSocket write failed');
                } catch (_) {
                  // Ignore close errors
                }
              }
            }
          case PubSubSubscribed():
            // Successfully subscribed to broadcast channel
            break;
          case PubSubUnsubscribed():
            // Unsubscribed from broadcast channel
            break;
        }
      });

      _initialized = true;
    });
  }

  Future<void> dispose() async {
    if (_disposed) return;

    // Clean up all subscriptions
    await _broadcastSubscription?.cancel();
    for (final sub in _personalSubscriptions.values) {
      await sub.cancel();
    }
    for (final sub in _roomSubscriptions.values) {
      await sub.cancel();
    }

    _personalSubscriptions.clear();
    _roomSubscriptions.clear();
    _roomConnectionCounts.clear();
    _roomOperations.clear();
    _unregisteringConnections.clear();
    _connectionStates.clear();
    _localWebSockets.clear();

    await _cache.dispose();

    _disposed = true;
    _initialized = false;
  }

  Future<void> registerConnection({
    required String connectionId,
    required WebSocket webSocket,
    Map<String, dynamic>? metadata,
  }) async {
    _ensureInitialized();

    // Quick validation and state updates in lock
    await _connectionLock.synchronized(() {
      // Check if connection already exists
      if (_localWebSockets.containsKey(connectionId)) {
        throw StateError('Connection $connectionId already registered');
      }

      // Check connection limit if configured
      if (maxConnectionsPerServer != null &&
          _localWebSockets.length >= maxConnectionsPerServer!) {
        throw StateError(
          'Maximum connections reached: $maxConnectionsPerServer',
        );
      }

      // Reserve the connection slot
      _connectionStates[connectionId] = ConnectionState.connecting;
      _localWebSockets[connectionId] = webSocket;
    });

    // Perform async operations outside the lock
    try {
      final connectionInfo = WebSocketConnectionInfo(
        id: connectionId,
        serverInstanceId: _serverInstanceId,
        connectTime: DateTime.now(),
        metadata: metadata ?? {},
      );

      // Save to cache
      await _cache.set('ws:connection:$connectionId', connectionInfo.toJson());

      // Subscribe to personal channel for direct messages
      final personalChannel = 'ws:direct:$connectionId';
      final personalStream = _cache.subscribe<dynamic>([personalChannel]);

      StreamSubscription<PubSubEvent>? subscription;
      try {
        subscription = personalStream.listen((event) {
          switch (event) {
            case PubSubMessage(:final data):
              // Forward message to the WebSocket connection with error handling
              try {
                webSocket.add(data);
              } catch (e) {
                // WebSocket error - close it to trigger proper cleanup
                try {
                  webSocket.close(1011, 'WebSocket write failed');
                } catch (_) {
                  // Ignore close errors
                }
              }
            case PubSubSubscribed():
              // Successfully subscribed to personal channel
              break;
            case PubSubUnsubscribed():
              // Lost personal channel - must disconnect WebSocket
              // This is critical: without personal channel, direct messages won't work
              _personalSubscriptions.remove(connectionId);
              try {
                webSocket.close(
                  1011,
                  'Lost subscription to personal channel - reconnect required',
                );
              } catch (_) {
                // WebSocket might already be closed
              }
          }
        });

        // Store subscription only after successful setup
        _personalSubscriptions[connectionId] = subscription;

        // Mark connection as fully connected
        await _connectionLock.synchronized(() {
          _connectionStates[connectionId] = ConnectionState.connected;
        });
      } catch (e) {
        // Subscription setup failed - clean up
        await subscription?.cancel();
        await _cache.remove('ws:connection:$connectionId');
        rethrow;
      }
    } catch (e) {
      // Clean up on any failure
      await _connectionLock.synchronized(() {
        _localWebSockets.remove(connectionId);
        _connectionStates.remove(connectionId);
      });

      // Clean up subscription if it exists
      final sub = _personalSubscriptions.remove(connectionId);
      await sub?.cancel();

      rethrow;
    }
  }

  Future<void> unregisterConnection(String connectionId) async {
    // Prevent double unregistration
    if (_unregisteringConnections.contains(connectionId)) {
      return;
    }
    _unregisteringConnections.add(connectionId);

    // Update connection state
    _connectionStates[connectionId] = ConnectionState.disconnecting;

    try {
      final connectionInfo = await getConnectionInfo(connectionId);

      _localWebSockets.remove(connectionId);

      // Cancel personal channel subscription first
      await _personalSubscriptions[connectionId]?.cancel();
      _personalSubscriptions.remove(connectionId);

      // Unsubscribe from personal channel
      try {
        await _cache.unsubscribe(['ws:direct:$connectionId']);
      } catch (e) {
        // Ignore unsubscribe errors
      }

      // Leave all rooms
      for (final room in connectionInfo?.rooms ?? <String>{}) {
        try {
          await leaveRoom(connectionId, room);
        } catch (e) {
          // Continue cleanup even if room leave fails
        }
      }

      // Remove from cache last
      await _cache.remove('ws:connection:$connectionId');

      // Mark as disconnected
      _connectionStates[connectionId] = ConnectionState.disconnected;
    } finally {
      _unregisteringConnections.remove(connectionId);
      // Clean up state after a delay to allow for any final operations
      Future.delayed(const Duration(seconds: 5), () {
        _connectionStates.remove(connectionId);
      });
    }
  }

  WebSocket? getLocalWebSocket(String connectionId) {
    return _localWebSockets[connectionId];
  }

  Future<WebSocketConnectionInfo?> getConnectionInfo(
    String connectionId,
  ) async {
    final json = await _cache.getJson('ws:connection:$connectionId');
    if (json == null) return null;
    return WebSocketConnectionInfo.fromJson(json);
  }

  Future<List<WebSocketConnectionInfo>> getAllConnections() async {
    // Since we don't have a way to list all keys in the cache,
    // we can only return information about local connections
    final connections = <WebSocketConnectionInfo>[];

    for (final connectionId in _localWebSockets.keys) {
      final connectionInfo = await getConnectionInfo(connectionId);
      if (connectionInfo != null) {
        connections.add(connectionInfo);
      }
    }

    return connections;
  }

  Future<List<WebSocketConnectionInfo>> getLocalConnections() async {
    final allConnections = await getAllConnections();
    return allConnections
        .where((conn) => conn.serverInstanceId == _serverInstanceId)
        .toList();
  }

  Future<void> joinRoom(String connectionId, String room) async {
    _ensureInitialized();

    // Validate room name
    if (!_validRoomName.hasMatch(room)) {
      throw ArgumentError(
        'Invalid room name: $room. '
        'Room names must only contain letters, numbers, hyphens, and underscores.',
      );
    }

    // Synchronize room operations to prevent race conditions
    final existingOperation = _roomOperations[room];
    if (existingOperation != null) {
      await existingOperation;
    }

    final operation = _doJoinRoom(connectionId, room);
    _roomOperations[room] = operation;

    try {
      await operation;
    } finally {
      _roomOperations.remove(room);
    }
  }

  Future<void> _doJoinRoom(String connectionId, String room) async {
    final connectionInfo = await getConnectionInfo(connectionId);
    if (connectionInfo == null) return;

    // Check if already in room
    if (connectionInfo.rooms.contains(room)) {
      return; // Already joined
    }

    // First, add to room member list (can be rolled back)
    try {
      await _addToRoom(connectionId, room);
    } catch (e) {
      // Failed to add to room member list
      rethrow;
    }

    // Then update connection info
    try {
      final updatedInfo = connectionInfo.addToRoom(room);
      await _cache.set('ws:connection:$connectionId', updatedInfo.toJson());
    } catch (e) {
      // Rollback room member list change
      await _removeFromRoom(connectionId, room);
      rethrow;
    }

    // Track local connections per room
    _roomConnectionCounts[room] = (_roomConnectionCounts[room] ?? 0) + 1;

    // If this is the first local connection in this room, subscribe to the room channel
    if (_roomConnectionCounts[room] == 1 &&
        !_roomSubscriptions.containsKey(room)) {
      try {
        final roomChannel = 'ws:room:$room';
        final roomStream = _cache.subscribe<dynamic>([roomChannel]);
        _roomSubscriptions[room] = roomStream.listen((event) {
          switch (event) {
            case PubSubMessage(:final data):
              // Forward message to all local connections in this room
              _forwardToRoomMembers(room, data);
            case PubSubSubscribed():
              // Successfully subscribed to room channel
              break;
            case PubSubUnsubscribed():
              // Unexpectedly unsubscribed from room channel
              _roomSubscriptions.remove(room);
            // Don't remove the count - there may still be local connections
            // They will need to resubscribe on next message send
          }
        });
      } catch (e) {
        // Subscription failed, decrement count
        _roomConnectionCounts[room] = _roomConnectionCounts[room]! - 1;
        if (_roomConnectionCounts[room]! <= 0) {
          _roomConnectionCounts.remove(room);
        }
        // Note: We don't rollback the room membership as the connection is valid
      }
    }
  }

  Future<void> leaveRoom(String connectionId, String room) async {
    _ensureInitialized();

    // Validate room name
    if (!_validRoomName.hasMatch(room)) {
      throw ArgumentError(
        'Invalid room name: $room. '
        'Room names must only contain letters, numbers, hyphens, and underscores.',
      );
    }

    // Synchronize room operations to prevent race conditions
    final existingOperation = _roomOperations[room];
    if (existingOperation != null) {
      await existingOperation;
    }

    final operation = _doLeaveRoom(connectionId, room);
    _roomOperations[room] = operation;

    try {
      await operation;
    } finally {
      _roomOperations.remove(room);
    }
  }

  Future<void> _doLeaveRoom(String connectionId, String room) async {
    final connectionInfo = await getConnectionInfo(connectionId);
    if (connectionInfo == null) return;

    // Check if connection is actually in this room
    if (!connectionInfo.rooms.contains(room)) {
      return; // Not in room, nothing to do
    }

    final updatedInfo = connectionInfo.removeFromRoom(room);
    await _cache.set('ws:connection:$connectionId', updatedInfo.toJson());
    await _removeFromRoom(connectionId, room);

    // Only decrement if this is a local connection
    if (_localWebSockets.containsKey(connectionId) &&
        _roomConnectionCounts.containsKey(room)) {
      _roomConnectionCounts[room] = _roomConnectionCounts[room]! - 1;

      // If no more local connections in this room, unsubscribe
      if (_roomConnectionCounts[room]! <= 0) {
        _roomConnectionCounts.remove(room);
        final subscription = _roomSubscriptions.remove(room);
        if (subscription != null) {
          await subscription.cancel();
          await _cache.unsubscribe(['ws:room:$room']);
        }
      }
    }
  }

  Future<List<String>> getRoomMembers(String room) async {
    final members = await _cache.getList<String>('ws:room:$room');
    return members ?? [];
  }

  Future<void> updateConnectionMetadata(
    String connectionId,
    Map<String, dynamic> metadata,
  ) async {
    final connectionInfo = await getConnectionInfo(connectionId);
    if (connectionInfo == null) return;

    final updatedInfo = connectionInfo.updateMetadata(metadata);
    await _cache.set('ws:connection:$connectionId', updatedInfo.toJson());
  }

  Future<void> _addToRoom(String connectionId, String room) async {
    final members = await getRoomMembers(room);
    if (!members.contains(connectionId)) {
      members.add(connectionId);
      await _cache.set('ws:room:$room', members);
    }
  }

  Future<void> _removeFromRoom(String connectionId, String room) async {
    final members = await getRoomMembers(room);
    members.remove(connectionId);

    if (members.isEmpty) {
      await _cache.remove('ws:room:$room');
    } else {
      await _cache.set('ws:room:$room', members);
    }
  }

  bool get hasLocalConnection => _localWebSockets.isNotEmpty;

  Iterable<String> get localConnectionIds => _localWebSockets.keys;

  String get serverInstanceId => _serverInstanceId;

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'WebSocketStorageManager not initialized. Call init() first.',
      );
    }
    if (_disposed) {
      throw StateError('WebSocketStorageManager has been disposed');
    }
  }

  // Helper method to forward messages to local room members
  Future<void> _forwardToRoomMembers(String room, dynamic message) async {
    try {
      final members = await getRoomMembers(room);

      for (final connectionId in members) {
        // Only forward to connections that are local to this server
        final ws = _localWebSockets[connectionId];
        if (ws != null) {
          try {
            ws.add(message);
          } catch (e) {
            // WebSocket error detected - trigger proper cleanup
            // Close the WebSocket which will trigger onDone handler
            try {
              ws.close(1011, 'WebSocket write failed');
            } catch (_) {
              // Ignore close errors
            }
          }
        }
      }
    } catch (e) {
      // Log error but don't throw - message delivery is best effort
    }
  }

  // Publish message to a channel
  Future<void> publish(String channel, dynamic message) async {
    _ensureInitialized();
    await _cache.publish(channel, message);
  }

  // Health check to ensure all local connections have active subscriptions
  Future<void> validateConnectionHealth() async {
    _ensureInitialized();

    final deadConnections = <String>[];

    for (final connectionId in _localWebSockets.keys.toList()) {
      // Check if personal subscription exists
      if (!_personalSubscriptions.containsKey(connectionId)) {
        // Connection without subscription - mark for cleanup
        deadConnections.add(connectionId);
        continue;
      }

      // Check WebSocket state
      final ws = _localWebSockets[connectionId];
      if (ws == null || ws.readyState != WebSocket.open) {
        deadConnections.add(connectionId);
      }
    }

    // Clean up dead connections
    for (final connectionId in deadConnections) {
      try {
        final ws = _localWebSockets[connectionId];
        if (ws != null && ws.readyState == WebSocket.open) {
          ws.close(
            1011,
            'Connection health check failed - missing subscription',
          );
        }
      } catch (_) {
        // Ignore errors during cleanup
      }
    }
  }
}
