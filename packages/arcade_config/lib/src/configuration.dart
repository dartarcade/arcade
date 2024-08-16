import 'dart:io';

class ArcadeConfiguration {
  /// The name of the default logger.
  static String get rootLoggerName => _rootLoggerName;

  /// The directory where the static files are located.
  static Directory get staticFilesDirectory => _staticFilesDirectory;

  /// The directory where the views are located. To be used with [`arcade_views`](https://pub.dev/packages/arcade_views).
  static Directory get viewsDirectory => _viewsDirectory;

  /// The extension of the views files. To be used with [`arcade_views`](https://pub.dev/packages/arcade_views).
  static String get viewsExtension => _viewsExtension;

  /// The file where the environment variables are located.
  static File? get envFile => _envFile;

  static String _rootLoggerName = 'ROOT';
  static Directory _staticFilesDirectory = Directory('static');
  static Directory _viewsDirectory = Directory('views');
  static String _viewsExtension = '.html';
  static File? _envFile;

  ArcadeConfiguration._();

  static void override({
    String? rootLoggerName,
    Directory? staticFilesDirectory,
    Directory? viewsDirectory,
    String? viewsExtension,
    File? envFile,
  }) {
    if (rootLoggerName != null) {
      ArcadeConfiguration._rootLoggerName = rootLoggerName;
    }
    if (staticFilesDirectory != null) {
      ArcadeConfiguration._staticFilesDirectory = staticFilesDirectory;
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
  }
}
