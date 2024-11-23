import 'dart:io';

import 'package:arcade_logger/arcade_logger.dart';

class ArcadeConfiguration {
  /// The name of the default logger.
  static String get rootLoggerName => _rootLoggerName;

  /// The directory where the static files are located.
  static Directory get staticFilesDirectory => _staticFilesDirectory;

  static Map<String, Object> get staticFilesHeaders => _staticFilesHeaders;

  /// The directory where the views are located. To be used with [`arcade_views`](https://pub.dev/packages/arcade_views).
  static Directory get viewsDirectory => _viewsDirectory;

  /// The extension of the views files. To be used with [`arcade_views`](https://pub.dev/packages/arcade_views).
  static String get viewsExtension => _viewsExtension;

  /// The file where the environment variables are located.
  static File? get envFile => _envFile;

  /// The log level to be used.
  static LogLevel get logLevel => _logLevel;

  static String _rootLoggerName = 'ROOT';
  static Directory _staticFilesDirectory = Directory('static');
  static Map<String, Object> _staticFilesHeaders = {};
  static Directory _viewsDirectory = Directory('views');
  static String _viewsExtension = '.jinja';
  static File? _envFile;
  static LogLevel _logLevel = LogLevel.none;

  ArcadeConfiguration._();

  static void override({
    String? rootLoggerName,
    Directory? staticFilesDirectory,
    Map<String, Object>? staticFilesHeaders,
    Directory? viewsDirectory,
    String? viewsExtension,
    File? envFile,
    LogLevel? logLevel,
  }) {
    if (rootLoggerName != null) {
      ArcadeConfiguration._rootLoggerName = rootLoggerName;
    }
    if (staticFilesDirectory != null) {
      ArcadeConfiguration._staticFilesDirectory = staticFilesDirectory;
    }
    if (staticFilesHeaders != null) {
      ArcadeConfiguration._staticFilesHeaders = staticFilesHeaders;
    }
    if (viewsDirectory != null) {
      ArcadeConfiguration._viewsDirectory = viewsDirectory;
    }
    if (viewsExtension != null) {
      ArcadeConfiguration._viewsExtension = viewsExtension;
    }
    if (envFile != null) {
      ArcadeConfiguration._envFile = envFile;
    }
    if (logLevel != null) {
      ArcadeConfiguration._logLevel = logLevel;
    }
  }
}
