import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/database/database.dart';
import 'package:todo_app/core/services/notification_service.dart';

// Singletons managed safely via Riverpod dependency graph
final databaseProvider = Provider<AppDatabase>((ref) {
  return appDatabase;
});

// Real-time stream bound directly to the UI layer
final todoStreamProvider = StreamProvider<List<TodosTableData>>((ref) {
  return ref.watch(databaseProvider).watchTodos();
});

final todoControllerProvider = Provider((ref) => TodoController(ref));

class TodoController {
  final Ref _ref;
  TodoController(this._ref);

  Future<void> toggleTodo(int id, bool targetStatus) async {
    final db = _ref.read(databaseProvider);
    await db.toggleTodoLocal(id, targetStatus);

    // If completed, cancel reminder
    if (targetStatus) {
      await NotificationService.cancelReminder(id);
    }
  }

  Future<void> addTodo(
    String title, {
    DateTime? dueDate,
    int priority = 0,
  }) async {
    final db = _ref.read(databaseProvider);
    final id = await db.insertTodoLocal(
      title,
      dueDate: dueDate,
      priority: priority,
    );

    // Schedule reminder if dueDate is provided
    if (dueDate != null) {
      await NotificationService.scheduleReminder(id, title, dueDate);
    }
  }

  Future<void> deleteTodo(int id) async {
    final db = _ref.read(databaseProvider);
    await db.deleteTodoLocal(id);
    await NotificationService.cancelReminder(id);
  }

  Future<void> updateTodoTitle(int id, String title) async {
    final db = _ref.read(databaseProvider);
    await db.updateTodoTitle(id, title);
  }

  Future<void> updateTodoPriority(int id, int priority) async {
    final db = _ref.read(databaseProvider);
    await db.updateTodoPriority(id, priority);
  }

  Future<void> updateTodoDueDate(
    int id,
    DateTime? dueDate,
    String title,
  ) async {
    final db = _ref.read(databaseProvider);
    await db.updateTodoDueDate(id, dueDate);

    if (dueDate == null) {
      await NotificationService.cancelReminder(id);
      return;
    }

    await NotificationService.scheduleReminder(id, title, dueDate);
  }
}
