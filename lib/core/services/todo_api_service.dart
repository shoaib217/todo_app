import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/models/todo.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      // 10.0.2.2 is the special alias for your host machine's localhost in Android Emulator
      // Use 'localhost' for iOS or Web.
      baseUrl: Platform.isAndroid ? 'http://192.168.1.183:8080' : 'http://localhost:8080',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );
});

final todoApiServiceProvider = Provider<TodoApiService>((ref) {
  return TodoApiService(ref.read(dioProvider));
});

class TodoApiService {
  TodoApiService(this._dio);

  final Dio _dio;

  Future<List<Todo>> fetchTodos() async {
    try {
      final response = await _dio.get('/todos');
      final list = response.data as List;
      return list.map((json) => Todo.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Todo> createTodo(Todo todo) async {
    try {
      final response = await _dio.post(
        '/todos',
        data: todo.toJson(),
      );
      return Todo.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<Todo> updateTodo(int id, Todo todo) async {
    try {
      final response = await _dio.put(
        '/todos/$id',
        data: todo.toJson(),
      );
      return Todo.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTodo(int id) async {
    try {
      await _dio.delete('/todos/$id');
    } catch (e) {
      rethrow;
    }
  }
}
