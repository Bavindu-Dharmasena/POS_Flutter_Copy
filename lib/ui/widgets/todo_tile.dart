import 'package:flutter/material.dart';
import '../../data/models/todo.dart';

class TodoTile extends StatelessWidget {
  final Todo todo;
  final VoidCallback? onTap;
  final ValueChanged<bool?>? onChanged;

  const TodoTile({
    super.key,
    required this.todo,
    this.onTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Checkbox(
        value: todo.isDone,
        onChanged: onChanged,
      ),
      title: Text(
        todo.title,
        style: TextStyle(
          decoration: todo.isDone ? TextDecoration.lineThrough : null,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: (todo.description?.isNotEmpty ?? false)
          ? Text(todo.description!)
          : null,
      trailing: Text(
        _formatDate(todo.createdAt),
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
    // keep simple; use intl if you like
  }
}
