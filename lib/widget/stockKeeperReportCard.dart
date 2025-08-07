import 'package:flutter/material.dart';

// Constants for better maintainability
class AppConstants {
  static const primaryDark = Color(0xFF0B1623);
  static const cardPadding = EdgeInsets.all(20.0);
  static const gridSpacing = 16.0;
  static const borderRadius = 16.0;
  static const iconContainerRadius = 12.0;
  static const buttonBorderRadius = 8.0;
}

class StockKeeperReportCard extends StatelessWidget {
  final String reportId;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onViewTap;
  final VoidCallback onDownloadTap;
  final bool isDownloading;

  const StockKeeperReportCard({
    Key? key,
    required this.reportId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onViewTap,
    required this.onDownloadTap,
    required this.isDownloading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(
                      AppConstants.iconContainerRadius,
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: onViewTap,
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.18),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.buttonBorderRadius,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: isDownloading ? null : onDownloadTap,
                  icon: isDownloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.download, size: 18),
                  label: Text(isDownloading ? 'Downloading...' : 'Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.18),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.buttonBorderRadius,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}