import 'package:meta/meta.dart';

mixin InsertMixin {
  @protected
  final List<Map<String, dynamic>> $insertWithParams = [];

  void insertWith(Map<String, dynamic> value) {
    $insertWithParams.add(value);
  }
}
