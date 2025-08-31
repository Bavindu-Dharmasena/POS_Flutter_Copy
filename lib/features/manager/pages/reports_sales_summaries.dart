import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SalesSummariesReportPage extends StatefulWidget {
  const SalesSummariesReportPage({super.key});

  @override
  State<SalesSummariesReportPage> createState() =>
      _SalesSummariesReportPageState();
}

class _SalesSummariesReportPageState extends State<SalesSummariesReportPage>
    with TickerProviderStateMixin {
  // ---------------- UI State ----------------
  String _period = 'Day';
  DateTime _anchor = DateTime.now();
  String _store = 'All Stores';
  final Set<String> _paymentFilters = {};
  String _query = '';
  bool _isFilterExpanded = false;

  // Animation controllers for smooth transitions
  late AnimationController _filterAnimationController;
  late AnimationController _chartAnimationController;
  late Animation<double> _filterAnimation;
  late Animation<double> _chartAnimation;

  // data state
  bool _loading = false;
  String? _error;
  List<SalesRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.elasticOut,
    );
    _load();
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    _chartAnimationController.reset();

    try {
      final repo = FakeSalesRepository(seed: 42);
      final fromTo = _periodRange(_anchor, _period);
      final all = await repo.fetch(fromTo.$1, fromTo.$2);

      final filtered = all.where((r) {
        if (_store != 'All Stores' && r.store != _store) return false;
        if (_paymentFilters.isNotEmpty &&
            !_paymentFilters.contains(r.paymentMethod)) {
          return false;
        }
        if (_query.isNotEmpty &&
            !r.orderId.toLowerCase().contains(_query.toLowerCase())) {
          return false;
        }
        return true;
      }).toList();

      setState(() {
        _records = filtered;
      });

      // Animate chart after data loads
      _chartAnimationController.forward();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  (DateTime, DateTime) _periodRange(DateTime anchor, String period) {
    if (period == 'Day') {
      final start = DateTime(anchor.year, anchor.month, anchor.day);
      final end = start.add(const Duration(days: 1));
      return (start, end);
    } else if (period == 'Month') {
      final start = DateTime(anchor.year, anchor.month);
      final end = DateTime(anchor.year, anchor.month + 1);
      return (start, end);
    } else {
      final start = DateTime(anchor.year);
      final end = DateTime(anchor.year + 1);
      return (start, end);
    }
  }

  Future<void> _pickAnchor() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _anchor,
      firstDate: DateTime(2018),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: _period == 'Day'
          ? 'Pick Day'
          : _period == 'Month'
              ? 'Pick Any Day Within Month'
              : 'Pick Any Day Within Year',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Colors.blue,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      if (_period == 'Day') {
        _anchor = picked;
      } else if (_period == 'Month') {
        _anchor = DateTime(picked.year, picked.month, 1);
      } else {
        _anchor = DateTime(picked.year, 1, 1);
      }
    });
    _load();
  }

  String get _anchorLabel {
    if (_period == 'Day') {
      return _anchor.toString().split(' ').first;
    } else if (_period == 'Month') {
      return '${_monthName(_anchor.month)} ${_anchor.year}';
    } else {
      return _anchor.year.toString();
    }
  }

  double get _totalSales =>
      _records.fold(0.0, (sum, r) => sum + r.amount.toDouble());
  int get _orders => _records.length;
  double get _avgTicket => _orders == 0 ? 0 : _totalSales / _orders;

  Map<String, double> get _grouped {
    final map = <String, double>{};
    for (final r in _records) {
      late String k;
      if (_period == 'Day') {
        k = '${r.timestamp.hour.toString().padLeft(2, '0')}:00';
      } else if (_period == 'Month') {
        k = r.timestamp.day.toString().padLeft(2, '0');
      } else {
        k = _monthName(r.timestamp.month).substring(0, 3);
      }
      map[k] = (map[k] ?? 0) + r.amount.toDouble();
    }

    final ordered = Map<String, double>.fromEntries(
      map.entries.toList()
        ..sort((a, b) {
          int parseHourDay(String s) =>
              int.tryParse(s.replaceAll(':00', '')) ?? 0;
          if (_period == 'Day') {
            return parseHourDay(a.key).compareTo(parseHourDay(b.key));
          } else if (_period == 'Month') {
            return (int.tryParse(a.key) ?? 0)
                .compareTo(int.tryParse(b.key) ?? 0);
          } else {
            const idx = [
              'Jan',
              'Feb',
              'Mar',
              'Apr',
              'May',
              'Jun',
              'Jul',
              'Aug',
              'Sep',
              'Oct',
              'Nov',
              'Dec'
            ];
            return idx.indexOf(a.key).compareTo(idx.indexOf(b.key));
          }
        }),
    );
    return ordered;
  }

  String _toCsv() {
    final buf = StringBuffer()..writeln('Order ID,DateTime,Store,Payment,Amount');
    for (final r in _records) {
      buf.writeln(
          '${r.orderId},${r.timestamp.toIso8601String()},${r.store},${r.paymentMethod},${r.amount.toStringAsFixed(2)}');
    }
    return buf.toString();
  }

  Future<void> _copyCsv() async {
    final csv = _toCsv();
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('CSV copied to clipboard'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1200;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Sales Analytics',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: !isMobile,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: AnimatedRotation(
              turns: _loading ? 1 : 0,
              duration: const Duration(milliseconds: 1000),
              child: const Icon(Icons.refresh),
            ),
          ),
          IconButton(
            tooltip: 'Export CSV',
            onPressed: _records.isEmpty ? null : _copyCsv,
            icon: const Icon(Icons.file_download),
          ),
          if (isMobile)
            IconButton(
              tooltip: 'Filters',
              onPressed: () {
                setState(() {
                  _isFilterExpanded = !_isFilterExpanded;
                  if (_isFilterExpanded) {
                    _filterAnimationController.forward();
                  } else {
                    _filterAnimationController.reverse();
                  }
                });
              },
              icon: AnimatedRotation(
                turns: _isFilterExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(Icons.tune),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Filters Section
              if (isMobile)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _isFilterExpanded ? null : 0,
                  child: AnimatedBuilder(
                    animation: _filterAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _filterAnimation.value,
                        child: Opacity(
                          opacity: _filterAnimation.value,
                          child: _buildFilters(isMobile, isTablet),
                        ),
                      );
                    },
                  ),
                )
              else
                _buildFilters(isMobile, isTablet),

              SizedBox(height: isMobile ? 12 : 16),

              // Loading indicator
              if (_loading)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),

              // Error or KPIs
              if (_error != null)
                _ErrorBox(message: _error!, onRetry: _load)
              else
                _buildKpiSection(isMobile, isTablet, isDesktop),

              SizedBox(height: isMobile ? 12 : 16),

              // Chart and Table Section
              _buildDataVisualization(isMobile, isTablet, isDesktop),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(bool isMobile, bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Period selector - always on top on mobile
          _PeriodSegmented(
            value: _period,
            onChanged: (v) {
              setState(() {
                _period = v;
                if (v == 'Day') {
                  _anchor = DateTime(_anchor.year, _anchor.month, _anchor.day);
                } else if (v == 'Month') {
                  _anchor = DateTime(_anchor.year, _anchor.month, 1);
                } else {
                  _anchor = DateTime(_anchor.year, 1, 1);
                }
              });
              _load();
            },
          ),

          const SizedBox(height: 12),

          // Other filters in responsive layout
          if (isMobile)
            Column(
              children: [
                _buildMobileFilterRow(),
                const SizedBox(height: 12),
                _PaymentChips(
                  selected: _paymentFilters,
                  onChanged: (set) {
                    setState(() {
                      _paymentFilters
                        ..clear()
                        ..addAll(set);
                    });
                    _load();
                  },
                ),
                const SizedBox(height: 12),
                _buildSearchField(),
              ],
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _FilterPill(
                  icon: Icons.event,
                  label: _anchorLabel,
                  onTap: _pickAnchor,
                ),
                _StoreDropdown(
                  value: _store,
                  onChanged: (v) {
                    setState(() => _store = v);
                    _load();
                  },
                ),
                _PaymentChips(
                  selected: _paymentFilters,
                  onChanged: (set) {
                    setState(() {
                      _paymentFilters
                        ..clear()
                        ..addAll(set);
                    });
                    _load();
                  },
                ),
                _buildSearchField(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMobileFilterRow() {
    return Row(
      children: [
        Expanded(
          child: _FilterPill(
            icon: Icons.event,
            label: _anchorLabel,
            onTap: _pickAnchor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StoreDropdown(
            value: _store,
            onChanged: (v) {
              setState(() => _store = v);
              _load();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      width: MediaQuery.of(context).size.width < 768 ? double.infinity : 240,
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, size: 20),
          hintText: 'Search order ID...',
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blue),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        onChanged: (v) {
          _query = v;
          _load();
        },
      ),
    );
  }

  Widget _buildKpiSection(bool isMobile, bool isTablet, bool isDesktop) {
    return _KpiRow(
      total: _totalSales,
      orders: _orders,
      avg: _avgTicket,
      isMobile: isMobile,
      isTablet: isTablet,
    );
  }

  Widget _buildDataVisualization(bool isMobile, bool isTablet, bool isDesktop) {
    if (_loading) {
      return SizedBox(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading data...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (_records.isEmpty) {
      return const _EmptyState();
    }

    if (isMobile) {
      return Column(
        children: [
          SizedBox(
            height: 280,
            child: AnimatedBuilder(
              animation: _chartAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _chartAnimation.value,
                  child: _BarChart(grouped: _grouped),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _GroupedTable(
            grouped: _grouped,
            grandTotal: _totalSales,
            isMobile: true,
          ),
        ],
      );
    }

    return SizedBox(
      height: 500,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: isDesktop ? 5 : 1,
            child: AnimatedBuilder(
              animation: _chartAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _chartAnimation.value,
                  child: _BarChart(grouped: _grouped),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: isDesktop ? 4 : 1,
            child: _GroupedTable(
              grouped: _grouped,
              grandTotal: _totalSales,
              isMobile: false,
            ),
          ),
        ],
      ),
    );
  }
}

String _monthName(int m) =>
    const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ][m - 1];

// ================== Enhanced Widgets ==================

class _PeriodSegmented extends StatelessWidget {
  const _PeriodSegmented({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[100],
      ),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(
            value: 'Day',
            label: Text('Day', style: TextStyle(fontSize: 13)),
            icon: Icon(Icons.today, size: 18),
          ),
          ButtonSegment(
            value: 'Month',
            label: Text('Month', style: TextStyle(fontSize: 13)),
            icon: Icon(Icons.date_range, size: 18),
          ),
          ButtonSegment(
            value: 'Year',
            label: Text('Year', style: TextStyle(fontSize: 13)),
            icon: Icon(Icons.event, size: 18),
          ),
        ],
        selected: {value},
        showSelectedIcon: false,
        onSelectionChanged: (s) => onChanged(s.first),
        style: SegmentedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.grey[700],
          selectedBackgroundColor: Colors.white,
          selectedForegroundColor: Colors.blue,
          side: BorderSide.none,
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.blue[50],
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreDropdown extends StatelessWidget {
  const _StoreDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const stores = <String>[
      'All Stores',
      'Downtown',
      'Airport',
      'Mall',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: (v) => onChanged(v!),
          items: stores
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s, style: const TextStyle(fontSize: 14)),
                  ))
              .toList(),
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
        ),
      ),
    );
  }
}

class _PaymentChips extends StatefulWidget {
  const _PaymentChips({required this.selected, required this.onChanged});

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  State<_PaymentChips> createState() => _PaymentChipsState();
}

class _PaymentChipsState extends State<_PaymentChips> {
  static const methods = ['Cash', 'Card', 'Online'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: methods.map((m) {
        final isSel = widget.selected.contains(m);
        return FilterChip(
          label: Text(m, style: const TextStyle(fontSize: 12)),
          selected: isSel,
          onSelected: (s) {
            final next = {...widget.selected};
            if (s) {
              next.add(m);
            } else {
              next.remove(m);
            }
            widget.onChanged(next);
          },
          backgroundColor: Colors.grey[100],
          selectedColor: Colors.blue[100],
          checkmarkColor: Colors.blue[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSel ? Colors.blue[300]! : Colors.grey[300]!,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.total,
    required this.orders,
    required this.avg,
    required this.isMobile,
    required this.isTablet,
  });

  final double total;
  final int orders;
  final double avg;
  final bool isMobile;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiCard(
        title: 'Total Sales',
        value: _money(total),
        icon: Icons.attach_money,
        color: Colors.green,
      ),
      _KpiCard(
        title: 'Orders',
        value: orders.toString(),
        icon: Icons.receipt_long,
        color: Colors.blue,
      ),
      _KpiCard(
        title: 'Avg Ticket',
        value: _money(avg),
        icon: Icons.show_chart,
        color: Colors.orange,
      ),
    ];

    if (isMobile) {
      return Column(
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: item,
                ))
            .toList(),
      );
    }

    return Row(
      children: items
          .map((item) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: item,
                ),
              ))
          .toList(),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.grouped});
  final Map<String, double> grouped;

  @override
  Widget build(BuildContext context) {
    if (grouped.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(child: Text('No data available')),
      );
    }

    final maxVal = grouped.values.fold<double>(0, max);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(Icons.bar_chart, color: Colors.blue[700], size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sales Overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth = max(
                      20.0, constraints.maxWidth / (grouped.length * 2));
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width:
                          max(constraints.maxWidth, grouped.length * (barWidth + 16)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: grouped.entries.map((e) {
                          final h = maxVal == 0
                              ? 0
                              : (e.value / maxVal) *
                                  (constraints.maxHeight - 60);
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Tooltip(
                                message: '${e.key}: ${_money(e.value)}',
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 800),
                                  curve: Curves.easeOutCubic,
                                  width: barWidth,
                                  height: h.toDouble(),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.blue.shade600,
                                        Colors.blue.shade300,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: barWidth + 6,
                                child: Text(
                                  e.key,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupedTable extends StatelessWidget {
  const _GroupedTable({
    required this.grouped,
    required this.grandTotal,
    required this.isMobile,
  });

  final Map<String, double> grouped;
  final double grandTotal;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final rows = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    Widget buildRow(String label, double value, {bool bold = false}) {
      final pct = grandTotal == 0 ? 0 : (value / grandTotal) * 100;
      final textStyle = TextStyle(
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        color: bold ? Colors.black87 : Colors.black87,
        fontSize: 13,
      );
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: textStyle),
            ),
            SizedBox(
              width: 100,
              child: Text(
                _money(value),
                textAlign: TextAlign.right,
                style: textStyle,
              ),
            ),
            SizedBox(
              width: 70,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('${pct.toStringAsFixed(1)}%',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.blue)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.store, color: Colors.green[700], size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sales Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                )
              ],
            ),
          ),
          // head row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: const [
                Expanded(
                  child: Text('Bucket',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ),
                SizedBox(
                    width: 100,
                    child: Text('Amount',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12))),
                SizedBox(
                    width: 70,
                    child: Align(
                        alignment: Alignment.centerRight,
                        child: Text('Share',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12)))),
              ],
            ),
          ),
          // rows
          ...rows.map((e) => buildRow(e.key, e.value)),
          // total
          buildRow('Total', grandTotal, bold: true),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[900]),
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 6,
          )
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 44, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No records for the selected filters',
              style:
                  TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text('Try changing period, store, or payment method',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ================== Data Layer & Utilities ==================

String _money(double v) => '\$${v.toStringAsFixed(2)}';

class SalesRecord {
  const SalesRecord({
    required this.orderId,
    required this.timestamp,
    required this.store,
    required this.paymentMethod,
    required this.amount,
  });

  final String orderId;
  final DateTime timestamp;
  final String store;
  final String paymentMethod; // Cash, Card, Online
  final double amount;
}

class FakeSalesRepository {
  FakeSalesRepository({int seed = 1}) : _rng = Random(seed);

  final Random _rng;

  static const _stores = ['Downtown', 'Airport', 'Mall'];
  static const _payments = ['Cash', 'Card', 'Online'];

  Future<List<SalesRecord>> fetch(DateTime from, DateTime to) async {
    // simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final hours = to.difference(from).inHours.clamp(1, 24 * 365);
    final count = max(40, (hours * 1.2).toInt()); // scale with range

    return List.generate(count, (i) {
      final ts = from.add(Duration(
          minutes: _rng.nextInt(max(1, to.difference(from).inMinutes))));
      final store = _stores[_rng.nextInt(_stores.length)];
      final pay = _payments[_rng.nextInt(_payments.length)];
      final cents = (_rng.nextDouble() * 200) + 5; // $5 - $205
      final id = 'ORD-${ts.millisecondsSinceEpoch}-${_rng.nextInt(999)}';
      return SalesRecord(
        orderId: id,
        timestamp: ts,
        store: store,
        paymentMethod: pay,
        amount: double.parse(cents.toStringAsFixed(2)),
      );
    });
  }
}
