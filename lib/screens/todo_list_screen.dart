import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../models/todo_model.dart';
import '../providers/todo_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../widgets/subtask_dialog.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final TextEditingController _todoController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  TodoCategory? _selectedCategory;
  TodoPriority _selectedPriority = TodoPriority.low;
  DateTime? _selectedDueDate;

  void _showAddTodoDialog() {
    // Reset controllers and state
    _todoController.clear();
    _descriptionController.clear();
    _selectedCategory = null;
    _selectedPriority = TodoPriority.low;
    _selectedDueDate = null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _todoController,
                      decoration: InputDecoration(
                        hintText: 'Task Title',
                        errorText: _todoController.text.trim().isEmpty
                            ? 'Task title cannot be empty'
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: 'Description (Optional)',
                      ),
                      maxLines: 3,
                      minLines: 1,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TodoCategory>(
                      decoration: const InputDecoration(
                        hintText: 'Select Category',
                      ),
                      value: _selectedCategory,
                      items: TodoCategory.values
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child:
                                    Text(category.toString().split('.').last),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TodoPriority>(
                      decoration: const InputDecoration(
                        hintText: 'Select Priority',
                      ),
                      value: _selectedPriority,
                      items: TodoPriority.values
                          .map((priority) => DropdownMenuItem(
                                value: priority,
                                child:
                                    Text(priority.toString().split('.').last),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPriority = value ?? TodoPriority.low;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Due Date'),
                      subtitle: Text(_selectedDueDate == null
                          ? 'Not set'
                          : '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _selectedDueDate = pickedDate;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _todoController.text.trim().isEmpty
                      ? null
                      : () {
                          final todoProvider =
                              Provider.of<TodoProvider>(context, listen: false);

                          final newTodo = Todo(
                            title: _todoController.text.trim(),
                            description:
                                _descriptionController.text.trim().isEmpty
                                    ? null
                                    : _descriptionController.text.trim(),
                            category: _selectedCategory ?? TodoCategory.other,
                            priority: _selectedPriority,
                            dueDate: _selectedDueDate,
                          );

                          todoProvider.addTodo(newTodo);

                          // Reset controllers and state
                          _todoController.clear();
                          _descriptionController.clear();
                          _selectedCategory = null;
                          _selectedPriority = TodoPriority.low;
                          _selectedDueDate = null;

                          Navigator.of(context).pop();
                        },
                  child: const Text('Add Task'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTodoDetailsDialog(Todo todo) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final todoProvider = Provider.of<TodoProvider>(context);

            return AlertDialog(
              title: Text(
                todo.title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (todo.description != null)
                      Text(
                        todo.description!,
                        style: GoogleFonts.poppins(),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Subtasks',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (todo.subtasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No subtasks yet',
                          style: GoogleFonts.poppins(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ...todo.subtasks.map((subtask) => CheckboxListTile(
                          title: Text(
                            subtask.title,
                            style: GoogleFonts.poppins(
                              decoration: subtask.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          value: subtask.isCompleted,
                          onChanged: (bool? value) {
                            todoProvider.toggleSubtask(todo.id, subtask.id);
                          },
                          secondary: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => SubtaskDialog(
                                      todo: todo,
                                      existingSubtask: subtask,
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () {
                                  todoProvider.removeSubtask(
                                      todo.id, subtask.id);
                                },
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => SubtaskDialog(todo: todo),
                    );
                  },
                  child: Text(
                    'Add Subtask',
                    style: GoogleFonts.poppins(),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddSubtaskDialog(String todoId) {
    final subtaskController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Subtask'),
        content: TextField(
          controller: subtaskController,
          decoration: const InputDecoration(
            hintText: 'Subtask Title',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (subtaskController.text.isNotEmpty) {
                final subtask = Subtask(title: subtaskController.text);
                context.read<TodoProvider>().addSubtask(todoId, subtask);
                subtaskController.clear();
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Method to get category icon
  IconData _getCategoryIcon(TodoCategory category) {
    switch (category) {
      case TodoCategory.work:
        return Icons.work_outline;
      case TodoCategory.personal:
        return Icons.person_outline;
      case TodoCategory.shopping:
        return Icons.shopping_cart_outlined;
      case TodoCategory.health:
        return Icons.health_and_safety_outlined;
      case TodoCategory.other:
      default:
        return Icons.category_outlined;
    }
  }

  // Method to show filter bottom sheet
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final todoProvider = Provider.of<TodoProvider>(context);
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Tasks',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Category',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Wrap(
                    spacing: 8,
                    children: TodoCategory.values.map((category) {
                      final isSelected = _selectedCategory == category;
                      return ChoiceChip(
                        label: Text(category.toString().split('.').last),
                        selected: isSelected,
                        avatar: Icon(_getCategoryIcon(category)),
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedCategory = selected ? category : null;
                          });
                        },
                        selectedColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Priority',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Wrap(
                    spacing: 8,
                    children: TodoPriority.values.map((priority) {
                      final isSelected = _selectedPriority == priority;
                      return ChoiceChip(
                        label: Text(priority.toString().split('.').last),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedPriority = priority;
                          });
                        },
                        selectedColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategory = null;
                            _selectedPriority = TodoPriority.low;
                          });
                          todoProvider.clearFilters();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear Filters'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          todoProvider.setFilters(
                            category: _selectedCategory,
                            priority: _selectedPriority,
                          );
                          Navigator.pop(context);
                        },
                        child: const Text('Apply Filters'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context);
    final themeModeProvider = Provider.of<ThemeModeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Habits++'),
        actions: [
          IconButton(
            icon: Icon(
              Provider.of<ThemeModeProvider>(context).themeMode ==
                      ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Provider.of<ThemeModeProvider>(context).themeMode ==
                          ThemeMode.system
                      ? Icons.brightness_auto_outlined
                      : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              Provider.of<ThemeModeProvider>(context, listen: false)
                  .toggleThemeMode();
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                Provider.of<TodoProvider>(context, listen: false)
                    .setSearchQuery(value);
              },
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<TodoProvider>(context, listen: false)
                              .setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: Consumer<TodoProvider>(
        builder: (context, todoProvider, child) {
          if (todoProvider.isLoading) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Shimmer.fromColors(
                    baseColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    highlightColor: Theme.of(context).colorScheme.surface,
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                );
              },
            );
          }

          if (todoProvider.todos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeIn(
                    child: Icon(
                      Icons.task_outlined,
                      size: 100,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Tasks Yet!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap the + button to create your first task',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: todoProvider.todos.length,
            itemBuilder: (context, index) {
              final todo = todoProvider.todos[index];
              return Slidable(
                key: ValueKey(todo.id),
                startActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) =>
                          todoProvider.toggleTodoCompletionBySwipe(todo.id),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      icon: Icons.check,
                      label: 'Complete',
                    ),
                  ],
                ),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  dismissible: DismissiblePane(
                    onDismissed: () => todoProvider.removeTodo(todo.id),
                  ),
                  children: [
                    SlidableAction(
                      onPressed: (_) => todoProvider.removeTodo(todo.id),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Delete',
                    ),
                  ],
                ),
                child: Container(
                  key: Key(todo.id),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: CircularPercentIndicator(
                      radius: 25.0,
                      lineWidth: 5.0,
                      percent: _calculateTaskProgress(todo),
                      progressColor: _getProgressColor(context, todo),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      center: Checkbox(
                        value: todo.isCompleted,
                        onChanged: (_) => todoProvider.toggleTodo(todo.id),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        decoration: todo.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: todo.isCompleted
                            ? Theme.of(context).colorScheme.outline
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      '${todo.category.toString().split('.').last} | ${todo.priority.toString().split('.').last}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => _showTodoDetailsDialog(todo),
                    ),
                  ),
                ),
              );
            },
            onReorder: (int oldIndex, int newIndex) {
              todoProvider.reorderTodos(oldIndex, newIndex);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTodoDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  double _calculateTaskProgress(Todo todo) {
    if (todo.isCompleted) return 1.0;

    if (todo.subtasks.isNotEmpty) {
      final completedSubtasks =
          todo.subtasks.where((subtask) => subtask.isCompleted).length;
      return completedSubtasks / todo.subtasks.length;
    }

    return 0.0;
  }

  Color _getProgressColor(BuildContext context, Todo todo) {
    if (todo.isCompleted) {
      return Colors.green;
    }

    if (todo.subtasks.isNotEmpty) {
      final completedSubtasks =
          todo.subtasks.where((subtask) => subtask.isCompleted).length;
      final totalSubtasks = todo.subtasks.length;

      if (completedSubtasks > 0) {
        return Colors.orange;
      }
    }

    return Theme.of(context).colorScheme.primary.withOpacity(0.5);
  }
}
