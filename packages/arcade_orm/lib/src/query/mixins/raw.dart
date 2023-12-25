import 'package:meta/meta.dart';

mixin RawMixin {
  @protected
  String? $rawSql;
  @protected
  Map<String, dynamic>? $params;
  @protected
  List<Map<String, dynamic>>? $rawNoSqlAggregate;
  @protected
  Map<String, dynamic>? $rawNoSqlAggregateOptions;

  // ignore: use_setters_to_change_properties
  void aggregate(
    List<Map<String, dynamic>>? aggregate, {
    Map<String, dynamic>? options,
  }) {
    $rawNoSqlAggregate = aggregate;
    $rawNoSqlAggregateOptions = options;
  }

  // ignore: use_setters_to_change_properties
  void sql(String query, {Map<String, dynamic>? params}) {
    $rawSql = query;
    $params = params;
  }
}
