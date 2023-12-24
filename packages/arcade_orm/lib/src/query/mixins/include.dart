import 'package:arcade_orm/arcade_orm.dart';
import 'package:arcade_orm/src/query/include.dart';
import 'package:arcade_orm/src/query/where.dart';
import 'package:meta/meta.dart';

mixin IncludeMixin {
  @protected
  final List<IncludeParam> $includeParams = [];

  void include(
    ArcadeOrmTableSchema table, {
    String? on,
    String? as,
    Map<String, WhereParamBuilder>? where,
    JoinOperation joinType = JoinOperation.inner,
  }) {
    $includeParams.add(
      IncludeParam(
        table.tableName,
        on: on,
        as: as,
        where: where,
        joinType: joinType,
      ),
    );
  }
}
