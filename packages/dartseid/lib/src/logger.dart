import 'dart:isolate';

import 'package:ansi_styles/extension.dart';

enum LogLevel {
  none,
  debug,
  info,
  warning,
  error,
}

class LogRecord {
  final LogLevel level;
  final String message;

  const LogRecord({
    required this.level,
    required this.message,
  });
}

class Logger {
  final String _name;

  static final ReceivePort _receivePort = ReceivePort();
  static late final SendPort _sendPort;

  static Isolate? _isolate;

  const Logger(this._name);

  static Future<void> init() async {
    if (_isolate != null) {
      return;
    }
    _isolate = await Isolate.spawn(_log, _receivePort.sendPort);
    _sendPort = (await _receivePort.first) as SendPort;
  }

  void log(LogRecord record) {
    _sendPort.send({'name': _name, 'record': record});
  }

  void debug(String message) {
    log(
      LogRecord(
        level: LogLevel.debug,
        message: message,
      ),
    );
  }

  void info(String message) {
    log(
      LogRecord(
        level: LogLevel.info,
        message: message,
      ),
    );
  }

  void warning(String message) {
    log(
      LogRecord(
        level: LogLevel.warning,
        message: message,
      ),
    );
  }

  void error(String message) {
    log(
      LogRecord(
        level: LogLevel.error,
        message: message,
      ),
    );
  }

  static Future<void> _log(SendPort sp) async {
    final rp = ReceivePort();
    sp.send(rp.sendPort);

    await for (final data in rp) {
      if (data is! Map) continue;
      final {'name': name, 'record': record} = data;

      if (name is! String || record is! LogRecord) continue;
      final message = switch (record.level) {
        LogLevel.none => record.message,
        LogLevel.debug => '[DEBUG]: $name: ${record.message}'.green,
        LogLevel.info => '[INFO]: $name: ${record.message}'.blue,
        LogLevel.warning => '[WARNING]: $name: ${record.message}'.yellow,
        LogLevel.error => '[ERROR]: $name: ${record.message}'.red,
      };
      // ignore: avoid_print
      print(message);
    }
  }

  Future<void> close() async {
    _receivePort.close();
    _isolate?.kill();
  }

  static const root = Logger('ROOT');
}
