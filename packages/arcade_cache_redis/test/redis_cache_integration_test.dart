import 'dart:async';
import 'dart:io';

import 'package:arcade_cache/arcade_cache.dart';
import 'package:arcade_cache_redis/arcade_cache_redis.dart';
import 'package:test/test.dart';

void main() {
  group('Redis Cache Integration Tests', () {
    late RedisCacheManager cache;

    setUpAll(() async {
      // Check if Redis is running
      try {
        final result = await Process.run('docker', ['ps']);
        if (!result.stdout.toString().contains('redis')) {
          fail(
              'Redis container is not running. Please run: docker-compose up -d');
        }
      } catch (e) {
        fail('Docker is not available or Redis is not running: $e');
      }
    });

    setUp(() async {
      cache = RedisCacheManager();
      await cache.init((host: 'localhost', port: 6379, secure: false));
      await cache.clear(); // Start with clean state
    });

    tearDown(() async {
      await cache.dispose();
    });

    group('Basic Operations', () {
      test('init connects to Redis successfully', () async {
        // Already connected in setUp, just verify we can perform operations
        await cache.set('test_key', 'test_value');
        final value = await cache.get<String>('test_key');
        expect(value, equals('test_value'));
      });

      test('set and get string values', () async {
        await cache.set('string_key', 'Hello Redis');
        final value = await cache.get<String>('string_key');
        expect(value, equals('Hello Redis'));
      });

      test('set and get numeric values', () async {
        await cache.set('int_key', 42);
        await cache.set('double_key', 3.14);

        final intValue = await cache.get<String>('int_key');
        final doubleValue = await cache.get<String>('double_key');

        expect(intValue, equals('42'));
        expect(doubleValue, equals('3.14'));
      });

      test('getString retrieves string values', () async {
        await cache.set('string_key', 'Test String');
        final value = await cache.getString('string_key');
        expect(value, equals('Test String'));
      });

      test('set and getList', () async {
        final list = ['item1', 'item2', 'item3'];
        await cache.set('list_key', list);

        final retrieved = await cache.getList<String>('list_key');
        expect(retrieved, equals(list));
      });

      test('set and getJson', () async {
        final json = {
          'name': 'Test User',
          'age': 30,
          'active': true,
          'tags': ['dart', 'redis', 'cache']
        };
        await cache.set('json_key', json);

        final retrieved = await cache.getJson('json_key');
        expect(retrieved, equals(json));
      });

      test('contains returns true for existing keys', () async {
        await cache.set('exists', 'value');
        expect(await cache.contains('exists'), isTrue);
      });

      test('contains returns false for non-existing keys', () async {
        expect(await cache.contains('does_not_exist'), isFalse);
      });

      test('remove deletes keys', () async {
        await cache.set('to_remove', 'value');
        expect(await cache.contains('to_remove'), isTrue);

        await cache.remove('to_remove');
        expect(await cache.contains('to_remove'), isFalse);
      });

      test('clear removes all keys', () async {
        await cache.set('key1', 'value1');
        await cache.set('key2', 'value2');
        await cache.set('key3', 'value3');

        await cache.clear();

        expect(await cache.contains('key1'), isFalse);
        expect(await cache.contains('key2'), isFalse);
        expect(await cache.contains('key3'), isFalse);
      });

      test('setWithTtl expires keys', () async {
        await cache.setWithTtl(
            'ttl_key', 'expires soon', const Duration(seconds: 1));

        // Key should exist immediately
        expect(await cache.contains('ttl_key'), isTrue);
        expect(await cache.get<String>('ttl_key'), equals('expires soon'));

        // Wait for expiration
        await Future.delayed(const Duration(seconds: 2));

        // Key should be gone
        expect(await cache.contains('ttl_key'), isFalse);
        expect(await cache.get<String>('ttl_key'), isNull);
      });

      test('get returns null for non-existing keys', () async {
        expect(await cache.get<String>('non_existing'), isNull);
        expect(await cache.getString('non_existing'), isNull);
        expect(await cache.getList<String>('non_existing'), isNull);
        expect(await cache.getJson('non_existing'), isNull);
      });
    });

    group('Pub-Sub Operations', () {
      test('subscribe and publish with simple messages', () async {
        final messages = <PubSubEvent>[];
        final subscribeCompleter = Completer<void>();
        final messagesCompleter = Completer<void>();

        final subscription = cache.subscribe<String>(['test_channel']);

        final listener = subscription.listen((event) {
          messages.add(event);

          if (event is PubSubSubscribed && !subscribeCompleter.isCompleted) {
            subscribeCompleter.complete();
          } else if (event is PubSubMessage &&
              messages.whereType<PubSubMessage>().length == 2) {
            messagesCompleter.complete();
          }
        });

        // Wait for subscription to be established
        await expectLater(
          subscribeCompleter.future.timeout(const Duration(seconds: 2)),
          completes,
          reason: 'Subscription should be established within 2 seconds',
        );

        // Publish messages
        final count1 = await cache.publish('test_channel', 'Hello');
        final count2 = await cache.publish('test_channel', 'World');

        // Wait for messages to arrive
        await expectLater(
          messagesCompleter.future.timeout(const Duration(seconds: 2)),
          completes,
          reason: 'Messages should arrive within 2 seconds',
        );

        // Verify
        expect(count1, equals(1));
        expect(count2, equals(1));

        expect(
            messages.length, greaterThanOrEqualTo(3)); // subscribe + 2 messages

        // Check subscribe event
        final subscribeEvent = messages.firstWhere((e) => e is PubSubSubscribed,
            orElse: () => throw StateError('No subscribe event found'));
        expect(subscribeEvent, isA<PubSubSubscribed>());
        expect((subscribeEvent as PubSubSubscribed).channel,
            equals('test_channel'));

        // Check message events
        final messageEvents =
            messages.whereType<PubSubMessage<String>>().toList();
        expect(messageEvents.length, equals(2));
        expect(messageEvents[0].data, equals('Hello'));
        expect(messageEvents[1].data, equals('World'));

        await listener.cancel();
        await cache.unsubscribe(['test_channel']);
      });

      test('subscribe with message mapper', () async {
        final messages = <PubSubMessage<int>>[];
        final subscribeCompleter = Completer<void>();
        final messagesCompleter = Completer<void>();

        final subscription = cache.subscribe<int>(
          ['number_channel'],
          messageMapper: (data) => int.parse(data.toString()),
        );

        final listener = subscription.listen((event) {
          if (event is PubSubSubscribed && !subscribeCompleter.isCompleted) {
            subscribeCompleter.complete();
          } else if (event is PubSubMessage<int>) {
            messages.add(event);
            if (messages.length == 2) {
              messagesCompleter.complete();
            }
          }
        });

        // Wait for subscription
        await expectLater(
          subscribeCompleter.future.timeout(const Duration(seconds: 2)),
          completes,
        );

        await cache.publish('number_channel', '42');
        await cache.publish('number_channel', '100');

        // Wait for messages
        await expectLater(
          messagesCompleter.future.timeout(const Duration(seconds: 2)),
          completes,
        );

        expect(messages.length, equals(2));
        expect(messages[0].data, equals(42));
        expect(messages[1].data, equals(100));

        await listener.cancel();
        await cache.unsubscribe(['number_channel']);
      });

      test('subscribe to multiple channels', () async {
        final events = <PubSubEvent>[];
        final subscribeCompleter = Completer<void>();
        final messagesCompleter = Completer<void>();
        var subscribedChannels = 0;

        final subscription = cache.subscribe<String>(['channel1', 'channel2']);
        final listener = subscription.listen((event) {
          events.add(event);

          if (event is PubSubSubscribed) {
            subscribedChannels++;
            if (subscribedChannels == 2 && !subscribeCompleter.isCompleted) {
              subscribeCompleter.complete();
            }
          } else if (event is PubSubMessage) {
            final messageCount = events.whereType<PubSubMessage>().length;
            if (messageCount == 3) {
              messagesCompleter.complete();
            }
          }
        });

        // Wait for both subscriptions
        await expectLater(
          subscribeCompleter.future.timeout(const Duration(seconds: 2)),
          completes,
        );

        await cache.publish('channel1', 'Message 1');
        await cache.publish('channel2', 'Message 2');
        await cache.publish('channel1', 'Message 3');

        // Wait for all messages
        await expectLater(
          messagesCompleter.future.timeout(const Duration(seconds: 2)),
          completes,
        );

        final messages = events.whereType<PubSubMessage<String>>().toList();
        expect(messages.length, equals(3));

        expect(
            messages.where((m) => m.channel == 'channel1').length, equals(2));
        expect(
            messages.where((m) => m.channel == 'channel2').length, equals(1));

        await listener.cancel();
        await cache.unsubscribe(['channel1', 'channel2']);
      });

      test('publish JSON data', () async {
        final messages = <Map<String, dynamic>>[];
        final subscribeCompleter = Completer<void>();
        final messageCompleter = Completer<void>();

        final subscription = cache.subscribe<Map<String, dynamic>>(
          ['json_channel'],
          messageMapper: (data) => data as Map<String, dynamic>,
        );

        final listener = subscription.listen((event) {
          if (event is PubSubSubscribed && !subscribeCompleter.isCompleted) {
            subscribeCompleter.complete();
          } else if (event is PubSubMessage<Map<String, dynamic>>) {
            messages.add(event.data);
            messageCompleter.complete();
          }
        });

        // Wait for subscription
        await expectLater(
          subscribeCompleter.future.timeout(const Duration(seconds: 2)),
          completes,
        );

        final testData = {'id': 1, 'name': 'Test', 'active': true};
        await cache.publish('json_channel', testData);

        // Wait for message
        await expectLater(
          messageCompleter.future.timeout(const Duration(seconds: 2)),
          completes,
        );

        expect(messages.length, equals(1));
        expect(messages[0], equals(testData));

        await listener.cancel();
        await cache.unsubscribe(['json_channel']);
      });

      test('unsubscribe stops receiving messages', () async {
        final messages = <String>[];
        final subscribeCompleter = Completer<void>();
        final firstMessageCompleter = Completer<void>();

        final subscription = cache.subscribe<String>(['unsub_channel']);
        final listener = subscription.listen((event) {
          if (event is PubSubSubscribed && !subscribeCompleter.isCompleted) {
            subscribeCompleter.complete();
          } else if (event is PubSubMessage<String>) {
            messages.add(event.data);
            if (!firstMessageCompleter.isCompleted) {
              firstMessageCompleter.complete();
            }
          }
        });

        // Wait for subscription
        await expectLater(
          subscribeCompleter.future.timeout(const Duration(seconds: 2)),
          completes,
        );

        await cache.publish('unsub_channel', 'Message 1');

        // Wait for first message
        await expectLater(
          firstMessageCompleter.future.timeout(const Duration(seconds: 2)),
          completes,
        );

        expect(messages.length, equals(1));

        await cache.unsubscribe(['unsub_channel']);
        await listener.cancel();

        // Give time for unsubscribe to process
        await Future.delayed(const Duration(milliseconds: 50));

        // This message should not be received
        await cache.publish('unsub_channel', 'Message 2');

        // Brief wait to ensure no message arrives
        await Future.delayed(const Duration(milliseconds: 50));

        expect(messages.length, equals(1)); // Still only one message
      });

      test('publish returns 0 for no subscribers', () async {
        final count = await cache.publish('no_subscribers', 'Hello');
        expect(count, equals(0));
      });

      test('concurrent subscriptions work correctly', () async {
        final messages1 = <String>[];
        final messages2 = <String>[];
        final subscribeCompleter1 = Completer<void>();
        final subscribeCompleter2 = Completer<void>();
        final messageCompleter1 = Completer<void>();
        final messageCompleter2 = Completer<void>();

        final sub1 = cache.subscribe<String>(['concurrent']);
        final sub2 = cache.subscribe<String>(['concurrent']);

        final listener1 = sub1.listen((event) {
          if (event is PubSubSubscribed && !subscribeCompleter1.isCompleted) {
            subscribeCompleter1.complete();
          } else if (event is PubSubMessage<String>) {
            messages1.add(event.data);
            messageCompleter1.complete();
          }
        });

        final listener2 = sub2.listen((event) {
          if (event is PubSubSubscribed && !subscribeCompleter2.isCompleted) {
            subscribeCompleter2.complete();
          } else if (event is PubSubMessage<String>) {
            messages2.add(event.data);
            messageCompleter2.complete();
          }
        });

        // Wait for both subscriptions
        await expectLater(
          Future.wait([
            subscribeCompleter1.future,
            subscribeCompleter2.future,
          ]).timeout(const Duration(seconds: 2)),
          completes,
        );

        final count = await cache.publish('concurrent', 'Broadcast');

        // Wait for both messages
        await expectLater(
          Future.wait([
            messageCompleter1.future,
            messageCompleter2.future,
          ]).timeout(const Duration(seconds: 2)),
          completes,
        );

        expect(count, equals(2)); // Two subscribers
        expect(messages1, contains('Broadcast'));
        expect(messages2, contains('Broadcast'));

        await listener1.cancel();
        await listener2.cancel();
        await cache.unsubscribe(['concurrent']);
      });
    });

    group('Error Handling', () {
      test('handles invalid JSON gracefully', () async {
        // Set a non-JSON string
        await cache.set('invalid_json', 'not a json');

        // Should return null when trying to parse as JSON
        final result = await cache.getJson('invalid_json');
        expect(result, isNull);
      });

      test('handles empty keys', () async {
        await cache.set('', 'empty key value');
        final value = await cache.get<String>('');
        expect(value, equals('empty key value'));
      });

      test('handles very large values', () async {
        final largeString = 'x' * 1000000; // 1MB string
        await cache.set('large_key', largeString);
        final retrieved = await cache.get<String>('large_key');
        expect(retrieved, equals(largeString));
      });

      test('handles special characters in keys', () async {
        const specialKey = 'key:with:colons:and-dashes_underscores';
        await cache.set(specialKey, 'special value');
        final value = await cache.get<String>(specialKey);
        expect(value, equals('special value'));
      });

      test('handles unicode in values', () async {
        const unicodeValue = '你好世界 🌍 مرحبا بالعالم';
        await cache.set('unicode_key', unicodeValue);
        final retrieved = await cache.get<String>('unicode_key');
        expect(retrieved, equals(unicodeValue));
      });
    });

    group('Resource Management', () {
      test('dispose closes all connections', () async {
        // Create multiple subscriptions
        final sub1 = cache.subscribe<String>(['dispose1']);
        final sub2 = cache.subscribe<String>(['dispose2']);

        final completer1 = Completer<void>();
        final completer2 = Completer<void>();
        final subscribeCompleter = Completer<void>();
        var subscribedCount = 0;

        sub1.listen((event) {
          if (event is PubSubSubscribed) {
            subscribedCount++;
            if (subscribedCount == 1 && !subscribeCompleter.isCompleted) {
              subscribeCompleter.complete();
            }
          }
        }, onDone: completer1.complete);

        sub2.listen(null, onDone: completer2.complete);

        // Wait for at least one subscription to be established
        await expectLater(
          subscribeCompleter.future.timeout(const Duration(seconds: 2)),
          completes,
        );

        // Dispose should close all connections
        await cache.dispose();

        // Streams should complete within timeout
        await expectLater(
          Future.wait([
            completer1.future,
            completer2.future,
          ]).timeout(const Duration(seconds: 2)),
          completes,
          reason: 'All streams should close when cache is disposed',
        );
      });

      test('multiple init calls handled gracefully', () async {
        // First init already done in setUp
        // Second init should work without issues
        await cache.init((host: 'localhost', port: 6379, secure: false));

        // Should still be able to use cache
        await cache.set('reinit_test', 'value');
        expect(await cache.get<String>('reinit_test'), equals('value'));
      });
    });
  });
}
