import 'package:meta/meta.dart';

mixin GroupMixin {
  @protected
  final List<String> $groupParams = [];
  void group(String column) {
    $groupParams.add(column);
  }
}
