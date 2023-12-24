const dAnd = r'$__AND';
const dOr = r'$__OR';

enum WhereExpressionOperator {
  and(dAnd),
  or(dOr);

  final String name;

  const WhereExpressionOperator(this.name);
}

sealed class WhereParamBuilder {
  WhereParamBuilder();

  // ignore: prefer_constructors_over_static_methods
  static WhereExpressionOperatorNode root(WhereExpressionOperatorNode? node) {
    return node ??
        WhereExpressionOperatorNode(
          operator: WhereExpressionOperator.and,
          nodes: [],
        );
  }
}

class WhereParam<T> extends WhereParamBuilder {
  final WhereOperator operator;
  final T? value;
  final T? start;
  final T? end;

  WhereParam({
    required this.operator,
    this.value,
    this.start,
    this.end,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WhereParam &&
          other.operator == operator &&
          other.value == value &&
          other.start == start &&
          other.end == end;

  @override
  int get hashCode => Object.hash(operator, value, start, end);

  @override
  String toString() {
    return 'WhereParam{operator: $operator, value: $value, start: $start, end: $end}';
  }

  String toJson() {
    return toString();
  }
}

sealed class WhereExpressionNode extends WhereParamBuilder {
  List<WhereExpressionNode> nodes;

  WhereExpressionNode({
    this.nodes = const [],
  });

  void addNode(
    WhereParamBuilder node, [
    String? field,
  ]) {
    if (this is WhereExpressionCompareNode) {
      throw StateError('Cannot add node to compare node');
    }
    if (this is WhereParam) {
      throw StateError('Cannot add node to where param');
    }
    if (this is WhereExpressionOperatorNode) {
      if (node is WhereExpressionOperatorNode) {
        if (node.operator == (this as WhereExpressionOperatorNode).operator) {
          nodes.addAll(node.nodes);
          return;
        }
        nodes.add(node);
        return;
      }
      if (node is WhereExpressionCompareNode) {
        nodes.add(node);
        return;
      }
      if (node is WhereParam) {
        if (field == null) {
          throw StateError('Field cannot be null for WhereParam');
        }
        nodes.add(
          WhereExpressionCompareNode(
            field: field,
            param: node,
          ),
        );
      }
    }
  }

  WhereExpressionNode simplify() {
    if (nodes.length == 1) {
      return nodes.first;
    }
    bool isSame = true;
    WhereExpressionOperator? operator;
    for (final node in nodes) {
      if (node is WhereExpressionOperatorNode) {
        if (operator == null) {
          operator = node.operator;
        } else if (operator != node.operator) {
          isSame = false;
          break;
        }
      } else {
        isSame = false;
        break;
      }
    }
    if (isSame && operator != null) {
      final simplifiedNodes = nodes.fold<List<WhereExpressionNode>>(
        [],
        (previousValue, element) {
          previousValue.addAll(element.nodes);
          return previousValue;
        },
      );
      return WhereExpressionOperatorNode(
        operator: operator,
        nodes: simplifiedNodes,
      );
    }
    return this;
  }

  Map<dynamic, dynamic> toMap();
}

extension MapParse on List<WhereExpressionNode> {
  List<Map<String, dynamic>> toMap() {
    // turn list into map
    return fold<List<Map<String, dynamic>>>(
      [],
      (previousValue, element) {
        if (element is WhereExpressionCompareNode) {
          previousValue.add({element.field: element.param});
        } else if (element is WhereExpressionOperatorNode) {
          previousValue.add({element.operator.name: element.nodes.toMap()});
        }
        return previousValue;
      },
    );
  }
}

class WhereExpressionOperatorNode extends WhereExpressionNode {
  final WhereExpressionOperator operator;
  WhereExpressionOperatorNode({
    required this.operator,
    required super.nodes,
  });

  @override
  Map<String, List<Map<String, dynamic>>> toMap() {
    return {operator.name: nodes.toMap()};
  }
}

class WhereExpressionCompareNode extends WhereExpressionNode {
  final String field;
  final WhereParam param;
  WhereExpressionCompareNode({
    required this.field,
    required this.param,
  });

  @override
  Map<String, dynamic> toMap() {
    return {field: param};
  }
}

enum WhereOperator {
  eq,
  gt,
  gte,
  lt,
  lte,
  between,
  notEq,
  like,
  inList,
  notInList,
  and,
  or,
}

Map<String, WhereParamBuilder> and(List<Map<String, WhereParam>> input) {
  return {
    dAnd: WhereExpressionOperatorNode(
      operator: WhereExpressionOperator.and,
      nodes: _getNodesFromMap(input),
    ),
  };
}

Map<String, WhereParamBuilder> or(List<Map<String, WhereParam>> input) {
  return {
    dOr: WhereExpressionOperatorNode(
      operator: WhereExpressionOperator.or,
      nodes: _getNodesFromMap(input),
    ),
  };
}

List<WhereExpressionCompareNode> _getNodesFromMap(
  List<Map<String, WhereParam>> value,
) {
  final List<WhereExpressionCompareNode> nodes = [];

  for (final item in value) {
    for (final entry in item.entries) {
      nodes.add(
        WhereExpressionCompareNode(
          field: entry.key,
          param: entry.value,
        ),
      );
    }
  }

  return nodes;
}

WhereParam inList<T extends List>(T value) {
  return WhereParam(
    operator: WhereOperator.inList,
    value: value,
  );
}

WhereParam between<T>(T start, T end) {
  return WhereParam(
    operator: WhereOperator.between,
    start: start,
    end: end,
  );
}

WhereParam eq<T>(T value) {
  return WhereParam(
    operator: WhereOperator.eq,
    value: value,
  );
}

WhereParam gt<T>(T value) {
  return WhereParam(
    operator: WhereOperator.gt,
    value: value,
  );
}

WhereParam gte<T>(T value) {
  return WhereParam(
    operator: WhereOperator.gte,
    value: value,
  );
}

WhereParam like(String value) {
  return WhereParam(
    operator: WhereOperator.like,
    value: value,
  );
}

WhereParam lt<T>(T value) {
  return WhereParam(
    operator: WhereOperator.lt,
    value: value,
  );
}

WhereParam lte<T>(T value) {
  return WhereParam(
    operator: WhereOperator.lte,
    value: value,
  );
}

WhereParam notInList<T extends List>(T value) {
  return WhereParam(
    operator: WhereOperator.notInList,
    value: value,
  );
}

WhereParam notEq<T>(T value) {
  return WhereParam(
    operator: WhereOperator.notEq,
    value: value,
  );
}
