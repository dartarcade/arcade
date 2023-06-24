import 'package:dartseid/dartseid.dart';
import 'package:injectable/injectable.dart';
import 'package:todo_api/config/database.dart';
import 'package:todo_api/core/orm/prisma_client.dart';
import 'package:todo_api/modules/todo/dtos/todo_request.dart';
import 'package:todo_api/modules/todo/dtos/update_todo_request.dart';

@singleton
class TodoService {
  Future<Iterable<Todo>> getAll({required int userId}) async {
    return prisma.todo
        .findMany(
          where: TodoWhereInput(userId: IntFilter(equals: userId)),
        )
        .then((value) => value.toList());
  }

  Future<Todo> getById({required int id}) async {
    final todo = await prisma.todo.findUnique(
      where: TodoWhereUniqueInput(id: id),
    );
    if (todo == null) {
      throw const NotFoundException(message: 'Todo not found');
    }
    return todo;
  }

  Future<Todo> create({required int userId, required TodoRequest dto}) async {
    return prisma.todo.create(
      data: TodoCreateInput(
        title: dto.title,
        user: UserCreateNestedOneWithoutTodoInput(
          connect: UserWhereUniqueInput(id: userId),
        ),
      ),
    );
  }

  Future<Todo> updateById({
    required int id,
    required UpdateTodoRequest dto,
  }) async {
    final todo = await prisma.todo.findUnique(
      where: TodoWhereUniqueInput(id: id),
    );
    if (todo == null) {
      throw const NotFoundException(message: 'Todo not found');
    }
    return prisma.todo
        .update(
          where: TodoWhereUniqueInput(id: id),
          data: TodoUpdateInput(
            title: dto.title != null
                ? StringFieldUpdateOperationsInput(set: dto.title)
                : null,
            completed: dto.completed != null
                ? BoolFieldUpdateOperationsInput(set: dto.completed)
                : null,
          ),
        )
        .then((value) => value!);
  }

  Future<Todo> deleteById({required int id}) async {
    final deletedTodo =
        await prisma.todo.delete(where: TodoWhereUniqueInput(id: id));
    if (deletedTodo == null) {
      throw const NotFoundException(message: 'Todo not found');
    }
    return deletedTodo;
  }
}
