sealed class BodyParseResult<T> {
  const BodyParseResult._();
}

class BodyParseSuccess<T> extends BodyParseResult<T> {
  final T value;

  const BodyParseSuccess(this.value) : super._();
}

class BodyParseFailure<T> extends BodyParseResult<T> {
  final dynamic error;

  const BodyParseFailure(this.error) : super._();
}
