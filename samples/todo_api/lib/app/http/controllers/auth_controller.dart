import 'package:dartseid/dartseid.dart';

class AuthController {
  const AuthController();

  Future<Map> register(RequestContext context) async {
    return context.jsonMap().then((value) => switch (value) {
          BodyParseSuccess(value: final value) => value,
          BodyParseFailure(error: final error) => throw error
        });
  }
}
