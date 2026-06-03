import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/core/database/database.dart';

class TodoCard extends StatelessWidget {
  final TodosTableData todo;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  // New optional callbacks for direct inline actions
  final ValueChanged<int>? onPriorityChanged;
  final ValueChanged<DateTime?>? onDueDateChanged;

  const TodoCard({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    this.onTap,
    this.onPriorityChanged,
    this.onDueDateChanged,
    this.onEdit,
  });

  // --- UI Color & Text Helpers ---
  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 2:
        return const Color(0xFFE53935); // Vivid Red
      case 1:
        return const Color(0xFFFFB300); // Amber
      default:
        return const Color(0xFF1E88E5); // Modern Blue
    }
  }

  Color _getPriorityBackgroundColor(int priority) {
    switch (priority) {
      case 2:
        return const Color(0xFFFFEBEE);
      case 1:
        return const Color(0xFFFFF8E1);
      default:
        return const Color(0xFFE3F2FD);
    }
  }

  Color _getPriorityTextColor(int priority) {
    switch (priority) {
      case 2:
        return const Color(0xFFC62828);
      case 1:
        return const Color(0xFFB7791F);
      default:
        return const Color(0xFF1565C0);
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

  // Helper to determine if a task is overdue
  bool get _isOverdue {
    if (todo.dueDate == null || todo.completed) return false;
    return todo.dueDate!.isBefore(DateTime.now());
  }

  // --- Reusable Interactive Badge Builder ---
  Widget _buildInteractiveBadge({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    VoidCallback? onTap,
    Widget? popupMenu,
  }) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor.withOpacity(0.9)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (onTap != null || popupMenu != null) ...[
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down,
              size: 12,
              color: textColor.withOpacity(0.7),
            ),
          ],
        ],
      ),
    );

    if (popupMenu != null) {
      return popupMenu;
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: badge,
      );
    }

    return badge;
  }

  Widget _buildSwipeAction(
    IconData icon,
    String label,
    Color backgroundColor,
    Alignment alignment,
  ) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Dialog to handle inline quick rescheduling
  Future<void> _selectDueDate(BuildContext context) async {
    if (onDueDateChanged == null) return;

    final initialDate = todo.dueDate ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      final finalDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? 12,
        pickedTime?.minute ?? 0,
      );

      onDueDateChanged!(finalDateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = todo.completed
        ? (isDark ? Colors.white38 : Colors.grey[400]!)
        : (isDark ? Colors.white : Colors.black87);

    // Overdue colors override standard date badge color
    final dateBadgeBg = _isOverdue
        ? Colors.red.shade100
        : (isDark ? Colors.grey.shade800 : Colors.grey.shade100);
    final dateBadgeText = _isOverdue
        ? Colors.red.shade800
        : (isDark ? Colors.grey.shade300 : Colors.grey.shade700);
    final dateBadgeIcon = _isOverdue ? Icons.error_outline : Icons.access_time;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey(todo.id),
        direction: DismissDirection.horizontal,
        background: _buildSwipeAction(
          todo.completed ? Icons.undo : Icons.check_circle_outline,
          todo.completed ? 'Mark Undone' : 'Complete',
          Colors.green.shade600,
          Alignment.centerLeft,
        ),
        secondaryBackground: _buildSwipeAction(
          Icons.delete_outline,
          'Delete',
          Colors.red.shade600,
          Alignment.centerRight,
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onToggle(!todo.completed);
            return false;
          }
          if (direction == DismissDirection.endToStart) {
            onDelete();
            return true;
          }
          return false;
        },
        child: Card(
          elevation: todo.completed ? 1 : 3,
          shadowColor: Colors.black12,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: todo.completed
                        ? Colors.grey.shade400
                        : _getPriorityColor(todo.priority),
                    width: 6,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(14, 16, 8, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Custom Checkbox Action Target
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 10),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: todo.completed,
                        activeColor: Colors.green.shade500,
                        checkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        side: BorderSide(
                          color: Colors.grey.shade400,
                          width: 1.5,
                        ),
                        onChanged: (bool? isChecked) {
                          if (isChecked != null) onToggle(isChecked);
                        },
                      ),
                    ),
                  ),

                  // 2. Info Layout
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            decoration: todo.completed
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: textColor,
                            decorationThickness: 2,
                          ),
                          child: Text(
                            todo.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Actionable Interactive Badges
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Interactive Priority Badge (PopupMenuButton)
                            _buildInteractiveBadge(
                              icon: Icons.flag_outlined,
                              label: _getPriorityLabel(todo.priority),
                              backgroundColor: _getPriorityBackgroundColor(
                                todo.priority,
                              ),
                              textColor: _getPriorityTextColor(todo.priority),
                              popupMenu: onPriorityChanged == null
                                  ? null
                                  : PopupMenuButton<int>(
                                      tooltip: 'Change Priority',
                                      offset: const Offset(0, 30),
                                      onSelected: onPriorityChanged,
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 2,
                                          child: Text('🔴 High Priority'),
                                        ),
                                        const PopupMenuItem(
                                          value: 1,
                                          child: Text('🟡 Medium Priority'),
                                        ),
                                        const PopupMenuItem(
                                          value: 0,
                                          child: Text('🔵 Low Priority'),
                                        ),
                                      ],
                                      child: _buildInteractiveBadge(
                                        icon: Icons.flag_outlined,
                                        label: _getPriorityLabel(todo.priority),
                                        backgroundColor:
                                            _getPriorityBackgroundColor(
                                              todo.priority,
                                            ),
                                        textColor: _getPriorityTextColor(
                                          todo.priority,
                                        ),
                                      ),
                                    ),
                            ),

                            // Interactive Date/Time Badge
                            _buildInteractiveBadge(
                              icon: dateBadgeIcon,
                              label: todo.dueDate != null
                                  ? '${_isOverdue ? "Overdue: " : ""}${DateFormat('d MMM, h:mm a').format(todo.dueDate!)}'
                                  : 'Add Date',
                              backgroundColor: dateBadgeBg,
                              textColor: dateBadgeText,
                              onTap: onDueDateChanged != null
                                  ? () => _selectDueDate(context)
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 3. Trailing Quick Action Menu (Eliminates navigating away)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    tooltip: 'Quick Actions',
                    onSelected: (action) {
                      switch (action) {
                        case 'edit':
                          if (onEdit != null) onEdit!();
                          break;
                        case 'postpone':
                          if (onDueDateChanged != null) {
                            final current = todo.dueDate ?? DateTime.now();
                            onDueDateChanged!(
                              current.add(const Duration(days: 1)),
                            );
                          }
                          break;
                        case 'clear_date':
                          if (onDueDateChanged != null) {
                            onDueDateChanged!(null);
                          }
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit Details'),
                          ],
                        ),
                      ),
                      if (todo.dueDate != null) ...[
                        const PopupMenuItem(
                          value: 'postpone',
                          child: Row(
                            children: [
                              Icon(Icons.snooze, size: 18),
                              SizedBox(width: 8),
                              Text('Postpone 1 Day'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'clear_date',
                          child: Row(
                            children: [
                              Icon(Icons.event_busy, size: 18),
                              SizedBox(width: 8),
                              Text('Remove Date'),
                            ],
                          ),
                        ),
                      ],
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Delete Task',
                              style: TextStyle(color: Colors.red.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
