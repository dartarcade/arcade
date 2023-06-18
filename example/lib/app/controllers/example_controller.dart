import 'package:dartseid/dartseid.dart';
import 'package:dartseid_example/models/dtos/sample_dto.dart';

class ExampleController {
  const ExampleController();

  SampleDto index(RequestContext context) {
    return SampleDto(name: 'John Doe', age: 42);
  }

  Future<Map<String, dynamic>> post(RequestContext context) async {
    final body = switch (await context.jsonMap()) {
      BodyParseSuccess(value: final json) => json,
      _ => throw Exception('Invalid JSON'),
    };
    return body;
  }

  String hello(RequestContext context) {
    final name = context.pathParameters['name'];
    return 'Hello, $name!';
  }
}
