import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/features/todo/presentation/controller/todo_controller.dart';

class AddTodoBottomSheet extends StatefulWidget {
  final TodoController controller;

  const AddTodoBottomSheet({super.key, required this.controller});

  @override
  State<AddTodoBottomSheet> createState() => _AddTodoBottomSheetState();
}

class _AddTodoBottomSheetState extends State<AddTodoBottomSheet> {
  final _todoTitleController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  int selectedPriority = 0; // 0: Low, 1: Medium, 2: High
  String? titleError;

  @override
  void dispose() {
    _todoTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Add New Task',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _todoTitleController,
                autofocus: true,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
                onChanged: (val) {
                  if (titleError != null) {
                    setState(() => titleError = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'What needs to be done?',
                  errorText: titleError,
                  hintStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white54
                        : Colors.grey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[900]
                      : Colors.grey[100],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'Priority: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SegmentedButton<int>(
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      segments: const [
                        ButtonSegment(
                          value: 0,
                          label: Text('Low', overflow: TextOverflow.ellipsis),
                        ),
                        ButtonSegment(
                          value: 1,
                          label: Text('Med', overflow: TextOverflow.ellipsis),
                        ),
                        ButtonSegment(
                          value: 2,
                          label: Text('High', overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      selected: {selectedPriority},
                      onSelectionChanged: (val) {
                        setState(() => selectedPriority = val.first);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  selectedDate == null
                      ? 'Set Date & Time (Optional)'
                      : '${DateFormat.yMMMd().format(selectedDate!)} ${selectedTime?.format(context) ?? ""}',
                  style: TextStyle(
                    fontSize: 14,
                    color: selectedDate == null ? Colors.grey : null,
                  ),
                ),
                subtitle: const Text(
                  'Set a time to receive a notification reminder.',
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    if (!context.mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    setState(() {
                      selectedDate = date;
                      selectedTime = time;
                    });
                  }
                },
                trailing: selectedDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          selectedDate = null;
                          selectedTime = null;
                        }),
                      )
                    : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final text = _todoTitleController.text.trim();
                    if (text.isEmpty) {
                      setState(() => titleError = 'Title cannot be empty');
                    } else if (selectedDate != null && selectedTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please select a time for the reminder',
                          ),
                        ),
                      );
                    } else {
                      DateTime? finalDueDate;
                      if (selectedDate != null && selectedTime != null) {
                        finalDueDate = DateTime(
                          selectedDate!.year,
                          selectedDate!.month,
                          selectedDate!.day,
                          selectedTime!.hour,
                          selectedTime!.minute,
                        );
                      }
                      await widget.controller.addTodo(
                        text,
                        dueDate: finalDueDate,
                        priority: selectedPriority,
                      );
                      if (context.mounted) {
                        FocusScope.of(context).unfocus();
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF263238),
                    foregroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Add Task',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
