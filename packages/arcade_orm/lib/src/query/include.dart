import 'package:arcade_orm/src/query/where.dart';

enum JoinOperation {
  inner,
  left,
  right,
  cross,
}

class IncludeParam {
  final String tableName;
  final String? on;
  final String? as;
  final JoinOperation joinType;
  WhereExpressionNode? where;
  IncludeParam(
    this.tableName, {
    this.on,
    this.as,
    this.joinType = JoinOperation.inner,
    Map<String, WhereParamBuilder>? where,
  }) {
    final value = WhereParamBuilder.root(null);
    if (where != null) {
      for (final element in where.entries) {
        value.addNode(element.value, element.key);
      }
      this.where = value.simplify();
    }
  }
}
