import 'dart:io';

import 'package:ansi_styles/extension.dart';
import 'package:collection/collection.dart';
import 'package:dartseid/src/logger.dart';
import 'package:hotreloader/hotreloader.dart';
import 'package:vm_service/vm_service.dart';

Future<void> closeServerExit(
  HttpServer server,
  HotReloader hotreloader,
) async {
  logger.log('Shutting down');
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

Future<HotReloader> createHotReloader() {
  return HotReloader.create(
    debounceInterval: const Duration(milliseconds: 500),
    onBeforeReload: (ctx) {
      logger.log(
        '----------------------------------------------------------------------',
      );
      logger.log('Reloading server...');
      return true;
    },
    onAfterReload: (ctx) {
      switch (ctx.result) {
        case HotReloadResult.Succeeded:
          logger.log('Reload succeeded'.green);
        case HotReloadResult.PartiallySucceeded:
          logger.log('Reload partially succeeded'.yellow);
          _printReloadReports(ctx.reloadReports);
        case HotReloadResult.Skipped:
          logger.log('Reload skipped'.yellow);
          _printReloadReports(ctx.reloadReports);
        case HotReloadResult.Failed:
          logger.log('Reload failed'.red);
          _printReloadReports(ctx.reloadReports);
      }

      logger.log(
        '----------------------------------------------------------------------',
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
  logger.error('\n${messages.join('\n')}');
}
