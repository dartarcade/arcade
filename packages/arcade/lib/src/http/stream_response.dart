import 'dart:io';

final class StreamResponse {
  const StreamResponse({
    required this.stream,
    this.contentType,
    this.contentLength,
    this.statusCode = HttpStatus.ok,
    this.headers = const {},
  });

  final Stream<List<int>> stream;
  final ContentType? contentType;
  final int? contentLength;
  final int statusCode;
  final Map<String, String> headers;
}
