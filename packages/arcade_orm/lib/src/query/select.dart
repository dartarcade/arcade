enum SelectAggregationOperator {
  show,
  hide,
  count,
  sum,
  avg,
  min,
  max,
  distinct,
  countDistinct,
}

class SelectParam {
  String? fieldAs;
  final SelectAggregationOperator operator;

  SelectParam({
    required this.operator,
    this.fieldAs,
  });
}

SelectParam avg(String value) {
  return SelectParam(
    operator: SelectAggregationOperator.avg,
    fieldAs: value,
  );
}

SelectParam count(String value) {
  return SelectParam(
    operator: SelectAggregationOperator.count,
    fieldAs: value,
  );
}

SelectParam countDistinct(String value) {
  return SelectParam(
    operator: SelectAggregationOperator.countDistinct,
    fieldAs: value,
  );
}

SelectParam distinct(String value) {
  return SelectParam(
    operator: SelectAggregationOperator.distinct,
    fieldAs: value,
  );
}

SelectParam field(String value) {
  return SelectParam(
    operator: SelectAggregationOperator.show,
    fieldAs: value,
  );
}

SelectParam hide() {
  return SelectParam(
    operator: SelectAggregationOperator.hide,
  );
}

SelectParam max(String value) {
  return SelectParam(
    operator: SelectAggregationOperator.max,
    fieldAs: value,
  );
}

SelectParam min(String value) {
  return SelectParam(
    operator: SelectAggregationOperator.min,
    fieldAs: value,
  );
}

SelectParam show() {
  return SelectParam(
    operator: SelectAggregationOperator.show,
  );
}

SelectParam sum(String value) {
  return SelectParam(
    operator: SelectAggregationOperator.sum,
    fieldAs: value,
  );
}
