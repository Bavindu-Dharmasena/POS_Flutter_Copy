import 'package:flutter/material.dart';
import '../../data/models/todo.dart';
import '../../data/repositories/todo_repository.dart';

class EditTodoPage extends StatefulWidget {
  final Todo? todo;
  const EditTodoPage({super.key, this.todo});

  @override
  State<EditTodoPage> createState() => _EditTodoPageState();
}

class _EditTodoPageState extends State<EditTodoPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isDone = false;
  bool _saving = false;
  final TodoRepository _repo = TodoRepository();

  @override
  void initState() {
    super.initState();
    final t = widget.todo;
    if (t != null) {
      _titleCtrl.text = t.title;
      _descCtrl.text = t.description ?? '';
      _isDone = t.isDone;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final now = DateTime.now();
    final newTodo = Todo(
      id: widget.todo?.id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      isDone: _isDone,
      createdAt: widget.todo?.createdAt ?? now,
    );

    if (widget.todo == null) {
      await _repo.create(newTodo);
    } else {
      await _repo.update(newTodo);
    }

    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.todo != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Todo' : 'New Todo'),
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Buy groceries',
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional details…',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _isDone,
                  onChanged: (v) => setState(() => _isDone = v),
                  title: const Text('Mark as done'),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(isEditing ? 'Update' : 'Create'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
