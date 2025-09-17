import 'package:flutter/foundation.dart';

/// Sort keys to match your UI options.
enum TrendingSortBy { quantitySold, revenue, growthRate, profitMargin }

TrendingSortBy sortByFromLabel(String label) {
  switch (label) {
    case 'Quantity Sold':
      return TrendingSortBy.quantitySold;
    case 'Revenue':
      return TrendingSortBy.revenue;
    case 'Growth Rate':
      return TrendingSortBy.growthRate;
    case 'Profit Margin':
      return TrendingSortBy.profitMargin;
    default:
      return TrendingSortBy.quantitySold;
  }
}

/// A single row in the Trending Items report.
@immutable
class TrendingItemReport {
  final int itemId;
  final String name;
  final String category;
  final int quantitySold;      // in selected period
  final double revenue;        // in selected period
  final double? growthRate;    // % vs previous equal-length period (revenue-based)
  final double? profitMargin;  // % gross margin in selected period
  final int rank;              // computed client-side after sorting, starting at 1

  const TrendingItemReport({
    required this.itemId,
    required this.name,
    required this.category,
    required this.quantitySold,
    required this.revenue,
    required this.growthRate,
    required this.profitMargin,
    required this.rank,
  });

  TrendingItemReport copyWith({int? rank}) => TrendingItemReport(
        itemId: itemId,
        name: name,
        category: category,
        quantitySold: quantitySold,
        revenue: revenue,
        growthRate: growthRate,
        profitMargin: profitMargin,
        rank: rank ?? this.rank,
      );

  factory TrendingItemReport.fromSql(Map<String, Object?> m, {required int rank}) {
    double? _d(Object? v) => (v == null) ? null : (v as num).toDouble();
    return TrendingItemReport(
      itemId: (m['item_id'] as num).toInt(),
      name: (m['name'] as String?) ?? 'Item',
      category: (m['category'] as String?) ?? 'Uncategorized',
      quantitySold: ((m['qty_sold'] ?? 0) as num).toInt(),
      revenue: ((m['revenue'] ?? 0) as num).toDouble(),
      growthRate: _d(m['growth_rate']),
      profitMargin: _d(m['profit_margin']),
      rank: rank,
    );
  }
}
