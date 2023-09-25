import 'package:arcade/arcade.dart';
import 'package:collection/collection.dart';

HttpMethod? getHttpMethod(String methodString) {
  return HttpMethod.values.firstWhereOrNull(
    (method) => method.methodString == methodString,
  );
}
