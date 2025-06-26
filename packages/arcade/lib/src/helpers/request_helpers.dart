import 'package:arcade/arcade.dart';

/// Optimized constant-time HTTP method lookup
final Map<String, HttpMethod> _httpMethodLookup = {
  for (final method in HttpMethod.values) method.methodString: method,
};

HttpMethod? getHttpMethod(String methodString) {
  return _httpMethodLookup[methodString];
}
