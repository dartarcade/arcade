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
      other is WhereParam &&
      other.runtimeType == runtimeType &&
      other.operator == operator &&
      other.value == value &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(operator, value, start, end);
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
    if (nodes.length > 1) {
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
  array,
  notInArray,
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

WhereParam array<T>(T value) {
  return WhereParam(
    operator: WhereOperator.array,
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

WhereParam notInArray<T>(T value) {
  return WhereParam(
    operator: WhereOperator.notInArray,
    value: value,
  );
}

WhereParam notEq<T>(T value) {
  return WhereParam(
    operator: WhereOperator.notEq,
    value: value,
  );
}

// WhereExpressionNode test1() {
//   // where A = 1
//   final rootNode = WhereExpressionOperatorNode(
//     operator: WhereExpressionOperator.and,
//     nodes: [],
//   );

//   rootNode.addNode(
//     WhereExpressionCompareNode(
//       field: 'A',
//       param: eq(1),
//     ),
//   );

//   return rootNode.simplify();
// }

// WhereExpressionNode test2() {
//   // where A = 1 and A = 2 and B = 3
//   final rootNode = WhereExpressionOperatorNode(
//     operator: WhereExpressionOperator.and,
//     nodes: [],
//   );

//   rootNode.addNode(
//     WhereExpressionCompareNode(
//       field: 'A',
//       param: eq(1),
//     ),
//   );

//   rootNode.addNode(
//     WhereExpressionCompareNode(
//       field: 'A',
//       param: eq(2),
//     ),
//   );

//   rootNode.addNode(
//     WhereExpressionCompareNode(
//       field: 'B',
//       param: eq(3),
//     ),
//   );

//   return rootNode.simplify();
// }

// WhereExpressionNode test3() {
//   // where (A = 1 or A = 2) and A = 3 and B = 2
//   final rootNode = WhereExpressionOperatorNode(
//     operator: WhereExpressionOperator.and,
//     nodes: [],
//   );

//   rootNode.addNode(
//     or([
//       {'A': eq(1)},
//       {'A': eq(2)},
//     ]),
//   );

//   rootNode.addNode(
//     and([
//       {
//         'A': eq(3),
//         'B': eq(2),
//       },
//     ]),
//   );

//   return rootNode.simplify();
// }

// WhereExpressionNode test4() {
//   // where A = 1 or A = 2 or B = 2 or B = 3 or A = 3 or B = 4
//   final rootNode = WhereExpressionOperatorNode(
//     operator: WhereExpressionOperator.and,
//     nodes: [],
//   );

//   rootNode.addNode(
//     or([
//       {'A': eq(1)},
//       {'A': eq(2)},
//       {'B': eq(2)},
//     ]),
//   );

//   rootNode.addNode(
//     or([
//       {'B': eq(3)},
//     ]),
//   );

//   rootNode.addNode(
//     or([
//       {'A': eq(3)},
//     ]),
//   );

//   rootNode.addNode(
//     or([
//       {'B': eq(4)},
//     ]),
//   );

//   return rootNode.simplify();
// }
