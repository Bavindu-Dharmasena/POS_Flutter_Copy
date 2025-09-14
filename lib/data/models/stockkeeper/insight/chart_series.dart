class ChartSeries {
  final List<String> labels;   // x-axis labels
  final List<double> values;   // y values (same length as labels)
  final String yUnit;          // e.g., 'Rs.'
  const ChartSeries({
    required this.labels,
    required this.values,
    required this.yUnit,
  });
}
