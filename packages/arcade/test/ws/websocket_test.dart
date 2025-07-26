import 'dart:async';
import 'dart:convert';

import 'package:arcade/arcade.dart';
import 'package:arcade_test/arcade_test.dart';
import 'package:test/test.dart';

void main() {
  group('WebSocket', () {
    late ArcadeTestServer server;

    setUpAll(() async {
      // Initialize WebSocket storage once for all tests
      await initializeWebSocketStorage();
    });

    tearDown(() async {
      await server.close();
    });

    tearDownAll(() async {
      // Dispose WebSocket storage after all tests
      await disposeWebSocketStorage();
    });

    group('Basic WebSocket Connection', () {
      test('establishes WebSocket connection', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws').handleWebSocket((context, message, manager) {
            // Echo server
            manager.emit(message);
          });
        });

        final ws = await server.connectWebSocket('/ws');
        expect(ws.isOpen, isTrue);

        await ws.close();
      });

      test('sends and receives messages', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/echo').handleWebSocket((context, message, manager) {
            manager.emit('Echo: $message');
          });
        });

        final ws = await server.connectWebSocket('/ws/echo');

        ws.send(null, 'Hello WebSocket');

        final response = await ws.messages.first;
        expect(response.data, equals('Echo: Hello WebSocket'));

        await ws.close();
      });

      test('handles JSON messages', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/json').handleWebSocket((context, message, manager) {
            final data = jsonDecode(message as String) as Map<String, dynamic>;
            manager.emit(jsonEncode({
              'type': 'response',
              'original': data,
              'timestamp': DateTime.now().toIso8601String(),
            }));
          });
        });

        final ws = await server.connectWebSocket('/ws/json');

        ws.send(null, jsonEncode({'type': 'request', 'data': 'test'}));

        final response = await ws.messages.first;
        final responseData =
            jsonDecode(response.data as String) as Map<String, dynamic>;

        expect(responseData['type'], equals('response'));
        expect(responseData['original'],
            equals({'type': 'request', 'data': 'test'}));
        expect(responseData, contains('timestamp'));

        await ws.close();
      });

      test('handles binary messages', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/binary').handleWebSocket((context, message, manager) {
            if (message is List<int>) {
              // Echo back the binary data
              manager.emit(message);
            } else {
              manager.emit('Expected binary data');
            }
          });
        });

        final ws = await server.connectWebSocket('/ws/binary');

        final binaryData = [1, 2, 3, 4, 5];
        ws.sendRaw(binaryData);

        final response = await ws.messages.first;
        expect(response.data, equals(binaryData));

        await ws.close();
      });

      test('multiple clients can connect simultaneously', () async {
        final connectedClients = <String>[];

        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/multi').handleWebSocket((context, message, manager) {
            if (message == 'connect') {
              connectedClients.add(manager.id);
              manager.emit('Connected: ${manager.id}');
            }
          });
        });

        final ws1 = await server.connectWebSocket('/ws/multi');
        final ws2 = await server.connectWebSocket('/ws/multi');
        final ws3 = await server.connectWebSocket('/ws/multi');

        ws1.send(null, 'connect');
        ws2.send(null, 'connect');
        ws3.send(null, 'connect');

        await Future.delayed(const Duration(milliseconds: 100));

        expect(connectedClients.length, equals(3));
        expect(connectedClients.toSet().length, equals(3)); // All unique IDs

        await ws1.close();
        await ws2.close();
        await ws3.close();
      });
    });

    group('WebSocket with Context', () {
      test('WebSocket handler has access to request context', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/context').handleWebSocket((context, message, manager) {
            manager.emit(jsonEncode({
              'path': context.path,
              'method': context.method.methodString,
              'headers': {
                'user-agent':
                    context.requestHeaders.value('user-agent') ?? 'not-set',
              },
            }));
          });
        });

        // Note: TestWebSocket doesn't support custom headers on connection
        // This is a limitation of the test client
        final ws = await server.connectWebSocket('/ws/context');

        ws.send(null, 'trigger');

        final response = await ws.messages.first;
        final data =
            jsonDecode(response.data as String) as Map<String, dynamic>;

        expect(data['path'], equals('/ws/context'));
        expect(data['method'], equals('GET'));
        expect(data['headers']['user-agent'], isNotNull);

        await ws.close();
      });

      test('WebSocket with path parameters', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/ws/room/:roomId/user/:userId')
              .handleWebSocket((context, message, manager) {
            final roomId = context.pathParameters['roomId'];
            final userId = context.pathParameters['userId'];
            manager.emit(jsonEncode({
              'roomId': roomId,
              'userId': userId,
              'message': message,
            }));
          });
        });

        final ws = await server.connectWebSocket('/ws/room/lobby/user/alice');

        ws.send(null, 'Hello from Alice');

        final response = await ws.messages.first;
        final data =
            jsonDecode(response.data as String) as Map<String, dynamic>;

        expect(data['roomId'], equals('lobby'));
        expect(data['userId'], equals('alice'));
        expect(data['message'], equals('Hello from Alice'));

        await ws.close();
      });

      test('WebSocket with query parameters', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/query').handleWebSocket((context, message, manager) {
            final token = context.queryParameters['token'];
            final debug = context.queryParameters['debug'] == 'true';
            manager.emit(jsonEncode({
              'authenticated': token == 'valid-token',
              'debug': debug,
              'message': message,
            }));
          });
        });

        final ws = await server
            .connectWebSocket('/ws/query?token=valid-token&debug=true');

        ws.send(null, 'Test message');

        final response = await ws.messages.first;
        final data =
            jsonDecode(response.data as String) as Map<String, dynamic>;

        expect(data['authenticated'], isTrue);
        expect(data['debug'], isTrue);
        expect(data['message'], equals('Test message'));

        await ws.close();
      });
    });

    group('WebSocket Lifecycle', () {
      test('onConnect callback is called when client connects', () async {
        final connectedIds = <String>[];

        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/lifecycle').handleWebSocket(
            (context, message, manager) {
              manager.emit('Message received: $message');
            },
            onConnect: (context, manager) {
              connectedIds.add(manager.id);
              manager.emit('Welcome! Your ID is: ${manager.id}');
            },
          );
        });

        final ws = await server.connectWebSocket('/ws/lifecycle');

        // Wait for welcome message
        final welcomeMsg = await ws.messages.first;
        expect(welcomeMsg.data, contains('Welcome! Your ID is:'));
        expect(connectedIds.length, equals(1));

        await ws.close();
      });

      test('manager.close() closes the connection', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/close').handleWebSocket((context, message, manager) {
            if (message == 'close') {
              manager.emit('Goodbye!');
              manager.close();
            } else {
              manager.emit('Echo: $message');
            }
          });
        });

        final ws = await server.connectWebSocket('/ws/close');

        // Collect all messages from the start
        final messages = <String>[];
        final closeCompleter = Completer<void>();

        ws.messages.listen(
          (msg) {
            messages.add(msg.data as String);
          },
          onDone: () {
            closeCompleter.complete();
          },
        );

        // First send a normal message
        ws.send(null, 'Hello');

        // Give time for echo
        await Future.delayed(const Duration(milliseconds: 100));
        expect(messages, contains('Echo: Hello'));

        // Then request close
        ws.send(null, 'close');

        // Wait for the connection to close
        await closeCompleter.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            throw TimeoutException(
                'WebSocket did not close after manager.close()');
          },
        );

        // Should have received both messages
        expect(messages.length, equals(2));
        expect(messages[0], equals('Echo: Hello'));
        expect(messages[1], equals('Goodbye!'));
      });

      test('handles client disconnect gracefully', () async {
        final disconnectedIds = <String>[];

        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/disconnect').handleWebSocket(
            (context, message, manager) {
              if (message == 'ping') {
                manager.emit('pong');
              }
            },
            onConnect: (context, manager) {
              // Track when this specific connection is cleaned up
            },
          ).after((context, result, wsId) {
            // After hook runs when WebSocket disconnects
            disconnectedIds.add(wsId);
            return (context, result, wsId);
          });
        });

        final ws = await server.connectWebSocket('/ws/disconnect');

        // Verify connection
        ws.send(null, 'ping');
        final response = await ws.messages.first;
        expect(response.data, equals('pong'));

        // Verify no disconnections yet
        expect(disconnectedIds, isEmpty);

        // Close connection
        await ws.close();

        // Wait for the after hook to execute
        await Future.delayed(const Duration(milliseconds: 500));

        // Verify that the after hook was called with the WebSocket ID
        expect(disconnectedIds.length, equals(1));
      });
    });

    group('WebSocket Error Handling', () {
      test('handles handler exceptions gracefully', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/error').handleWebSocket((context, message, manager) {
            if (message == 'error') {
              throw Exception('Test exception');
            }
            manager.emit('Echo: $message');
          });
        });

        final ws = await server.connectWebSocket('/ws/error');

        // Collect all messages
        final messages = <String>[];
        ws.messages.listen((msg) {
          messages.add(msg.data as String);
        });

        // Normal message should work
        ws.send(null, 'Hello');
        await Future.delayed(const Duration(milliseconds: 100));
        expect(messages, contains('Echo: Hello'));

        // Error message - connection should remain open despite exception
        ws.send(null, 'error');
        await Future.delayed(const Duration(milliseconds: 100));

        // Send another message to verify connection is still open
        ws.send(null, 'Still alive?');
        await Future.delayed(const Duration(milliseconds: 100));
        expect(messages.last, equals('Echo: Still alive?'));

        await ws.close();
      });

      test('rejects non-WebSocket requests', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/only').handleWebSocket((context, message, manager) {
            manager.emit('WebSocket only');
          });
        });

        // Regular HTTP request should fail
        final response = await server.get('/ws/only');
        expect(response, hasStatus(400));
      });
    });

    group('WebSocket with Hooks', () {
      test('before hooks run for WebSocket routes', () async {
        final executedHooks = <String>[];

        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/hooks').before((ctx) {
            executedHooks.add('before-hook');
            ctx.responseHeaders.add('x-hook-executed', 'true');
            return ctx;
          }).handleWebSocket((context, message, manager) {
            manager.emit(jsonEncode({
              'message': message,
              'hookExecuted':
                  context.responseHeaders['x-hook-executed'] != null,
            }));
          });
        });

        final ws = await server.connectWebSocket('/ws/hooks');

        ws.send(null, 'Test');

        final response = await ws.messages.first;
        final data =
            jsonDecode(response.data as String) as Map<String, dynamic>;

        expect(executedHooks, contains('before-hook'));
        expect(data['message'], equals('Test'));

        await ws.close();
      });

      test('after hooks run when WebSocket disconnects', () async {
        final afterHookMessages = <String>[];

        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/ws/after-hook')
              .handleWebSocket((context, message, manager) {
            manager.emit('Original: $message');
            // WebSocket handlers don't return values
          }).after((context, result, wsId) {
            afterHookMessages
                .add('After hook executed for: $wsId when disconnecting');
            return (context, result, wsId);
          });
        });

        final ws = await server.connectWebSocket('/ws/after-hook');

        ws.send(null, 'Test message');

        final response = await ws.messages.first;
        expect(response.data, equals('Original: Test message'));

        // After hooks should not have run yet
        expect(afterHookMessages.length, equals(0));

        // Close the WebSocket - this should trigger after hooks
        await ws.close();

        // Give time for the after hook to execute
        await Future.delayed(const Duration(milliseconds: 100));

        // Now after hooks should have run
        expect(afterHookMessages.length, equals(1));
        expect(afterHookMessages.first, contains('After hook executed for:'));
        expect(afterHookMessages.first, contains('when disconnecting'));
      });

      test('global hooks affect WebSocket routes', () async {
        final globalHookExecutions = <String>[];

        server = await ArcadeTestServer.withRoutes(() {
          route.registerGlobalBeforeHook((ctx) {
            globalHookExecutions.add('global-before');
            return ctx;
          });

          route.registerGlobalAfterWebSocketHook((ctx, result, wsId) {
            globalHookExecutions.add('global-after-ws');
            return (ctx, result, wsId);
          });

          route.get('/ws/global').handleWebSocket((context, message, manager) {
            manager.emit('Processed: $message');
          });
        });

        final ws = await server.connectWebSocket('/ws/global');

        ws.send(null, 'Test');

        final response = await ws.messages.first;
        expect(response.data, equals('Processed: Test'));

        // Before hook should have run during connection
        expect(globalHookExecutions, contains('global-before'));

        // After WebSocket hook should not have run yet
        expect(globalHookExecutions, isNot(contains('global-after-ws')));

        // Close WebSocket to trigger after hooks
        await ws.close();

        // Give time for after hooks to execute
        await Future.delayed(const Duration(milliseconds: 100));

        // Now global after WebSocket hook should have run
        expect(globalHookExecutions, contains('global-after-ws'));
      });
    });

    group('WebSocket Broadcasting', () {
      test('emitToAll broadcasts to all connected clients', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route
              .get('/ws/broadcast')
              .handleWebSocket((context, message, manager) async {
            if (message == 'broadcast') {
              await emitToAll('Broadcast message from ${manager.id}');
            }
          });
        });

        final ws1 = await server.connectWebSocket('/ws/broadcast');
        final ws2 = await server.connectWebSocket('/ws/broadcast');
        final ws3 = await server.connectWebSocket('/ws/broadcast');

        // Set up message collectors
        final messages1 = <dynamic>[];
        final messages2 = <dynamic>[];
        final messages3 = <dynamic>[];

        ws1.messages.listen((msg) => messages1.add(msg.data));
        ws2.messages.listen((msg) => messages2.add(msg.data));
        ws3.messages.listen((msg) => messages3.add(msg.data));

        // Client 1 triggers broadcast
        ws1.send(null, 'broadcast');

        await Future.delayed(const Duration(milliseconds: 100));

        // All clients should receive the broadcast
        expect(messages1.length, greaterThan(0));
        expect(messages2.length, greaterThan(0));
        expect(messages3.length, greaterThan(0));

        expect(messages1.last.toString(), contains('Broadcast message from'));
        expect(messages2.last.toString(), contains('Broadcast message from'));
        expect(messages3.last.toString(), contains('Broadcast message from'));

        await ws1.close();
        await ws2.close();
        await ws3.close();
      });

      test('emitTo sends to specific client', () async {
        final clientIds = <String>[];

        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/direct').handleWebSocket(
            (context, message, manager) async {
              if (message == 'get-id') {
                manager.emit(manager.id);
              } else if (message.toString().startsWith('send-to:')) {
                final parts = message.toString().split(':');
                final targetId = parts[1];
                final msg = parts[2];
                await emitTo(targetId, 'Direct message: $msg');
              }
            },
            onConnect: (context, manager) {
              clientIds.add(manager.id);
            },
          );
        });

        final ws1 = await server.connectWebSocket('/ws/direct');
        final ws2 = await server.connectWebSocket('/ws/direct');

        // Set up message collectors first
        final messages1 = <dynamic>[];
        final messages2 = <dynamic>[];
        String? id2;

        ws1.messages.listen((msg) {
          messages1.add(msg.data);
        });

        ws2.messages.listen((msg) {
          messages2.add(msg.data);
          // Capture the ID when it arrives
          if (id2 == null && msg.data is String) {
            id2 = msg.data as String;
          }
        });

        // Get IDs
        ws1.send(null, 'get-id');
        ws2.send(null, 'get-id');

        // Wait for ID to be received
        await Future.delayed(const Duration(milliseconds: 100));

        // Clear the ID messages from our collectors
        messages1.clear();
        messages2.clear();

        // Client 1 sends direct message to client 2
        ws1.send(null, 'send-to:$id2:Hello Client 2');

        await Future.delayed(const Duration(milliseconds: 100));

        // Only client 2 should receive the message
        expect(messages1, isEmpty);
        expect(messages2.length, equals(1));
        expect(messages2.first.toString(),
            equals('Direct message: Hello Client 2'));

        await ws1.close();
        await ws2.close();
      });
    });
  });
}
