class TopItemSummary {
  final int itemId;
  final String name;
  final double? price;  // optional, null if not available
  final int sold;
  const TopItemSummary({
    required this.itemId,
    required this.name,
    required this.sold,
    this.price,
  });
}
