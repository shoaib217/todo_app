import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/exceptions/api_exception.dart';
import 'package:todo_app/core/models/todo.dart';

final dioProvider = Provider<Dio>((ref) {
  String baseUrl = 'http://localhost:8080';
  if (!kIsWeb && Platform.isAndroid) {
    baseUrl = 'http://192.168.1.183:8080';
  }

  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
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

  Future<List<Todo>> fetchTodos(int userId) async {
    try {
      final response = await _dio.get(
        '/todos',
        queryParameters: {'userId': userId},
      );
      final list = response.data as List;
      return list.map((json) => Todo.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiUtils.handleDioError(e);
    } catch (e) {
      throw ApiException('An unexpected error occurred while fetching todos');
    }
  }

  Future<Todo> createTodo(Todo todo) async {
    try {
      final response = await _dio.post(
        '/todos',
        data: todo.toJson(),
      );
      return Todo.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiUtils.handleDioError(e);
    } catch (e) {
      throw ApiException('An unexpected error occurred while creating todo');
    }
  }

  Future<Todo> updateTodo(int id, Todo todo) async {
    try {
      final response = await _dio.put(
        '/todos/$id',
        data: todo.toJson(),
      );
      return Todo.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiUtils.handleDioError(e);
    } catch (e) {
      throw ApiException('An unexpected error occurred while updating todo');
    }
  }

  Future<void> deleteTodo(int id) async {
    try {
      await _dio.delete('/todos/$id');
    } on DioException catch (e) {
      throw ApiUtils.handleDioError(e);
    } catch (e) {
      throw ApiException('An unexpected error occurred while deleting todo');
    }
  }
}
