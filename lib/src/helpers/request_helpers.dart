import 'package:collection/collection.dart';
import 'package:dartseid/dartseid.dart';

HttpMethod? getHttpMethod(String methodString) {
  return HttpMethod.values.firstWhereOrNull(
    (method) => method.methodString == methodString,
  );
}
