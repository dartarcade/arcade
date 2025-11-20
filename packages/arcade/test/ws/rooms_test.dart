import 'dart:async';
import 'dart:convert';

import 'package:arcade/arcade.dart';
import 'package:arcade_test/arcade_test.dart';
import 'package:test/test.dart';

void main() {
  group('WebSocket Rooms', () {
    late ArcadeTestServer server;

    setUpAll(() async {
      // Initialize WebSocket storage once for all tests
      await initializeWebSocketStorage();
    });

    tearDown(() async {
      await server.close();
    });

    tearDownAll(() async {
      // Clean up WebSocket storage after all tests
      await disposeWebSocketStorage();
    });

    group('Basic Room Operations', () {
      test('client can join a room', () async {
        String? joinedClientId;
        String? joinedRoom;

        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/room').handleWebSocket((
            context,
            message,
            manager,
          ) async {
            final data = jsonDecode(message as String) as Map<String, dynamic>;

            if (data['action'] == 'join') {
              final room = data['room'] as String;
              await joinRoom(manager.id, room);
              joinedClientId = manager.id;
              joinedRoom = room;
              manager.emit(
                jsonEncode({
                  'type': 'joined',
                  'room': room,
                  'clientId': manager.id,
                }),
              );
            }
          });
        });

        final ws = await server.connectWebSocket('/ws/room');

        // Collect messages
        final messages = <Map<String, dynamic>>[];
        ws.messages.listen((msg) {
          messages.add(jsonDecode(msg.data as String) as Map<String, dynamic>);
        });

        // Join a room
        ws.send(null, jsonEncode({'action': 'join', 'room': 'lobby'}));

        await Future.delayed(const Duration(milliseconds: 100));

        // Verify join confirmation
        expect(messages.length, equals(1));
        expect(messages[0]['type'], equals('joined'));
        expect(messages[0]['room'], equals('lobby'));

        // Verify room membership
        final members = await getRoomMembers('lobby');
        expect(members, contains(joinedClientId));
        expect(joinedRoom, equals('lobby'));

        await ws.close();
      });

      test('client can leave a room', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/room').handleWebSocket((
            context,
            message,
            manager,
          ) async {
            final data = jsonDecode(message as String) as Map<String, dynamic>;

            switch (data['action']) {
              case 'join':
                final room = data['room'] as String;
                await joinRoom(manager.id, room);
                manager.emit(jsonEncode({'type': 'joined', 'room': room}));
              case 'leave':
                final room = data['room'] as String;
                await leaveRoom(manager.id, room);
                manager.emit(jsonEncode({'type': 'left', 'room': room}));
            }
          });
        });

        final ws = await server.connectWebSocket('/ws/room');

        // Collect messages
        final messages = <Map<String, dynamic>>[];
        ws.messages.listen((msg) {
          messages.add(jsonDecode(msg.data as String) as Map<String, dynamic>);
        });

        // Join a room
        ws.send(null, jsonEncode({'action': 'join', 'room': 'lobby'}));

        await Future.delayed(const Duration(milliseconds: 100));

        // Leave the room
        ws.send(null, jsonEncode({'action': 'leave', 'room': 'lobby'}));

        await Future.delayed(const Duration(milliseconds: 100));

        // Verify messages
        expect(messages.length, equals(2));
        expect(messages[0]['type'], equals('joined'));
        expect(messages[1]['type'], equals('left'));

        // Verify room membership
        final members = await getRoomMembers('lobby');
        expect(members, isEmpty);

        await ws.close();
      });

      test('client can be in multiple rooms', () async {
        String? clientId;

        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/room').handleWebSocket((
            context,
            message,
            manager,
          ) async {
            clientId = manager.id;
            final data = jsonDecode(message as String) as Map<String, dynamic>;

            if (data['action'] == 'join') {
              final room = data['room'] as String;
              await joinRoom(manager.id, room);
              manager.emit(jsonEncode({'type': 'joined', 'room': room}));
            }
          });
        });

        final ws = await server.connectWebSocket('/ws/room');

        // Collect messages
        final messages = <Map<String, dynamic>>[];
        ws.messages.listen((msg) {
          messages.add(jsonDecode(msg.data as String) as Map<String, dynamic>);
        });

        // Join multiple rooms
        ws.send(null, jsonEncode({'action': 'join', 'room': 'lobby'}));
        await Future.delayed(const Duration(milliseconds: 50));

        ws.send(null, jsonEncode({'action': 'join', 'room': 'game-1'}));
        await Future.delayed(const Duration(milliseconds: 50));

        ws.send(null, jsonEncode({'action': 'join', 'room': 'chat'}));
        await Future.delayed(const Duration(milliseconds: 50));

        // Verify all joins
        expect(messages.length, equals(3));
        expect(messages[0]['room'], equals('lobby'));
        expect(messages[1]['room'], equals('game-1'));
        expect(messages[2]['room'], equals('chat'));

        // Verify room memberships
        final lobbyMembers = await getRoomMembers('lobby');
        final gameMembers = await getRoomMembers('game-1');
        final chatMembers = await getRoomMembers('chat');

        expect(lobbyMembers, contains(clientId));
        expect(gameMembers, contains(clientId));
        expect(chatMembers, contains(clientId));

        await ws.close();
      });
    });

    group('Room Broadcasting', () {
      test('emitToRoom broadcasts to all clients in a room', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/room').handleWebSocket((
            context,
            message,
            manager,
          ) async {
            final data = jsonDecode(message as String) as Map<String, dynamic>;

            switch (data['action']) {
              case 'join':
                final room = data['room'] as String;
                await joinRoom(manager.id, room);
                manager.emit(
                  jsonEncode({
                    'type': 'joined',
                    'room': room,
                    'clientId': manager.id,
                  }),
                );
              case 'broadcast':
                final room = data['room'] as String;
                final msg = data['message'] as String;
                await emitToRoom(
                  room,
                  jsonEncode({
                    'type': 'room-message',
                    'room': room,
                    'message': msg,
                    'from': manager.id,
                  }),
                );
            }
          });
        });

        // Connect three clients
        final ws1 = await server.connectWebSocket('/ws/room');
        final ws2 = await server.connectWebSocket('/ws/room');
        final ws3 = await server.connectWebSocket('/ws/room');

        // Collect messages for each client
        final messages1 = <Map<String, dynamic>>[];
        final messages2 = <Map<String, dynamic>>[];
        final messages3 = <Map<String, dynamic>>[];

        ws1.messages.listen((msg) {
          messages1.add(jsonDecode(msg.data as String) as Map<String, dynamic>);
        });
        ws2.messages.listen((msg) {
          messages2.add(jsonDecode(msg.data as String) as Map<String, dynamic>);
        });
        ws3.messages.listen((msg) {
          messages3.add(jsonDecode(msg.data as String) as Map<String, dynamic>);
        });

        // Client 1 and 2 join the room
        ws1.send(null, jsonEncode({'action': 'join', 'room': 'game-room'}));
        ws2.send(null, jsonEncode({'action': 'join', 'room': 'game-room'}));
        // Client 3 stays outside the room

        await Future.delayed(const Duration(milliseconds: 100));

        // Clear join messages
        messages1.clear();
        messages2.clear();
        messages3.clear();

        // Client 1 broadcasts to the room
        ws1.send(
          null,
          jsonEncode({
            'action': 'broadcast',
            'room': 'game-room',
            'message': 'Hello room!',
          }),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        // Both clients in the room should receive the message
        expect(messages1.length, equals(1));
        expect(messages1[0]['type'], equals('room-message'));
        expect(messages1[0]['message'], equals('Hello room!'));

        expect(messages2.length, equals(1));
        expect(messages2[0]['type'], equals('room-message'));
        expect(messages2[0]['message'], equals('Hello room!'));

        // Client 3 should not receive the message
        expect(messages3, isEmpty);

        await ws1.close();
        await ws2.close();
        await ws3.close();
      });

      test(
        'client in multiple rooms receives messages from all rooms',
        () async {
          server = await ArcadeTestServer.withRoutes(() {
            route.get('/ws/room').handleWebSocket((
              context,
              message,
              manager,
            ) async {
              final data =
                  jsonDecode(message as String) as Map<String, dynamic>;

              switch (data['action']) {
                case 'join':
                  final room = data['room'] as String;
                  await joinRoom(manager.id, room);
                case 'broadcast':
                  final room = data['room'] as String;
                  final msg = data['message'] as String;
                  await emitToRoom(
                    room,
                    jsonEncode({
                      'type': 'room-message',
                      'room': room,
                      'message': msg,
                    }),
                  );
              }
            });
          });

          // Connect two clients
          final ws1 = await server.connectWebSocket('/ws/room');
          final ws2 = await server.connectWebSocket('/ws/room');

          // Collect messages
          final messages1 = <Map<String, dynamic>>[];
          ws1.messages.listen((msg) {
            messages1.add(
              jsonDecode(msg.data as String) as Map<String, dynamic>,
            );
          });

          // Client 1 joins multiple rooms
          ws1.send(null, jsonEncode({'action': 'join', 'room': 'room-a'}));
          ws1.send(null, jsonEncode({'action': 'join', 'room': 'room-b'}));

          // Client 2 joins only room-a
          ws2.send(null, jsonEncode({'action': 'join', 'room': 'room-a'}));

          await Future.delayed(const Duration(milliseconds: 100));
          messages1.clear();

          // Broadcast to room-a
          ws2.send(
            null,
            jsonEncode({
              'action': 'broadcast',
              'room': 'room-a',
              'message': 'Message to room A',
            }),
          );

          // Broadcast to room-b (from client 1)
          ws1.send(
            null,
            jsonEncode({
              'action': 'broadcast',
              'room': 'room-b',
              'message': 'Message to room B',
            }),
          );

          await Future.delayed(const Duration(milliseconds: 100));

          // Client 1 should receive both messages
          expect(messages1.length, equals(2));
          expect(
            messages1.any(
              (m) =>
                  m['room'] == 'room-a' && m['message'] == 'Message to room A',
            ),
            isTrue,
          );
          expect(
            messages1.any(
              (m) =>
                  m['room'] == 'room-b' && m['message'] == 'Message to room B',
            ),
            isTrue,
          );

          await ws1.close();
          await ws2.close();
        },
      );
    });

    group('Room Edge Cases', () {
      test('invalid room names are rejected', () async {
        String? errorMessage;

        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/room').handleWebSocket((
            context,
            message,
            manager,
          ) async {
            final data = jsonDecode(message as String) as Map<String, dynamic>;

            if (data['action'] == 'join') {
              final room = data['room'] as String;
              try {
                await joinRoom(manager.id, room);
                manager.emit(jsonEncode({'type': 'joined', 'room': room}));
              } catch (e) {
                errorMessage = e.toString();
                manager.emit(
                  jsonEncode({'type': 'error', 'message': 'Invalid room name'}),
                );
              }
            }
          });
        });

        final ws = await server.connectWebSocket('/ws/room');

        // Collect messages
        final messages = <Map<String, dynamic>>[];
        ws.messages.listen((msg) {
          messages.add(jsonDecode(msg.data as String) as Map<String, dynamic>);
        });

        // Try to join room with invalid name (contains spaces)
        ws.send(
          null,
          jsonEncode({'action': 'join', 'room': 'invalid room name'}),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        expect(messages.length, equals(1));
        expect(messages[0]['type'], equals('error'));
        expect(errorMessage, contains('Invalid room name'));

        await ws.close();
      });

      test('leaving a room not joined is handled gracefully', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/room').handleWebSocket((
            context,
            message,
            manager,
          ) async {
            final data = jsonDecode(message as String) as Map<String, dynamic>;

            if (data['action'] == 'leave') {
              final room = data['room'] as String;
              await leaveRoom(manager.id, room);
              manager.emit(jsonEncode({'type': 'left', 'room': room}));
            }
          });
        });

        final ws = await server.connectWebSocket('/ws/room');

        // Collect messages
        final messages = <Map<String, dynamic>>[];
        ws.messages.listen((msg) {
          messages.add(jsonDecode(msg.data as String) as Map<String, dynamic>);
        });

        // Try to leave a room never joined
        ws.send(null, jsonEncode({'action': 'leave', 'room': 'never-joined'}));

        await Future.delayed(const Duration(milliseconds: 100));

        // Should handle gracefully
        expect(messages.length, equals(1));
        expect(messages[0]['type'], equals('left'));
        expect(messages[0]['room'], equals('never-joined'));

        await ws.close();
      });

      test('client disconnect removes them from all rooms', () async {
        String? clientId;

        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/room').handleWebSocket((
            context,
            message,
            manager,
          ) async {
            clientId = manager.id;
            final data = jsonDecode(message as String) as Map<String, dynamic>;

            if (data['action'] == 'join') {
              final room = data['room'] as String;
              await joinRoom(manager.id, room);
            }
          });
        });

        final ws = await server.connectWebSocket('/ws/room');

        // Join multiple rooms with delays between each join
        ws.send(null, jsonEncode({'action': 'join', 'room': 'room1'}));
        await Future.delayed(const Duration(milliseconds: 50));

        ws.send(null, jsonEncode({'action': 'join', 'room': 'room2'}));
        await Future.delayed(const Duration(milliseconds: 50));

        ws.send(null, jsonEncode({'action': 'join', 'room': 'room3'}));
        await Future.delayed(const Duration(milliseconds: 50));

        // Verify memberships
        expect(await getRoomMembers('room1'), contains(clientId));
        expect(await getRoomMembers('room2'), contains(clientId));
        expect(await getRoomMembers('room3'), contains(clientId));

        // Get connection info before disconnect
        final connInfo = await getConnectionInfo(clientId!);
        expect(connInfo, isNotNull);
        expect(connInfo!.rooms, hasLength(3));

        // Disconnect
        await ws.close();

        // Wait and poll for cleanup
        var retries = 0;
        while (retries < 20) {
          await Future.delayed(const Duration(milliseconds: 100));

          // Check if connection is removed
          final info = await getConnectionInfo(clientId!);
          if (info == null) {
            // Connection removed, rooms should be cleaned up
            break;
          }
          retries++;
        }

        // Verify removed from all rooms
        expect(await getRoomMembers('room1'), isNot(contains(clientId)));
        expect(await getRoomMembers('room2'), isNot(contains(clientId)));
        expect(await getRoomMembers('room3'), isNot(contains(clientId)));
      });
    });
  });
}
