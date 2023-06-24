import 'package:dartseid/dartseid.dart';
import 'package:injectable/injectable.dart';
import 'package:todo_api/common/dtos/response_with_message.dart';
import 'package:todo_api/common/extensions/parse_with_luthor.dart';
import 'package:todo_api/modules/auth/dtos/login_request.dart';
import 'package:todo_api/modules/auth/dtos/register_request.dart';
import 'package:todo_api/modules/auth/services/auth_service.dart';

@singleton
class AuthController {
  final AuthService _authService;

  AuthController(this._authService) {
    Route.post('/auth/register', register);
    Route.post('/auth/login', login);
  }

  Future<ResponseWithMessage> register(RequestContext context) async {
    return _authService
        .register(await context.parseWithLuthor(RegisterRequest.validate));
  }

  Future<LoginResponse> login(RequestContext context) async {
    return _authService
        .login(await context.parseWithLuthor(LoginRequest.validate));
  }
}
