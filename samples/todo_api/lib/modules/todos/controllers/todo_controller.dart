import 'package:arcade/arcade.dart';
import 'package:injectable/injectable.dart';
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
    Route.group(
      '/todos',
      before: [authHook],
      defineRoutes: () {
        Route.post('/').handle(
          (context) => _createTodo(context as AuthenticatedRequestContext),
        );

        Route.get('/').handle(
          (context) => _getTodos(context as AuthenticatedRequestContext),
        );

        Route.patch('/:id').handle(
          (context) => _updateTodo(context as AuthenticatedRequestContext),
        );

        Route.delete('/:id').handle(
          (context) => _deleteTodo(context as AuthenticatedRequestContext),
        );
      },
    );
  }

  final TodoService _todoService;

  Future<TodoWithoutUser> _createTodo(
    AuthenticatedRequestContext context,
  ) async {
    return _todoService.createTodo(
      context.id,
      await $$CreateTodoDtoValidate.validate(context),
    );
  }

  Future<List<TodoWithoutUser>> _getTodos(
    AuthenticatedRequestContext context,
  ) {
    return _todoService.getTodos(context.id);
  }

  Future<TodoWithoutUser> _updateTodo(
    AuthenticatedRequestContext context,
  ) async {
    final id = context.pathParameters['id']!;
    return _todoService.updateTodo(
      id,
      context.id,
      await $$UpdateTodoDtoValidate.validate(context),
    );
  }

  Future<TodoWithoutUser> _deleteTodo(
    AuthenticatedRequestContext context,
  ) async {
    final id = context.pathParameters['id']!;
    return _todoService.deleteTodo(id, context.id);
  }
}
