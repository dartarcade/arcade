import 'package:meta/meta.dart';

mixin RawMixin {
  @protected
  String? $rawSql;
  @protected
  Map<String, dynamic>? $rawNoSql;

  // ignore: use_setters_to_change_properties
  void noSql(Map<String, dynamic> query) {
    $rawNoSql = query;
  }

  // ignore: use_setters_to_change_properties
  void sql(String query) {
    $rawSql = query;
  }
}
