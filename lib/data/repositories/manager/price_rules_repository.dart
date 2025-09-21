import 'package:pos_system/data/db/database_helper.dart';
import 'package:pos_system/data/models/manager/price_rules_model.dart';
import 'package:sqflite/sqflite.dart';


class PriceRuleRepository {
  static const String tableName = 'price_rule';
  
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String> create(PriceRule rule) async {
    final db = await _dbHelper.database;
    
    final ruleWithId = rule.id.isEmpty 
        ? rule.copyWith(id: _generateId())
        : rule;
    
    await db.insert(
      tableName,
      ruleWithId.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    return ruleWithId.id;
  }

  Future<List<PriceRule>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      tableName,
      orderBy: 'priority ASC, created_at DESC',
    );
    
    return maps.map((map) => PriceRule.fromMap(map)).toList();
  }

  Future<List<PriceRule>> getActive() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      tableName,
      where: 'active = ?',
      whereArgs: [1],
      orderBy: 'priority ASC',
    );
    
    return maps.map((map) => PriceRule.fromMap(map)).toList();
  }

  Future<List<PriceRule>> getCurrentlyEffective() async {
    final activeRules = await getActive();
    return activeRules.where((rule) => rule.isCurrentlyEffective).toList();
  }

  Future<PriceRule?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return PriceRule.fromMap(maps.first);
  }

  Future<List<PriceRule>> getByScopeKind(ScopeKind scopeKind, {String? scopeValue}) async {
    final db = await _dbHelper.database;
    
    String whereClause = 'active = ? AND scope_kind = ?';
    List<dynamic> whereArgs = [1, scopeKind.value];
    
    if (scopeValue != null && scopeKind != ScopeKind.all) {
      whereClause += ' AND scope_value = ?';
      whereArgs.add(scopeValue);
    }
    
    final maps = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'priority ASC',
    );
    
    return maps.map((map) => PriceRule.fromMap(map)).toList();
  }

  Future<List<PriceRule>> getApplicableRules({
    String? itemId,
    String? categoryName,
    String? customerGroup,
  }) async {
    final db = await _dbHelper.database;
    
    final maps = await db.rawQuery('''
      SELECT * FROM $tableName 
      WHERE active = 1 
      AND (
        scope_kind = 'ALL' 
        OR (scope_kind = 'CATEGORY' AND scope_value = ?) 
        OR (scope_kind = 'PRODUCT' AND scope_value = ?)
        OR (scope_kind = 'CUSTOMER_GROUP' AND scope_value = ?)
      )
      ORDER BY priority ASC
    ''', [categoryName ?? '', itemId ?? '', customerGroup ?? '']);
    
    final rules = maps.map((map) => PriceRule.fromMap(map)).toList();
    
    return rules.where((rule) => rule.isCurrentlyEffective).toList();
  }

  Future<bool> update(PriceRule rule) async {
    final db = await _dbHelper.database;
    final updatedRule = rule.copyWith(updatedAt: DateTime.now());
    
    final count = await db.update(
      tableName,
      updatedRule.toMap(),
      where: 'id = ?',
      whereArgs: [rule.id],
    );
    
    return count > 0;
  }

  Future<bool> delete(String id) async {
    final db = await _dbHelper.database;
    final count = await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    return count > 0;
  }

  Future<bool> toggleActive(String id) async {
    final rule = await getById(id);
    if (rule == null) return false;
    
    final updatedRule = rule.copyWith(
      active: !rule.active,
      updatedAt: DateTime.now(),
    );
    
    return await update(updatedRule);
  }

  Future<List<PriceRule>> search({
    String? query,
    RuleType? type,
    ScopeKind? scopeKind,
    bool? active,
  }) async {
    final db = await _dbHelper.database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (query != null && query.trim().isNotEmpty) {
      whereClause += ' AND (name LIKE ? OR scope_value LIKE ?)';
      final searchPattern = '%${query.trim()}%';
      whereArgs.addAll([searchPattern, searchPattern]);
    }
    
    if (type != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(type.value);
    }
    
    if (scopeKind != null) {
      whereClause += ' AND scope_kind = ?';
      whereArgs.add(scopeKind.value);
    }
    
    if (active != null) {
      whereClause += ' AND active = ?';
      whereArgs.add(active ? 1 : 0);
    }
    
    final maps = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'priority ASC, created_at DESC',
    );
    
    return maps.map((map) => PriceRule.fromMap(map)).toList();
  }

  Future<Map<String, int>> getStatusCounts() async {
    final db = await _dbHelper.database;
    
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    final activeResult = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName WHERE active = 1');
    final inactiveResult = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName WHERE active = 0');
    
    final total = (totalResult.first['count'] as int?) ?? 0;
    final active = (activeResult.first['count'] as int?) ?? 0;
    final inactive = (inactiveResult.first['count'] as int?) ?? 0;
    
    final allActiveRules = await getActive();
    final scheduled = allActiveRules.where((rule) => rule.isScheduled).length;
    
    return {
      'total': total,
      'active': active - scheduled,
      'scheduled': scheduled,
      'inactive': inactive,
    };
  }

  Future<void> createMany(List<PriceRule> rules) async {
    return _dbHelper.runInTransaction((txn) async {
      for (final rule in rules) {
        final ruleWithId = rule.id.isEmpty 
            ? rule.copyWith(id: _generateId())
            : rule;
            
        await txn.insert(
          tableName,
          ruleWithId.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> deleteMany(List<String> ids) async {
    if (ids.isEmpty) return;
    
    final db = await _dbHelper.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    
    await db.delete(
      tableName,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  String _generateId() {
    return 'rule_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  Future<int> cleanupExpiredRules() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    return await db.delete(
      tableName,
      where: 'end_date IS NOT NULL AND end_date < ?',
      whereArgs: [now],
    );
  }

  Future<List<PriceRule>> getExpiringSoon(int days) async {
    final db = await _dbHelper.database;
    final futureTime = DateTime.now().add(Duration(days: days)).millisecondsSinceEpoch;
    
    final maps = await db.query(
      tableName,
      where: 'active = 1 AND end_date IS NOT NULL AND end_date <= ?',
      whereArgs: [futureTime],
      orderBy: 'end_date ASC',
    );
    
    return maps.map((map) => PriceRule.fromMap(map)).toList();
  }
}