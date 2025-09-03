import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/todo.dart';

class TodoRepository {
  final _table = 'todos';

  Future<int> create(Todo todo) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert(_table, todo.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Todo>> getAll({String? query}) async {
    final db = await DatabaseHelper.instance.database;
    final where = (query != null && query.trim().isNotEmpty)
        ? 'WHERE title LIKE ? OR description LIKE ?'
        : '';
    final args = (where.isNotEmpty) ? ['%$query%', '%$query%'] : null;

    final res = await db.rawQuery('''
      SELECT * FROM $_table
      $where
      ORDER BY is_done ASC, created_at DESC
    ''', args);

    return res.map((e) => Todo.fromMap(e)).toList();
  }

  Future<Todo?> getById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (res.isEmpty) return null;
    return Todo.fromMap(res.first);
  }

  Future<int> update(Todo todo) async {
    final db = await DatabaseHelper.instance.database;
    if (todo.id == null) throw ArgumentError('Todo id is null');
    return db.update(_table, todo.toMap(), where: 'id = ?', whereArgs: [todo.id]);
  }

  Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> toggleDone(int id, bool isDone) async {
    final db = await DatabaseHelper.instance.database;
    return db.update(_table, {'is_done': isDone ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(_table);
  }
}
