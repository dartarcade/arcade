import 'dart:io';

import 'package:ansi_styles/extension.dart';
import 'package:collection/collection.dart';
import 'package:dartseid/dartseid.dart';
import 'package:dartseid/src/core/logger.dart';
import 'package:dartseid/src/http/route.dart';
import 'package:hotreloader/hotreloader.dart';
import 'package:vm_service/vm_service.dart' hide LogRecord;

Future<void> closeServerExit(
  HttpServer server,
  HotReloader hotreloader,
) async {
  Logger.root.log(
    const LogRecord(
      level: LogLevel.none,
      message: 'Shutting down',
    ),
  );
  await server.close();
  await hotreloader.stop();
  exit(0);
}

void setupProcessSignalWatchers(HttpServer server, HotReloader hotreloader) {
  ProcessSignal.sigint.watch().listen((_) async {
    await closeServerExit(server, hotreloader);
  });

  ProcessSignal.sigterm.watch().listen((_) async {
    await closeServerExit(server, hotreloader);
  });
}

Future<HotReloader> createHotReloader(InitApplication init) {
  const separator =
      '----------------------------------------------------------------------';
  return HotReloader.create(
    debounceInterval: const Duration(milliseconds: 500),
    onBeforeReload: (ctx) {
      Logger.root.log(
        const LogRecord(
          level: LogLevel.none,
          message: separator,
        ),
      );
      Logger.root.log(
        const LogRecord(
          level: LogLevel.none,
          message: 'Reloading server...',
        ),
      );
      return true;
    },
    onAfterReload: (ctx) async {
      routes.clear();
      await init();

      switch (ctx.result) {
        case HotReloadResult.Succeeded:
          Logger.root.log(
            LogRecord(
              level: LogLevel.none,
              message: 'Reload succeeded'.green,
            ),
          );
        case HotReloadResult.PartiallySucceeded:
          Logger.root.log(
            LogRecord(
              level: LogLevel.none,
              message: 'Reload partially succeeded'.yellow,
            ),
          );
          _printReloadReports(ctx.reloadReports);
        case HotReloadResult.Skipped:
          Logger.root.log(
            LogRecord(
              level: LogLevel.none,
              message: 'Reload skipped'.yellow,
            ),
          );
          _printReloadReports(ctx.reloadReports);
        case HotReloadResult.Failed:
          Logger.root.log(
            LogRecord(
              level: LogLevel.none,
              message: 'Reload failed'.red,
            ),
          );
          _printReloadReports(ctx.reloadReports);
      }

      Logger.root.log(
        const LogRecord(
          level: LogLevel.none,
          message: separator,
        ),
      );
    },
  );
}

void _printReloadReports(Map<IsolateRef, ReloadReport> reloadReports) {
  final failedReports = reloadReports.values.where(
    (report) => report.success == false,
  );
  if (failedReports.isEmpty) return;

  final List<String> messages = [];

  for (final report in failedReports) {
    final json = report.json;
    final notices = json?['notices'];
    if (json == null || notices is! List) continue;

    // ignore: avoid_dynamic_calls
    final message = notices.firstWhereOrNull(
      // ignore: avoid_dynamic_calls
      (notice) => notice['message'] != null,
    )?['message'];

    if (message == null) continue;

    messages.add(message as String);
  }

  if (messages.isEmpty) return;
  Logger.root.error('\n${messages.join('\n')}');
}
