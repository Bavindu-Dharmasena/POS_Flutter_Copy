import 'package:flutter/material.dart';

class ReportCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onFiltersTap;

  const ReportCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.colors,
    required this.onFiltersTap,
  }) : super(key: key);

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  bool _isDownloading = false;

  void _handleDownload() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    // Simulate download delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isDownloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.title} downloaded successfully!'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
      ),
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: widget.colors.first.withOpacity(0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: widget.colors.first.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
            hoverColor: widget.colors.first.withOpacity(0.04),
            splashColor: widget.colors.first.withOpacity(0.12),
            onTap: widget.onFiltersTap,
            child: Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isMobile),
                  const Spacer(),
                  _buildActionButtons(isMobile),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(isMobile),
              const SizedBox(height: 12),
              _buildTitleAndSubtitle(),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(isMobile),
              const SizedBox(width: 16),
              Expanded(child: _buildTitleAndSubtitle()),
            ],
          );
  }

  Widget _buildIcon(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.colors.first.withOpacity(0.12),
            widget.colors.last.withOpacity(0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        border: Border.all(color: widget.colors.first.withOpacity(0.25), width: 1),
      ),
      child: Icon(widget.icon, color: widget.colors.first, size: isMobile ? 24 : 26),
    );
  }

  Widget _buildTitleAndSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        const Text(
          'Generate detailed analytics',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isMobile) {
    return isMobile
        ? Column(
            children: [
              _buildButton(
                onTap: widget.onFiltersTap,
                label: 'Filters',
                icon: Icons.tune_rounded,
                isPrimary: false,
                isMobile: true,
              ),
              const SizedBox(height: 8),
              _buildButton(
                onTap: _handleDownload,
                label: _isDownloading ? 'Getting...' : 'Export',
                icon: _isDownloading ? null : Icons.download_rounded,
                isPrimary: true,
                isMobile: true,
                child: _isDownloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : null,
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: _buildButton(
                  onTap: widget.onFiltersTap,
                  label: 'Filters',
                  icon: Icons.tune_rounded,
                  isPrimary: false,
                  isMobile: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildButton(
                  onTap: _handleDownload,
                  label: _isDownloading ? 'Getting...' : 'Export',
                  icon: _isDownloading ? null : Icons.download_rounded,
                  isPrimary: true,
                  isMobile: false,
                  child: _isDownloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : null,
                ),
              ),
            ],
          );
  }

  Widget _buildButton({
    required VoidCallback onTap,
    required String label,
    IconData? icon,
    required bool isPrimary,
    required bool isMobile,
    Widget? child,
  }) {
    final textColor = isPrimary ? Colors.white : const Color(0xFF475569);
    final buttonGradient = isPrimary
        ? LinearGradient(
            colors: [widget.colors.first, widget.colors.last],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    return SizedBox(
      width: isMobile ? double.infinity : null,
      height: isMobile ? 36 : 40,
      child: Container(
        decoration: BoxDecoration(
          gradient: buttonGradient,
          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
          border: isPrimary ? null : Border.all(color: const Color(0xFFCBD5E1), width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
            onTap: _isDownloading ? null : onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (child != null)
                  child
                else if (icon != null)
                  Icon(icon, size: isMobile ? 16 : 18, color: textColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}