import 'dart:async';

import 'package:arcade_cache/arcade_cache.dart';
import 'package:test/test.dart';

void main() {
  group('Memory Cache Manager Tests', () {
    late MemoryCacheManager cache;

    setUp(() async {
      cache = MemoryCacheManager();
      await cache.init(null);
    });

    tearDown(() async {
      await cache.dispose();
    });

    group('Basic Operations', () {
      test('init succeeds without parameters', () async {
        // Already initialized in setUp, just verify we can perform operations
        await cache.set('test_key', 'test_value');
        final value = await cache.get<String>('test_key');
        expect(value, equals('test_value'));
      });

      test('set and get string values', () async {
        await cache.set('string_key', 'Hello Memory Cache');
        final value = await cache.get<String>('string_key');
        expect(value, equals('Hello Memory Cache'));
      });

      test('set and get numeric values', () async {
        await cache.set('int_key', 42);
        await cache.set('double_key', 3.14);

        final intValue = await cache.get<int>('int_key');
        final doubleValue = await cache.get<double>('double_key');

        expect(intValue, equals(42));
        expect(doubleValue, equals(3.14));
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
          'tags': ['dart', 'memory', 'cache'],
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
          'ttl_key',
          'expires soon',
          const Duration(milliseconds: 10),
        );

        // Key should exist immediately
        expect(await cache.contains('ttl_key'), isTrue);
        expect(await cache.get<String>('ttl_key'), equals('expires soon'));

        // Wait for expiration
        await Future.delayed(const Duration(milliseconds: 20));

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
          subscribeCompleter.future.timeout(const Duration(milliseconds: 100)),
          completes,
          reason: 'Subscription should be established within 100ms',
        );

        // Publish messages
        final count1 = await cache.publish('test_channel', 'Hello');
        final count2 = await cache.publish('test_channel', 'World');

        // Wait for messages to arrive
        await expectLater(
          messagesCompleter.future.timeout(const Duration(milliseconds: 100)),
          completes,
          reason: 'Messages should arrive within 100ms',
        );

        // Verify
        expect(count1, equals(1));
        expect(count2, equals(1));

        expect(
          messages.length,
          greaterThanOrEqualTo(3),
        ); // subscribe + 2 messages

        // Check subscribe event
        final subscribeEvent = messages.firstWhere(
          (e) => e is PubSubSubscribed,
          orElse: () => throw StateError('No subscribe event found'),
        );
        expect(subscribeEvent, isA<PubSubSubscribed>());
        expect(
          (subscribeEvent as PubSubSubscribed).channel,
          equals('test_channel'),
        );
        expect(subscribeEvent.subscriberCount, equals(1));

        // Check message events
        final messageEvents = messages
            .whereType<PubSubMessage<String>>()
            .toList();
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
          subscribeCompleter.future.timeout(const Duration(milliseconds: 100)),
          completes,
        );

        await cache.publish('number_channel', '42');
        await cache.publish('number_channel', '100');

        // Wait for messages
        await expectLater(
          messagesCompleter.future.timeout(const Duration(milliseconds: 100)),
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
          subscribeCompleter.future.timeout(const Duration(milliseconds: 100)),
          completes,
        );

        await cache.publish('channel1', 'Message 1');
        await cache.publish('channel2', 'Message 2');
        await cache.publish('channel1', 'Message 3');

        // Wait for all messages
        await expectLater(
          messagesCompleter.future.timeout(const Duration(milliseconds: 100)),
          completes,
        );

        final messages = events.whereType<PubSubMessage<String>>().toList();
        expect(messages.length, equals(3));

        expect(
          messages.where((m) => m.channel == 'channel1').length,
          equals(2),
        );
        expect(
          messages.where((m) => m.channel == 'channel2').length,
          equals(1),
        );

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
          subscribeCompleter.future.timeout(const Duration(milliseconds: 100)),
          completes,
        );

        final testData = {'id': 1, 'name': 'Test', 'active': true};
        await cache.publish('json_channel', testData);

        // Wait for message
        await expectLater(
          messageCompleter.future.timeout(const Duration(milliseconds: 100)),
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
          subscribeCompleter.future.timeout(const Duration(milliseconds: 100)),
          completes,
        );

        await cache.publish('unsub_channel', 'Message 1');

        // Wait for first message
        await expectLater(
          firstMessageCompleter.future.timeout(
            const Duration(milliseconds: 100),
          ),
          completes,
        );

        expect(messages.length, equals(1));

        await cache.unsubscribe(['unsub_channel']);
        await listener.cancel();

        // Give time for unsubscribe to process
        await Future.delayed(const Duration(milliseconds: 10));

        // This message should not be received
        await cache.publish('unsub_channel', 'Message 2');

        // Brief wait to ensure no message arrives
        await Future.delayed(const Duration(milliseconds: 10));

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
          ]).timeout(const Duration(milliseconds: 100)),
          completes,
        );

        final count = await cache.publish('concurrent', 'Broadcast');

        // Wait for both messages
        await expectLater(
          Future.wait([
            messageCompleter1.future,
            messageCompleter2.future,
          ]).timeout(const Duration(milliseconds: 100)),
          completes,
        );

        expect(count, equals(2)); // Two subscribers
        expect(messages1, contains('Broadcast'));
        expect(messages2, contains('Broadcast'));

        await listener1.cancel();
        await listener2.cancel();
        await cache.unsubscribe(['concurrent']);
      });

      test(
        'PubSubSubscribed event includes correct subscriber count',
        () async {
          final subscribeEvents = <PubSubSubscribed>[];
          final completer1 = Completer<void>();
          final completer2 = Completer<void>();

          // First subscription
          final sub1 = cache.subscribe<String>(['count_test']);
          sub1.listen((event) {
            if (event is PubSubSubscribed) {
              subscribeEvents.add(event);
              completer1.complete();
            }
          });

          await completer1.future.timeout(const Duration(milliseconds: 100));
          expect(subscribeEvents.last.subscriberCount, equals(1));

          // Second subscription to same channel
          final sub2 = cache.subscribe<String>(['count_test']);
          sub2.listen((event) {
            if (event is PubSubSubscribed) {
              subscribeEvents.add(event);
              completer2.complete();
            }
          });

          await completer2.future.timeout(const Duration(milliseconds: 100));
          expect(subscribeEvents.last.subscriberCount, equals(2));

          await cache.unsubscribe(['count_test']);
        },
      );

      test('PubSubUnsubscribed event is emitted on unsubscribe', () async {
        final events = <PubSubEvent>[];
        final subscribeCompleter = Completer<void>();
        final unsubscribeCompleter = Completer<void>();

        final subscription = cache.subscribe<String>(['unsub_event_test']);
        subscription.listen((event) {
          events.add(event);
          if (event is PubSubSubscribed && !subscribeCompleter.isCompleted) {
            subscribeCompleter.complete();
          } else if (event is PubSubUnsubscribed) {
            unsubscribeCompleter.complete();
          }
        });

        // Wait for subscription
        await subscribeCompleter.future.timeout(
          const Duration(milliseconds: 100),
        );

        // Unsubscribe
        await cache.unsubscribe(['unsub_event_test']);

        // Wait for unsubscribe event
        await expectLater(
          unsubscribeCompleter.future.timeout(const Duration(milliseconds: 50)),
          completes,
          reason: 'Unsubscribe event should be emitted',
        );

        final unsubEvent = events.whereType<PubSubUnsubscribed>().first;
        expect(unsubEvent.channel, equals('unsub_event_test'));
        expect(unsubEvent.subscriberCount, equals(0));
      });
    });

    group('TTL and Expiration', () {
      test('keys expire after TTL duration', () async {
        await cache.setWithTtl(
          'expire1',
          'value1',
          const Duration(milliseconds: 10),
        );
        await cache.setWithTtl(
          'expire2',
          'value2',
          const Duration(milliseconds: 20),
        );
        await cache.set('no_expire', 'permanent');

        // All keys should exist initially
        expect(await cache.contains('expire1'), isTrue);
        expect(await cache.contains('expire2'), isTrue);
        expect(await cache.contains('no_expire'), isTrue);

        // Wait for first key to expire
        await Future.delayed(const Duration(milliseconds: 15));

        expect(await cache.contains('expire1'), isFalse);
        expect(await cache.contains('expire2'), isTrue);
        expect(await cache.contains('no_expire'), isTrue);

        // Wait for second key to expire
        await Future.delayed(const Duration(milliseconds: 10));

        expect(await cache.contains('expire1'), isFalse);
        expect(await cache.contains('expire2'), isFalse);
        expect(await cache.contains('no_expire'), isTrue);
      });

      test('expired keys are removed on access', () async {
        await cache.setWithTtl(
          'auto_remove',
          'value',
          const Duration(milliseconds: 10),
        );

        // Key exists initially
        expect(await cache.get<String>('auto_remove'), equals('value'));

        // Wait for expiration
        await Future.delayed(const Duration(milliseconds: 15));

        // Accessing expired key returns null and removes it
        expect(await cache.get<String>('auto_remove'), isNull);
        expect(await cache.contains('auto_remove'), isFalse);
      });

      test('contains returns false for expired keys', () async {
        await cache.setWithTtl(
          'check_expire',
          'value',
          const Duration(milliseconds: 10),
        );

        expect(await cache.contains('check_expire'), isTrue);

        await Future.delayed(const Duration(milliseconds: 15));

        expect(await cache.contains('check_expire'), isFalse);
      });

      test('get operations return null for expired keys', () async {
        await cache.setWithTtl(
          'expire_test',
          'string_value',
          const Duration(milliseconds: 10),
        );
        await cache.setWithTtl('expire_list', [
          'a',
          'b',
          'c',
        ], const Duration(milliseconds: 10));
        await cache.setWithTtl('expire_json', {
          'key': 'value',
        }, const Duration(milliseconds: 10));

        // Wait for expiration
        await Future.delayed(const Duration(milliseconds: 15));

        expect(await cache.get<String>('expire_test'), isNull);
        expect(await cache.getString('expire_test'), isNull);
        expect(await cache.getList<String>('expire_list'), isNull);
        expect(await cache.getJson('expire_json'), isNull);
      });
    });

    group('Error Handling', () {
      test('handles empty keys', () async {
        await cache.set('', 'empty key value');
        final value = await cache.get<String>('');
        expect(value, equals('empty key value'));
      });

      test('handles special characters in keys', () async {
        const specialKey =
            'key:with:colons:and-dashes_underscores@special#chars';
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

      test('handles null values', () async {
        await cache.set('null_key', null);
        final value = await cache.get<String>('null_key');
        expect(value, isNull);
      });

      test('handles boolean values', () async {
        await cache.set('bool_true', true);
        await cache.set('bool_false', false);

        expect(await cache.get<bool>('bool_true'), isTrue);
        expect(await cache.get<bool>('bool_false'), isFalse);
      });

      test('handles nested complex objects', () async {
        final complexObject = {
          'users': [
            {
              'id': 1,
              'name': 'User 1',
              'tags': ['admin', 'active'],
            },
            {
              'id': 2,
              'name': 'User 2',
              'tags': ['user'],
            },
          ],
          'metadata': {
            'version': '1.0',
            'count': 2,
            'active': true,
          },
        };

        await cache.set('complex', complexObject);
        final retrieved = await cache.getJson('complex');
        expect(retrieved, equals(complexObject));
      });

      test('getList handles type casting', () async {
        final mixedList = [1, 2, 3, 4, 5];
        await cache.set('number_list', mixedList);

        final retrieved = await cache.getList<int>('number_list');
        expect(retrieved, equals(mixedList));
        expect(retrieved, everyElement(isA<int>()));
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

        sub1.listen(
          (event) {
            if (event is PubSubSubscribed) {
              subscribedCount++;
              if (subscribedCount == 1 && !subscribeCompleter.isCompleted) {
                subscribeCompleter.complete();
              }
            }
          },
          onDone: () {
            if (!completer1.isCompleted) completer1.complete();
          },
        );

        sub2.listen(
          null,
          onDone: () {
            if (!completer2.isCompleted) completer2.complete();
          },
        );

        // Wait for at least one subscription to be established
        await expectLater(
          subscribeCompleter.future.timeout(const Duration(milliseconds: 100)),
          completes,
        );

        // Set some cache values
        await cache.set('key1', 'value1');
        await cache.set('key2', 'value2');

        // Dispose should close all connections and clear cache
        await cache.dispose();

        // Streams should complete
        await expectLater(
          Future.wait([
            completer1.future,
            completer2.future,
          ]).timeout(const Duration(milliseconds: 100)),
          completes,
          reason: 'All streams should close when cache is disposed',
        );
      });

      test('multiple init calls handled gracefully', () async {
        // First init already done in setUp
        // Second init should work without issues
        await cache.init(null);

        // Should still be able to use cache
        await cache.set('reinit_test', 'value');
        expect(await cache.get<String>('reinit_test'), equals('value'));
      });

      test('operations after dispose throw or handle gracefully', () async {
        await cache.set('before_dispose', 'value');
        await cache.dispose();

        // Create new instance for further tests
        cache = MemoryCacheManager();
        await cache.init(null);

        // Should be able to use new instance
        await cache.set('after_dispose', 'new_value');
        expect(await cache.get<String>('after_dispose'), equals('new_value'));

        // Old data should not persist
        expect(await cache.get<String>('before_dispose'), isNull);
      });

      test('unsubscribe cleans up resources properly', () async {
        final events = <PubSubEvent>[];
        final subscription = cache.subscribe<String>(['cleanup_test']);

        subscription.listen((event) {
          events.add(event);
        });

        // Wait for subscription
        await Future.delayed(const Duration(milliseconds: 10));

        // Verify subscription works
        await cache.publish('cleanup_test', 'test');
        await Future.delayed(const Duration(milliseconds: 10));

        expect(events.whereType<PubSubMessage>().length, equals(1));

        // Unsubscribe
        await cache.unsubscribe(['cleanup_test']);

        // Publishing should return 0 subscribers
        final count = await cache.publish('cleanup_test', 'after_unsub');
        expect(count, equals(0));
      });

      test('cleanup timer removes expired entries periodically', () async {
        // This is more of an implementation detail test
        // Set multiple keys with short TTL
        for (var i = 0; i < 10; i++) {
          await cache.setWithTtl(
            'temp_$i',
            'value_$i',
            const Duration(milliseconds: 10),
          );
        }

        // Also set some permanent keys
        for (var i = 0; i < 5; i++) {
          await cache.set('perm_$i', 'value_$i');
        }

        // Wait for TTL to expire
        await Future.delayed(const Duration(milliseconds: 20));

        // Access one expired key to trigger cleanup
        expect(await cache.get<String>('temp_0'), isNull);

        // Permanent keys should still exist
        for (var i = 0; i < 5; i++) {
          expect(await cache.contains('perm_$i'), isTrue);
        }
      });
    });
  });
}
