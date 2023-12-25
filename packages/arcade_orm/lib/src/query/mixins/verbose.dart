import 'package:meta/meta.dart';

mixin VerboseMixin {
  @protected
  bool $verbose = false;
  void verbose() {
    $verbose = true;
  }
}
