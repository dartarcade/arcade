import 'package:arcade/arcade.dart';
import 'package:arcade_swagger/arcade_swagger.dart';
import 'package:arcade_swagger/src/utils/route_to_path_item.dart';
import 'package:arcade_swagger/src/utils/schemas.dart';
import 'package:arcade_swagger/src/utils/validator_to_swagger.dart';
import 'package:arcade_views/arcade_views.dart';
import 'package:luthor/luthor.dart';
import 'package:openapi_spec/openapi_spec.dart';

void setupSwagger({
  required String title,
  String? description,
  required String version,
  List<Server> servers = const [],
  Map<String, Validator>? requestSchemas,
  Map<String, Validator>? responseSchemas,
  Map<String, SecurityScheme>? securitySchemes,
  String uiPath = '/ui',
  String docPath = '/doc',
  bool autoGlobalComponents = true,
}) {
  final pathItems = getPathItems(autoGlobalComponents: autoGlobalComponents);
  route.get(docPath).handle((context) {
    return OpenApi(
      info: Info(title: title, version: version),
      servers: servers,
      components: Components(
        schemas: {
          ...globalRequestSchemas.map(
            (key, value) => MapEntry(
              key,
              _firstRequestSchema(value),
            ),
          ),
          ...globalResponseSchemas.map(
            (key, value) => MapEntry(
              key,
              value.content!['application/json']!.schema!,
            ),
          ),
          ...?requestSchemas?.map(
            (key, value) {
              return MapEntry(
                key,
                validatorToSwagger(value),
              );
            },
          ),
        },
        requestBodies: {
          ...globalRequestSchemas,
          ...?requestSchemas?.map(
            (key, value) {
              final requestContentType = validatorContainsFileValidation(value)
                  ? 'multipart/form-data'
                  : 'application/json';

              return MapEntry(
                key,
                RequestBody(
                  content: {
                    requestContentType: MediaType(
                      schema: validatorToSwagger(value),
                    ),
                  },
                ),
              );
            },
          ),
        },
        responses: {
          ...globalResponseSchemas,
          ...?responseSchemas?.map(
            (key, value) {
              return MapEntry(
                key,
                Response(
                  content: {
                    'application/json': MediaType(
                      schema: validatorToSwagger(value),
                    ),
                  },
                ),
              );
            },
          ),
        },
        securitySchemes: securitySchemes,
      ),
      paths: pathItems,
    );
  });

  route.get(uiPath).handle((context) {
    return view(
      'index',
      {'title': title, 'url': docPath},
      (packagePath: 'package:arcade_swagger/', viewsPath: 'views'),
    );
  });
}

Schema _firstRequestSchema(RequestBody requestBody) {
  final content = requestBody.content;
  if (content == null || content.isEmpty) {
    throw StateError('Request body content is empty.');
  }

  final schema = content.values.first.schema;
  if (schema == null) {
    throw StateError('Request body schema is missing.');
  }

  return schema;
}
