import 'package:arcade_swagger/arcade_swagger.dart';
import 'package:luthor/luthor.dart';

Map<String, RequestBody> globalRequestSchemas = {};
Map<String, Response> globalResponseSchemas = {};
Map<String, Validator> globalRequestValidators = {};
Map<String, Validator> globalResponseValidators = {};

void resetGlobalSwaggerSchemas() {
  globalRequestSchemas.clear();
  globalResponseSchemas.clear();
  globalRequestValidators.clear();
  globalResponseValidators.clear();
}
