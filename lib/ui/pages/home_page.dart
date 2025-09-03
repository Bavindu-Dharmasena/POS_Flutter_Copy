import 'package:flutter/material.dart';
import '../../data/models/todo.dart';
import '../../data/repositories/todo_repository.dart';
import '../widgets/todo_tile.dart';
import 'edit_todo_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TodoRepository _repo = TodoRepository();
  final TextEditingController _searchCtrl = TextEditingController();
  List<Todo> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _repo.getAll(query: _searchCtrl.text.trim());
    setState(() {
      _items = data;
      _loading = false;
    });
  }

  Future<void> _toggleDone(Todo todo, bool? val) async {
    await _repo.toggleDone(todo.id!, val ?? false);
    _load();
  }

  Future<void> _delete(Todo todo) async {
    await _repo.delete(todo.id!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleted')),
      );
    }
    _load();
  }

  Future<void> _openEditor({Todo? todo}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditTodoPage(todo: todo)),
    );
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SQLite Todos'),
        actions: [
          IconButton(
            tooltip: 'Clear all',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _items.isEmpty
                ? null
                : () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear all?'),
                        content: const Text('This will delete all todos.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel')),
                          FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete')),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await _repo.clearAll();
                      _load();
                    }
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search title or description...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('No items yet. Tap + to add.'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 0, thickness: 0.5),
                          itemBuilder: (context, index) {
                            final todo = _items[index];
                            return Dismissible(
                              key: ValueKey('todo-${todo.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              onDismissed: (_) => _delete(todo),
                              child: TodoTile(
                                todo: todo,
                                onTap: () => _openEditor(todo: todo),
                                onChanged: (v) => _toggleDone(todo, v),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}
