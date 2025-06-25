---
title: WebSockets Guide
description: Building real-time applications with Arcade's WebSocket support
---

Arcade provides built-in WebSocket support for creating real-time applications. This guide covers everything from basic connections to advanced patterns.

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

## Chat Room Example

Build a complete chat room with rooms and user management:

```dart
class ChatRoom {
  final String id;
  final String name;
  final Set<String> users = {};
  final List<ChatMessage> messages = [];
  
  ChatRoom({required this.id, required this.name});
  
  void addUser(String userId) {
    users.add(userId);
  }
  
  void removeUser(String userId) {
    users.remove(userId);
  }
  
  void addMessage(ChatMessage message) {
    messages.add(message);
    // Keep last 100 messages
    if (messages.length > 100) {
      messages.removeAt(0);
    }
  }
}

class ChatMessage {
  final String id;
  final String userId;
  final String message;
  final DateTime timestamp;
  
  ChatMessage({
    required this.id,
    required this.userId,
    required this.message,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
  };
}

final chatRooms = <String, ChatRoom>{};

route.get('/ws/chat/:roomId')
  .handleWebSocket(
    (context, websocket, id) {
      final roomId = context.pathParameters['roomId']!;
      var room = chatRooms[roomId];
      
      if (room == null) {
        websocket.add(jsonEncode({'error': 'Room not found'}));
        websocket.close();
        return;
      }
      
      // Store room association
      WebSocketManager.setConnectionData(id, {'roomId': roomId});
      
      websocket.listen(
        (data) {
          final json = jsonDecode(data);
          final type = json['type'];
          
          switch (type) {
            case 'message':
              final message = ChatMessage(
                id: Uuid().v4(),
                userId: id,
                message: json['message'],
                timestamp: DateTime.now(),
              );
              
              room.addMessage(message);
              
              // Broadcast to room members
              for (final userId in room.users) {
                emitTo(userId, 'message', message.toJson());
              }
              break;
              
            case 'typing':
              // Notify others that user is typing
              for (final userId in room.users) {
                if (userId != id) {
                  emitTo(userId, 'user-typing', {'userId': id});
                }
              }
              break;
          }
        },
        onDone: () {
          // Remove user from room
          room?.removeUser(id);
          
          // Notify others
          for (final userId in room?.users ?? {}) {
            emitTo(userId, 'user-left', {'userId': id});
          }
        },
      );
    },
    onConnect: (context, websocket, id) {
      final roomId = context.pathParameters['roomId']!;
      final room = chatRooms[roomId]!;
      
      // Add user to room
      room.addUser(id);
      
      // Send room info and history
      websocket.add(jsonEncode({
        'type': 'room-info',
        'room': {
          'id': room.id,
          'name': room.name,
          'users': room.users.toList(),
        },
        'messages': room.messages.map((m) => m.toJson()).toList(),
      }));
      
      // Notify others
      for (final userId in room.users) {
        if (userId != id) {
          emitTo(userId, 'user-joined', {'userId': id});
        }
      }
    },
  );

// Create room endpoint
route.post('/api/rooms').handle((context) async {
  final result = await context.jsonMap();
  
  if (result case BodyParseSuccess(:final value)) {
    final roomId = Uuid().v4();
    final room = ChatRoom(
      id: roomId,
      name: value['name'],
    );
    
    chatRooms[roomId] = room;
    
    return {
      'id': roomId,
      'name': room.name,
      'wsUrl': '/ws/chat/$roomId',
    };
  }
  
  throw BadRequestException();
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

## Connection Management

Monitor and manage WebSocket connections:

```dart
// Get all connected clients
route.get('/api/ws/connections').handle((context) {
  final connections = WebSocketManager.getConnectedIds();
  
  return {
    'count': connections.length,
    'connections': connections.map((id) {
      final data = WebSocketManager.getConnectionData(id);
      return {
        'id': id,
        'data': data,
      };
    }).toList(),
  };
});

// Disconnect specific client
route.delete('/api/ws/connections/:id').handle((context) {
  final connectionId = context.pathParameters['id']!;
  
  // Send disconnect message
  final sent = emitTo(connectionId, 'disconnect', {
    'reason': 'Admin action',
  });
  
  if (!sent) {
    throw NotFoundException(message: 'Connection not found');
  }
  
  // The client should close the connection upon receiving this message
  
  return {'disconnected': true};
});
```

## Best Practices

1. **Authenticate connections** - Use before hooks for auth
2. **Validate messages** - Don't trust client input
3. **Handle errors gracefully** - Connections can drop unexpectedly
4. **Limit message size** - Prevent memory issues
5. **Use heartbeats** - Detect stale connections
6. **Clean up resources** - Use after hooks for cleanup
7. **Rate limit messages** - Prevent spam/DoS

## Client-Side Example

JavaScript client for connecting to Arcade WebSocket:

```javascript
class ArcadeWebSocket {
  constructor(url) {
    this.url = url;
    this.ws = null;
    this.reconnectDelay = 1000;
    this.maxReconnectDelay = 30000;
  }
  
  connect() {
    this.ws = new WebSocket(this.url);
    
    this.ws.onopen = () => {
      console.log('Connected to Arcade WebSocket');
      this.reconnectDelay = 1000;
    };
    
    this.ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        this.handleMessage(data);
      } catch (e) {
        console.log('Received:', event.data);
      }
    };
    
    this.ws.onerror = (error) => {
      console.error('WebSocket error:', error);
    };
    
    this.ws.onclose = () => {
      console.log('Disconnected from Arcade WebSocket');
      this.reconnect();
    };
  }
  
  reconnect() {
    setTimeout(() => {
      console.log('Attempting to reconnect...');
      this.connect();
      this.reconnectDelay = Math.min(
        this.reconnectDelay * 2,
        this.maxReconnectDelay
      );
    }, this.reconnectDelay);
  }
  
  send(type, data) {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify({ type, ...data }));
    }
  }
  
  handleMessage(data) {
    // Override in subclass
    console.log('Message:', data);
  }
}

// Usage
const ws = new ArcadeWebSocket('ws://localhost:3000/ws/chat/room123');
ws.connect();
ws.send('message', { message: 'Hello, Arcade!' });
```

## Next Steps

- Explore [Static Files](/guides/static-files/) for serving client apps
- Learn about [Dependency Injection](/guides/dependency-injection/) for complex services
- See [Error Handling](/core/error-handling/) for robust WebSocket apps