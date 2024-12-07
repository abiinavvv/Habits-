import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo_model.dart';
import '../services/notification_service.dart';
import '../services/performance_service.dart';

class TodoProvider with ChangeNotifier {
  List<Todo> _todos = [];
  bool _isLoading = false;
  String? _error;
  TodoCategory _currentFilter = TodoCategory.other;
  TodoPriority _currentPriorityFilter = TodoPriority.low;
  String _searchQuery = '';
  TodoCategory? _filteredCategory;
  TodoPriority? _filteredPriority;

  List<Todo> get todos {
    //  all filters
    return _todos.where((todo) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty || 
          todo.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (todo.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      // Category filter
      final matchesCategory =
          _filteredCategory == null || todo.category == _filteredCategory;

      // Priority filter
      final matchesPriority =
          _filteredPriority == null || todo.priority == _filteredPriority;

      // Existing category filter
      final matchesExistingCategory = _currentFilter == TodoCategory.other ||
          todo.category == _currentFilter;

      // Existing priority filter
      final matchesExistingPriority =
          _currentPriorityFilter == TodoPriority.low ||
              todo.priority == _currentPriorityFilter;

      return matchesSearch &&
          matchesCategory &&
          matchesPriority &&
          matchesExistingCategory &&
          matchesExistingPriority;
    }).toList();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  TodoCategory get currentFilter => _currentFilter;
  TodoPriority get currentPriorityFilter => _currentPriorityFilter;
  String get searchQuery => _searchQuery;

  TodoProvider() {
    _loadTodos();
  }

  void setFilter(TodoCategory category) {
    _currentFilter = category;
    notifyListeners();
  }

  void setPriorityFilter(TodoPriority priority) {
    _currentPriorityFilter = priority;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilters({TodoCategory? category, TodoPriority? priority}) {
    _filteredCategory = category;
    _filteredPriority = priority;
    notifyListeners();
  }

  void clearFilters() {
    _filteredCategory = null;
    _filteredPriority = null;
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> _loadTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todosJson = prefs.getStringList('todos') ?? [];

      _todos = await PerformanceService.computeInBackground(() {
        return todosJson.map((json) => Todo.fromJson(jsonDecode(json))).toList();
      });

      // Schedule notifications for todos with due dates
      for (var todo in _todos) {
        if (todo.dueDate != null && !todo.isCompleted) {
          await NotificationService.scheduleTodoNotification(todo);
        }
      }

      notifyListeners();
    } catch (e) {
      setError('Failed to load todos: $e');
    }
  }

  Future<void> _saveTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todosJson = _todos.map((todo) => jsonEncode(todo.toJson())).toList();
      await prefs.setStringList('todos', todosJson);
    } catch (e) {
      setError('Failed to save todos: $e');
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> addTodo(Todo todo) async {
    try {
      setLoading(true);
      setError(null);

      await PerformanceService.debounce(
        () async => await _addTodo(todo),
        duration: const Duration(milliseconds: 500),
      );
    } catch (e) {
      setError('Failed to add todo: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> _addTodo(Todo todo) async {
    _todos.add(todo);
    await _saveTodos();

    // Schedule notification if due date is set
    if (todo.dueDate != null) {
      await NotificationService.scheduleTodoNotification(todo);
    }

    notifyListeners();
  }

  Future<void> updateTodo(Todo updatedTodo) async {
    try {
      setLoading(true);
      setError(null);

      final index = _todos.indexWhere((todo) => todo.id == updatedTodo.id);
      if (index != -1) {
        // Cancel previous notification
        await NotificationService.cancelTodoNotification(_todos[index].id);

        // Update todo
        _todos[index] = updatedTodo;
        await _saveTodos();

        // Reschedule notification if applicable
        if (updatedTodo.dueDate != null && !updatedTodo.isCompleted) {
          await NotificationService.scheduleTodoNotification(updatedTodo);
        }

        notifyListeners();
      }
    } catch (e) {
      setError('Failed to update todo: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> toggleTodo(String id) async {
    try {
      setError(null);
      final todoIndex = _todos.indexWhere((todo) => todo.id == id);
      if (todoIndex >= 0) {
        _todos[todoIndex].toggleCompleted();
        notifyListeners();
        await _saveTodos();

        // Cancel notification if completed
        if (_todos[todoIndex].isCompleted) {
          await NotificationService.cancelTodoNotification(id);
        }
      }
    } catch (e) {
      setError('Failed to toggle todo: $e');
    }
  }

  Future<void> removeTodo(String id) async {
    try {
      final todoIndex = _todos.indexWhere((todo) => todo.id == id);
      if (todoIndex >= 0) {
        _todos.removeAt(todoIndex);
        await _saveTodos();
        await NotificationService.cancelTodoNotification(id);
        notifyListeners();
      }
    } catch (e) {
      setError('Failed to remove todo: $e');
    }
  }

  Future<void> addSubtask(String todoId, Subtask subtask) async {
    try {
      setLoading(true);
      setError(null);

      final todoIndex = _todos.indexWhere((todo) => todo.id == todoId);
      if (todoIndex >= 0) {
        _todos[todoIndex].subtasks.add(subtask);
        notifyListeners();
        await _saveTodos();
      } else {
        setError('Todo not found');
      }
    } catch (e) {
      setError('Failed to add subtask: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> updateSubtask(String todoId, String subtaskId, Subtask updatedSubtask) async {
    try {
      setLoading(true);
      setError(null);

      final todoIndex = _todos.indexWhere((todo) => todo.id == todoId);
      if (todoIndex >= 0) {
        final subtaskIndex = _todos[todoIndex].subtasks
            .indexWhere((subtask) => subtask.id == subtaskId);
        
        if (subtaskIndex >= 0) {
          _todos[todoIndex].subtasks[subtaskIndex] = updatedSubtask;
          notifyListeners();
          await _saveTodos();
        } else {
          setError('Subtask not found');
        }
      } else {
        setError('Todo not found');
      }
    } catch (e) {
      setError('Failed to update subtask: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> removeSubtask(String todoId, String subtaskId) async {
    try {
      setLoading(true);
      setError(null);

      final todoIndex = _todos.indexWhere((todo) => todo.id == todoId);
      if (todoIndex >= 0) {
        _todos[todoIndex].subtasks.removeWhere((subtask) => subtask.id == subtaskId);
        notifyListeners();
        await _saveTodos();
      } else {
        setError('Todo not found');
      }
    } catch (e) {
      setError('Failed to remove subtask: $e');
    } finally {
      setLoading(false);
    }
  }

  double calculateTodoProgress(Todo todo) {
    if (todo.subtasks.isEmpty) return todo.isCompleted ? 1.0 : 0.0;
    
    final completedSubtasks = todo.subtasks.where((subtask) => subtask.isCompleted).length;
    return completedSubtasks / todo.subtasks.length;
  }

  Future<void> toggleSubtask(String todoId, String subtaskId) async {
    try {
      final todoIndex = _todos.indexWhere((todo) => todo.id == todoId);
      if (todoIndex >= 0) {
        final subtaskIndex = _todos[todoIndex]
            .subtasks
            .indexWhere((subtask) => subtask.id == subtaskId);
        if (subtaskIndex >= 0) {
          _todos[todoIndex].subtasks[subtaskIndex].toggleCompleted();
          notifyListeners();
          await _saveTodos();
        }
      }
    } catch (e) {
      setError('Failed to toggle subtask: $e');
    }
  }

  Future<void> reorderTodos(int oldIndex, int newIndex) async {
    try {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      final Todo removedTodo = _todos.removeAt(oldIndex);
      _todos.insert(newIndex, removedTodo);

      notifyListeners();
      await _saveTodos();
    } catch (e) {
      setError('Failed to reorder todos: $e');
    }
  }

  Future<void> toggleTodoCompletionBySwipe(String id) async {
    try {
      final todoIndex = _todos.indexWhere((todo) => todo.id == id);
      if (todoIndex >= 0) {
        _todos[todoIndex].isCompleted = !_todos[todoIndex].isCompleted;
        notifyListeners();
        await _saveTodos();

        // Cancel notification if completed
        if (_todos[todoIndex].isCompleted) {
          await NotificationService.cancelTodoNotification(id);
        }
      }
    } catch (e) {
      setError('Failed to toggle todo completion: $e');
    }
  }

  double get todosCompletionProgress {
    if (_todos.isEmpty) return 0.0;

    final completedTodos = _todos.where((todo) => todo.isCompleted).length;
    return completedTodos / _todos.length;
  }

  List<Todo> filterTodos({
    bool? isCompleted,
    TodoPriority? priority,
    TodoCategory? category,
  }) {
    return PerformanceService.efficientFilter(
      _todos,
      (todo) =>
        (isCompleted == null || todo.isCompleted == isCompleted) &&
        (priority == null || todo.priority == priority) &&
        (category == null || todo.category == category),
    ).toList();
  }
}
