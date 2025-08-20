import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ========= Data models =========

class SupplierRequestItem {
  SupplierRequestItem({
    required this.itemName,
    required this.currentStock,
    required this.requestedAmount,
    required this.quantity,
    required this.unitPrice,
    required this.salePrice,
  });

  final String itemName;
  final int currentStock;
  final int requestedAmount;
  int quantity; // editable
  final double unitPrice;
  final double salePrice;
}

class SupplierRequest {
  SupplierRequest({
    required this.id,
    required this.supplierName,
    required this.createdAt,
    required this.items,
  });

  final String id;
  final String supplierName;
  final DateTime createdAt;
  final List<SupplierRequestItem> items;
}

/// ========= Screen =========

class stockkeeper_supplier_request extends StatefulWidget {
  const stockkeeper_supplier_request({super.key});

  @override
  State<stockkeeper_supplier_request> createState() =>
      _stockkeeper_supplier_requestState();
}

class _stockkeeper_supplier_requestState
    extends State<stockkeeper_supplier_request> {
  // Search + date filters
  final TextEditingController _searchCtrl = TextEditingController();
  DateTimeRange? _dateRange;

  // Demo data: multiple supplier requests
  final List<SupplierRequest> _allRequests = [
    SupplierRequest(
      id: 'REQ-1001',
      supplierName: 'AASA Distributors (Pvt) Ltd',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      items: [
        SupplierRequestItem(
          itemName: 'Cadbury Dairy Milk 100g',
          currentStock: 45,
          requestedAmount: 60,
          quantity: 60,
          unitPrice: 210.00,
          salePrice: 250.00,
        ),
        SupplierRequestItem(
          itemName: 'Maliban Cream Crackers',
          currentStock: 8,
          requestedAmount: 30,
          quantity: 30,
          unitPrice: 150.00,
          salePrice: 180.00,
        ),
      ],
    ),
    SupplierRequest(
      id: 'REQ-1002',
      supplierName: 'Sunshine Traders',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      items: [
        SupplierRequestItem(
          itemName: 'Sunquick Orange 700ml',
          currentStock: 23,
          requestedAmount: 20,
          quantity: 20,
          unitPrice: 360.00,
          salePrice: 420.00,
        ),
        SupplierRequestItem(
          itemName: 'Coca Cola 330ml',
          currentStock: 67,
          requestedAmount: 40,
          quantity: 40,
          unitPrice: 120.00,
          salePrice: 150.00,
        ),
      ],
    ),
    SupplierRequest(
      id: 'REQ-1003',
      supplierName: 'Fonterra Lanka',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      items: [
        SupplierRequestItem(
          itemName: 'Anchor Milk Powder 400g',
          currentStock: 12,
          requestedAmount: 25,
          quantity: 25,
          unitPrice: 750.00,
          salePrice: 850.00,
        ),
      ],
    ),
  ];

  // Which request is selected
  int? _selectedIndex;

  // quantity controllers per visible row (for the selected request only)
  final Map<int, TextEditingController> _qtyCtrls = {};

  @override
  void initState() {
    super.initState();
    // Select the first request by default
    if (_allRequests.isNotEmpty) {
      _selectRequest(0);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    for (final c in _qtyCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ===== Helpers =====

  String _money(double v) => 'Rs. ${v.toStringAsFixed(2)}';

  List<SupplierRequest> get _filteredRequests {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _allRequests.where((r) {
      final matchesText = q.isEmpty ||
          r.supplierName.toLowerCase().contains(q) ||
          r.id.toLowerCase().contains(q);
      final matchesDate = _dateRange == null
          ? true
          : (r.createdAt.isAfter(
                  _dateRange!.start.subtract(const Duration(days: 1))) &&
              r.createdAt.isBefore(
                  _dateRange!.end.add(const Duration(days: 1))));
      return matchesText && matchesDate;
    }).toList();
  }

  SupplierRequest? get _selectedRequest =>
      (_selectedIndex == null) ? null : _filteredRequests[_selectedIndex!];

  void _rebuildQtyControllers() {
    for (final c in _qtyCtrls.values) {
      c.dispose();
    }
    _qtyCtrls.clear();
    final req = _selectedRequest;
    if (req == null) return;
    for (var i = 0; i < req.items.length; i++) {
      _qtyCtrls[i] = TextEditingController(text: req.items[i].quantity.toString());
    }
  }

  void _selectRequest(int indexInFiltered) {
    setState(() {
      _selectedIndex = indexInFiltered;
      _rebuildQtyControllers();
    });
  }

  void _deleteRow(int itemIndex) {
    final req = _selectedRequest;
    if (req == null) return;
    setState(() {
      req.items.removeAt(itemIndex);
      _rebuildQtyControllers();
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
      initialDateRange: _dateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
        // When filter changes, keep a valid selection index
        if (_filteredRequests.isEmpty) {
          _selectedIndex = null;
        } else {
          _selectedIndex = 0;
        }
        _rebuildQtyControllers();
      });
    }
  }

  void _onReject() => _toast('Request rejected.');
  void _onResend() => _toast('Request re-sent to supplier.');
  void _onAccept() => _toast('Request accepted.');

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ===== UI =====

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900; // master-detail on wide; stacked on narrow

    final filtered = _filteredRequests;
    final selected = _selectedRequest;

    // Make sure selected index stays valid after filtering
    if (filtered.isEmpty && _selectedIndex != null) {
      _selectedIndex = null;
    } else if (_selectedIndex != null && _selectedIndex! >= filtered.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Requests'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.surface, cs.surfaceVariant.withOpacity(.35), cs.background],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isWide
                  ? Row(
                      children: [
                        // LEFT: list + search (master)
                        Flexible(
                          flex: 4,
                          child: _buildMasterList(
                            cs: cs,
                            textTheme: textTheme,
                            filtered: filtered,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // RIGHT: details (detail)
                        Flexible(
                          flex: 7,
                          child: _buildDetailCard(
                            cs: cs,
                            textTheme: textTheme,
                            selected: selected,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildMasterList(
                          cs: cs,
                          textTheme: textTheme,
                          filtered: filtered,
                          dense: true,
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _buildDetailCard(
                            cs: cs,
                            textTheme: textTheme,
                            selected: selected,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// Master (left/top): search + list of supplier requests
  Widget _buildMasterList({
    required ColorScheme cs,
    required TextTheme textTheme,
    required List<SupplierRequest> filtered,
    bool dense = false,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search + date filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      labelText: 'Search supplier or request ID',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(_dateRange == null
                      ? 'Filter dates'
                      : '${_dateRange!.start.toString().substring(0, 10)} → ${_dateRange!.end.toString().substring(0, 10)}'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No supplier requests found',
                        style: textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withOpacity(.7),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, i) {
                        final r = filtered[i];
                        final selected = _selectedIndex == i;
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _selectRequest(i),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: selected
                                  ? cs.primary.withOpacity(.12)
                                  : cs.surfaceVariant.withOpacity(.25),
                              border: Border.all(
                                color: selected ? cs.primary : cs.outlineVariant,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.supplierName,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(r.id),
                                      visualDensity: VisualDensity.compact,
                                      side: BorderSide(color: cs.outlineVariant),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.calendar_today,
                                        size: 16, color: cs.onSurface.withOpacity(.7)),
                                    const SizedBox(width: 4),
                                    Text(
                                      r.createdAt.toString().substring(0, 16),
                                      style: textTheme.bodySmall?.copyWith(
                                        color: cs.onSurface.withOpacity(.75),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${r.items.length} item${r.items.length == 1 ? '' : 's'}',
                                      style: textTheme.labelMedium?.copyWith(
                                        color: cs.onSurface.withOpacity(.75),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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

  /// Detail (right/bottom): supplier name + table + actions
  Widget _buildDetailCard({
    required ColorScheme cs,
    required TextTheme textTheme,
    required SupplierRequest? selected,
  }) {
    if (selected == null) {
      return Card(
        elevation: 2,
        child: Center(
          child: Text(
            'Select a supplier request to view details',
            style: textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(.7),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header line: Supplier name and request id/date
            Row(
              children: [
                Icon(Icons.store_mall_directory_outlined, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selected.supplierName,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(selected.id),
                  side: BorderSide(color: cs.outlineVariant),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                Icon(Icons.calendar_today, size: 16, color: cs.onSurface.withOpacity(.7)),
                const SizedBox(width: 4),
                Text(
                  selected.createdAt.toString().substring(0, 16),
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(.75),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Table
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 950),
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowHeight: 44,
                      dataRowMinHeight: 56,
                      dataRowMaxHeight: 64,
                      headingTextStyle: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                      columns: const [
                        DataColumn(label: Text('Item name')),
                        DataColumn(label: Text('Curr. stock')),
                        DataColumn(label: Text('Req. amount')),
                        DataColumn(label: Text('Quantity')),
                        DataColumn(label: Text('Unit price')),
                        DataColumn(label: Text('Sale price')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: List.generate(selected.items.length, (i) {
                        final r = selected.items[i];
                        final qtyCtrl = _qtyCtrls[i] ??
                            TextEditingController(text: r.quantity.toString());
                        _qtyCtrls[i] = qtyCtrl; // ensure stored

                        return DataRow(
                          cells: [
                            DataCell(Text(r.itemName)),
                            DataCell(Text('${r.currentStock}')),
                            DataCell(Text('${r.requestedAmount}')),
                            DataCell(
                              SizedBox(
                                width: 110,
                                child: TextField(
                                  controller: qtyCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  onChanged: (v) {
                                    final parsed = int.tryParse(v);
                                    setState(() {
                                      r.quantity = parsed ?? r.quantity;
                                    });
                                  },
                                ),
                              ),
                            ),
                            DataCell(Text(_money(r.unitPrice))),
                            DataCell(Text(_money(r.salePrice))),
                            DataCell(
                              IconButton(
                                tooltip: 'Delete row',
                                icon: Icon(Icons.delete_outline, color: cs.error),
                                onPressed: () => _deleteRow(i),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom buttons
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      side: BorderSide(color: cs.error),
                    ),
                    onPressed: _onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _onResend,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Resend'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _onAccept,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Accept'),
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
