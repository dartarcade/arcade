import 'package:arcade/arcade.dart';
import 'package:luthor/luthor.dart';

extension LuthorValidation<T> on SchemaValidationResult<T> Function(
  Map<String, dynamic> json,
) {
  Future<T> validate(RequestContext context) async {
    final body = switch (await context.jsonMap()) {
      BodyParseSuccess(value: final body) => body,
      BodyParseFailure(error: final error) =>
        throw BadRequestException(message: 'Error parsing JSON: $error'),
    };

    return switch (this.call(body)) {
      SchemaValidationSuccess(data: final data) => data,
      SchemaValidationError(errors: final errors) =>
        throw BadRequestException(errors: errors),
    };
  }
}
