import 'package:arcade/arcade.dart';
import 'package:arcade_example/core/context/authed_request_context.dart';

class ExampleController {
  String? wsId;

  ExampleController();

  Map<String, dynamic> index(RequestContext context) {
    if (wsId != null) {
      emitTo(wsId!, 'Hello from get');
    }
    return {'message': 'Hello, world!'};
  }

  Map<String, dynamic> get(covariant AuthedRequestContext context) {
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

  Future<dynamic> printBodyAsString(RequestContext context) async {
    final data = await context.formData();
    return switch (data) {
      BodyParseSuccess(value: final data) => data.files.first.path,
      BodyParseFailure(error: final e) => throw e as Object? ??
          const BadRequestException(message: 'Invalid input'),
    };
  }

  void onWsConnect(covariant AuthedRequestContext _, WebSocketManager manager) {
    print('On connect ${manager.id}');
    wsId = manager.id;
  }

  void ws(
    covariant AuthedRequestContext context,
    dynamic message,
    WebSocketManager manager,
  ) {
    print('Message from client: $message');
    manager.emit('Hello from server');
  }
}
