import 'package:dartseid/dartseid.dart';

class ExampleController {
  const ExampleController();

  String index(RequestContext context) {
    return 'Hello, world!';
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
