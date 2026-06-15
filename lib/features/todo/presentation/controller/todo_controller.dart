import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/core/database/database.dart';
import 'package:todo_app/core/models/todo.dart';
import 'package:todo_app/core/services/auth_service.dart';
import 'package:todo_app/core/services/notification_service.dart';
import 'package:todo_app/core/services/todo_api_service.dart';

// Use Drift database for initial data and caching
final databaseProvider = Provider<AppDatabase>((ref) {
  return appDatabase;
});

// Real-time stream from the LOCAL database
final todoListProvider = StreamProvider<List<Todo>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value([]);
  
  final db = ref.watch(databaseProvider);
  return db.watchTodos(user.id).map((list) => list.map((e) => Todo.fromDatabaseData(e)).toList());
});

// Alias for UI compatibility
final todoStreamProvider = Provider<AsyncValue<List<Todo>>>((ref) {
  return ref.watch(todoListProvider);
});

// Search query provider
final todoSearchQueryProvider = StateProvider<String>((ref) => '');

// Grouping logic remains optimized but now watches the local stream
final groupedTodosProvider = Provider<AsyncValue<Map<String, List<Todo>>>>((ref) {
  final todosAsync = ref.watch(todoListProvider);
  final searchQuery = ref.watch(todoSearchQueryProvider).toLowerCase();

  return todosAsync.whenData((todos) {
    final filtered = todos.where((t) => t.title.toLowerCase().contains(searchQuery)).toList();
    filtered.sort((a, b) {
      if (a.priority != b.priority) return b.priority.compareTo(a.priority);
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
    final Map<String, List<Todo>> grouped = {};
    for (var todo in filtered) {
      final dateKey = todo.dueDate != null ? _getDateHeader(todo.dueDate!) : 'No Date';
      grouped.putIfAbsent(dateKey, () => []).add(todo);
    }
    return grouped;
  });
});

String _getDateHeader(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final yesterday = today.subtract(const Duration(days: 1));
  final dateToCheck = DateTime(date.year, date.month, date.day);

  if (dateToCheck == today) return 'Today';
  if (dateToCheck == tomorrow) return 'Tomorrow';
  if (dateToCheck == yesterday) return 'Yesterday';
  return DateFormat('EEEE, d MMM yyyy').format(date);
}

final todoControllerProvider = Provider((ref) => TodoController(ref));

class TodoController {
  final Ref _ref;
  TodoController(this._ref);

  TodoApiService get _api => _ref.read(todoApiServiceProvider);
  AppDatabase get _db => _ref.read(databaseProvider);
  int? get _userId => _ref.read(authProvider)?.id;

  /// Background sync: Fetch from API and update local database
  Future<void> syncTodos() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final remoteTodos = await _api.fetchTodos(userId);
      final localDataList = remoteTodos.map((t) => t.toDatabaseData()).toList();
      await _db.cacheTodos(localDataList);
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
  }

  Future<void> toggleTodo(int id, bool status) async {
    // Optimistic Update Local
    await _db.toggleTodoLocal(id, status);
    if (status) await NotificationService.cancelReminder(id);

    // Sync to Backend
    try {
      final current = await (_db.select(_db.todosTable)..where((t) => t.id.equals(id))).getSingle();
      await _api.updateTodo(id, Todo.fromDatabaseData(current));
    } catch (e) {
      debugPrint('Toggle sync failed: $e');
    }
  }

  Future<void> addTodo(String title, {DateTime? dueDate, int priority = 0}) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      // 1. Add to backend to get real ID
      final newTodo = await _api.createTodo(
        Todo(id: 0, userId: userId, title: title, dueDate: dueDate, priority: priority),
      );
      
      // 2. Save locally
      await _db.insertTodoLocalWithId(
        newTodo.id,
        newTodo.userId,
        newTodo.title,
        newTodo.completed,
        dueDate: newTodo.dueDate,
        priority: newTodo.priority,
      );

      if (dueDate != null) {
        await NotificationService.scheduleReminder(newTodo.id, title, dueDate);
      }
    } catch (e) {
      debugPrint('Add todo sync failed: $e');
      // Fallback: Add locally if offline
      final id = await _db.insertTodoLocal(userId, title, dueDate: dueDate, priority: priority);
      if (dueDate != null) {
        await NotificationService.scheduleReminder(id, title, dueDate);
      }
    }
  }

  Future<void> deleteTodo(int id) async {
    await _db.deleteTodoLocal(id);
    await NotificationService.cancelReminder(id);
    try {
      await _api.deleteTodo(id);
    } catch (e) {}
  }

  Future<void> updateTodoTitle(int id, String title) async {
    await _db.updateTodoTitle(id, title);
    try {
      final current = await (_db.select(_db.todosTable)..where((t) => t.id.equals(id))).getSingle();
      await _api.updateTodo(id, Todo.fromDatabaseData(current));
    } catch (e) {}
  }

  Future<void> updateTodoPriority(int id, int priority) async {
    await _db.updateTodoPriority(id, priority);
    try {
      final current = await (_db.select(_db.todosTable)..where((t) => t.id.equals(id))).getSingle();
      await _api.updateTodo(id, Todo.fromDatabaseData(current));
    } catch (e) {}
  }

  Future<void> updateTodoDueDate(int id, DateTime? dueDate, String title) async {
    await _db.updateTodoDueDate(id, dueDate);
    if (dueDate == null) {
      await NotificationService.cancelReminder(id);
    } else {
      await NotificationService.scheduleReminder(id, title, dueDate);
    }
    try {
      final current = await (_db.select(_db.todosTable)..where((t) => t.id.equals(id))).getSingle();
      await _api.updateTodo(id, Todo.fromDatabaseData(current));
    } catch (e) {}
  }
}
