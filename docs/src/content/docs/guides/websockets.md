---
title: WebSockets Guide
description: Building real-time applications with Arcade's WebSocket support
---

Arcade provides built-in WebSocket support for creating real-time applications. This guide covers everything from basic connections to advanced patterns.

## WebSocket Storage Initialization

Before using WebSockets with room management and persistence features, you need to initialize the WebSocket storage system:

### Basic Initialization (Memory Storage)

```dart
import 'package:arcade/arcade.dart';

void main() async {
  // Initialize WebSocket storage with default memory cache
  initializeWebSocketStorage();
  
  await runServer(
    port: 3000,
    init: () {
      // Your WebSocket routes...
    },
  );
  
  // Clean up on shutdown
  await disposeWebSocketStorage();
}
```

### Redis-backed Storage (Recommended for Production)

```dart
import 'package:arcade/arcade.dart';
import 'package:arcade_cache_redis/arcade_cache_redis.dart';

void main() async {
  // Initialize Redis cache
  final redisCache = RedisCacheManager();
  await redisCache.init((
    host: Platform.environment['REDIS_HOST'] ?? 'localhost',
    port: int.parse(Platform.environment['REDIS_PORT'] ?? '6379'),
    secure: Platform.environment['REDIS_SECURE'] == 'true',
  ));
  
  // Initialize WebSocket storage with Redis
  initializeWebSocketStorage(redisCache);
  
  await runServer(
    port: 3000,
    init: () {
      // Your WebSocket routes with room support...
    },
  );
  
  // Clean up on shutdown
  await disposeWebSocketStorage();
}
```

### Custom Cache Implementation

```dart
import 'package:arcade/arcade.dart';
import 'package:arcade_cache/arcade_cache.dart';

void main() async {
  // Use any BaseCacheManager implementation
  final customCache = MyCustomCacheManager();
  await customCache.init(MyCustomConfig());
  
  // Initialize WebSocket storage
  initializeWebSocketStorage(customCache);
  
  await runServer(
    port: 3000,
    init: () {
      // Your routes...
    },
  );
  
  // Clean up
  await disposeWebSocketStorage();
}
```

**Important Notes:**
- Call `initializeWebSocketStorage()` **before** starting your server
- Always call `disposeWebSocketStorage()` when shutting down
- Without initialization, room management functions will be ignored
- Redis storage enables WebSocket rooms across multiple server instances

## Basic WebSocket Server

Create a simple WebSocket echo server:

```dart
import 'package:arcade/arcade.dart';

void main() async {
  await runServer(
    port: 3000,
    init: () {
      route.get('/ws')
        .handleWebSocket((context, websocket, id) {
          // Send welcome message
          websocket.add('Welcome! Your ID is $id');
          
          // Echo messages back
          websocket.listen(
            (message) {
              print('Received from $id: $message');
              websocket.add('Echo: $message');
            },
            onDone: () {
              print('Client $id disconnected');
            },
            onError: (error) {
              print('Error from $id: $error');
            },
          );
        });
    },
  );
}
```

## WebSocket with Connection Handler

Use the `onConnect` callback for initialization:

```dart
route.get('/ws/chat')
  .handleWebSocket(
    (context, websocket, id) {
      // Main message handler
      websocket.listen((message) {
        // Broadcast to all connected clients
        emitToAll('chat', {
          'from': id,
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
    },
    onConnect: (context, websocket, id) {
      // Called when connection is established
      print('New connection: $id');
      
      // Notify others about new user
      emitToAll('user-joined', {'userId': id});
      
      // Send current users list to new client
      final users = WebSocketManager.getConnectedIds();
      websocket.add(jsonEncode({
        'type': 'users-list',
        'users': users,
      }));
    },
  );
```

## Authentication with WebSockets

Authenticate WebSocket connections using before hooks:

```dart
class AuthedWebSocketContext extends RequestContext {
  final User user;
  
  AuthedWebSocketContext({
    required super.request,
    required super.route,
    required this.user,
  });
}

route.get('/ws/private')
  .before<AuthedWebSocketContext>((context) async {
    // Check authorization header or cookie
    final token = context.requestHeaders.value('authorization') ??
                 context.requestHeaders.cookie?.firstWhere(
                   (c) => c.name == 'auth-token',
                   orElse: () => throw UnauthorizedException(),
                 ).value;
    
    if (token == null) {
      throw UnauthorizedException();
    }
    
    final user = await validateTokenAndGetUser(token);
    
    return AuthedWebSocketContext(
      request: context.rawRequest,
      route: context.route,
      user: user,
    );
  })
  .handleWebSocket(
    (AuthedWebSocketContext context, websocket, id) {
      // Now we have access to context.user
      websocket.add('Welcome ${context.user.name}!');
      
      // Store user info for this connection
      WebSocketManager.setConnectionData(id, {'user': context.user});
      
      websocket.listen((message) {
        // Handle authenticated messages
      });
    },
  );
```

## Broadcasting Messages

Use Arcade's built-in broadcasting functions:

```dart
// Broadcast to all connected clients
route.post('/api/broadcast').handle((context) async {
  final result = await context.jsonMap();
  
  if (result case BodyParseSuccess(:final value)) {
    final message = value['message'];
    
    // Send to all WebSocket clients
    emitToAll('broadcast', {
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    return {'sent': true, 'recipients': WebSocketManager.getConnectedIds().length};
  }
  
  throw BadRequestException();
});

// Send to specific client
route.post('/api/message/:userId').handle((context) async {
  final userId = context.pathParameters['userId']!;
  final result = await context.jsonMap();
  
  if (result case BodyParseSuccess(:final value)) {
    final sent = emitTo(userId, 'private-message', value);
    
    if (!sent) {
      throw NotFoundException(message: 'User not connected');
    }
    
    return {'sent': true};
  }
  
  throw BadRequestException();
});
```

## Simple Chat with Native Rooms

Build a chat application using Arcade's built-in room management:

```dart
route.get('/ws/chat/:roomId')
  .handleWebSocket(
    (context, websocket, id) {
      final roomId = context.pathParameters['roomId']!;
      
      websocket.listen((data) async {
        final json = jsonDecode(data);
        
        switch (json['type']) {
          case 'message':
            // Broadcast message to all room members using native room support
            await emitToRoom(roomId, jsonEncode({
              'type': 'chat_message',
              'from': id,
              'message': json['message'],
              'timestamp': DateTime.now().toIso8601String(),
            }));
            break;
            
          case 'typing':
            // Notify others in room that user is typing
            await emitToRoom(roomId, jsonEncode({
              'type': 'user_typing',
              'userId': id,
            }));
            break;
        }
      });
    },
    onConnect: (context, websocket, id) async {
      final roomId = context.pathParameters['roomId']!;
      
      // Join the room using native room support
      await joinRoom(id, roomId);
      
      // Get current room members
      final members = await getRoomMembers(roomId);
      
      // Send room info to new user
      websocket.add(jsonEncode({
        'type': 'room_joined',
        'roomId': roomId,
        'members': members,
        'memberCount': members.length,
      }));
      
      // Notify other room members
      await emitToRoom(roomId, jsonEncode({
        'type': 'user_joined',
        'userId': id,
        'memberCount': members.length,
      }));
    },
  );

// API to get room information
route.get('/api/rooms/:roomId').handle((context) async {
  final roomId = context.pathParameters['roomId']!;
  final members = await getRoomMembers(roomId);
  
  return {
    'roomId': roomId,
    'members': members,
    'memberCount': members.length,
  };
});
```

## WebSocket Hooks

Use after hooks for cleanup and logging:

```dart
route.get('/ws/monitored')
  .handleWebSocket(
    (context, websocket, id) {
      final startTime = DateTime.now();
      var messageCount = 0;
      
      websocket.listen((message) {
        messageCount++;
        // Handle message
      });
      
      // Store metrics
      WebSocketManager.setConnectionData(id, {
        'startTime': startTime,
        'messageCount': messageCount,
      });
    },
  )
  .after((context, result, id) {
    // Called after WebSocket closes
    final data = WebSocketManager.getConnectionData(id);
    final duration = DateTime.now().difference(data['startTime'] as DateTime);
    
    Logger.root.info('WebSocket closed', {
      'connectionId': id,
      'duration': duration.inSeconds,
      'messages': data['messageCount'],
    });
    
    return (context, result, id);
  });
```

## Binary Data over WebSocket

Handle binary data transmission:

```dart
route.get('/ws/binary')
  .handleWebSocket((context, websocket, id) {
    websocket.listen(
      (data) {
        if (data is String) {
          // Text message
          websocket.add('Received text: $data');
        } else if (data is List<int>) {
          // Binary data
          print('Received ${data.length} bytes from $id');
          
          // Echo binary data back
          websocket.add(data);
        }
      },
    );
    
    // Send binary data to client
    final binaryData = Uint8List.fromList([1, 2, 3, 4, 5]);
    websocket.add(binaryData);
  });
```

## WebSocket Subprotocols

Handle WebSocket subprotocols:

```dart
route.get('/ws/protocol')
  .before((context) {
    // Check requested protocols
    final protocols = context.requestHeaders.value('sec-websocket-protocol')?.split(',') ?? [];
    
    if (!protocols.contains('chat-v1')) {
      throw BadRequestException(message: 'Unsupported protocol');
    }
    
    // Set accepted protocol
    context.responseHeaders.add('sec-websocket-protocol', 'chat-v1');
    
    return context;
  })
  .handleWebSocket((context, websocket, id) {
    // Handle protocol-specific messages
    websocket.listen((message) {
      final data = jsonDecode(message);
      // Process according to chat-v1 protocol
    });
  });
```

## Room Management

Arcade now supports advanced room-based WebSocket functionality with cache-backed storage:

### Joining and Leaving Rooms

```dart
route.get('/ws/chat/:roomId')
  .handleWebSocket(
    (context, websocket, id) {
      final roomId = context.pathParameters['roomId']!;
      
      websocket.listen(
        (data) async {
          final json = jsonDecode(data);
          final type = json['type'];
          
          switch (type) {
            case 'message':
              // Broadcast to all room members
              await emitToRoom(roomId, jsonEncode({
                'type': 'message',
                'from': id,
                'message': json['message'],
                'timestamp': DateTime.now().toIso8601String(),
              }));
              break;
          }
        },
        onDone: () async {
          // Remove from room on disconnect
          await leaveRoom(id, roomId);
        },
      );
    },
    onConnect: (context, websocket, id) async {
      final roomId = context.pathParameters['roomId']!;
      
      // Join the room
      await joinRoom(id, roomId);
      
      // Get room members
      final members = await getRoomMembers(roomId);
      
      // Send room info to new member
      websocket.add(jsonEncode({
        'type': 'room-joined',
        'roomId': roomId,
        'members': members,
      }));
      
      // Notify other room members
      await emitToRoom(roomId, jsonEncode({
        'type': 'user-joined',
        'userId': id,
        'memberCount': members.length,
      }));
    },
  );
```

### Advanced Room Operations

```dart
// Get all room members
route.get('/api/rooms/:roomId/members').handle((context) async {
  final roomId = context.pathParameters['roomId']!;
  final members = await getRoomMembers(roomId);
  
  return {
    'roomId': roomId,
    'members': members,
    'count': members.length,
  };
});

// Move user between rooms
route.post('/api/users/:userId/move-room').handle((context) async {
  final userId = context.pathParameters['userId']!;
  final body = await context.jsonMap();
  final fromRoom = body['from'];
  final toRoom = body['to'];
  
  // Leave old room
  if (fromRoom != null) {
    await leaveRoom(userId, fromRoom);
  }
  
  // Join new room
  await joinRoom(userId, toRoom);
  
  return {'moved': true, 'from': fromRoom, 'to': toRoom};
});
```

## Connection Management with Cache Storage

The new WebSocket system includes cache-backed storage for connection persistence:

### Initialize WebSocket Storage

```dart
import 'package:arcade/arcade.dart';
import 'package:arcade_cache_redis/arcade_cache_redis.dart';

void main() async {
  // Initialize with Redis for distributed storage
  final redisCache = RedisCacheManager();
  await redisCache.init((
    host: 'localhost',
    port: 6379,
    secure: false,
  ));
  
  // Initialize WebSocket storage
  initializeWebSocketStorage(redisCache);
  
  await runServer(
    port: 3000,
    init: () {
      // Your WebSocket routes...
    },
  );
  
  // Clean up on shutdown
  await disposeWebSocketStorage();
}
```

### Connection Information and Metadata

```dart
// Get detailed connection information
route.get('/api/ws/connections').handle((context) async {
  final connections = await getAllConnections();
  
  return {
    'total': connections.length,
    'local': await getLocalConnections(),
    'connections': connections.map((conn) => {
      'id': conn.id,
      'serverInstanceId': conn.serverInstanceId,
      'connectTime': conn.connectTime.toIso8601String(),
      'rooms': conn.rooms.toList(),
      'metadata': conn.metadata,
    }).toList(),
  };
});

// Update connection metadata
route.put('/api/ws/connections/:id/metadata').handle((context) async {
  final connectionId = context.pathParameters['id']!;
  final metadata = await context.jsonMap();
  
  await updateConnectionMetadata(connectionId, metadata);
  
  return {'updated': true};
});

// Get specific connection info
route.get('/api/ws/connections/:id').handle((context) async {
  final connectionId = context.pathParameters['id']!;
  final info = await getConnectionInfo(connectionId);
  
  if (info == null) {
    throw NotFoundException(message: 'Connection not found');
  }
  
  return {
    'id': info.id,
    'serverInstanceId': info.serverInstanceId,
    'connectTime': info.connectTime.toIso8601String(),
    'rooms': info.rooms.toList(),
    'metadata': info.metadata,
  };
});
```

### Multi-Server Support

```dart
// Check server instance information
route.get('/api/ws/server-info').handle((context) async {
  return {
    'serverInstanceId': serverInstanceId,
    'localConnections': localConnectionIds.length,
    'hasLocalConnections': hasLocalConnections,
    'allConnections': (await getAllConnections()).length,
  };
});

// Broadcast to all servers
route.post('/api/ws/broadcast-global').handle((context) async {
  final message = await context.jsonMap();
  
  // Get all connections across all server instances
  final allConnections = await getAllConnections();
  
  for (final conn in allConnections) {
    // This will work across multiple server instances
    // when using Redis or other distributed cache
    await emitToConnection(conn.id, message);
  }
  
  return {
    'sent': true,
    'recipients': allConnections.length,
  };
});
```

### Disconnect Management

```dart
// Disconnect specific client
route.delete('/api/ws/connections/:id').handle((context) async {
  final connectionId = context.pathParameters['id']!;
  
  // Get connection info
  final info = await getConnectionInfo(connectionId);
  if (info == null) {
    throw NotFoundException(message: 'Connection not found');
  }
  
  // Send disconnect message if it's a local connection
  if (info.serverInstanceId == serverInstanceId) {
    emitTo(connectionId, jsonEncode({
      'type': 'disconnect',
      'reason': 'Admin action',
    }));
  }
  
  return {
    'connectionId': connectionId,
    'serverInstance': info.serverInstanceId,
    'wasLocal': info.serverInstanceId == serverInstanceId,
  };
});
```

## Room-Based Applications

Build sophisticated multi-room applications with the new room management features:

### Multi-Room Chat Application

```dart
class ChatService {
  static final rooms = <String, Room>{};
  
  static Future<void> createRoom(String roomId, String name, String createdBy) async {
    rooms[roomId] = Room(
      id: roomId,
      name: name,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );
  }
  
  static Future<void> handleUserMessage(
    String connectionId,
    String roomId,
    Map<String, dynamic> message,
  ) async {
    final room = rooms[roomId];
    if (room == null) return;
    
    final chatMessage = {
      'type': 'chat_message',
      'roomId': roomId,
      'from': connectionId,
      'message': message['text'],
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Store message in room history
    room.addMessage(chatMessage);
    
    // Broadcast to all room members
    await emitToRoom(roomId, jsonEncode(chatMessage));
  }
  
  static Future<List<String>> getRoomList() async {
    return rooms.keys.toList();
  }
}

// WebSocket route for multi-room chat
route.get('/ws/multi-chat')
  .handleWebSocket(
    (context, websocket, id) {
      websocket.listen((data) async {
        final message = jsonDecode(data);
        
        switch (message['action']) {
          case 'join_room':
            await joinRoom(id, message['roomId']);
            await updateConnectionMetadata(id, {
              'currentRoom': message['roomId'],
              'username': message['username'],
            });
            break;
            
          case 'leave_room':
            await leaveRoom(id, message['roomId']);
            break;
            
          case 'send_message':
            await ChatService.handleUserMessage(
              id,
              message['roomId'],
              message,
            );
            break;
            
          case 'list_rooms':
            final roomList = await ChatService.getRoomList();
            websocket.add(jsonEncode({
              'type': 'room_list',
              'rooms': roomList,
            }));
            break;
        }
      });
    },
    onConnect: (context, websocket, id) async {
      // Send available rooms
      final rooms = await ChatService.getRoomList();
      websocket.add(jsonEncode({
        'type': 'connection_established',
        'connectionId': id,
        'availableRooms': rooms,
      }));
    },
  );
```

### Gaming Lobbies

```dart
class GameLobby {
  static final lobbies = <String, Lobby>{};
  
  static Future<void> createLobby(String lobbyId) async {
    lobbies[lobbyId] = Lobby(id: lobbyId, maxPlayers: 4);
  }
  
  static Future<bool> joinLobby(String connectionId, String lobbyId) async {
    final lobby = lobbies[lobbyId];
    if (lobby == null || lobby.isFull) return false;
    
    await joinRoom(connectionId, lobbyId);
    lobby.addPlayer(connectionId);
    
    // Notify all players in lobby
    await emitToRoom(lobbyId, jsonEncode({
      'type': 'player_joined',
      'playerId': connectionId,
      'playerCount': lobby.playerCount,
      'isGameReady': lobby.isGameReady,
    }));
    
    return true;
  }
  
  static Future<void> startGame(String lobbyId) async {
    final lobby = lobbies[lobbyId];
    if (lobby == null || !lobby.isGameReady) return;
    
    lobby.status = LobbyStatus.inGame;
    
    await emitToRoom(lobbyId, jsonEncode({
      'type': 'game_started',
      'gameId': lobby.gameId,
      'players': lobby.players,
    }));
  }
}
```

### Live Streaming with Rooms

```dart
// Stream viewer system
route.get('/ws/stream/:streamId')
  .handleWebSocket(
    (context, websocket, id) {
      final streamId = context.pathParameters['streamId']!;
      
      websocket.listen((data) async {
        final message = jsonDecode(data);
        
        switch (message['type']) {
          case 'chat':
            // Broadcast chat to all viewers
            await emitToRoom('stream:$streamId', jsonEncode({
              'type': 'stream_chat',
              'from': message['username'],
              'message': message['text'],
              'timestamp': DateTime.now().toIso8601String(),
            }));
            break;
            
          case 'reaction':
            // Send reactions to streamer and other viewers
            await emitToRoom('stream:$streamId', jsonEncode({
              'type': 'viewer_reaction',
              'reaction': message['reaction'],
              'from': id,
            }));
            break;
        }
      });
    },
    onConnect: (context, websocket, id) async {
      final streamId = context.pathParameters['streamId']!;
      
      // Join stream room
      await joinRoom(id, 'stream:$streamId');
      
      // Update viewer count
      final viewers = await getRoomMembers('stream:$streamId');
      
      // Notify about new viewer
      await emitToRoom('stream:$streamId', jsonEncode({
        'type': 'viewer_update',
        'viewerCount': viewers.length,
        'newViewer': id,
      }));
    },
  );
```

## Best Practices

1. **Authenticate connections** - Use before hooks for auth
2. **Validate messages** - Don't trust client input
3. **Handle errors gracefully** - Connections can drop unexpectedly
4. **Limit message size** - Prevent memory issues
5. **Use heartbeats** - Detect stale connections
6. **Clean up resources** - Use after hooks for cleanup
7. **Rate limit messages** - Prevent spam/DoS
8. **Initialize storage early** - Call `initializeWebSocketStorage()` before starting server
9. **Use Redis for scaling** - Enable distributed WebSocket support
10. **Monitor room sizes** - Prevent rooms from growing too large
11. **Clean up empty rooms** - Remove rooms when they become empty
12. **Store user metadata** - Use connection metadata for user context


## Next Steps

- Explore [Static Files](/guides/static-files/) for serving client apps
- Learn about [Error Handling](/core/error-handling/) for robust WebSocket apps
- See [Arcade Cache](/packages/arcade-cache/) for connection storage options