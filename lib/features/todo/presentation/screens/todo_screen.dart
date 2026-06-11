import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/features/todo/presentation/controller/todo_controller.dart';
import 'package:todo_app/core/database/database.dart';
import 'package:todo_app/features/todo/presentation/screens/settings_screen.dart';
import 'package:todo_app/features/todo/presentation/widgets/add_todo_bottom_sheet.dart';
import 'package:todo_app/features/todo/presentation/widgets/rating_dialog.dart';
import 'package:todo_app/features/todo/presentation/widgets/todo_card.dart';

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

  Future<void> _showEditTitleDialog(
    BuildContext context,
    TodoController controller,
    TodosTableData todo,
  ) async {
    final titleController = TextEditingController(text: todo.title);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Task Title'),
          content: TextField(
            controller: titleController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Task title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = titleController.text.trim();
                if (text.isEmpty) return;
                await controller.updateTodoTitle(todo.id, text);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 2:
        return const Color(0xFFC62828);
      case 1:
        return const Color(0xFFF9A825);
      default:
        return const Color(0xFF1565C0);
    }
  }

  Color _getPriorityBackgroundColor(int priority) {
    switch (priority) {
      case 2:
        return const Color(0xFFFFEBEE);
      case 1:
        return const Color(0xFFFFFDE7);
      default:
        return const Color(0xFFE3F2FD);
    }
  }

  Color _getPriorityTextColor(int priority) {
    switch (priority) {
      case 2:
        return const Color(0xFFB71C1C);
      case 1:
        return const Color(0xFF827717);
      default:
        return const Color(0xFF0D47A1);
    }
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 2:
        return 'High';
      case 1:
        return 'Medium';
      default:
        return 'Low';
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

  Widget _buildBadge(
    IconData icon,
    String label,
    Color backgroundColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor.withOpacity(0.95)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeAction(
    IconData icon,
    String label,
    Color backgroundColor,
    Alignment alignment,
  ) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(todoStreamProvider);
    final controller = ref.read(todoControllerProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTodoBottomSheet(context, controller),
        label: const Text('Add Task'),
        icon: const Icon(Icons.add),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            expandedHeight: 280,
            toolbarHeight: 72,
            floating: true,
            snap: true,
            stretch: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            title: const Text('My Daily Tasks'),
            titleSpacing: 20,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF5B86E5), Color(0xFF36D1DC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      top: 40,
                      right: -40,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 120,
                      left: -30,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 30,
                      right: 30,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.checklist_rtl,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'My Daily Tasks',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Stay focused and finish your best work',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(84),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Material(
                  elevation: 4,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(30),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[900]
                      : Colors.white,
                  child: SizedBox(
                    height: 60,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        hintText: 'Search tasks...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[900]
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          todosAsync.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Error: $error')),
            ),
            data: (todoList) {
              final filteredList = todoList
                  .where(
                    (t) => t.title.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
                  )
                  .toList();

              if (filteredList.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
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
                  ),
                );
              }

              filteredList.sort((a, b) {
                if (a.priority != b.priority) {
                  return b.priority.compareTo(a.priority);
                }
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
                groupedTasks.putIfAbsent(dateKey, () => []).add(todo);
              }

              final sortedKeys = groupedTasks.keys.toList();
              final children = <Widget>[];

              for (var dateLabel in sortedKeys) {
                final tasks = groupedTasks[dateLabel]!;

                children.add(
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
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
                );

                children.addAll(
                  tasks.map((todo) {
                    final textColor = todo.completed
                        ? Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.grey[700]
                        : _getPriorityTextColor(todo.priority);
                    final subtitleColor = todo.completed
                        ? Theme.of(context).brightness == Brightness.dark
                              ? Colors.white54
                              : Colors.grey[600]
                        : _getPriorityTextColor(
                            todo.priority,
                          ).withOpacity(0.85);

                    return TodoCard(
                      todo: todo,
                      onToggle: (checked) =>
                          controller.toggleTodo(todo.id, checked),
                      onDelete: () async {
                        await controller.deleteTodo(todo.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Task deleted'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.redAccent,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      onPriorityChanged: (priority) async {
                        await controller.updateTodoPriority(todo.id, priority);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Priority set to ${_getPriorityLabel(priority)}',
                              ),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      onDueDateChanged: (date) async {
                        await controller.updateTodoDueDate(
                          todo.id,
                          date,
                          todo.title,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                date == null
                                    ? 'Reminder removed'
                                    : 'Due date updated',
                              ),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      onEdit: () {
                        _showEditTitleDialog(context, controller, todo);
                      },
                      onTap: () {},
                    );
                  }),
                );
              }

              children.add(const SizedBox(height: 24));

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(delegate: SliverChildListDelegate(children)),
              );
            },
          ),
        ],
      ),
    );
  }
}
