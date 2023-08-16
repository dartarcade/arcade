import 'dart:io';

import 'package:dartseid_logger/dartseid_logger.dart';

Future<void> closeServerExit(
  HttpServer server,
) async {
  Logger.root.log(
    const LogRecord(
      level: LogLevel.none,
      message: 'Shutting down',
    ),
  );
  await server.close();
  exit(0);
}

void setupProcessSignalWatchers(
  HttpServer server,
) {
  ProcessSignal.sigint.watch().listen((_) async {
    await closeServerExit(server);
  });

  ProcessSignal.sigterm.watch().listen((_) async {
    await closeServerExit(server);
  });
}
