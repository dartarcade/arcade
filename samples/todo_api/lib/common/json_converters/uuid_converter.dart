import 'package:drift_postgres/drift_postgres.dart';
import 'package:json_annotation/json_annotation.dart';

class UuidConverter extends JsonConverter<UuidValue, String> {
  const UuidConverter();

  @override
  UuidValue fromJson(String json) {
    return UuidValue.fromString(json);
  }

  @override
  String toJson(UuidValue object) {
    return object.uuid;
  }
}
