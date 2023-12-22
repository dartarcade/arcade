import 'package:arcade_orm/arcade_orm.dart';
import 'package:meta/meta.dart';

mixin PaginationMixin {
  @protected
  int? $limit;
  @protected
  int? $skip;

  /// Set the number of results skipped. Cannot be less than 0.
  void skip(int skip) {
    if (skip < 0) {
      throw ArcadeOrmException(
        message: "skip cannot be less then 0",
        originalError: null,
      );
    }
    $skip = skip;
  }

  /// Set the number of results to return. Cannot be less than 1.
  void limit(int limit) {
    if (limit <= 0) {
      throw ArcadeOrmException(
        message: "limit cannot be less then 1",
        originalError: null,
      );
    }
    $limit = limit;
  }
}
