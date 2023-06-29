import 'dart:io';

class DartseidConfiguration {
  /// The name of the default logger.
  static String rootLoggerName = 'ROOT';

  /// The directory where the static files are located.
  static Directory staticFilesDirectory = Directory('static');

  /// The directory where the views are located. To be used with [`dartseid_views`](https://pub.dev/packages/dartseid_views).
  static Directory viewsDirectory = Directory('views');

  /// The extension of the views files. To be used with [`dartseid_views`](https://pub.dev/packages/dartseid_views).
  static String viewsExtension = '.html';

  DartseidConfiguration._();
}
