import 'package:sqflite/sqflite.dart';
import '../../db/database_helper.dart';
import '../../models/cashier/cashier.dart';

class CashierRepository {
  final _table = 'todos';

  // Future<int> create(Todo todo) async {
  //   final db = await DatabaseHelper.instance.database;
  //   return db.insert(_table, todo.toMap(),
  //       conflictAlgorithm: ConflictAlgorithm.replace);
  // }

  Future<List<Map<String, dynamic>>> getCategoriesWithItemsAndBatches() async {
  final db = await DatabaseHelper.instance.database;

  // Flat query (joins category, item, stock)
  final res = await db.rawQuery('''
    SELECT
      c.id          AS category_id,
      c.category    AS category,
      c.color_code  AS categoryColor,
      c.category_image,
      i.id          AS item_id,
      i.barcode     AS itemcode,
      i.name        AS itemName,
      i.color_code  AS itemColor,
      s.batch_id    AS batchID,
      s.unit_price  AS pprice,
      s.sell_price  AS price,
      s.quantity,
      s.discount_amount
    FROM category c
    JOIN item i ON i.category_id = c.id
    JOIN stock s ON s.item_id = i.id
    ORDER BY c.id, i.id, s.id
  ''');

  // Group into nested JSON
  final Map<int, Map<String, dynamic>> categoryMap = {};

  for (final row in res) {
    final catId = row['category_id'] as int;

    // Category
    categoryMap.putIfAbsent(catId, () => {
      'id': catId,
      'category': row['category'],
      'colorCode': row['categoryColor'],
      'categoryImage': row['category_image'],
      'items': [],
    });

    final items = categoryMap[catId]!['items'] as List;

    // Item
    final itemId = row['item_id'] as int;
    var item = items.cast<Map<String, dynamic>>().firstWhere(
      (it) => it['id'] == itemId,
      orElse: () {
        final newItem = {
          'id': itemId,
          'itemcode': row['itemcode'],
          'name': row['itemName'],
          'colorCode': row['itemColor'],
          'batches': [],
        };
        items.add(newItem);
        return newItem;
      },
    );

    // Batch
    (item['batches'] as List).add({
      'batchID': row['batchID'],
      'pprice': row['pprice'],
      'price': row['price'],
      'quantity': row['quantity'],
      'discountAmount': row['discount_amount'],
    });
  }

  return categoryMap.values.toList();
}


  // Future<Todo?> getById(int id) async {
  //   final db = await DatabaseHelper.instance.database;
  //   final res = await db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
  //   if (res.isEmpty) return null;
  //   return Todo.fromMap(res.first);
  // }

  // Future<int> update(Todo todo) async {
  //   final db = await DatabaseHelper.instance.database;
  //   if (todo.id == null) throw ArgumentError('Todo id is null');
  //   return db.update(_table, todo.toMap(), where: 'id = ?', whereArgs: [todo.id]);
  // }

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
