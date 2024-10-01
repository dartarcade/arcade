import 'package:arcade/arcade.dart';
import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:injectable/injectable.dart';
import 'package:todo_api/common/dtos/todo_without_user.dart';
import 'package:todo_api/core/database/app_database.dart';
import 'package:todo_api/core/database/tables/todos.drift.dart';
import 'package:todo_api/modules/todos/dtos/create_todo_dto.dart';
import 'package:todo_api/modules/todos/dtos/update_todo_dto.dart';

@singleton
class TodoService {
  const TodoService(this._db);

  final AppDatabase _db;

  Future<TodoWithoutUser> createTodo(
    String userId,
    CreateTodoDto request,
  ) async {
    final todoToInsert = TodosCompanion.insert(
      title: request.title,
      completed: false,
      user: UuidValue.fromString(userId),
    );

    final insertedTodo = await _db.todos.insertReturning(todoToInsert);
    return insertedTodo.withoutUser;
  }

  Future<List<TodoWithoutUser>> getTodos(String userId) async {
    final findTodosQuery = _db.todos.selectOnly()
      ..addColumns([
        ..._db.todos.$columns
          ..removeWhere((element) => element.name == _db.todos.user.name),
      ])
      ..orderBy([
        OrderingTerm(expression: _db.todos.createdAt, mode: OrderingMode.desc),
      ])
      ..where(_db.todos.user.equals(UuidValue.fromString(userId)));
    return findTodosQuery
        .map(
          (row) => TodoWithoutUser(
            id: row.read(_db.todos.id)!,
            title: row.read(_db.todos.title)!,
            completed: row.read(_db.todos.completed)!,
            createdAt: row.read(_db.todos.createdAt)!,
          ),
        )
        .get();
  }

  Future<TodoWithoutUser> updateTodo(
    String todoId,
    String userId,
    UpdateTodoDto request,
  ) async {
    final todoToUpdateQuery = _db.todos.select()
      ..where(
        (tbl) =>
            tbl.id.equals(UuidValue.fromString(todoId)) &
            tbl.user.equals(UuidValue.fromString(userId)),
      );
    final todoToUpdate = await todoToUpdateQuery.getSingleOrNull();
    if (todoToUpdate == null) {
      throw const NotFoundException(message: 'Todo not found');
    }

    final updateQuery = _db.todos.update()
      ..where((tbl) => tbl.id.equals(todoToUpdate.id));
    final updatedTodo = await updateQuery.writeReturning(
      TodosCompanion(
        title: Value.absentIfNull(request.title),
        completed: Value.absentIfNull(request.completed),
      ),
    );
    return updatedTodo.first.withoutUser;
  }

  Future<TodoWithoutUser> deleteTodo(String id, String userId) async {
    final findQuery = _db.todos.selectOnly()
      ..addColumns([_db.todos.id])
      ..where(
        _db.todos.id.equals(UuidValue.fromString(id)) &
            _db.todos.user.equals(UuidValue.fromString(userId)),
      );
    final foundTodoId =
        await findQuery.map((row) => row.read(_db.todos.id)).getSingleOrNull();
    if (foundTodoId == null) {
      throw const NotFoundException(message: 'Todo not found');
    }

    final deleteQuery = _db.todos.delete()
      ..where((tbl) => tbl.id.equals(foundTodoId));
    final deleteTodos = await deleteQuery.goAndReturn();
    return deleteTodos.first.withoutUser;
  }
}
