import 'dart:io';

import 'package:arcade_logger/arcade_logger.dart';

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

  Platform.isWindows
      ? const Stream.empty()
      : ProcessSignal.sigterm.watch().listen((_) async {
          await closeServerExit(server);
        });
}
