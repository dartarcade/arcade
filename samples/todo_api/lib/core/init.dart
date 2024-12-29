import 'package:arcade/arcade.dart';
import 'package:arcade_swagger/arcade_swagger.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:todo_api/core/init.config.dart';
import 'package:todo_api/modules/auth/dtos/auth_dto.dart';

final getIt = GetIt.instance;

@injectableInit
Future<void> init() async {
  await getIt.reset();
  getIt.init();

  route.notFound((context) => 'Not found');

  setupSwagger(
    autoGlobalComponents: false,
    title: 'Todo API',
    description: 'Todo API',
    version: '1.0.0',
    responseSchemas: {
      'AuthResponseDto': AuthResponseDtoSchema,
    },
    securitySchemes: const {
      'JWT': SecurityScheme.apiKey(
        name: 'Authorization',
        location: ApiKeyLocation.header,
      ),
    },
    servers: const [
      Server(
        url: 'http://localhost:7331',
        description: 'Localhost',
      ),
    ],
  );
}
