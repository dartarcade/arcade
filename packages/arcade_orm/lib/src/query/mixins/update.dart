import 'package:meta/meta.dart';

mixin UpdateMixin {
  @protected
  final List<Map<String, dynamic>> $updateWithParams = [];

  void updateWith(Map<String, dynamic> value) {
    $updateWithParams.add(value);
  }
}
