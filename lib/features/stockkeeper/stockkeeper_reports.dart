import 'package:flutter/material.dart';

class StockKeeperReports extends StatelessWidget {
  const StockKeeperReports({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select report to view or print',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0B1623),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF0B1623),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 1;
                if (constraints.maxWidth > 900) {
                  crossAxisCount = 3;
                } else if (constraints.maxWidth > 600) {
                  crossAxisCount = 2;
                } else {
                  crossAxisCount = 1;
                }

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    _buildReportCardWithButtons(
                      context,
                      title: 'Daily Report',
                      subtitle: 'View today\'s sales & transactions',
                      icon: Icons.today_outlined,
                      gradientColors: [
                        const Color(0xFF1e3c72),
                        const Color(0xFF2a5298),
                      ], // Deep Navy Blue
                      onViewTap: () {
                        // Handle view daily report tap
                      },
                      onDownloadTap: () {
                        // Handle download daily report tap
                      },
                    ),
                    _buildReportCardWithButtons(
                      context,
                      title: 'Weekly Report',
                      subtitle: 'Analyze weekly performance',
                      icon: Icons.view_week_outlined,
                      gradientColors: [
                        const Color(0xFF134e5e),
                        const Color(0xFF71b280),
                      ], // Dark Teal to Forest Green
                      onViewTap: () {
                        // Handle view weekly report tap
                      },
                      onDownloadTap: () {
                        // Handle download weekly report tap
                      },
                    ),
                    _buildReportCardWithButtons(
                      context,
                      title: 'Monthly Report',
                      subtitle: 'Monthly business insights',
                      icon: Icons.calendar_month_outlined,
                      gradientColors: [
                        const Color(0xFF8B4513),
                        const Color(0xFFD2691E),
                      ], // Dark Brown to Bronze
                      onViewTap: () {
                        // Handle view monthly report tap
                      },
                      onDownloadTap: () {
                        // Handle download monthly report tap
                      },
                    ),
                    _buildReportCardWithButtons(
                      context,
                      title: 'Sales Report',
                      subtitle: 'Detailed sales analytics',
                      icon: Icons.trending_up_outlined,
                      gradientColors: [
                        const Color(0xFF2C5364),
                        const Color(0xFF203A43),
                      ], // Dark Slate Blue
                      onViewTap: () {
                        // Handle view sales report tap
                      },
                      onDownloadTap: () {
                        // Handle download sales report tap
                      },
                    ),
                    _buildReportCardWithButtons(
                      context,
                      title: 'Inventory Report',
                      subtitle: 'Stock levels & movements',
                      icon: Icons.inventory_2_outlined,
                      gradientColors: [
                        const Color(0xFF4B0082),
                        const Color(0xFF8B008B),
                      ], // Deep Purple to Dark Magenta
                      onViewTap: () {
                        // Handle view inventory report tap
                      },
                      onDownloadTap: () {
                        // Handle download inventory report tap
                      },
                    ),
                    _buildReportCardWithButtons(
                      context,
                      title: 'Profit Report',
                      subtitle: 'Profit margins & analysis',
                      icon: Icons.account_balance_wallet_outlined,
                      gradientColors: [
                        const Color(0xFF1a252f),
                        const Color(0xFF2b5876),
                      ], // Midnight Blue to Steel Blue
                      onViewTap: () {
                        // Handle view profit report tap
                      },
                      onDownloadTap: () {
                        // Handle download profit report tap
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportCardWithButtons(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onViewTap,
    required VoidCallback onDownloadTap,
  }) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.4),
              offset: const Offset(0, 8),
              blurRadius: 16,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 6,
              spreadRadius: 0,
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 24, color: Colors.white),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onViewTap,
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.15),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onDownloadTap,
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Download'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gradientColors[1].withOpacity(0.8),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
