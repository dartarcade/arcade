import 'dart:math';

import 'package:arcade/arcade.dart';

final class TableFormatter {
  static const _headers = (type: 'Type', method: 'Method', path: 'Path');

  final List<RouteMetadata> data;

  const TableFormatter(this.data);

  String format() {
    int maxTypeStringLength = _headers.type.length;
    int maxMethodStringLength = _headers.method.length;
    int maxPathStringLength = _headers.path.length;

    for (final route in data) {
      maxTypeStringLength = max(maxTypeStringLength, route.type.length);
      maxMethodStringLength = max(
        maxMethodStringLength,
        route.method.methodString.length,
      );
      maxPathStringLength = max(maxPathStringLength, route.path.length);
    }

    return [
      _formatHeader(
        maxTypeStringLength,
        maxMethodStringLength,
        maxPathStringLength,
      ),
      _formatSeparator(
        maxTypeStringLength,
        maxMethodStringLength,
        maxPathStringLength,
      ),
      for (final route in data)
        _formatRow(
          route,
          maxTypeStringLength,
          maxMethodStringLength,
          maxPathStringLength,
        ),
    ].join('\n');
  }

  String _formatRow(
    RouteMetadata route,
    int maxTypeStringLength,
    int maxMethodStringLength,
    int maxPathStringLength,
  ) {
    return '${route.type.padRight(maxTypeStringLength)} | '
        '${route.method.methodString.padRight(maxMethodStringLength)} | '
        '${route.path.padRight(maxPathStringLength)} |';
  }

  String _formatHeader(
    int maxTypeStringLength,
    int maxMethodStringLength,
    int maxPathStringLength,
  ) {
    return '${_headers.type.padRight(maxTypeStringLength)} | '
        '${_headers.method.padRight(maxMethodStringLength)} | '
        '${_headers.path.padRight(maxPathStringLength)} |';
  }

  String _formatSeparator(
    int maxTypeStringLength,
    int maxMethodStringLength,
    int maxPathStringLength,
  ) {
    return '${'-' * maxTypeStringLength} | '
        '${'-' * maxMethodStringLength} | '
        '${'-' * maxPathStringLength} |';
  }
}
