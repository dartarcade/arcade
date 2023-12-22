import 'package:arcade_orm/src/query/where.dart';
import 'package:meta/meta.dart';

mixin WhereMixin {
  @protected
  WhereExpressionOperatorNode? $whereParams;

  void where(Map<String, WhereParamBuilder> map) {
    $whereParams ??= WhereParamBuilder.root(null);
    for (final entry in map.entries) {
      $whereParams!.addNode(entry.value, entry.key);
    }
  }
}
