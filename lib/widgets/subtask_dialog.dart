import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/todo_model.dart';
import '../providers/todo_provider.dart';

class SubtaskDialog extends StatefulWidget {
  final Todo todo;
  final Subtask? existingSubtask;

  const SubtaskDialog({
    super.key, 
    required this.todo, 
    this.existingSubtask,
  });

  @override
  _SubtaskDialogState createState() => _SubtaskDialogState();
}

class _SubtaskDialogState extends State<SubtaskDialog> {
  late TextEditingController _subtaskController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _subtaskController = TextEditingController(
      text: widget.existingSubtask?.title ?? '',
    );
    _isEditing = widget.existingSubtask != null;
  }

  @override
  void dispose() {
    _subtaskController.dispose();
    super.dispose();
  }

  void _saveSubtask() {
    final subtaskTitle = _subtaskController.text.trim();
    
    if (subtaskTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Subtask title cannot be empty',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final todoProvider = Provider.of<TodoProvider>(context, listen: false);

    if (_isEditing && widget.existingSubtask != null) {
      // Update existing subtask
      todoProvider.updateSubtask(
        widget.todo.id, 
        widget.existingSubtask!.id, 
        widget.existingSubtask!.copyWith(title: subtaskTitle)
      );
    } else {
      // Add new subtask
      todoProvider.addSubtask(
        widget.todo.id, 
        Subtask(title: subtaskTitle)
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'Edit Subtask' : 'Add Subtask',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: TextField(
        controller: _subtaskController,
        autofocus: true,
        style: GoogleFonts.poppins(),
        decoration: InputDecoration(
          hintText: 'Enter subtask title',
          hintStyle: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
        onSubmitted: (_) => _saveSubtask(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(),
          ),
        ),
        ElevatedButton(
          onPressed: _saveSubtask,
          child: Text(
            _isEditing ? 'Update' : 'Add',
            style: GoogleFonts.poppins(),
          ),
        ),
      ],
    );
  }
}
