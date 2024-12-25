import 'package:arcade/arcade.dart';
import 'package:arcade_swagger/arcade_swagger.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:injectable/injectable.dart';
import 'package:luthor/luthor.dart';
import 'package:todo_api/common/contexts/authenticated_request_context.dart';
import 'package:todo_api/common/dtos/todo_without_user.dart';
import 'package:todo_api/common/extensions/luthor_validation.dart';
import 'package:todo_api/common/hooks/auth_hook.dart';
import 'package:todo_api/modules/todos/dtos/create_todo_dto.dart';
import 'package:todo_api/modules/todos/dtos/update_todo_dto.dart';
import 'package:todo_api/modules/todos/services/todo_service.dart';

@singleton
class TodoController {
  TodoController(AuthHook authHook, this._todoService) {
    route.group<AuthenticatedRequestContext>(
      '/todos',
      before: [authHook],
      defineRoutes: (route) {
        route()
            .swagger(
              summary: 'Create todo',
              tags: ['Todos'],
              security: const [Security(name: 'JWT')],
              request: $$CreateTodoDtoSchema,
              responses: {
                '201': TodoWithoutUserSchema,
              },
            )
            .post('/')
            .handle(_createTodo);

        route()
            .swagger(
              summary: 'Get todos',
              tags: ['Todos'],
              security: const [Security(name: 'JWT')],
              responses: {
                '200': l.list(validators: [TodoWithoutUserSchema]),
              },
            )
            .get('/')
            .handle(_getTodos);

        route()
            .swagger(
              summary: 'Update todo',
              tags: ['Todos'],
              security: const [Security(name: 'JWT')],
              request: $$UpdateTodoDtoSchema,
              parameters: const [
                Parameter.path(name: 'id'),
              ],
              responses: {
                '200': TodoWithoutUserSchema,
              },
            )
            .patch('/:id')
            .handle(_updateTodo);

        route()
            .swagger(
              summary: 'Delete todo',
              security: const [Security(name: 'JWT')],
              tags: ['Todos'],
              parameters: const [
                Parameter.path(name: 'id'),
              ],
              responses: {
                '200': TodoWithoutUserSchema,
              },
            )
            .delete('/:id')
            .handle(_deleteTodo);
      },
    );
  }

  final TodoService _todoService;

  Future<TodoWithoutUser> _createTodo(
    covariant AuthenticatedRequestContext context,
  ) async {
    return _todoService.createTodo(
      context.id,
      await $$CreateTodoDtoValidate.validate(context),
    );
  }

  Future<List<TodoWithoutUser>> _getTodos(
    covariant AuthenticatedRequestContext context,
  ) {
    return _todoService.getTodos(context.id);
  }

  Future<TodoWithoutUser> _updateTodo(
    covariant AuthenticatedRequestContext context,
  ) async {
    final id = context.pathParameters['id']!;
    return _todoService.updateTodo(
      id,
      context.id,
      await $$UpdateTodoDtoValidate.validate(context),
    );
  }

  Future<TodoWithoutUser> _deleteTodo(
    covariant AuthenticatedRequestContext context,
  ) async {
    final id = context.pathParameters['id']!;
    return _todoService.deleteTodo(id, context.id);
  }
}
