import 'dart:io';

class DartseidConfiguration {
  /// The name of the default logger.
  static String rootLoggerName = 'ROOT';

  /// The directory where the static files are located.
  static Directory staticFilesDirectory = Directory('static');

  /// The directory where the views are located. To be used with dartseid_views.
  static Directory viewsDirectory = Directory('views');

  DartseidConfiguration._();
}
