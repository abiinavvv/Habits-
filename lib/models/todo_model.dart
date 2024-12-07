import 'package:uuid/uuid.dart';

enum TodoCategory {
  work,
  personal,
  shopping,
  health,
  other,
}

enum TodoPriority {
  low,
  medium,
  high,
  urgent,
}

class Todo {
  String id;
  String title;
  String? description;
  bool isCompleted;
  TodoCategory category;
  TodoPriority priority;
  DateTime? createdAt;
  DateTime? dueDate;
  List<Subtask> subtasks;

  Todo({
    String? id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.category = TodoCategory.other,
    this.priority = TodoPriority.low,
    DateTime? createdAt,
    this.dueDate,
    List<Subtask>? subtasks,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        subtasks = subtasks ?? [];

  void toggleCompleted() {
    isCompleted = !isCompleted;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'category': category.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'createdAt': createdAt?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'subtasks': subtasks.map((subtask) => subtask.toJson()).toList(),
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      isCompleted: json['isCompleted'],
      category: TodoCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category']
      ),
      priority: TodoPriority.values.firstWhere(
        (e) => e.toString().split('.').last == json['priority']
      ),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      subtasks: (json['subtasks'] as List?)
        ?.map((subtaskJson) => Subtask.fromJson(subtaskJson))
        .toList() ?? [],
    );
  }
}

class Subtask {
  String id;
  String title;
  bool isCompleted;
  DateTime? createdAt;

  Subtask({
    String? id,
    required this.title,
    this.isCompleted = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  void toggleCompleted() {
    isCompleted = !isCompleted;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'],
      title: json['title'],
      isCompleted: json['isCompleted'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
    );
  }

  Subtask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
