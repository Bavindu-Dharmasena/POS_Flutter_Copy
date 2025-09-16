import 'package:sqflite/sqflite.dart';
import 'package:pos_system/data/db/database_helper.dart';
import 'package:pos_system/data/models/manager/reports/trending_item_report.dart';

/// Repository to read "Trending Items" analytics from SQLite.
class TrendingItemsRepository {
  TrendingItemsRepository._();
  static final TrendingItemsRepository instance = TrendingItemsRepository._();

  Future<List<TrendingItemReport>> fetch({
    required int fromMs,
    required int toMs,
    TrendingSortBy sortBy = TrendingSortBy.quantitySold,
    int limit = 50,
  }) async {
    final Database db = await DatabaseHelper.instance.database;

    final int period = toMs - fromMs;
    final int prevFrom = fromMs - period;
    final int prevTo = fromMs;

    // Choose ORDER BY field based on [sortBy]. For nullable fields we COALESCE
    // to very small values so items without data don't float to the top.
    final String orderExpr;
    switch (sortBy) {
      case TrendingSortBy.quantitySold:
        orderExpr = 'qty_sold DESC, revenue DESC';
        break;
      case TrendingSortBy.revenue:
        orderExpr = 'revenue DESC, qty_sold DESC';
        break;
      case TrendingSortBy.growthRate:
        orderExpr = 'COALESCE(growth_rate, -9999) DESC, revenue DESC';
        break;
      case TrendingSortBy.profitMargin:
        orderExpr = 'COALESCE(profit_margin, -9999) DESC, revenue DESC';
        break;
    }

    // Explanation:
    // cur:   aggregates current-period sales per item.
    //        - qty_sold: SUM(invoice.quantity)
    //        - revenue:  SUM(invoice.quantity * invoice.unit_saled_price)
    //        - gross_profit uses stock.unit_price via batch_id to estimate cost
    //          (one row per batch_id,item_id in your schema).
    //
    // prev:  aggregates previous-period revenue per item (for growth rate).
    //
    // Finally we compute:
    //   growth_rate   = (revenue - revenue_prev) / revenue_prev * 100
    //   profit_margin = gross_profit / revenue * 100
    //
    // We filter by payment.date to ensure invoices are picked by their sale date.

    const String sql = '''
WITH cur AS (
  SELECT it.id        AS item_id,
         it.name      AS name,
         COALESCE(cat.category, 'Uncategorized') AS category,
         SUM(inv.quantity)                             AS qty_sold,
         SUM(inv.quantity * inv.unit_saled_price)      AS revenue,
         SUM(inv.quantity * (inv.unit_saled_price - COALESCE(st.unit_price, 0))) AS gross_profit
  FROM invoice inv
  JOIN item it           ON it.id = inv.item_id
  LEFT JOIN category cat ON cat.id = it.category_id
  LEFT JOIN stock st     ON st.batch_id = inv.batch_id AND st.item_id = inv.item_id
  JOIN payment pay       ON pay.sale_invoice_id = inv.sale_invoice_id
  WHERE pay.date >= ? AND pay.date < ?
  GROUP BY it.id
),
prev AS (
  SELECT inv.item_id AS item_id,
         SUM(inv.quantity * inv.unit_saled_price) AS revenue_prev
  FROM invoice inv
  JOIN payment pay ON pay.sale_invoice_id = inv.sale_invoice_id
  WHERE pay.date >= ? AND pay.date < ?
  GROUP BY inv.item_id
)
SELECT
  c.item_id,
  c.name,
  c.category,
  COALESCE(c.qty_sold, 0) AS qty_sold,
  COALESCE(c.revenue, 0)  AS revenue,
  CASE
    WHEN p.revenue_prev IS NULL OR p.revenue_prev = 0 THEN NULL
    ELSE ( (c.revenue - p.revenue_prev) * 100.0 / p.revenue_prev )
  END AS growth_rate,
  CASE
    WHEN c.revenue IS NULL OR c.revenue = 0 THEN NULL
    ELSE ( c.gross_profit * 100.0 / c.revenue )
  END AS profit_margin
FROM cur c
LEFT JOIN prev p ON p.item_id = c.item_id
ORDER BY __ORDER_EXPR__
LIMIT ?;
''';

    final rows = await db.rawQuery(
      sql.replaceFirst('__ORDER_EXPR__', orderExpr),
      [fromMs, toMs, prevFrom, prevTo, limit],
    );

    // Build models & assign rank by current order.
    final List<TrendingItemReport> out = [];
    for (int i = 0; i < rows.length; i++) {
      out.add(TrendingItemReport.fromSql(rows[i], rank: i + 1));
    }
    return out;
  }
}
