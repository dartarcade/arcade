// ignore_for_file: invalid_use_of_protected_member

import 'package:arcade_swagger/arcade_swagger.dart';
import 'package:luthor/luthor.dart';

Schema validatorToSwagger(Validator validator) {
  if (validator.validations.isEmpty) {
    throw StateError('Validator has no validations');
  }
  return _validationsToSwagger(validator.validations, null, [], [validator])!;
}

Schema? _validationsToSwagger(
  List<Validation> validations,
  String? fieldName,
  List<String> requiredKeys,
  List<Validator> processingStack,
) {
  if (validations.isEmpty) return null;
  final [first, ...rest] = validations;
  if (!_isNotModifierValidation(first)) {
    throw StateError('First validation must be a type validation');
  }

  final isRequired = rest.any((v) => v is RequiredValidation);

  if (first is AnyValidation) {
    if (fieldName != null && isRequired) {
      requiredKeys.add(fieldName);
    }
    return const Schema.string(
      example: 'any',
    );
  }

  if (first is BoolValidation) {
    if (fieldName != null && isRequired) {
      requiredKeys.add(fieldName);
    }
    return const Schema.boolean();
  }

  if (first is DoubleValidation) {
    if (fieldName != null && isRequired) {
      requiredKeys.add(fieldName);
    }
    return const Schema.number();
  }

  if (first is IntValidation) {
    if (fieldName != null && isRequired) {
      requiredKeys.add(fieldName);
    }
    return const Schema.integer();
  }

  if (first is ListValidation) {
    if (fieldName != null && isRequired) {
      requiredKeys.add(fieldName);
    }
    if (first.validators == null || first.validators!.isEmpty) {
      return const Schema.array(items: Schema.string(example: 'any'));
    }

    final itemValidator = first.validators!.first.resolve();

    for (final validator in processingStack) {
      if (identical(validator, itemValidator)) {
        if (itemValidator.name == null) {
          throw StateError(
            'Self-referential validator must have a name. Use .withName() to set it.',
          );
        }
        return Schema.array(
          items: Schema.object(ref: itemValidator.name),
        );
      }
    }

    // If the item validator has a name and is a schema, use a ref
    if (itemValidator.name != null &&
        itemValidator.validations.isNotEmpty &&
        itemValidator.validations.first is SchemaValidation) {
      return Schema.array(
        items: Schema.object(ref: itemValidator.name),
      );
    }

    return Schema.array(
      items: _validationsToSwagger(
        itemValidator.validations,
        null,
        [],
        [...processingStack, itemValidator],
      )!,
    );
  }

  if (first is MapValidation) {
    if (fieldName != null && isRequired) {
      requiredKeys.add(fieldName);
    }
    return const Schema.map(
      example: {},
    );
  }

  if (first is NullValidation) {
    if (fieldName != null && isRequired) {
      requiredKeys.add(fieldName);
    }
    return const Schema.string(example: 'null');
  }

  if (first is NumberValidation) {
    if (fieldName != null && isRequired) {
      requiredKeys.add(fieldName);
    }
    return const Schema.number();
  }

  if (first is StringValidation) {
    if (fieldName != null && isRequired) {
      requiredKeys.add(fieldName);
    }
    return const Schema.string();
  }

  if (first is SchemaValidation) {
    if (fieldName != null && isRequired) {
      requiredKeys.add(fieldName);
    }
    final r = <String>[];
    return Schema.object(
      required: r,
      properties: first.validatorSchema.map((key, value) {
        final resolvedValidator = value.resolve();

        for (final validator in processingStack) {
          if (identical(validator, resolvedValidator)) {
            if (resolvedValidator.name == null) {
              throw StateError(
                'Self-referential validator must have a name. Use .withName() to set it.',
              );
            }
            return MapEntry(key, Schema.object(ref: resolvedValidator.name));
          }
        }

        // If the resolved validator has a name and is a schema, use a ref
        if (resolvedValidator.name != null &&
            resolvedValidator.validations.isNotEmpty &&
            resolvedValidator.validations.first is SchemaValidation) {
          return MapEntry(key, Schema.object(ref: resolvedValidator.name));
        }

        final propertySchema = _validationsToSwagger(
          resolvedValidator.validations,
          key,
          r,
          [...processingStack, resolvedValidator],
        );
        return MapEntry(key, propertySchema!);
      }),
    );
  }

  throw StateError('Unknown validation type: $first');
}

bool _isNotModifierValidation(Validation validation) {
  return validation is AnyValidation ||
      validation is BoolValidation ||
      validation is DoubleValidation ||
      validation is IntValidation ||
      validation is ListValidation ||
      validation is MapValidation ||
      validation is NullValidation ||
      validation is NumberValidation ||
      validation is SchemaValidation ||
      validation is StringValidation;
}
