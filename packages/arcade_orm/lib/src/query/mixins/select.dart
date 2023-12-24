import 'package:arcade_orm/src/query/select.dart';
import 'package:meta/meta.dart';

mixin SelectMixin {
  @protected
  final List<Map<String, SelectParam>> $selectParams = [];
  void select(Map<String, SelectParam> value) {
    $selectParams.add(value);
  }
}
