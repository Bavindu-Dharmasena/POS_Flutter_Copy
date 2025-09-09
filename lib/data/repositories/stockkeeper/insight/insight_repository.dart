import 'dart:math' as math;
import 'package:pos_system/data/models/stockkeeper/insight/top_selling_item.dart';
import 'package:sqflite/sqflite.dart';
import 'package:pos_system/data/db/database_helper.dart';
import 'package:pos_system/data/models/stockkeeper/insight/chart_series.dart';

enum InsightPeriod { today, week, month, year }

class _Range {
  final DateTime start;
  final DateTime end;
  const _Range(this.start, this.end);
  int get startMs => start.millisecondsSinceEpoch;
  int get endMs => end.millisecondsSinceEpoch;
}

class InsightRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  // ----------- Public API -----------
  Future<double> totalSales(InsightPeriod p) async {
    final db = await _db;
    final r = _range(p);
    final row = (await db.rawQuery(
      'SELECT IFNULL(SUM(total),0) AS t FROM sale WHERE date BETWEEN ? AND ?',
      [r.startMs, r.endMs],
    ))
        .first;
    final t = row['t'];
    return (t is num) ? t.toDouble() : 0.0;
  }

  Future<int> totalProducts() async {
    final db = await _db;
    final row = (await db.rawQuery('SELECT COUNT(*) AS c FROM item')).first;
    final c = row['c'];
    return (c is num) ? c.toInt() : 0;
  }

  Future<int> totalCustomers() async {
    final db = await _db;
    final row = (await db.rawQuery('SELECT COUNT(*) AS c FROM customer')).first;
    final c = row['c'];
    return (c is num) ? c.toInt() : 0;
  }

  Future<List<TopItemSummary>> topSellingItems(InsightPeriod p, {int limit = 10}) async {
    final db = await _db;
    final r = _range(p);
    final rows = await db.rawQuery('''
      SELECT i.id AS item_id, i.name AS name, IFNULL(SUM(iv.quantity),0) AS sold
      FROM invoice iv
      JOIN sale s   ON s.id = iv.sale_invoice_id
      JOIN item i   ON i.id = iv.item_id
      WHERE s.date BETWEEN ? AND ?
      GROUP BY i.id, i.name
      ORDER BY sold DESC
      LIMIT ?
    ''', [r.startMs, r.endMs, limit]);

    return rows.map((m) {
      final id = (m['item_id'] as num).toInt();
      final name = (m['name'] ?? 'Item').toString();
      final sold = (m['sold'] is num) ? (m['sold'] as num).toInt() : 0;
      return TopItemSummary(itemId: id, name: name, price: null, sold: sold);
    }).toList();
  }

  /// Builds an evenly spaced time series + labels for the chart.
  Future<ChartSeries> salesSeries(InsightPeriod p) async {
    final db = await _db;
    final r = _range(p);

    switch (p) {
      case InsightPeriod.today:
        // 24 buckets: 00..23
        final rows = await db.rawQuery('''
          SELECT strftime('%H', datetime(s.date/1000,'unixepoch','localtime')) AS h,
                 SUM(s.total) AS t
          FROM sale s
          WHERE s.date BETWEEN ? AND ?
          GROUP BY h ORDER BY h
        ''', [r.startMs, r.endMs]);

        final byHour = <int, double>{};
        for (final m in rows) {
          final h = int.parse((m['h'] ?? '0') as String);
          final t = (m['t'] is num) ? (m['t'] as num).toDouble() : 0.0;
          byHour[h] = t;
        }
        final labels = List.generate(24, (i) => i.toString().padLeft(2, '0'));
        final values = List.generate(24, (i) => byHour[i] ?? 0.0);
        return ChartSeries(labels: labels, values: values, yUnit: 'Rs.');

      case InsightPeriod.week:
        // 7 days ending today (Mon..Sun labels from each date)
        final days = List.generate(7, (i) => r.end.subtract(Duration(days: 6 - i)));
        final rows = await db.rawQuery('''
          SELECT strftime('%Y-%m-%d', datetime(s.date/1000,'unixepoch','localtime')) AS d,
                 SUM(s.total) AS t
          FROM sale s
          WHERE s.date BETWEEN ? AND ?
          GROUP BY d ORDER BY d
        ''', [r.startMs, r.endMs]);

        final map = <String, double>{};
        for (final m in rows) {
          final d = (m['d'] ?? '').toString();
          final t = (m['t'] is num) ? (m['t'] as num).toDouble() : 0.0;
          map[d] = t;
        }
        final labels = days.map((dt) => _dow(dt)).toList(); // Mon..Sun
        final values = days
            .map((dt) => map[_ymd(dt)] ?? 0.0)
            .toList(growable: false);
        return ChartSeries(labels: labels, values: values, yUnit: 'Rs.');

      case InsightPeriod.month:
        // current month day-by-day
        final first = DateTime(r.start.year, r.start.month, 1);
        final last = DateTime(r.end.year, r.end.month + 1, 0);
        final count = last.day;
        final days = List.generate(count, (i) => DateTime(first.year, first.month, i + 1));

        final rows = await db.rawQuery('''
          SELECT strftime('%Y-%m-%d', datetime(s.date/1000,'unixepoch','localtime')) AS d,
                 SUM(s.total) AS t
          FROM sale s
          WHERE s.date BETWEEN ? AND ?
          GROUP BY d ORDER BY d
        ''', [r.startMs, r.endMs]);

        final map = <String, double>{};
        for (final m in rows) {
          final d = (m['d'] ?? '').toString();
          final t = (m['t'] is num) ? (m['t'] as num).toDouble() : 0.0;
          map[d] = t;
        }
        final labels = days.map((dt) => dt.day.toString()).toList();
        final values = days.map((dt) => map[_ymd(dt)] ?? 0.0).toList();
        return ChartSeries(labels: labels, values: values, yUnit: 'Rs.');

      case InsightPeriod.year:
        // 12 months of current year
        final months = List.generate(12, (i) => DateTime(r.start.year, i + 1, 1));
        final rows = await db.rawQuery('''
          SELECT strftime('%Y-%m', datetime(s.date/1000,'unixepoch','localtime')) AS m,
                 SUM(s.total) AS t
          FROM sale s
          WHERE s.date BETWEEN ? AND ?
          GROUP BY m ORDER BY m
        ''', [r.startMs, r.endMs]);

        final map = <String, double>{};
        for (final m in rows) {
          final k = (m['m'] ?? '').toString();
          final t = (m['t'] is num) ? (m['t'] as num).toDouble() : 0.0;
          map[k] = t;
        }
        final labels = months.map((dt) => _mon(dt.month)).toList();
        final values = months
            .map((dt) => map['${dt.year}-${dt.month.toString().padLeft(2, '0')}'] ?? 0.0)
            .toList();
        return ChartSeries(labels: labels, values: values, yUnit: 'Rs.');
    }
  }

  // ----------- Helpers -----------
  _Range _range(InsightPeriod p) {
    final now = DateTime.now();
    switch (p) {
      case InsightPeriod.today:
        final start = DateTime(now.year, now.month, now.day);
        return _Range(start, now);
      case InsightPeriod.week:
        // last 7 days inclusive ending today
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        final start = end.subtract(const Duration(days: 6));
        return _Range(DateTime(start.year, start.month, start.day), end);
      case InsightPeriod.month:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        return _Range(start, end);
      case InsightPeriod.year:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31, 23, 59, 59, 999);
        return _Range(start, end);
    }
  }

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _dow(DateTime d) => const ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d.weekday - 1];
  String _mon(int m) => const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];

 
}
