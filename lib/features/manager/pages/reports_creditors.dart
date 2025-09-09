import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreditorsReportPage extends StatefulWidget {
  const CreditorsReportPage({super.key});

  @override
  State<CreditorsReportPage> createState() => _CreditorsReportPageState();
}

class _CreditorsReportPageState extends State<CreditorsReportPage>
    with TickerProviderStateMixin {
  // ----------------------------- UI State -----------------------------
  String _tab = 'All'; // All | Overdue | Paid
  String _query = '';
  String _sort = 'Due Amount';
  bool _desc = true;
  RangeValues _amountRange = const RangeValues(0, 500000);
  DateTimeRange? _dateRange; // last invoice date range
  bool _showFilters = false;
  final Set<String> _selected = {};

  // ----------------------------- Data State -----------------------------
  late List<Creditor> _all;
  List<Creditor> _view = [];
  final bool _loading = false;
  String? _error;

  // Animations
  late AnimationController _filterAC;
  late Animation<double> _filterA;

  @override
  void initState() {
    super.initState();
    _filterAC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _filterA = CurvedAnimation(parent: _filterAC, curve: Curves.easeInOut);

    _seedData();
    _apply();
  }

  @override
  void dispose() {
    _filterAC.dispose();
    super.dispose();
  }

  // ----------------------------- Mock Data -----------------------------
  void _seedData() {
    final rng = Random(7);
    final now = DateTime.now();
    _all = List.generate(48, (i) {
      final daysAgo = rng.nextInt(120);
      final lastInvoice = now.subtract(Duration(days: daysAgo));
      final amount = (rng.nextDouble() * 500000).roundToDouble();
      final paid = rng.nextBool() && amount < 120000; // some paid
      final overdueDays = paid ? 0 : (rng.nextInt(90));
      return Creditor(
        id: 'CR${1000 + i}',
        name: _names[i % _names.length],
        company: _companies[i % _companies.length],
        phone: '+94 7${rng.nextInt(9)} ${rng.nextInt(900) + 100} ${rng.nextInt(900) + 100}',
        email: 'contact$i@example.com',
        lastInvoiceDate: lastInvoice,
        dueAmount: paid ? 0 : amount,
        paidAmount: paid ? amount : 0,
        overdueDays: paid ? 0 : overdueDays,
      );
    });
  }

  // ----------------------------- Filtering + Sorting -----------------------------
  void _apply() {
    List<Creditor> v = List.of(_all);

    // Tab filter
    if (_tab == 'Overdue') {
      v = v.where((c) => c.dueAmount > 0 && c.overdueDays > 0).toList();
    } else if (_tab == 'Paid') {
      v = v.where((c) => c.dueAmount == 0).toList();
    }

    // Search
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      v = v.where((c) =>
          c.name.toLowerCase().contains(q) ||
          c.company.toLowerCase().contains(q) ||
          c.id.toLowerCase().contains(q)).toList();
    }

    // Amount range
    v = v.where((c) => c.dueAmount >= _amountRange.start && c.dueAmount <= _amountRange.end).toList();

    // Date range (last invoice)
    if (_dateRange != null) {
      v = v.where((c) =>
          !c.lastInvoiceDate.isBefore(_dateRange!.start) &&
          !c.lastInvoiceDate.isAfter(_dateRange!.end)).toList();
    }

    // Sorting
    int cmp(Creditor a, Creditor b) {
      int r;
      switch (_sort) {
        case 'Name':
          r = a.name.compareTo(b.name);
          break;
        case 'Overdue Days':
          r = a.overdueDays.compareTo(b.overdueDays);
          break;
        case 'Last Invoice':
          r = a.lastInvoiceDate.compareTo(b.lastInvoiceDate);
          break;
        case 'Due Amount':
        default:
          r = a.dueAmount.compareTo(b.dueAmount);
      }
      return _desc ? -r : r;
    }
    v.sort(cmp);

    setState(() => _view = v);
  }

  // ----------------------------- Helpers -----------------------------
  String _money(num v) => NumberFormat.currency(locale: 'en_US', symbol: 'Rs ').format(v);
  String _date(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Color _badgeColor(int overdueDays) {
    if (overdueDays >= 60) return Colors.redAccent;
    if (overdueDays >= 30) return Colors.orangeAccent;
    if (overdueDays > 0) return Colors.amber;
    return Colors.green;
  }

  // ----------------------------- Bulk Actions -----------------------------
  void _markSelectedAsPaid() {
    setState(() {
      for (final id in _selected) {
        final i = _all.indexWhere((c) => c.id == id);
        if (i != -1) {
          final c = _all[i];
          _all[i] = c.copyWith(dueAmount: 0, overdueDays: 0, paidAmount: c.paidAmount + c.dueAmount);
        }
      }
      _selected.clear();
      _apply();
    });
    _snack('Marked selected as paid');
  }

  void _exportCsv() {
    final header = 'ID,Name,Company,Last Invoice,Due Amount,Overdue Days';
    final rows = _view.map((c) =>
        [c.id, c.name, c.company, _date(c.lastInvoiceDate), c.dueAmount.toStringAsFixed(2), c.overdueDays]
            .join(',')
    );
    final csv = ([header, ...rows]).join('\n');
    // TODO: write to file or share
    _snack('CSV generated (${csv.length} chars). Wire to File/Share.');
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );

  // ----------------------------- UI -----------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports • Creditors'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: _view.isEmpty ? null : _exportCsv,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1623), Color(0xFF0F2030)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildFilters(isDark),
              if (_selected.isNotEmpty) _buildBulkBar(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!))
                        : _view.isEmpty
                            ? _emptyState()
                            : _responsiveList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewCreditorDialog(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('New Creditor'),
      ),
    );
  }

  Widget _buildHeader() {
    final totalDue = _view.fold<double>(0, (s, c) => s + c.dueAmount);
    final overdueCount = _view.where((c) => c.overdueDays > 0 && c.dueAmount > 0).length;
    final paidCount = _view.where((c) => c.dueAmount == 0).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chipTab('All'),
              _chipTab('Overdue'),
              _chipTab('Paid'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _kpiCard('Total Due', _money(totalDue), Icons.account_balance_wallet_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _kpiCard('Overdue', '$overdueCount creditors', Icons.warning_amber_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _kpiCard('Paid', '$paidCount creditors', Icons.verified_outlined)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipTab(String label) {
    final selected = _tab == label;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() {
        _tab = label;
        _apply();
      }),
      selectedColor: Colors.blueGrey.shade700,
      backgroundColor: Colors.blueGrey.shade900,
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 8))],
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name, company or ID…',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white.withOpacity(isDark ? 0.06 : 0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                  ),
                  onChanged: (v) {
                    _query = v;
                    _apply();
                  },
                ),
              ),
              const SizedBox(width: 12),
              _sortMenu(),
              const SizedBox(width: 8),
              IconButton(
                tooltip: _desc ? 'Sort Desc' : 'Sort Asc',
                onPressed: () => setState(() {
                  _desc = !_desc;
                  _apply();
                }),
                icon: Icon(_desc ? Icons.south : Icons.north),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  _showFilters = !_showFilters;
                  if (_showFilters) {
                    _filterAC.forward();
                  } else {
                    _filterAC.reverse();
                  }
                  setState(() {});
                },
                icon: const Icon(Icons.tune),
                label: const Text('Filters'),
              ),
            ],
          ),
          SizeTransition(
            sizeFactor: _filterA,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _filtersPanel(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortMenu() {
    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: DropdownButton<String>(
          value: _sort,
          items: const [
            DropdownMenuItem(value: 'Due Amount', child: Text('Due Amount')),
            DropdownMenuItem(value: 'Name', child: Text('Name')),
            DropdownMenuItem(value: 'Overdue Days', child: Text('Overdue Days')),
            DropdownMenuItem(value: 'Last Invoice', child: Text('Last Invoice')),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _sort = v;
              _apply();
            });
          },
        ),
      ),
    );
  }

  Widget _filtersPanel(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Amount range', style: TextStyle(color: Colors.white70)),
                    RangeSlider(
                      values: _amountRange,
                      max: 500000,
                      divisions: 50,
                      labels: RangeLabels(
                        _money(_amountRange.start),
                        _money(_amountRange.end),
                      ),
                      onChanged: (v) => setState(() {
                        _amountRange = v;
                        _apply();
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Last invoice date', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final now = DateTime.now();
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(now.year - 2),
                                lastDate: DateTime(now.year + 1),
                                initialDateRange: _dateRange,
                              );
                              if (picked != null) {
                                setState(() {
                                  _dateRange = picked;
                                  _apply();
                                });
                              }
                            },
                            icon: const Icon(Icons.date_range),
                            label: Text(_dateRange == null
                                ? 'Pick range'
                                : '${_date(_dateRange!.start)} → ${_date(_dateRange!.end)}'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_dateRange != null)
                          IconButton(
                            tooltip: 'Clear',
                            onPressed: () => setState(() {
                              _dateRange = null;
                              _apply();
                            }),
                            icon: const Icon(Icons.close),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _amountRange = const RangeValues(0, 500000);
                    _dateRange = null;
                    _query = '';
                    _tab = 'All';
                    _sort = 'Due Amount';
                    _desc = true;
                    _selected.clear();
                    _apply();
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
              ),
              const SizedBox(width: 8),
              Text('${_view.length} results', style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBulkBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blueGrey.shade900,
      child: Row(
        children: [
          Text('${_selected.length} selected', style: const TextStyle(color: Colors.white)),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _markSelectedAsPaid,
            icon: const Icon(Icons.verified),
            label: const Text('Mark as Paid'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _selected.clear());
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Selection'),
          ),
        ],
      ),
    );
  }

  Widget _responsiveList() {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth > 900) {
          return _tableView();
        } else {
          return _cardList();
        }
      },
    );
  }

  // ----------------------------- Empty State -----------------------------
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.inbox, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            'No creditors found.',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ],
      ),
    );
  }

  // ----------------------------- Table (Desktop) -----------------------------
  Widget _tableView() {
    final hdrStyle = TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text('Select', style: hdrStyle)),
                DataColumn(label: Text('ID', style: hdrStyle)),
                DataColumn(label: Text('Name', style: hdrStyle)),
                DataColumn(label: Text('Company', style: hdrStyle)),
                DataColumn(label: Text('Last Invoice', style: hdrStyle)),
                DataColumn(label: Text('Due Amount', style: hdrStyle), numeric: true),
                DataColumn(label: Text('Overdue', style: hdrStyle)),
                DataColumn(label: Text('Actions', style: hdrStyle)),
              ],
              rows: _view.map((c) {
                final selected = _selected.contains(c.id);
                return DataRow(
                  selected: selected,
                  onSelectChanged: (_) {
                    setState(() {
                      if (selected) {
                        _selected.remove(c.id);
                      } else {
                        _selected.add(c.id);
                      }
                    });
                  },
                  cells: [
                    DataCell(Checkbox(
                      value: selected,
                      onChanged: (v) {
                        setState(() => v == true ? _selected.add(c.id) : _selected.remove(c.id));
                      },
                    )),
                    DataCell(Text(c.id, style: const TextStyle(color: Colors.white70))),
                    DataCell(Text(c.name, style: const TextStyle(color: Colors.white))),
                    DataCell(Text(c.company, style: const TextStyle(color: Colors.white70))),
                    DataCell(Text(_date(c.lastInvoiceDate), style: const TextStyle(color: Colors.white70))),
                    DataCell(Text(_money(c.dueAmount), style: const TextStyle(color: Colors.white))),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _badgeColor(c.overdueDays).withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        c.overdueDays == 0 ? '—' : '${c.overdueDays} d',
                        style: TextStyle(color: _badgeColor(c.overdueDays), fontWeight: FontWeight.w600),
                      ),
                    )),
                    DataCell(Row(
                      children: [
                        IconButton(
                          tooltip: 'View details',
                          onPressed: () => _showDetails(c),
                          icon: const Icon(Icons.receipt_long, color: Colors.white70),
                        ),
                        IconButton(
                          tooltip: 'Call',
                          onPressed: () => _snack('Call ${c.phone} (wire with url_launcher)'),
                          icon: const Icon(Icons.call, color: Colors.white70),
                        ),
                        IconButton(
                          tooltip: 'Mark paid',
                          onPressed: c.dueAmount == 0 ? null : () => _markPaid(c),
                          icon: const Icon(Icons.verified, color: Colors.lightGreenAccent),
                        ),
                      ],
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------- Cards (Mobile) -----------------------------
  Widget _cardList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, i) {
        final c = _view[i];
        final selected = _selected.contains(c.id);
        return GestureDetector(
          onLongPress: () => setState(() => selected ? _selected.remove(c.id) : _selected.add(c.id)),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? Colors.blueAccent : Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('${c.company} • ${c.id}', style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _badgeColor(c.overdueDays).withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        c.overdueDays == 0 ? 'Up-to-date' : '${c.overdueDays} d overdue',
                        style: TextStyle(color: _badgeColor(c.overdueDays), fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _kv('Last Invoice', _date(c.lastInvoiceDate))),
                    Expanded(child: _kv('Due Amount', _money(c.dueAmount))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton.icon(onPressed: () => _showDetails(c), icon: const Icon(Icons.receipt_long), label: const Text('Details')),
                    const SizedBox(width: 8),
                    TextButton.icon(onPressed: () => _snack('Call ${c.phone} (wire url_launcher)'), icon: const Icon(Icons.call), label: const Text('Call')),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: c.dueAmount == 0 ? null : () => _markPaid(c),
                      icon: const Icon(Icons.verified),
                      label: const Text('Mark Paid'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: _view.length,
    );
  }

  Widget _kv(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 4),
        Text(v, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ----------------------------- Actions -----------------------------
  Future<void> _markPaid(Creditor c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as Paid?'),
        content: Text('Confirm payment for ${c.name} (Due: ${_money(c.dueAmount)})'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        final i = _all.indexWhere((x) => x.id == c.id);
        if (i != -1) {
          _all[i] = c.copyWith(dueAmount: 0, overdueDays: 0, paidAmount: c.paidAmount + c.dueAmount);
          _apply();
        }
      });
      _snack('Marked ${c.name} as paid');
    }
  }

  void _showDetails(Creditor c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F2030),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.45,
        maxChildSize: 0.9,
        builder: (context, scroll) {
          return SingleChildScrollView(
            controller: scroll,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(child: Text(c.name.substring(0, 1).toUpperCase())),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('${c.company} • ${c.id}', style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _badgeColor(c.overdueDays).withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          c.overdueDays == 0 ? 'Up-to-date' : '${c.overdueDays} d overdue',
                          style: TextStyle(color: _badgeColor(c.overdueDays), fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _kv('Due Amount', _money(c.dueAmount))),
                      Expanded(child: _kv('Paid Total', _money(c.paidAmount))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _kv('Last Invoice', _date(c.lastInvoiceDate)),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  const Text('Ledger (sample)', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _fakeLedger(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      OutlinedButton.icon(onPressed: () => _snack('Send reminder (wire email/SMS)'), icon: const Icon(Icons.sms_outlined), label: const Text('Send Reminder')),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(onPressed: c.dueAmount == 0 ? null : () => _markPaid(c), icon: const Icon(Icons.verified), label: const Text('Mark Paid')),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _fakeLedger() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: List.generate(4, (i) {
          final d = DateTime.now().subtract(Duration(days: 7 * i + 2));
          final amt = (i.isEven ? 25000 : -18000) * (i + 1);
          return ListTile(
            dense: true,
            leading: Icon(amt >= 0 ? Icons.south_west : Icons.north_east, color: amt >= 0 ? Colors.lightGreenAccent : Colors.redAccent),
            title: Text(amt >= 0 ? 'Purchase' : 'Payment', style: const TextStyle(color: Colors.white)),
            subtitle: Text(_date(d), style: const TextStyle(color: Colors.white70)),
            trailing: Text(
              (amt >= 0 ? '+ ' : '- ') + _money(amt.abs()),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          );
        }),
      ),
    );
  }

  Future<void> _showNewCreditorDialog() async {
    final nameCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: '0');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Creditor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Name'), controller: nameCtrl),
            TextField(decoration: const InputDecoration(labelText: 'Company'), controller: companyCtrl),
            TextField(decoration: const InputDecoration(labelText: 'Initial Due Amount'), controller: amountCtrl, keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        final id = 'CR${1000 + _all.length}';
        _all.insert(0, Creditor(
          id: id,
          name: nameCtrl.text.trim().isEmpty ? 'New Creditor' : nameCtrl.text.trim(),
          company: companyCtrl.text.trim().isEmpty ? '—' : companyCtrl.text.trim(),
          phone: '+94 70 000 0000',
          email: 'n/a',
          lastInvoiceDate: DateTime.now(),
          dueAmount: double.tryParse(amountCtrl.text) ?? 0,
          paidAmount: 0,
          overdueDays: 0,
        ));
        _apply();
      });
      _snack('Creditor created');
    }
  }
}

class Creditor {
  final String id;
  final String name;
  final String company;
  final String phone;
  final String email;
  final DateTime lastInvoiceDate;
  final double dueAmount;
  final double paidAmount;
  final int overdueDays;

  Creditor({
    required this.id,
    required this.name,
    required this.company,
    required this.phone,
    required this.email,
    required this.lastInvoiceDate,
    required this.dueAmount,
    required this.paidAmount,
    required this.overdueDays,
  });

  Creditor copyWith({
    String? id,
    String? name,
    String? company,
    String? phone,
    String? email,
    DateTime? lastInvoiceDate,
    double? dueAmount,
    double? paidAmount,
    int? overdueDays,
  }) => Creditor(
        id: id ?? this.id,
        name: name ?? this.name,
        company: company ?? this.company,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        lastInvoiceDate: lastInvoiceDate ?? this.lastInvoiceDate,
        dueAmount: dueAmount ?? this.dueAmount,
        paidAmount: paidAmount ?? this.paidAmount,
        overdueDays: overdueDays ?? this.overdueDays,
      );
}

const _names = [
  'Amal Perera', 'Nimal Silva', 'Kavindi Fernando', 'Ishara Jayasundara',
  'Sachini Ranasinghe', 'Kasun Sameera', 'Tharindu Wickramasinghe',
  'Malsha Upeksha', 'Rashmi Gunasekara', 'Sahan Dias', 'Chathura Lakmal',
  'Sadeep Chathushan', 'Hansima Perera', 'Achintha Nimantha', 'Insaf Ahamed',
];

const _companies = [
  'ABC Traders', 'Colombo Suppliers', 'Island Wholesale', 'Kandy Stores',
  'Lanka Distributors', 'NorthMart', 'SouthLine Imports', 'Central Hub',
];
