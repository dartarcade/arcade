import 'dart:async';
import 'dart:convert';

import 'package:arcade/arcade.dart';
import 'package:arcade_test/arcade_test.dart';
import 'package:test/test.dart';

void main() {
  group('WebSocket Storage Manager', () {
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

    group('Connection Information', () {
      test('stores and retrieves connection info', () async {
        String? connectionId;

        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/info').handleWebSocket(
            (context, message, manager) async {
              connectionId = manager.id;
              if (message == 'get-info') {
                final info = await getConnectionInfo(manager.id);
                manager.emit(jsonEncode({
                  'id': info?.id,
                  'serverInstanceId': info?.serverInstanceId,
                  'hasConnectTime': info?.connectTime != null,
                  'metadata': info?.metadata,
                }));
              }
            },
          );
        });

        final ws = await server.connectWebSocket('/ws/info');

        // Collect messages
        final messages = <Map<String, dynamic>>[];
        ws.messages.listen((msg) {
          messages.add(jsonDecode(msg.data as String) as Map<String, dynamic>);
        });

        // Request connection info
        ws.send(null, 'get-info');

        await Future.delayed(const Duration(milliseconds: 100));

        // Verify connection info
        expect(messages.length, equals(1));
        expect(messages[0]['id'], isNotNull);
        expect(messages[0]['serverInstanceId'], isNotNull);
        expect(messages[0]['hasConnectTime'], isTrue);
        expect(messages[0]['metadata'], isA<Map>());

        // Verify we can get connection info directly
        final info = await getConnectionInfo(connectionId!);
        expect(info, isNotNull);
        expect(info!.id, equals(connectionId));

        await ws.close();
      });

      test('updates connection metadata', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/metadata').handleWebSocket(
            (context, message, manager) async {
              final data =
                  jsonDecode(message as String) as Map<String, dynamic>;

              if (data['action'] == 'update-metadata') {
                await updateConnectionMetadata(
                    manager.id, data['metadata'] as Map<String, dynamic>);

                // Get updated info
                final info = await getConnectionInfo(manager.id);
                manager.emit(jsonEncode({
                  'metadata': info?.metadata,
                }));
              }
            },
          );
        });

        final ws = await server.connectWebSocket('/ws/metadata');

        // Collect messages
        final messages = <Map<String, dynamic>>[];
        ws.messages.listen((msg) {
          messages.add(jsonDecode(msg.data as String) as Map<String, dynamic>);
        });

        // Update metadata
        ws.send(
            null,
            jsonEncode({
              'action': 'update-metadata',
              'metadata': {
                'username': 'test-user',
                'role': 'admin',
                'custom': {'level': 5},
              },
            }));

        await Future.delayed(const Duration(milliseconds: 100));

        // Verify metadata was updated
        expect(messages.length, equals(1));
        final metadata = messages[0]['metadata'] as Map<String, dynamic>;
        expect(metadata['username'], equals('test-user'));
        expect(metadata['role'], equals('admin'));
        final custom = metadata['custom'] as Map<String, dynamic>;
        expect(custom['level'], equals(5));

        await ws.close();
      });

      test('returns null for non-existent connection', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/dummy').handleWebSocket(
                (context, message, manager) {},
              );
        });

        // Check non-existent connection
        final info = await getConnectionInfo('non-existent-id');
        expect(info, isNull);
      });
    });

    group('Connection Lists', () {
      test('getAllConnections returns all active connections', () async {
        final connectionIds = <String>[];

        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/list').handleWebSocket(
            (context, message, manager) async {
              connectionIds.add(manager.id);
              if (message == 'list-all') {
                final connections = await getAllConnections();
                manager.emit(jsonEncode({
                  'count': connections.length,
                  'ids': connections.map((c) => c.id).toList(),
                }));
              }
            },
          );
        });

        // Connect multiple clients
        final ws1 = await server.connectWebSocket('/ws/list');
        final ws2 = await server.connectWebSocket('/ws/list');
        final ws3 = await server.connectWebSocket('/ws/list');

        await Future.delayed(const Duration(milliseconds: 100));

        // Get connection list from first client
        final messages = <Map<String, dynamic>>[];
        ws1.messages.listen((msg) {
          messages.add(jsonDecode(msg.data as String) as Map<String, dynamic>);
        });

        ws1.send(null, 'list-all');

        await Future.delayed(const Duration(milliseconds: 100));

        // Verify all connections are listed
        expect(messages.length, equals(1));
        expect(messages[0]['count'], equals(3));
        expect(messages[0]['ids'], containsAll(connectionIds));

        await ws1.close();
        await ws2.close();
        await ws3.close();
      });

      test('getLocalConnections returns only local server connections',
          () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/local').handleWebSocket(
            (context, message, manager) async {
              if (message == 'list-local') {
                final connections = await getLocalConnections();
                manager.emit(jsonEncode({
                  'count': connections.length,
                  'allSameServer': connections
                      .every((c) => c.serverInstanceId == serverInstanceId),
                }));
              }
            },
          );
        });

        final ws = await server.connectWebSocket('/ws/local');

        // Collect messages
        final messages = <Map<String, dynamic>>[];
        ws.messages.listen((msg) {
          messages.add(jsonDecode(msg.data as String) as Map<String, dynamic>);
        });

        ws.send(null, 'list-local');

        await Future.delayed(const Duration(milliseconds: 100));

        // Verify local connections
        expect(messages.length, equals(1));
        expect(messages[0]['count'], greaterThan(0));
        expect(messages[0]['allSameServer'], isTrue);

        await ws.close();
      });
    });

    group('Local Connection Tracking', () {
      test('hasLocalConnections returns correct state', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/has-local').handleWebSocket(
            (context, message, manager) {
              manager.emit(jsonEncode({
                'hasLocal': hasLocalConnections,
              }));
            },
          );
        });

        // Before any connections
        expect(hasLocalConnections, isFalse);

        final ws = await server.connectWebSocket('/ws/has-local');

        // After connection
        expect(hasLocalConnections, isTrue);

        await ws.close();

        // Wait for cleanup
        await Future.delayed(const Duration(milliseconds: 500));

        // After disconnect
        expect(hasLocalConnections, isFalse);
      });

      test('localConnectionIds returns current connection IDs', () async {
        final trackedIds = <String>[];

        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/ids').handleWebSocket(
            (context, message, manager) {
              trackedIds.add(manager.id);
              if (message == 'get-ids') {
                manager.emit(jsonEncode({
                  'ids': localConnectionIds.toList(),
                }));
              }
            },
          );
        });

        // Connect multiple clients
        final ws1 = await server.connectWebSocket('/ws/ids');
        final ws2 = await server.connectWebSocket('/ws/ids');

        await Future.delayed(const Duration(milliseconds: 100));

        // Get local IDs
        final messages = <Map<String, dynamic>>[];
        ws1.messages.listen((msg) {
          messages.add(jsonDecode(msg.data as String) as Map<String, dynamic>);
        });

        ws1.send(null, 'get-ids');

        await Future.delayed(const Duration(milliseconds: 100));

        // Verify IDs match
        expect(messages.length, equals(1));
        expect(messages[0]['ids'], containsAll(trackedIds.take(2)));
        expect((messages[0]['ids'] as List).length, equals(2));

        await ws1.close();
        await ws2.close();
      });
    });

    group('Server Instance', () {
      test('serverInstanceId is consistent', () async {
        String? instanceId1;
        String? instanceId2;

        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/instance').handleWebSocket(
            (context, message, manager) async {
              if (message == 'get-instance') {
                final info = await getConnectionInfo(manager.id);
                manager.emit(jsonEncode({
                  'serverInstanceId': info?.serverInstanceId,
                  'globalInstanceId': serverInstanceId,
                }));
              }
            },
          );
        });

        final ws1 = await server.connectWebSocket('/ws/instance');
        final ws2 = await server.connectWebSocket('/ws/instance');

        // Collect messages
        final messages1 = <Map<String, dynamic>>[];
        final messages2 = <Map<String, dynamic>>[];

        ws1.messages.listen((msg) {
          final data = jsonDecode(msg.data as String) as Map<String, dynamic>;
          messages1.add(data);
          instanceId1 = data['serverInstanceId'] as String?;
        });

        ws2.messages.listen((msg) {
          final data = jsonDecode(msg.data as String) as Map<String, dynamic>;
          messages2.add(data);
          instanceId2 = data['serverInstanceId'] as String?;
        });

        ws1.send(null, 'get-instance');
        ws2.send(null, 'get-instance');

        await Future.delayed(const Duration(milliseconds: 100));

        // Verify same server instance ID
        expect(instanceId1, isNotNull);
        expect(instanceId2, isNotNull);
        expect(instanceId1, equals(instanceId2));
        expect(
            messages1[0]['globalInstanceId'] as String?, equals(instanceId1));
        expect(
            messages2[0]['globalInstanceId'] as String?, equals(instanceId2));

        await ws1.close();
        await ws2.close();
      });
    });

    group('Connection Health', () {
      test('validateConnectionHealth maintains healthy connections', () async {
        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/health').handleWebSocket(
            (context, message, manager) async {
              if (message == 'validate') {
                await validateConnectionHealth();
                manager.emit('health-check-complete');
              } else {
                manager.emit('echo: $message');
              }
            },
          );
        });

        final ws = await server.connectWebSocket('/ws/health');

        // Collect messages
        final messages = <String>[];
        ws.messages.listen((msg) {
          messages.add(msg.data as String);
        });

        // Test connection before health check
        ws.send(null, 'ping');
        await Future.delayed(const Duration(milliseconds: 50));
        expect(messages.last, equals('echo: ping'));

        // Run health check
        ws.send(null, 'validate');
        await Future.delayed(const Duration(milliseconds: 100));
        expect(messages.last, equals('health-check-complete'));

        // Test connection after health check - should still work
        ws.send(null, 'pong');
        await Future.delayed(const Duration(milliseconds: 50));
        expect(messages.last, equals('echo: pong'));

        await ws.close();
      });
    });

    group('Edge Cases', () {
      test('handles multiple concurrent connections', () async {
        final connectedIds = <String>{};

        server = await ArcadeTestServer.withRoutes(() {
          route.get('/ws/concurrent').handleWebSocket(
            (context, message, manager) async {
              if (message == 'broadcast') {
                await emitToAll('Broadcast from ${manager.id}');
              }
            },
            onConnect: (context, manager) {
              connectedIds.add(manager.id);
              manager.emit('connected: ${manager.id}');
            },
          );
        });

        // Collect messages
        final messages1 = <String>[];
        final messages2 = <String>[];
        final messages3 = <String>[];

        // Connect multiple clients
        final ws1 = await server.connectWebSocket('/ws/concurrent');
        ws1.messages.listen((msg) => messages1.add(msg.data as String));

        final ws2 = await server.connectWebSocket('/ws/concurrent');
        ws2.messages.listen((msg) => messages2.add(msg.data as String));

        final ws3 = await server.connectWebSocket('/ws/concurrent');
        ws3.messages.listen((msg) => messages3.add(msg.data as String));

        await Future.delayed(const Duration(milliseconds: 200));

        // Verify all connected
        expect(connectedIds.length, equals(3));
        expect(messages1.length, equals(1));
        expect(messages2.length, equals(1));
        expect(messages3.length, equals(1));

        // Clear initial messages
        messages1.clear();
        messages2.clear();
        messages3.clear();

        // Test broadcast
        ws1.send(null, 'broadcast');
        await Future.delayed(const Duration(milliseconds: 100));

        // All should receive broadcast
        expect(messages1.length, equals(1));
        expect(messages2.length, equals(1));
        expect(messages3.length, equals(1));

        await ws1.close();
        await ws2.close();
        await ws3.close();
      });
    });
  });
}
