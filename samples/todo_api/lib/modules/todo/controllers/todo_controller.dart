import 'package:arcade/arcade.dart';
import 'package:injectable/injectable.dart';
import 'package:luthor/luthor.dart';
import 'package:todo_api/common/contexts/is_auth_context.dart';
import 'package:todo_api/common/extensions/parse_with_luthor.dart';
import 'package:todo_api/common/hooks/auth_hook.dart';
import 'package:todo_api/config/injection.dart';
import 'package:todo_api/core/orm/prisma_client.dart';
import 'package:todo_api/modules/todo/dtos/todo_request.dart';
import 'package:todo_api/modules/todo/dtos/update_todo_request.dart';
import 'package:todo_api/modules/todo/services/todo_service.dart';

@singleton
class TodoController {
  final TodoService _todoService;

  TodoController(this._todoService) {
    final authHook = getIt<AuthHook>().hook;

    Route.get('/todos').before(authHook).handle(getTodos);
    Route.get('/todos/:id').before(authHook).handle(getTodoById);
    Route.post('/todos').before(authHook).handle(createTodo);
    Route.patch('/todos/:id').before(authHook).handle(updateTodoById);
    Route.delete('/todos/:id').before(authHook).handle(deleteTodoById);
  }

  Future<Iterable<Todo>> getTodos(covariant IsAuthContext context) {
    return _todoService.getAll(userId: context.userId);
  }

  Future<Todo> getTodoById(covariant IsAuthContext context) {
    final rawId = context.pathParameters['id'];
    final validationResult = l.int()
        .required(message: 'Invalid id')
        .validateValueWithFieldName('id', int.tryParse(rawId ?? ''));
    return switch (validationResult) {
      SingleValidationSuccess(data: final id) => _todoService.getById(id: id!),
      SingleValidationError(errors: final errors) =>
        throw BadRequestException(message: errors.first),
    };
  }

  Future<Todo> createTodo(covariant IsAuthContext context) async {
    final body = await context.parseWithLuthor(TodoRequest.validate);
    return _todoService.create(
      userId: context.userId,
      dto: body,
    );
  }

  Future<Todo> updateTodoById(covariant IsAuthContext context) async {
    final rawId = context.pathParameters['id'];
    final validationResult = l.int()
        .required(message: 'Invalid id')
        .validateValueWithFieldName('id', int.tryParse(rawId ?? ''));
    final dto = await context.parseWithLuthor(
      UpdateTodoRequest.validate,
    );

    return switch (validationResult) {
      SingleValidationSuccess(data: final id) =>
        _todoService.updateById(id: id!, dto: dto),
      SingleValidationError(errors: final errors) =>
        throw BadRequestException(message: errors.first)
    };
  }

  Future<Todo> deleteTodoById(covariant IsAuthContext context) {
    final rawId = context.pathParameters['id'];
    final validationResult = l.int()
        .required(message: 'Invalid id')
        .validateValueWithFieldName('id', int.tryParse(rawId ?? ''));
    return switch (validationResult) {
      SingleValidationSuccess(data: final id) =>
        _todoService.deleteById(id: id!),
      SingleValidationError(errors: final errors) =>
        throw BadRequestException(message: errors.first)
    };
  }
}
