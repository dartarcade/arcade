import 'package:dartseid/dartseid.dart';
import 'package:luthor/luthor.dart';

typedef LuthorValidator<T> = SchemaValidationResult<T> Function(
  Map<String, dynamic> json,
);

extension ParseWithLuthor on RequestContext {
  Future<T> parseWithLuthor<T>(LuthorValidator<T> parser) async {
    return jsonMap()
        .then(
          (value) => switch (value) {
            BodyParseSuccess(value: final value) => parser(value),
            _ => throw const BadRequestException()
          },
        )
        .then(
          (value) => switch (value) {
            SchemaValidationSuccess(data: final data) => data,
            SchemaValidationError(errors: final errors) =>
              throw BadRequestException(errors: errors)
          },
        );
  }
}
