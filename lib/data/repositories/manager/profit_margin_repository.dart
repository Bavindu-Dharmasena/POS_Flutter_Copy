
import 'package:pos_system/data/db/database_helper.dart';
import 'package:pos_system/data/models/manager/profit_margin.dart';

class ProfitMarginRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get profit margins for all items with optional filters
  Future<List<ProfitMargin>> getProfitMargins({
    String period = 'all', // 'day', 'month', 'year', 'all'
    String paymentMethod = 'all', // 'cash', 'card', 'all'
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;
    
    String dateFilter = _buildDateFilter(period, startDate, endDate);
    String paymentFilter = _buildPaymentFilter(paymentMethod);
    
    final query = '''
      SELECT 
        i.id as item_id,
        i.name as item_name,
        i.barcode,
        i.color_code,
        c.category as category_name,
        s.name as supplier_name,
        COALESCE(SUM(inv.quantity * inv.unit_saled_price), 0) as total_revenue,
        COALESCE(SUM(inv.quantity * st.unit_price), 0) as total_cost,
        COALESCE(SUM(inv.quantity), 0) as quantity_sold
      FROM item i
      LEFT JOIN category c ON i.category_id = c.id
      LEFT JOIN supplier s ON i.supplier_id = s.id
      LEFT JOIN invoice inv ON i.id = inv.item_id
      LEFT JOIN payment p ON inv.sale_invoice_id = p.sale_invoice_id
      LEFT JOIN stock st ON inv.batch_id = st.batch_id AND inv.item_id = st.item_id
      WHERE 1=1 
        $dateFilter
        $paymentFilter
      GROUP BY i.id, i.name, i.barcode, i.color_code, c.category, s.name
      HAVING quantity_sold > 0
      ORDER BY total_revenue DESC
    ''';

    final result = await db.rawQuery(query);
    return result.map((map) => ProfitMargin.fromMap(map)).toList();
  }

  // Get profit margins for a specific category
  Future<List<ProfitMargin>> getProfitMarginsByCategory(
    int categoryId, {
    String period = 'all',
    String paymentMethod = 'all',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;
    
    String dateFilter = _buildDateFilter(period, startDate, endDate);
    String paymentFilter = _buildPaymentFilter(paymentMethod);
    
    final query = '''
      SELECT 
        i.id as item_id,
        i.name as item_name,
        i.barcode,
        i.color_code,
        c.category as category_name,
        s.name as supplier_name,
        COALESCE(SUM(inv.quantity * inv.unit_saled_price), 0) as total_revenue,
        COALESCE(SUM(inv.quantity * st.unit_price), 0) as total_cost,
        COALESCE(SUM(inv.quantity), 0) as quantity_sold
      FROM item i
      LEFT JOIN category c ON i.category_id = c.id
      LEFT JOIN supplier s ON i.supplier_id = s.id
      LEFT JOIN invoice inv ON i.id = inv.item_id
      LEFT JOIN payment p ON inv.sale_invoice_id = p.sale_invoice_id
      LEFT JOIN stock st ON inv.batch_id = st.batch_id AND inv.item_id = st.item_id
      WHERE i.category_id = ? 
        $dateFilter
        $paymentFilter
      GROUP BY i.id, i.name, i.barcode, i.color_code, c.category, s.name
      HAVING quantity_sold > 0
      ORDER BY total_revenue DESC
    ''';

    final result = await db.rawQuery(query, [categoryId]);
    return result.map((map) => ProfitMargin.fromMap(map)).toList();
  }

  // Get profit margins for a specific supplier
  Future<List<ProfitMargin>> getProfitMarginsBySupplier(
    int supplierId, {
    String period = 'all',
    String paymentMethod = 'all',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;
    
    String dateFilter = _buildDateFilter(period, startDate, endDate);
    String paymentFilter = _buildPaymentFilter(paymentMethod);
    
    final query = '''
      SELECT 
        i.id as item_id,
        i.name as item_name,
        i.barcode,
        i.color_code,
        c.category as category_name,
        s.name as supplier_name,
        COALESCE(SUM(inv.quantity * inv.unit_saled_price), 0) as total_revenue,
        COALESCE(SUM(inv.quantity * st.unit_price), 0) as total_cost,
        COALESCE(SUM(inv.quantity), 0) as quantity_sold
      FROM item i
      LEFT JOIN category c ON i.category_id = c.id
      LEFT JOIN supplier s ON i.supplier_id = s.id
      LEFT JOIN invoice inv ON i.id = inv.item_id
      LEFT JOIN payment p ON inv.sale_invoice_id = p.sale_invoice_id
      LEFT JOIN stock st ON inv.batch_id = st.batch_id AND inv.item_id = st.item_id
      WHERE i.supplier_id = ? 
        $dateFilter
        $paymentFilter
      GROUP BY i.id, i.name, i.barcode, i.color_code, c.category, s.name
      HAVING quantity_sold > 0
      ORDER BY total_revenue DESC
    ''';

    final result = await db.rawQuery(query, [supplierId]);
    return result.map((map) => ProfitMargin.fromMap(map)).toList();
  }

  // Get overall profit margin summary
  Future<ProfitMarginSummary> getProfitMarginSummary({
    String period = 'all',
    String paymentMethod = 'all',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;
    
    String dateFilter = _buildDateFilter(period, startDate, endDate);
    String paymentFilter = _buildPaymentFilter(paymentMethod);
    
    final query = '''
      SELECT 
        COALESCE(SUM(inv.quantity * inv.unit_saled_price), 0) as total_revenue,
        COALESCE(SUM(inv.quantity * st.unit_price), 0) as total_cost,
        COALESCE(SUM(inv.quantity), 0) as total_items_sold,
        COUNT(DISTINCT p.sale_invoice_id) as total_transactions
      FROM invoice inv
      LEFT JOIN payment p ON inv.sale_invoice_id = p.sale_invoice_id
      LEFT JOIN stock st ON inv.batch_id = st.batch_id AND inv.item_id = st.item_id
      WHERE 1=1 
        $dateFilter
        $paymentFilter
    ''';

    final result = await db.rawQuery(query);
    if (result.isNotEmpty) {
      return ProfitMarginSummary.fromMap(result.first);
    }
    
    return ProfitMarginSummary(
      totalRevenue: 0,
      totalCost: 0,
      totalProfit: 0,
      overallMarginPercentage: 0,
      totalItemsSold: 0,
      totalTransactions: 0,
    );
  }

  // Get top performing items by profit margin
  Future<List<ProfitMargin>> getTopProfitMargins({
    int limit = 10,
    String period = 'all',
    String paymentMethod = 'all',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final margins = await getProfitMargins(
      period: period,
      paymentMethod: paymentMethod,
      startDate: startDate,
      endDate: endDate,
    );
    
    margins.sort((a, b) => b.marginPercentage.compareTo(a.marginPercentage));
    return margins.take(limit).toList();
  }

  // Get low performing items by profit margin
  Future<List<ProfitMargin>> getLowProfitMargins({
    int limit = 10,
    String period = 'all',
    String paymentMethod = 'all',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final margins = await getProfitMargins(
      period: period,
      paymentMethod: paymentMethod,
      startDate: startDate,
      endDate: endDate,
    );
    
    margins.sort((a, b) => a.marginPercentage.compareTo(b.marginPercentage));
    return margins.take(limit).toList();
  }

  // Helper methods for building query filters
  String _buildDateFilter(String period, DateTime? startDate, DateTime? endDate) {
    final now = DateTime.now();
    
    switch (period.toLowerCase()) {
      case 'day':
        final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;
        return 'AND p.date BETWEEN $todayStart AND $todayEnd';
        
      case 'month':
        final monthStart = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
        final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59).millisecondsSinceEpoch;
        return 'AND p.date BETWEEN $monthStart AND $monthEnd';
        
      case 'year':
        final yearStart = DateTime(now.year, 1, 1).millisecondsSinceEpoch;
        final yearEnd = DateTime(now.year, 12, 31, 23, 59, 59).millisecondsSinceEpoch;
        return 'AND p.date BETWEEN $yearStart AND $yearEnd';
        
      case 'custom':
        if (startDate != null && endDate != null) {
          final start = startDate.millisecondsSinceEpoch;
          final end = endDate.millisecondsSinceEpoch;
          return 'AND p.date BETWEEN $start AND $end';
        }
        return '';
        
      default:
        return '';
    }
  }

  String _buildPaymentFilter(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        return "AND LOWER(p.type) = 'cash'";
      case 'card':
        return "AND LOWER(p.type) = 'card'";
      default:
        return '';
    }
  }

  // Get profit margins grouped by category
  Future<Map<String, List<ProfitMargin>>> getProfitMarginsByCategories({
    String period = 'all',
    String paymentMethod = 'all',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final margins = await getProfitMargins(
      period: period,
      paymentMethod: paymentMethod,
      startDate: startDate,
      endDate: endDate,
    );
    
    final Map<String, List<ProfitMargin>> grouped = {};
    for (final margin in margins) {
      if (!grouped.containsKey(margin.categoryName)) {
        grouped[margin.categoryName] = [];
      }
      grouped[margin.categoryName]!.add(margin);
    }
    
    return grouped;
  }

  // Get category-wise profit summary
  Future<List<Map<String, dynamic>>> getCategoryProfitSummary({
    String period = 'all',
    String paymentMethod = 'all',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;
    
    String dateFilter = _buildDateFilter(period, startDate, endDate);
    String paymentFilter = _buildPaymentFilter(paymentMethod);
    
    final query = '''
      SELECT 
        c.category as category_name,
        c.color_code,
        COALESCE(SUM(inv.quantity * inv.unit_saled_price), 0) as total_revenue,
        COALESCE(SUM(inv.quantity * st.unit_price), 0) as total_cost,
        COALESCE(SUM(inv.quantity), 0) as quantity_sold,
        COUNT(DISTINCT i.id) as item_count
      FROM category c
      LEFT JOIN item i ON c.id = i.category_id
      LEFT JOIN invoice inv ON i.id = inv.item_id
      LEFT JOIN payment p ON inv.sale_invoice_id = p.sale_invoice_id
      LEFT JOIN stock st ON inv.batch_id = st.batch_id AND inv.item_id = st.item_id
      WHERE 1=1 
        $dateFilter
        $paymentFilter
      GROUP BY c.id, c.category, c.color_code
      HAVING quantity_sold > 0
      ORDER BY total_revenue DESC
    ''';

    final result = await db.rawQuery(query);
    return result.map((map) {
      final revenue = (map['total_revenue'] as num?)?.toDouble() ?? 0.0;
      final cost = (map['total_cost'] as num?)?.toDouble() ?? 0.0;
      final profit = revenue - cost;
      final marginPercentage = revenue > 0 ? (profit / revenue * 100) : 0.0;
      
      return {
        ...map,
        'total_profit': profit,
        'margin_percentage': marginPercentage,
      };
    }).toList();
  }
}