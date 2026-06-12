import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/database/database.dart';
import 'package:todo_app/core/models/todo.dart';
import 'package:todo_app/core/services/notification_service.dart';
import 'package:todo_app/core/services/todo_api_service.dart';

// Simplified Provider for the API data
final todoListProvider = StateNotifierProvider<TodoNotifier, AsyncValue<List<Todo>>>((ref) {
  return TodoNotifier(ref);
});

// Alias for UI compatibility if needed, though we should transition UI to todoListProvider
final todoStreamProvider = Provider<AsyncValue<List<Todo>>>((ref) {
  return ref.watch(todoListProvider);
});

class TodoNotifier extends StateNotifier<AsyncValue<List<Todo>>> {
  TodoNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchTodos();
  }

  final Ref _ref;
  TodoApiService get _api => _ref.read(todoApiServiceProvider);

  Future<void> fetchTodos() async {
    state = const AsyncValue.loading();
    try {
      final todos = await _api.fetchTodos();
      state = AsyncValue.data(todos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTodo(String title, DateTime? dueDate, int priority) async {
    try {
      final newTodo = await _api.createTodo(
        Todo(id: 0, title: title, dueDate: dueDate, priority: priority),
      );
      state = AsyncValue.data([...state.value ?? [], newTodo]);
      
      if (dueDate != null) {
        await NotificationService.scheduleReminder(newTodo.id, title, dueDate);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> toggleTodo(int id, bool completed) async {
    final currentTodos = state.value;
    if (currentTodos == null) return;

    try {
      final todo = currentTodos.firstWhere((t) => t.id == id);
      final updatedTodo = await _api.updateTodo(id, Todo(
        id: todo.id,
        title: todo.title,
        completed: completed,
        dueDate: todo.dueDate,
        priority: todo.priority,
      ));
      
      state = AsyncValue.data(
        currentTodos.map((t) => t.id == id ? updatedTodo : t).toList(),
      );

      if (completed) {
        await NotificationService.cancelReminder(id);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteTodo(int id) async {
    try {
      await _api.deleteTodo(id);
      state = AsyncValue.data(
        (state.value ?? []).where((t) => t.id != id).toList(),
      );
      await NotificationService.cancelReminder(id);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateTodoTitle(int id, String title) async {
    final todo = state.value?.firstWhere((t) => t.id == id);
    if (todo == null) return;
    try {
      final updated = await _api.updateTodo(id, Todo(
        id: id,
        title: title,
        completed: todo.completed,
        dueDate: todo.dueDate,
        priority: todo.priority,
      ));
      state = AsyncValue.data(
        state.value!.map((t) => t.id == id ? updated : t).toList(),
      );
    } catch (e) {}
  }

  Future<void> updateTodoPriority(int id, int priority) async {
    final todo = state.value?.firstWhere((t) => t.id == id);
    if (todo == null) return;
    try {
      final updated = await _api.updateTodo(id, Todo(
        id: id,
        title: todo.title,
        completed: todo.completed,
        dueDate: todo.dueDate,
        priority: priority,
      ));
      state = AsyncValue.data(
        state.value!.map((t) => t.id == id ? updated : t).toList(),
      );
    } catch (e) {}
  }

  Future<void> updateTodoDueDate(int id, DateTime? dueDate, String title) async {
    final todo = state.value?.firstWhere((t) => t.id == id);
    if (todo == null) return;
    try {
      final updated = await _api.updateTodo(id, Todo(
        id: id,
        title: todo.title,
        completed: todo.completed,
        dueDate: dueDate,
        priority: todo.priority,
      ));
      state = AsyncValue.data(
        state.value!.map((t) => t.id == id ? updated : t).toList(),
      );
      
      if (dueDate == null) {
        await NotificationService.cancelReminder(id);
      } else {
        await NotificationService.scheduleReminder(id, title, dueDate);
      }
    } catch (e) {}
  }
}

final todoControllerProvider = Provider((ref) => TodoController(ref));

class TodoController {
  final Ref _ref;
  TodoController(this._ref);

  Future<void> syncTodos() async => _ref.read(todoListProvider.notifier).fetchTodos();
  Future<void> toggleTodo(int id, bool status) async => _ref.read(todoListProvider.notifier).toggleTodo(id, status);
  Future<void> addTodo(String title, {DateTime? dueDate, int priority = 0}) async => 
      _ref.read(todoListProvider.notifier).addTodo(title, dueDate, priority);
  Future<void> deleteTodo(int id) async => _ref.read(todoListProvider.notifier).deleteTodo(id);
  Future<void> updateTodoTitle(int id, String title) async => _ref.read(todoListProvider.notifier).updateTodoTitle(id, title);
  Future<void> updateTodoPriority(int id, int priority) async => _ref.read(todoListProvider.notifier).updateTodoPriority(id, priority);
  Future<void> updateTodoDueDate(int id, DateTime? dueDate, String title) async => 
      _ref.read(todoListProvider.notifier).updateTodoDueDate(id, dueDate, title);
}
