import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Represents a WebSocket message received from the server.
///
/// This class encapsulates both event-based and raw message formats
/// to provide flexibility in testing different WebSocket implementations.
class WebSocketMessage {
  /// The event type of the message (optional).
  ///
  /// For structured messages in the format `{"event": "eventName", "data": {...}}`,
  /// this will contain the event name. For raw messages, this will be null.
  final String? event;

  /// The raw data received from the WebSocket.
  ///
  /// This contains the original data as received from the server.
  /// For JSON messages, this will be the parsed object.
  /// For text messages, this will be the string.
  final dynamic data;

  /// Creates a new WebSocket message.
  ///
  /// [data] is required and contains the raw message data.
  /// [event] is optional and represents the event type for structured messages.
  const WebSocketMessage({
    required this.data,
    this.event,
  });

  /// Creates a WebSocketMessage from raw data received from the server.
  ///
  /// This factory method attempts to parse structured messages in the format:
  /// `{"event": "eventName", "data": {...}}`
  ///
  /// If the message follows this format, both [event] and [data] will be extracted.
  /// Otherwise, [data] will contain the raw message and [event] will be null.
  factory WebSocketMessage.fromRaw(dynamic rawData) {
    if (rawData is String) {
      try {
        final parsed = jsonDecode(rawData);
        if (parsed is Map<String, dynamic> &&
            parsed.containsKey('event') &&
            parsed.containsKey('data')) {
          return WebSocketMessage(
            event: parsed['event'] as String,
            data: parsed['data'],
          );
        }
      } catch (_) {
        // If JSON parsing fails, treat as raw string
      }
      return WebSocketMessage(data: rawData);
    }

    if (rawData is Map<String, dynamic> &&
        rawData.containsKey('event') &&
        rawData.containsKey('data')) {
      return WebSocketMessage(
        event: rawData['event'] as String,
        data: rawData['data'],
      );
    }

    return WebSocketMessage(data: rawData);
  }

  @override
  String toString() {
    if (event != null) {
      return 'WebSocketMessage(event: $event, data: $data)';
    }
    return 'WebSocketMessage(data: $data)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WebSocketMessage &&
        other.event == event &&
        other.data == data;
  }

  @override
  int get hashCode => Object.hash(event, data);
}

/// A WebSocket client for testing Arcade WebSocket endpoints.
///
/// This class provides an easy-to-use API for connecting to WebSocket
/// endpoints, sending messages, and receiving responses in tests.
///
/// Example usage:
/// ```dart
/// final ws = await TestWebSocket.connect('ws://localhost:8080/ws');
/// ws.send('ping', 'test data');
/// final message = await ws.waitForMessage('pong');
/// expect(message.data, equals('test data'));
/// await ws.close();
/// ```
class TestWebSocket {
  final WebSocketChannel _channel;
  final StreamController<WebSocketMessage> _messageController;
  late final StreamSubscription _subscription;
  bool _isClosed = false;

  TestWebSocket._(this._channel)
    : _messageController = StreamController<WebSocketMessage>.broadcast() {
    _subscription = _channel.stream.listen(
      (data) {
        if (!_isClosed) {
          _messageController.add(WebSocketMessage.fromRaw(data));
        }
      },
      onError: (Object error) {
        if (!_isClosed) {
          _messageController.addError(error);
        }
      },
      onDone: () {
        if (!_isClosed) {
          _isClosed = true;
          _messageController.close();
        }
      },
    );
  }

  /// Creates a new WebSocket connection to the specified URL.
  ///
  /// [url] should be a valid WebSocket URL (ws:// or wss://).
  ///
  /// Throws [WebSocketException] if the connection fails.
  ///
  /// Example:
  /// ```dart
  /// final ws = await TestWebSocket.connect('ws://localhost:8080/ws');
  /// ```
  static Future<TestWebSocket> connect(String url) async {
    try {
      final uri = Uri.parse(url);
      final channel = WebSocketChannel.connect(uri);

      // Wait for the connection to be established
      await channel.ready;

      return TestWebSocket._(channel);
    } on Object catch (e) {
      throw WebSocketException('Failed to connect to $url: $e');
    }
  }

  /// Stream of incoming WebSocket messages.
  ///
  /// This stream emits [WebSocketMessage] objects for each message
  /// received from the server. The stream is closed when the
  /// WebSocket connection is closed.
  ///
  /// Example:
  /// ```dart
  /// ws.messages.listen((message) {
  ///   print('Received: ${message.data}');
  /// });
  /// ```
  Stream<WebSocketMessage> get messages => _messageController.stream;

  /// Sends a message to the WebSocket server.
  ///
  /// For event-based communication, provide both [event] and [data].
  /// The message will be sent in the format: `{"event": event, "data": data}`.
  ///
  /// For raw message sending, provide only [data] and leave [event] as null.
  ///
  /// [event] - The event type (optional).
  /// [data] - The data to send. Can be any JSON-serializable object.
  ///
  /// Throws [StateError] if the WebSocket is closed.
  ///
  /// Examples:
  /// ```dart
  /// // Event-based message
  /// ws.send('ping', {'timestamp': DateTime.now().millisecondsSinceEpoch});
  ///
  /// // Raw message
  /// ws.send(null, 'Hello, server!');
  /// ```
  void send(String? event, dynamic data) {
    if (_isClosed) {
      throw StateError('WebSocket is closed');
    }

    dynamic message;
    if (event != null) {
      message = jsonEncode({
        'event': event,
        'data': data,
      });
    } else {
      message = data is String ? data : jsonEncode(data);
    }

    _channel.sink.add(message);
  }

  /// Sends a raw message to the WebSocket server.
  ///
  /// This method sends the data exactly as provided without any formatting.
  /// Useful for testing edge cases or non-standard message formats.
  ///
  /// [data] - The raw data to send.
  ///
  /// Throws [StateError] if the WebSocket is closed.
  ///
  /// Example:
  /// ```dart
  /// ws.sendRaw('{"custom": "format"}');
  /// ```
  void sendRaw(dynamic data) {
    if (_isClosed) {
      throw StateError('WebSocket is closed');
    }
    _channel.sink.add(data);
  }

  /// Waits for a message with the specified event type.
  ///
  /// Returns the first [WebSocketMessage] that matches the given [event].
  /// If [event] is null, returns the first message regardless of type.
  ///
  /// [event] - The event type to wait for (optional).
  /// [timeout] - Maximum time to wait for the message (default: 10 seconds).
  ///
  /// Throws [TimeoutException] if no matching message is received within the timeout.
  /// Throws [StateError] if the WebSocket is closed.
  ///
  /// Examples:
  /// ```dart
  /// // Wait for a specific event
  /// final pong = await ws.waitForMessage('pong');
  ///
  /// // Wait for any message
  /// final anyMessage = await ws.waitForMessage(null);
  ///
  /// // Wait with custom timeout
  /// final message = await ws.waitForMessage('response',
  ///   timeout: Duration(seconds: 5));
  /// ```
  Future<WebSocketMessage> waitForMessage(
    String? event, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    if (_isClosed) {
      throw StateError('WebSocket is closed');
    }

    final completer = Completer<WebSocketMessage>();
    late StreamSubscription subscription;

    // Set up timeout
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.completeError(
          TimeoutException(
            'Timeout waiting for message${event != null ? " with event '$event'" : ""}',
            timeout,
          ),
        );
      }
    });

    subscription = messages.listen(
      (message) {
        if (event == null || message.event == event) {
          timer.cancel();
          subscription.cancel();
          if (!completer.isCompleted) {
            completer.complete(message);
          }
        }
      },
      onError: (Object error) {
        timer.cancel();
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      onDone: () {
        timer.cancel();
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.completeError(
            StateError('WebSocket closed while waiting for message'),
          );
        }
      },
    );

    return completer.future;
  }

  /// Waits for the next message received, regardless of event type.
  ///
  /// [timeout] - Maximum time to wait for the message (default: 10 seconds).
  ///
  /// Throws [TimeoutException] if no message is received within the timeout.
  /// Throws [StateError] if the WebSocket is closed.
  ///
  /// Example:
  /// ```dart
  /// final nextMessage = await ws.waitForNextMessage();
  /// print('Received: ${nextMessage.data}');
  /// ```
  Future<WebSocketMessage> waitForNextMessage({
    Duration timeout = const Duration(seconds: 10),
  }) {
    return waitForMessage(null, timeout: timeout);
  }

  /// Checks if the WebSocket connection is currently open.
  ///
  /// Returns `true` if the connection is open and ready to send/receive messages.
  bool get isOpen => !_isClosed && _channel.closeCode == null;

  /// Checks if the WebSocket connection is closed.
  ///
  /// Returns `true` if the connection has been closed.
  bool get isClosed => _isClosed;

  /// Closes the WebSocket connection.
  ///
  /// This method gracefully closes the WebSocket connection and cleans up
  /// all resources. It's safe to call this method multiple times.
  ///
  /// [code] - Optional close code (default: 1000 for normal closure).
  /// [reason] - Optional reason for closing.
  ///
  /// Example:
  /// ```dart
  /// await ws.close();
  /// // or with custom code and reason
  /// await ws.close(1001, 'Test completed');
  /// ```
  Future<void> close([int? code, String? reason]) async {
    if (_isClosed) return;

    _isClosed = true;
    await _subscription.cancel();
    await _channel.sink.close(code ?? 1000, reason);
    await _messageController.close();
  }
}

/// Exception thrown when WebSocket operations fail.
class WebSocketException implements Exception {
  /// The error message.
  final String message;

  /// Creates a new WebSocket exception with the given message.
  const WebSocketException(this.message);

  @override
  String toString() => 'WebSocketException: $message';
}
