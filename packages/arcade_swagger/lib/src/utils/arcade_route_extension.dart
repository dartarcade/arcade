import 'package:arcade/arcade.dart';
import 'package:arcade_swagger/arcade_swagger.dart';
import 'package:luthor/luthor.dart';

final _internalServerErrorSchema = l.schema({
  'statusCode': l.int().required(),
  'message': l.string().required(),
  'errors': l.map(),
});

final class SwaggerMetadata {
  final String? summary;
  final String? description;
  final List<String>? tags;
  final List<Security>? security;
  final List<Parameter>? parameters;
  final Validator? request;
  final Map<String, Validator> responses;
  final bool? deprecated;

  SwaggerMetadata({
    this.summary,
    this.description,
    this.tags,
    this.parameters,
    this.security,
    this.request,
    required this.responses,
    this.deprecated,
  });

  Map<String, dynamic> toJson() {
    return {
      if (summary != null) 'summary': summary,
      if (description != null) 'description': description,
      if (parameters != null) 'parameters': parameters,
      if (security != null) 'security': security,
      if (request != null) 'request': request!.name,
      if (responses.isNotEmpty)
        'responses': responses.map((key, value) {
          return MapEntry(key, value.name);
        }),
      if (deprecated != null) 'deprecated': deprecated,
    };
  }
}

extension SwaggerRoutebuilderX<T extends RequestContext> on RouteBuilder<T> {
  RouteBuilder<T> swagger({
    String? summary,
    String? description,
    List<String>? tags,
    Validator? request,
    Map<String, Validator>? responses,
    List<Parameter>? parameters,
    List<Security>? security,
    bool? deprecated,
    bool addDefaultInternalServerErrorSchema = true,
  }) {
    return withExtra({
      'swagger': SwaggerMetadata(
        summary: summary,
        description: description,
        tags: tags,
        parameters: parameters,
        security: security,
        request: request,
        responses: <String, Validator>{
          if (addDefaultInternalServerErrorSchema)
            '500': _internalServerErrorSchema,
          ...?responses,
        },
        deprecated: deprecated,
      ),
    });
  }
}
