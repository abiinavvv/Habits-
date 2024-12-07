import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:habits_plus_plus/models/todo_model.dart';

class AccessibilityService {
  // Improve semantic labeling for todo items
  static void enhanceTodoSemantics(BuildContext context, Todo todo) {
    SemanticsService.announce(
      'Todo: ${todo.title}. '
      'Priority: ${todo.priority.toString().split('.').last}. '
      'Category: ${todo.category.toString().split('.').last}',
      TextDirection.ltr,
    );
  }

  // Generate accessibility-friendly descriptions
  static String generateAccessibleDescription(Todo todo) {
    final statusText = todo.isCompleted ? 'Completed' : 'Pending';
    final subtaskText = todo.subtasks.isNotEmpty
        ? '${todo.subtasks.where((s) => s.isCompleted).length} of ${todo.subtasks.length} subtasks completed'
        : 'No subtasks';

    return '$statusText todo. $subtaskText. '
        'Priority: ${todo.priority.toString().split('.').last}. '
        'Category: ${todo.category.toString().split('.').last}';
  }

  // Semantic announcements for todo state changes
  static void announceTodoStateChange(Todo todo) {
    final stateText = todo.isCompleted ? 'completed' : 'marked as incomplete';
    SemanticsService.announce(
      'Todo "${todo.title}" has been $stateText',
      TextDirection.ltr,
    );
  }

  // Improve touch target sizes
  static Widget enlargeTouchTarget({
    required Widget child,
    double minWidth = 48.0,
    double minHeight = 48.0,
  }) {
    return SizedBox(
      width: minWidth,
      height: minHeight,
      child: Center(child: child),
    );
  }

  // High contrast mode detection
  static bool isHighContrastMode(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    return mediaQuery.highContrast;
  }

  // Dynamic text scaling
  static double getAccessibleFontSize(BuildContext context, double baseSize) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    return baseSize * mediaQuery.textScaleFactor;
  }
}
