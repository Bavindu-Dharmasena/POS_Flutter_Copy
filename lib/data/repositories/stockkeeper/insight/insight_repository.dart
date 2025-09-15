import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:pos_system/data/db/database_helper.dart';
import 'package:pos_system/data/models/stockkeeper/insight/chart_series.dart';
import 'package:pos_system/data/models/stockkeeper/insight/top_selling_item.dart';

enum InsightPeriod { today, week, month, year }

class InsightRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  // ---------- Quick stats ----------
  Future<int> totalProducts() async {
    final db = await _db;
    final r = await db.rawQuery('SELECT COUNT(*) AS c FROM item');
    return (Sqflite.firstIntValue(r) ?? 0);
  }

  Future<int> totalCustomers() async {
    final db = await _db;
    final r = await db.rawQuery('SELECT COUNT(*) AS c FROM customer');
    return (Sqflite.firstIntValue(r) ?? 0);
  }

  /// Sum of payments within the selected period
  Future<double> totalSales(InsightPeriod p) async {
    final db = await _db;
    final range = _rangeFor(p);
    final r = await db.rawQuery(
      '''
      SELECT IFNULL(SUM(amount), 0) AS t
      FROM payment
      WHERE date BETWEEN ? AND ?
      ''',
      [range.startMs, range.endMs],
    );
    final row = r.isNotEmpty ? r.first : const <String, Object?>{};
    final v = row['t'];
    return (v is int) ? v.toDouble() : (v as double? ?? 0.0);
  }

  // ---------- Top selling items ----------
  Future<List<TopItemSummary>> topSellingItems(InsightPeriod p,
      {int limit = 10}) async {
    final db = await _db;
    final range = _rangeFor(p);

    // Join invoice lines with payment header via sale_invoice_id (TEXT)
    final rows = await db.rawQuery(
      '''
      SELECT i.id AS item_id,
             i.name AS name,
             IFNULL(SUM(iv.quantity), 0) AS sold,
             MAX(iv.unit_saled_price) AS price
      FROM invoice iv
      JOIN item i       ON i.id = iv.item_id
      JOIN payment pay  ON pay.sale_invoice_id = iv.sale_invoice_id
      WHERE pay.date BETWEEN ? AND ?
      GROUP BY i.id, i.name
      ORDER BY sold DESC
      LIMIT ?
      ''',
      [range.startMs, range.endMs, limit],
    );

    return rows.map((r) {
       final sold = ((r['sold'] as num?) ?? 0).toInt();          
       final price = (r['price'] as num?)?.toDouble(); 
          
      return TopItemSummary(
        itemId: (r['item_id'] as int),
        name: (r['name'] as String),
        sold: sold,
        price: price,
      );
    }).toList();
  }

  // ---------- Sales series (for the line chart) ----------
  Future<ChartSeries> salesSeries(InsightPeriod p) async {
    final db = await _db;
    final rng = _rangeFor(p);

    // Different bucketings for the four periods
    late final String bucketSql; // column alias "k"
    late final List<String> labels;
    late final Map<String, int> indexOfKey;

    switch (p) {
      case InsightPeriod.today:
        bucketSql =
            "strftime('%H', datetime(pay.date/1000, 'unixepoch', 'localtime'))";
        labels = List<String>.generate(24, (h) => h.toString().padLeft(2, '0'));
        indexOfKey = {for (var i = 0; i < labels.length; i++) labels[i]: i};
        break;

      case InsightPeriod.week:
        // Key per day (YYYY-MM-DD). Labels Mon..Sun (starting Monday).
        bucketSql =
            "strftime('%Y-%m-%d', datetime(pay.date/1000, 'unixepoch', 'localtime'))";
        final start = DateTime.fromMillisecondsSinceEpoch(rng.startMs);
        labels = List<String>.generate(7, (i) {
          final d = start.add(Duration(days: i));
          return DateFormat('EEE').format(d); // Mon, Tue, …
        });
        // Map actual key (yyyy-mm-dd) to position 0..6
        final dateKeys = List<String>.generate(7, (i) {
          final d = start.add(Duration(days: i));
          return DateFormat('yyyy-MM-dd').format(d);
        });
        indexOfKey = {for (var i = 0; i < dateKeys.length; i++) dateKeys[i]: i};
        break;

      case InsightPeriod.month:
        bucketSql =
            "strftime('%Y-%m-%d', datetime(pay.date/1000, 'unixepoch', 'localtime'))";
        final start = DateTime.fromMillisecondsSinceEpoch(rng.startMs);
        final daysInMonth = DateTime(start.year, start.month + 1, 0).day;
        labels = List<String>.generate(daysInMonth, (i) => '${i + 1}');
        final dateKeys = List<String>.generate(daysInMonth, (i) {
          final d = DateTime(start.year, start.month, i + 1);
          return DateFormat('yyyy-MM-dd').format(d);
        });
        indexOfKey = {for (var i = 0; i < dateKeys.length; i++) dateKeys[i]: i};
        break;

      case InsightPeriod.year:
        bucketSql =
            "strftime('%m', datetime(pay.date/1000, 'unixepoch', 'localtime'))";
        labels = List<String>.generate(12, (i) => DateFormat('MMM').format(DateTime(2000, i + 1, 1)));
        indexOfKey = {
          for (var i = 0; i < 12; i++) (i + 1).toString().padLeft(2, '0'): i
        };
        break;
    }

    // Query per bucket
    final rows = await db.rawQuery(
      '''
      SELECT $bucketSql AS k, IFNULL(SUM(pay.amount),0) AS t
      FROM payment pay
      WHERE pay.date BETWEEN ? AND ?
      GROUP BY k
      ORDER BY k
      ''',
      [rng.startMs, rng.endMs],
    );

    // Fill series with zeros, then place sums into the right bucket index
    final values = List<double>.filled(labels.length, 0.0);
    for (final r in rows) {
      final k = r['k'] as String?;
      if (k == null) continue;
      final idx = indexOfKey[k];
      if (idx == null) {
        // today/week/month cases where label != key (e.g., 'Mon' vs '2025-09-15')
        // try to map hour buckets directly
        if (p == InsightPeriod.today && RegExp(r'^\d\d$').hasMatch(k)) {
          final h = int.tryParse(k) ?? -1;
          if (h >= 0 && h < values.length) {
            values[h] = _asDouble(r['t']);
          }
        }
        continue;
      }
      values[idx] = _asDouble(r['t']);
    }

    return ChartSeries(labels: labels, values: values, yUnit: 'Rs.');
  }

  // ---------- Helpers ----------
  double _asDouble(Object? x) {
    if (x == null) return 0.0;
    if (x is int) return x.toDouble();
    if (x is double) return x;
    return double.tryParse(x.toString()) ?? 0.0;
  }

  _Range _rangeFor(InsightPeriod p) {
    final now = DateTime.now();
    final today0 = DateTime(now.year, now.month, now.day);
    late DateTime start;
    late DateTime end;

    switch (p) {
      case InsightPeriod.today:
        start = today0;
        end = today0.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
        break;
      case InsightPeriod.week:
        final monday = today0.subtract(Duration(days: (today0.weekday - 1) % 7));
        start = monday;
        end = monday.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));
        break;
      case InsightPeriod.month:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));
        break;
      case InsightPeriod.year:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year + 1, 1, 1).subtract(const Duration(milliseconds: 1));
        break;
    }
    return _Range(start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
  }
}

class _Range {
  final int startMs;
  final int endMs;
  const _Range(this.startMs,this.endMs);
}

