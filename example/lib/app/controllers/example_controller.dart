import 'package:dartseid/dartseid.dart';

class ExampleController {
  const ExampleController();

  List<String> index(RequestContext context) {
    return ['Example Route'];
  }

  Future<Map<String, dynamic>> post(RequestContext context) async {
    final body = await context.json();
    return body;
  }
}
