import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:todo_api/config/injection.config.dart';

final getIt = GetIt.instance;

@injectableInit
void configureDependencies() {
  getIt.init();
}
