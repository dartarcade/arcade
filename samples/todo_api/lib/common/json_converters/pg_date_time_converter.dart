import 'package:drift_postgres/drift_postgres.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

class PgDateTimeConverter extends JsonConverter<PgDateTime, String> {
  const PgDateTimeConverter();

  @override
  PgDateTime fromJson(String json) {
    return PgDateTime(DateTime.parse(json));
  }

  @override
  String toJson(PgDateTime object) {
    return object.dateTime.toIso8601String();
  }
}
