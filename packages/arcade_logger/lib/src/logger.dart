import 'dart:io';
import 'dart:isolate';

import 'package:ansi_styles/extension.dart';
import 'package:arcade_config/arcade_config.dart';

enum LogLevel {
  error,
  warning,
  info,
  debug,
  none;

  bool operator >=(LogLevel other) => index >= other.index;
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
    if (!_shouldLog(record.level)) {
      return;
    }
    _sendPort.send({'name': _name, 'record': record});
  }

  void debug(Object? message) {
    log(
      LogRecord(
        level: LogLevel.debug,
        message: message.toString(),
      ),
    );
  }

  void info(Object? message) {
    log(
      LogRecord(
        level: LogLevel.info,
        message: message.toString(),
      ),
    );
  }

  void warning(Object? message) {
    log(
      LogRecord(
        level: LogLevel.warning,
        message: message.toString(),
      ),
    );
  }

  void error(Object? message) {
    log(
      LogRecord(
        level: LogLevel.error,
        message: message.toString(),
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
      stdout.writeln(message);
    }
  }

  Future<void> close() async {
    _receivePort.close();
    _isolate?.kill();
  }

  static final root = Logger(ArcadeConfiguration.rootLoggerName);

  bool _shouldLog(LogLevel level) => level >= ArcadeConfiguration.logLevel;
}
