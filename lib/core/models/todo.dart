import 'package:json_annotation/json_annotation.dart';
import 'package:todo_app/core/database/database.dart';

part 'todo.g.dart';

@JsonSerializable()
class Todo {
  const Todo({
    required this.id,
    required this.userId,
    required this.title,
    this.completed = false,
    this.dueDate,
    this.priority = 0,
  });

  factory Todo.fromJson(Map<String, dynamic> json) => _$TodoFromJson(json);

  final int id;
  final int userId;
  final String title;
  final bool completed;
  final DateTime? dueDate;
  final int priority;

  Map<String, dynamic> toJson() => _$TodoToJson(this);

  // Helper to convert from API model to Drift Database model
  TodosTableData toDatabaseData() {
    return TodosTableData(
      id: id,
      userId: userId,
      title: title,
      completed: completed,
      dueDate: dueDate,
      priority: priority,
    );
  }

  // Helper to convert from Drift Database model to API model
  factory Todo.fromDatabaseData(TodosTableData data) {
    return Todo(
      id: data.id,
      userId: data.userId,
      title: data.title,
      completed: data.completed,
      dueDate: data.dueDate,
      priority: data.priority,
    );
  }
}
