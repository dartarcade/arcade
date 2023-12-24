import 'package:meta/meta.dart';

mixin ExplainMixin {
  @protected
  bool $explain = false;
  void explain() {
    $explain = true;
  }
}
