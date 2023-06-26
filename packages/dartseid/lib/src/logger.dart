import 'dart:isolate';

class _Logger {
  final ReceivePort _receivePort = ReceivePort();
  late final SendPort _sendPort;

  Isolate? _isolate;

  Future<void> init() async {
    if (_isolate != null) {
      return;
    }
    _isolate = await Isolate.spawn(_log, _receivePort.sendPort);
    _sendPort = (await _receivePort.first) as SendPort;
  }

  void log(String message) {
    _sendPort.send(message);
  }

  void error(String message) {
    _sendPort.send(message);
  }

  static Future<void> _log(SendPort sp) async {
    final rp = ReceivePort();
    sp.send(rp.sendPort);

    await for (final message in rp) {
      // ignore: avoid_print
      print(message);
    }
  }

  Future<void> close() async {
    _receivePort.close();
    _isolate?.kill();
  }
}

final logger = _Logger();
