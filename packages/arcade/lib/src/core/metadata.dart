import 'package:arcade/src/http/route.dart';

final class RouteMetadata {
  final String type;
  final String path;
  final HttpMethod method;
  final Map<String, dynamic>? extra;

  const RouteMetadata({
    required this.type,
    required this.path,
    required this.method,
    this.extra,
  });

  factory RouteMetadata.fromJson(Map<String, dynamic> json) {
    return RouteMetadata(
      type: json['type'] as String,
      path: json['path'] as String,
      method: HttpMethod.values.firstWhere(
        (method) => method.methodString == json['method'],
      ),
      extra: json['extra'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'path': path,
      'method': method.methodString,
      'extra': extra,
    };
  }

  @override
  String toString() {
    return 'RouteMetadata(path: $path, method: ${method.methodString}, extra: $extra)';
  }
}

List<RouteMetadata> getRouteMetadata() {
  return routes
      .map((route) => route.metadata)
      .whereType<RouteMetadata>()
      .toList();
}
