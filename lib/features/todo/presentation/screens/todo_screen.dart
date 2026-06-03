import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/features/todo/presentation/controller/todo_controller.dart';
import 'package:todo_app/core/database/database.dart';
import 'package:todo_app/features/todo/presentation/widgets/add_todo_bottom_sheet.dart';
import 'package:todo_app/features/todo/presentation/widgets/rating_dialog.dart';

class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddTodoBottomSheet(
    BuildContext context,
    TodoController controller,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTodoBottomSheet(controller: controller),
    ).then((_) async {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;
      await RatingDialog.show(context);
    });
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 2:
        return Colors.redAccent;
      case 1:
        return Colors.orangeAccent;
      default:
        return Colors.blueGrey;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(todoStreamProvider);
    final controller = ref.read(todoControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Daily Tasks')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTodoBottomSheet(context, controller),
        label: const Text('Add Task'),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[900]
                    : Colors.white,
              ),
            ),
          ),
          Expanded(
            child: todosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (todoList) {
                final filteredList = todoList
                    .where(
                      (t) => t.title.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                    )
                    .toList();

                if (filteredList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No tasks yet!'
                              : 'No matching tasks!',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                filteredList.sort((a, b) {
                  if (a.dueDate == null && b.dueDate == null) return 0;
                  if (a.dueDate == null) return 1;
                  if (b.dueDate == null) return -1;
                  return a.dueDate!.compareTo(b.dueDate!);
                });

                final Map<String, List<TodosTableData>> groupedTasks = {};
                for (var todo in filteredList) {
                  final dateKey = todo.dueDate != null
                      ? _getDateHeader(todo.dueDate!)
                      : 'No Date';
                  if (!groupedTasks.containsKey(dateKey)) {
                    groupedTasks[dateKey] = [];
                  }
                  groupedTasks[dateKey]!.add(todo);
                }

                final sortedKeys = groupedTasks.keys.toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, groupIndex) {
                    final dateLabel = sortedKeys[groupIndex];
                    final tasks = groupedTasks[dateLabel]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 16,
                            bottom: 8,
                            left: 4,
                          ),
                          child: Text(
                            dateLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        ...tasks.map(
                          (todo) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              child: Column(
                                children: [
                                  Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(todo.priority),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                    ),
                                  ),
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: Transform.scale(
                                      scale: 1.2,
                                      child: Checkbox(
                                        value: todo.completed,
                                        activeColor: const Color(0xFF37474F),
                                        checkColor: Colors.amber,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        onChanged: (bool? isChecked) {
                                          if (isChecked != null) {
                                            controller.toggleTodo(
                                              todo.id,
                                              isChecked,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    title: Text(
                                      todo.title,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500,
                                        decoration: todo.completed
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: todo.completed
                                            ? (Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white38
                                                  : Colors.blueGrey[200])
                                            : (Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : const Color(0xFF263238)),
                                      ),
                                    ),
                                    subtitle: todo.dueDate != null
                                        ? Row(
                                            children: [
                                              const Icon(
                                                Icons.access_time,
                                                size: 14,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                DateFormat.jm().format(
                                                  todo.dueDate!,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          )
                                        : null,
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete_sweep_outlined,
                                      ),
                                      color: Colors.red[400],
                                      onPressed: () async {
                                        await controller.deleteTodo(todo.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                'Task deleted',
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              backgroundColor: Colors.red[400],
                                              duration: const Duration(
                                                seconds: 1,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
