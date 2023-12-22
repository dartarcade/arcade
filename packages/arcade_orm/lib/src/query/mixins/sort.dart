enum SortDirection { asc, desc }

mixin SortMixin {
  final List<Map<String, SortDirection>> $sortParams = [];

  void sort(Map<String, SortDirection> sortBy) {
    final Map<String, SortDirection> sortValue =
        sortBy.map((key, value) => MapEntry(key, value));
    $sortParams.add(sortValue);
  }
}
