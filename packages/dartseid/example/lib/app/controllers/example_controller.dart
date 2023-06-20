import 'package:dartseid/dartseid.dart';
import 'package:dartseid_example/core/context/authed_request_context.dart';
import 'package:dartseid_example/models/dtos/sample_dto.dart';

class ExampleController {
  const ExampleController();

  SampleDto index(RequestContext context) {
    return SampleDto(name: 'John Doe', age: 42);
  }

  Map<String, dynamic> get(RequestContext context) {
    return {
      'query': context.queryParameters,
      'path': context.pathParameters,
    };
  }

  Future<Map<String, dynamic>> post(
    covariant AuthedRequestContext context,
  ) async {
    final body = switch (await context.jsonMap()) {
      BodyParseSuccess(value: final json) => json,
      _ => throw const BadRequestException(message: 'Invalid input'),
    };
    return body;
  }

  String hello(RequestContext context) {
    final name = context.pathParameters['name'];
    return 'Hello, $name!';
  }
}
