import 'package:arcade/arcade.dart';
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
        route.post('/signup').handle(_signup);
        route.post('/login').handle(_login);
      },
    );
  }

  final AuthService _authService;

  Future<AuthResponseDto> _signup(RequestContext context) async {
    return _authService.signup(await $AuthRequestDtoValidate.validate(context));
  }

  Future<AuthResponseDto> _login(RequestContext context) async {
    return _authService.login(await $AuthRequestDtoValidate.validate(context));
  }
}
