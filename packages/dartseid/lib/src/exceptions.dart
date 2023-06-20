class DartseidHttpException {
  final String message;
  final Map<String, dynamic>? errors;
  final int statusCode;

  const DartseidHttpException(this.message, this.statusCode, {this.errors});

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      if (errors != null) 'errors': errors,
    };
  }
}

// 400
class BadRequestException extends DartseidHttpException {
  const BadRequestException({String? message, Map<String, dynamic>? errors})
      : super(message ?? 'Bad request', 400, errors: errors);
}

// 401
class UnauthorizedException extends DartseidHttpException {
  const UnauthorizedException({String? message, Map<String, dynamic>? errors})
      : super(message ?? 'Unauthorized', 401, errors: errors);
}

// 403
class ForbiddenException extends DartseidHttpException {
  const ForbiddenException({String? message, Map<String, dynamic>? errors})
      : super(message ?? 'Forbidden', 403, errors: errors);
}

// 404
class NotFoundException extends DartseidHttpException {
  const NotFoundException({String? message, Map<String, dynamic>? errors})
      : super(message ?? 'Not found', 404, errors: errors);
}

// 405
class MethodNotAllowedException extends DartseidHttpException {
  const MethodNotAllowedException({String? message, Map<String, dynamic>? errors})
      : super(message ?? 'Method not allowed', 405, errors: errors);
}

// 409
class ConflictException extends DartseidHttpException {
  const ConflictException({String? message, Map<String, dynamic>? errors})
      : super(message ?? 'Conflict', 409, errors: errors);
}

// 418
class ImATeapotException extends DartseidHttpException {
  const ImATeapotException({String? message, Map<String, dynamic>? errors})
      : super(message ?? "I'm a teapot", 418, errors: errors);
}

// 422
class UnprocessableEntityException extends DartseidHttpException {
  const UnprocessableEntityException({String? message, Map<String, dynamic>? errors})
      : super(message ?? 'Unprocessable entity', 422, errors: errors);
}

// 500
class InternalServerErrorException extends DartseidHttpException {
  const InternalServerErrorException({String? message, Map<String, dynamic>? errors})
      : super(message ?? 'Internal server error', 500, errors: errors);
}

// 503
class ServiceUnavailableException extends DartseidHttpException {
  const ServiceUnavailableException({String? message, Map<String, dynamic>? errors})
      : super(message ?? 'Service unavailable', 503, errors: errors);
}
