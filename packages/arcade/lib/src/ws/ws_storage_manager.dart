import 'dart:io';

import 'package:arcade/src/ws/ws_connection_info.dart';
import 'package:arcade_cache/arcade_cache.dart';
import 'package:uuid/uuid.dart';

class WebSocketStorageManager {
  late final BaseCacheManager _cache;
  final Map<String, WebSocket> _localWebSockets = {};
  late final String _serverInstanceId;

  WebSocketStorageManager([BaseCacheManager? cacheManager]) {
    _cache = cacheManager ?? MemoryCacheManager();
    _serverInstanceId = const Uuid().v4();
  }

  Future<void> init() async {
    await _cache.init(null);
  }

  Future<void> dispose() async {
    _localWebSockets.clear();
    await _cache.dispose();
  }

  Future<void> registerConnection({
    required String connectionId,
    required WebSocket webSocket,
    Map<String, dynamic>? metadata,
  }) async {
    final connectionInfo = WebSocketConnectionInfo(
      id: connectionId,
      serverInstanceId: _serverInstanceId,
      connectTime: DateTime.now(),
      metadata: metadata ?? {},
    );

    _localWebSockets[connectionId] = webSocket;
    await _cache.set('ws:connection:$connectionId', connectionInfo.toJson());
  }

  Future<void> unregisterConnection(String connectionId) async {
    final connectionInfo = await getConnectionInfo(connectionId);

    _localWebSockets.remove(connectionId);
    await _cache.remove('ws:connection:$connectionId');

    for (final room in connectionInfo?.rooms ?? <String>{}) {
      await _removeFromRoom(connectionId, room);
    }
  }

  WebSocket? getLocalWebSocket(String connectionId) {
    return _localWebSockets[connectionId];
  }

  Future<WebSocketConnectionInfo?> getConnectionInfo(
      String connectionId) async {
    final json = await _cache.getJson('ws:connection:$connectionId');
    if (json == null) return null;
    return WebSocketConnectionInfo.fromJson(json);
  }

  Future<List<WebSocketConnectionInfo>> getAllConnections() async {
    final connections = <WebSocketConnectionInfo>[];

    try {
      final keys = _getAllConnectionKeys();
      for (final key in keys) {
        final json = await _cache.getJson(key);
        if (json != null) {
          connections.add(WebSocketConnectionInfo.fromJson(json));
        }
      }
    } catch (e) {
      // If cache doesn't support key listing, return empty list
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
    final connectionInfo = await getConnectionInfo(connectionId);
    if (connectionInfo == null) return;

    final updatedInfo = connectionInfo.addToRoom(room);
    await _cache.set('ws:connection:$connectionId', updatedInfo.toJson());
    await _addToRoom(connectionId, room);
  }

  Future<void> leaveRoom(String connectionId, String room) async {
    final connectionInfo = await getConnectionInfo(connectionId);
    if (connectionInfo == null) return;

    final updatedInfo = connectionInfo.removeFromRoom(room);
    await _cache.set('ws:connection:$connectionId', updatedInfo.toJson());
    await _removeFromRoom(connectionId, room);
  }

  Future<List<String>> getRoomMembers(String room) async {
    final members = await _cache.getList<String>('ws:room:$room');
    return members ?? [];
  }

  Future<void> updateConnectionMetadata(
      String connectionId, Map<String, dynamic> metadata) async {
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

  List<String> _getAllConnectionKeys() {
    // This is a simplified implementation that assumes we can iterate through keys
    // In a real implementation with Redis, you might use SCAN or KEYS pattern
    // For MemoryCacheManager, this would need to be implemented
    throw UnimplementedError('Key listing not implemented for this cache type');
  }

  bool get hasLocalConnection => _localWebSockets.isNotEmpty;

  Iterable<String> get localConnectionIds => _localWebSockets.keys;

  String get serverInstanceId => _serverInstanceId;
}
