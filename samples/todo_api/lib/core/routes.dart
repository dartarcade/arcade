import 'package:dartseid/dartseid.dart';
import 'package:todo_api/app/http/controllers/auth_controller.dart';

const authController = AuthController();

void defineRoutes() {
  Route.post('/auth/register', authController.register);
}
