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

  // Which request is selected (index in the *filtered* list)
  int? _selectedIndex;

  // quantity controllers per visible row (for the selected request only)
  final Map<int, TextEditingController> _qtyCtrls = {};

  @override
  void initState() {
    super.initState();
    if (_allRequests.isNotEmpty) {
      _selectedIndex = 0;
      _rebuildQtyControllers();
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

  SupplierRequest? get _selectedRequest {
    final list = _filteredRequests;
    if (_selectedIndex == null || list.isEmpty) return null;
    if (_selectedIndex! < 0 || _selectedIndex! >= list.length) return null;
    return list[_selectedIndex!];
  }

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

  /// Ensure selection is valid *immediately* after any filter change
  void _fixSelectionAfterFilter() {
    final filtered = _filteredRequests;
    if (filtered.isEmpty) {
      _selectedIndex = null;
      for (final c in _qtyCtrls.values) {
        c.dispose();
      }
      _qtyCtrls.clear();
    } else {
      if (_selectedIndex == null || _selectedIndex! >= filtered.length) {
        _selectedIndex = 0;
        _rebuildQtyControllers();
      }
    }
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
        _fixSelectionAfterFilter();
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
    final size = MediaQuery.of(context).size;

    final isDesktop = size.width >= 1200;
    final isTablet = size.width >= 800 && size.width < 1200;
    final isMobile = size.width < 800;

    final selected = _selectedRequest;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Requests'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Clear filters',
            onPressed: () {
              setState(() {
                _searchCtrl.clear();
                _dateRange = null;
                _fixSelectionAfterFilter();
              });
            },
            icon: const Icon(Icons.filter_alt_off_outlined),
          ),
        ],
      ),

      // Mobile: actions move to FAB + bottom sheet
      floatingActionButton: isMobile && selected != null
          ? FloatingActionButton.extended(
              onPressed: () => _showActionSheet(context),
              icon: const Icon(Icons.tune),
              label: const Text('Actions'),
            )
          : null,

      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.surface, cs.surfaceVariant.withOpacity(.35), cs.background],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 12,
              vertical: isDesktop ? 16 : 8,
            ),
            child: isDesktop || isTablet
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LEFT: master list (fixed nice width on desktop)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: 320,
                          maxWidth: isDesktop ? 420 : 360,
                        ),
                        child: _buildMasterList(
                          cs: cs,
                          textTheme: textTheme,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // RIGHT: detail fills remaining space fully
                      Expanded(
                        child: _buildDetailCard(
                          cs: cs,
                          textTheme: textTheme,
                          selected: selected,
                          showInlineButtons: true, // desktop/tablet show buttons inline
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      // ✅ Mobile: master list must expand to get height
                      Expanded(
                        child: _buildMasterList(
                          cs: cs,
                          textTheme: textTheme,
                          dense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Mobile: details below, no inline buttons (use FAB)
                      Expanded(
                        child: _buildDetailCard(
                          cs: cs,
                          textTheme: textTheme,
                          selected: selected,
                          showInlineButtons: false,
                        ),
                      ),
                    ],
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
    bool dense = false,
  }) {
    final filtered = _filteredRequests;

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
                    onChanged: (_) => setState(_fixSelectionAfterFilter),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search supplier or request ID',
                      border: OutlineInputBorder(),
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
            // The list itself expands within its parent (works in both layouts)
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
    required bool showInlineButtons,
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

            // Desktop/tablet: inline bottom buttons
            if (showInlineButtons) ...[
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
          ],
        ),
      ),
    );
  }

  /// Mobile actions bottom sheet
  void _showActionSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Actions'),
                subtitle: const Text('Approve / reject / resend this request'),
                leading: Icon(Icons.tune, color: cs.primary),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.error,
                        side: BorderSide(color: cs.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _onReject();
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _onResend();
                      },
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Resend'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _onAccept();
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Accept'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
