import 'dart:convert';

class WebSocketConnectionInfo {
  final String id;
  final String serverInstanceId;
  final Set<String> rooms;
  final DateTime connectTime;
  final Map<String, dynamic> metadata;

  const WebSocketConnectionInfo({
    required this.id,
    required this.serverInstanceId,
    this.rooms = const {},
    required this.connectTime,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serverInstanceId': serverInstanceId,
      'rooms': rooms.toList(),
      'connectTime': connectTime.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory WebSocketConnectionInfo.fromJson(Map<String, dynamic> json) {
    return WebSocketConnectionInfo(
      id: json['id'] as String,
      serverInstanceId: json['serverInstanceId'] as String,
      rooms: Set<String>.from(json['rooms'] as List? ?? []),
      connectTime: DateTime.parse(json['connectTime'] as String),
      metadata: Map<String, dynamic>.from(
          json['metadata'] as Map<String, dynamic>? ?? {}),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory WebSocketConnectionInfo.fromJsonString(String jsonString) =>
      WebSocketConnectionInfo.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>);

  WebSocketConnectionInfo copyWith({
    String? id,
    String? serverInstanceId,
    Set<String>? rooms,
    DateTime? connectTime,
    Map<String, dynamic>? metadata,
  }) {
    return WebSocketConnectionInfo(
      id: id ?? this.id,
      serverInstanceId: serverInstanceId ?? this.serverInstanceId,
      rooms: rooms ?? this.rooms,
      connectTime: connectTime ?? this.connectTime,
      metadata: metadata ?? this.metadata,
    );
  }

  WebSocketConnectionInfo addToRoom(String room) {
    return copyWith(rooms: {...rooms, room});
  }

  WebSocketConnectionInfo removeFromRoom(String room) {
    final newRooms = Set<String>.from(rooms);
    newRooms.remove(room);
    return copyWith(rooms: newRooms);
  }

  WebSocketConnectionInfo updateMetadata(Map<String, dynamic> newMetadata) {
    return copyWith(metadata: {...metadata, ...newMetadata});
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WebSocketConnectionInfo &&
        other.id == id &&
        other.serverInstanceId == serverInstanceId &&
        other.rooms.length == rooms.length &&
        other.rooms.containsAll(rooms) &&
        other.connectTime == connectTime &&
        other.metadata.length == metadata.length &&
        _mapsEqual(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      serverInstanceId,
      rooms,
      connectTime,
      metadata,
    );
  }

  @override
  String toString() {
    return 'WebSocketConnectionInfo{id: $id, serverInstanceId: $serverInstanceId, rooms: $rooms, connectTime: $connectTime, metadata: $metadata}';
  }

  bool _mapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) return false;
    }
    return true;
  }
}
