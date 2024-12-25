import 'package:arcade/arcade.dart';
import 'package:arcade_swagger/arcade_swagger.dart';
import 'package:injectable/injectable.dart';
import 'package:todo_api/common/extensions/luthor_validation.dart';
import 'package:todo_api/modules/auth/dtos/auth_dto.dart';
import 'package:todo_api/modules/auth/services/auth_service.dart';

@singleton
class AuthController {
  AuthController(this._authService) {
    route.group<RequestContext>(
      '/auth',
      defineRoutes: (route) {
        route()
            .swagger(
              summary: 'Signup',
              tags: ['Auth'],
              request: $AuthRequestDtoSchema,
              responses: {
                '201': AuthResponseDtoSchema,
              },
            )
            .post('/signup')
            .handle(_signup);

        route()
            .swagger(
              summary: 'Login',
              tags: ['Auth'],
              request: $AuthRequestDtoSchema,
              responses: {
                '200': AuthResponseDtoSchema,
              },
            )
            .post('/login')
            .handle(_login);
      },
    );
  }

  final AuthService _authService;

  Future<AuthResponseDto> _signup(RequestContext context) async {
    context.statusCode = 201;
    return _authService.signup(await $AuthRequestDtoValidate.validate(context));
  }

  Future<AuthResponseDto> _login(RequestContext context) async {
    return _authService.login(await $AuthRequestDtoValidate.validate(context));
  }
}
