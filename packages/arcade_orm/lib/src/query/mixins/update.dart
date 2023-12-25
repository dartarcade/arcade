import 'package:meta/meta.dart';

mixin UpdateMixin {
  @protected
  final Map<String, dynamic> $updateWithParams = {};

  void updateWith(Map<String, dynamic> value) {
    $updateWithParams.addAll(value);
  }
}
