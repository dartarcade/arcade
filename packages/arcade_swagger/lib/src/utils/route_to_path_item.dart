// ignore_for_file: invalid_use_of_internal_member

import 'package:arcade/arcade.dart';
import 'package:arcade_swagger/arcade_swagger.dart';
import 'package:arcade_swagger/src/logger.dart';
import 'package:arcade_swagger/src/utils/schemas.dart';
import 'package:arcade_swagger/src/utils/validator_to_swagger.dart';

extension ListGroupX<T> on List<T> {
  Map<String, List<T>> groupBy(String Function(T) key) {
    final map = <String, List<T>>{};
    for (final item in this) {
      final k = key(item);
      if (!map.containsKey(k)) {
        map[k] = [];
      }
      map[k]!.add(item);
    }
    return map;
  }
}

Map<String, PathItem> getPathItems({required bool autoGlobalComponents}) {
  // Ensure any pending route is finalized before reading metadata
  // This handles the case where setupSwagger is called immediately after route definitions
  validatePreviousRouteHasHandler();

  final routeMetadata = getRouteMetadata();
  final groupedRoutes = routeMetadata.groupBy((r) => r.path);
  final pathItems = <String, PathItem>{};

  for (final MapEntry(
        key: path,
        value: metadataForPath,
      ) in groupedRoutes.entries) {
    if (path.isEmpty) continue;
    final swaggerFormattedPath =
        path.replaceAllMapped(RegExp(r':(\w+)'), (match) {
      return '{${match.group(1)}}';
    });

    for (final metadata in metadataForPath) {
      final RouteMetadata(:method, :extra) = metadata;
      if (extra == null) continue;
      final {'swagger': SwaggerMetadata? swagger} = extra;
      if (swagger == null) continue;
      var operation = Operation(
        summary: swagger.summary,
        description: swagger.description,
        tags: swagger.tags,
        security: swagger.security,
        parameters: swagger.parameters,
        deprecated: swagger.deprecated,
        responses: swagger.responses.map(
          (key, value) {
            final schema = validatorToSwagger(value);
            if (!autoGlobalComponents || value.name == null) {
              return MapEntry(
                key,
                Response(
                  content: {
                    'application/json': MediaType(schema: schema),
                  },
                ),
              );
            }

            globalResponseSchemas[value.name!] = Response(
              content: {
                'application/json': MediaType(schema: schema),
              },
            );
            return MapEntry(
              key,
              Response(
                content: {
                  'application/json': MediaType(
                    schema: Schema.object(ref: value.name),
                  ),
                },
              ),
            );
          },
        ),
      );

      if (swagger.request != null) {
        late final RequestBody requestBody;
        if (!autoGlobalComponents || swagger.request!.name == null) {
          requestBody = RequestBody(
            content: {
              'application/json': MediaType(
                schema: validatorToSwagger(swagger.request!),
              ),
            },
          );
        } else {
          globalRequestSchemas[swagger.request!.name!] = RequestBody(
            content: {
              'application/json': MediaType(
                schema: validatorToSwagger(swagger.request!),
              ),
            },
          );
          requestBody = RequestBody(
            content: {
              'application/json': MediaType(
                schema: Schema.object(
                  ref: swagger.request!.name,
                ),
              ),
            },
          );
        }
        operation = operation.copyWith(
          requestBody: requestBody,
        );
      }

      pathItems[swaggerFormattedPath] ??= const PathItem();
      var pathItem = pathItems[swaggerFormattedPath]!;

      switch (method) {
        case HttpMethod.any:
          logger.warning('Method $method is not supported');
        case HttpMethod.get:
          pathItem = pathItem.copyWith(get: operation);
        case HttpMethod.post:
          pathItem = pathItem.copyWith(post: operation);
        case HttpMethod.put:
          pathItem = pathItem.copyWith(put: operation);
        case HttpMethod.delete:
          pathItem = pathItem.copyWith(delete: operation);
        case HttpMethod.patch:
          pathItem = pathItem.copyWith(patch: operation);
        case HttpMethod.head:
          pathItem = pathItem.copyWith(head: operation);
        case HttpMethod.options:
          pathItem = pathItem.copyWith(options: operation);
      }
      pathItems[swaggerFormattedPath] = pathItem;
    }
  }

  return pathItems;
}
