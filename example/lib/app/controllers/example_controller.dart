import 'package:dartseid/dartseid.dart';

class SampleJson {
  final String name;
  final int age;

  SampleJson({required this.name, required this.age});

  Map<String, dynamic> toJson() {
    return {'name': name, 'age': age};
  }
}

class ExampleController {
  const ExampleController();

  SampleJson index(RequestContext context) {
    return SampleJson(name: 'John Doe', age: 42);
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
