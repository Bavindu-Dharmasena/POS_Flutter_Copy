// models/profit_margin.dart

class ProfitMargin {
  final int itemId;
  final String itemName;
  final String categoryName;
  final String supplierName;
  final double totalRevenue;
  final double totalCost;
  final double totalProfit;
  final double marginPercentage;
  final int quantitySold;
  final String? colorCode;
  final String? barcode;

  ProfitMargin({
    required this.itemId,
    required this.itemName,
    required this.categoryName,
    required this.supplierName,
    required this.totalRevenue,
    required this.totalCost,
    required this.totalProfit,
    required this.marginPercentage,
    required this.quantitySold,
    this.colorCode,
    this.barcode,
  });

  factory ProfitMargin.fromMap(Map<String, dynamic> map) {
    final revenue = (map['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final cost = (map['total_cost'] as num?)?.toDouble() ?? 0.0;
    final profit = revenue - cost;
    final marginPercentage = revenue > 0 ? (profit / revenue * 100) : 0.0;

    return ProfitMargin(
      itemId: map['item_id'] as int,
      itemName: map['item_name'] as String,
      categoryName: map['category_name'] as String,
      supplierName: map['supplier_name'] as String,
      totalRevenue: revenue,
      totalCost: cost,
      totalProfit: profit,
      marginPercentage: marginPercentage,
      quantitySold: map['quantity_sold'] as int,
      colorCode: map['color_code'] as String?,
      barcode: map['barcode'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item_id': itemId,
      'item_name': itemName,
      'category_name': categoryName,
      'supplier_name': supplierName,
      'total_revenue': totalRevenue,
      'total_cost': totalCost,
      'total_profit': totalProfit,
      'margin_percentage': marginPercentage,
      'quantity_sold': quantitySold,
      'color_code': colorCode,
      'barcode': barcode,
    };
  }
}

class ProfitMarginSummary {
  final double totalRevenue;
  final double totalCost;
  final double totalProfit;
  final double overallMarginPercentage;
  final int totalItemsSold;
  final int totalTransactions;

  ProfitMarginSummary({
    required this.totalRevenue,
    required this.totalCost,
    required this.totalProfit,
    required this.overallMarginPercentage,
    required this.totalItemsSold,
    required this.totalTransactions,
  });

  factory ProfitMarginSummary.fromMap(Map<String, dynamic> map) {
    final revenue = (map['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final cost = (map['total_cost'] as num?)?.toDouble() ?? 0.0;
    final profit = revenue - cost;
    final marginPercentage = revenue > 0 ? (profit / revenue * 100) : 0.0;

    return ProfitMarginSummary(
      totalRevenue: revenue,
      totalCost: cost,
      totalProfit: profit,
      overallMarginPercentage: marginPercentage,
      totalItemsSold: map['total_items_sold'] as int,
      totalTransactions: map['total_transactions'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_revenue': totalRevenue,
      'total_cost': totalCost,
      'total_profit': totalProfit,
      'overall_margin_percentage': overallMarginPercentage,
      'total_items_sold': totalItemsSold,
      'total_transactions': totalTransactions,
    };
  }
}