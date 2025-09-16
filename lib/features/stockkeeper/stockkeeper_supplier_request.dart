import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pos_system/data/models/stockkeeper/supplier_request_model.dart' as m;
import 'package:pos_system/data/repositories/stockkeeper/supplier_request_repository.dart' hide Row;

/// Supplier Requests — master/detail with ability to add items to a request.
class stockkeeper_supplier_request extends StatefulWidget {
  const stockkeeper_supplier_request({super.key});

  @override
  State<stockkeeper_supplier_request> createState() =>
      _stockkeeper_supplier_requestState();
}

class _stockkeeper_supplier_requestState
    extends State<stockkeeper_supplier_request> {
  // ---------- State ----------
  final _repo = SupplierRequestRepository.instance;

  final TextEditingController _searchCtrl = TextEditingController();
  DateTimeRange? _dateRange;

  // headers (no lines) for master list
  List<m.SupplierRequestRecord> _headers = [];
  int? _selectedId; // DB id of selected request

  // full selected record (with lines)
  m.SupplierRequestRecord? _selected;

  // line qty controllers (keyed by lineId)
  final Map<int, TextEditingController> _qtyCtrls = {};

  bool _loadingList = false;
  bool _loadingDetail = false;
  String? _error;

  // ---------- Lifecycle ----------
  @override
  void initState() {
    super.initState();
    _loadList(); // initial
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    for (final c in _qtyCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------- Helpers ----------
  String _money(num v) => 'Rs. ${v.toStringAsFixed(2)}';

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loadList() async {
    setState(() {
      _loadingList = true;
      _error = null;
    });

    try {
      final start = _dateRange?.start.millisecondsSinceEpoch;
      final end = _dateRange?.end.millisecondsSinceEpoch;
      final list = await _repo.list(
        query: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        startMs: start,
        endMs: end,
      );

      setState(() {
        _headers = list;
        _loadingList = false;

        if (_headers.isEmpty) {
          _selectedId = null;
          _selected = null;
          _disposeAllLineCtrls();
        } else {
          // keep selection if still present, else select first
          if (_selectedId == null || !_headers.any((h) => h.id == _selectedId)) {
            _selectedId = _headers.first.id;
          }
          _loadDetail(_selectedId!);
        }
      });
    } catch (e) {
      setState(() {
        _loadingList = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadDetail(int requestId) async {
    setState(() {
      _loadingDetail = true;
      _error = null;
      _selectedId = requestId;
    });

    try {
      final full = await _repo.getById(requestId);
      if (!mounted) return;
      setState(() {
        _selected = full;
        _rebuildQtyControllers(full);
        _loadingDetail = false;
      });
    } catch (e) {
      setState(() {
        _loadingDetail = false;
        _error = e.toString();
      });
    }
  }

  void _disposeAllLineCtrls() {
    for (final c in _qtyCtrls.values) {
      c.dispose();
    }
    _qtyCtrls.clear();
  }

  void _rebuildQtyControllers(m.SupplierRequestRecord? full) {
    _disposeAllLineCtrls();
    if (full == null) return;
    for (final line in full.items) {
      _qtyCtrls[line.id] =
          TextEditingController(text: line.quantity.toString());
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
      setState(() => _dateRange = picked);
      await _loadList();
    }
  }

  // ---------- Row actions ----------
  Future<void> _updateQty(m.SupplierRequestLine line, String v) async {
    final parsed = int.tryParse(v);
    if (parsed == null || parsed <= 0) {
      _toast('Invalid quantity');
      // restore text
      _qtyCtrls[line.id]?.text = line.quantity.toString();
      return;
    }

    await _repo.updateLineQuantity(lineId: line.id, quantity: parsed);
    // refresh detail only (not the whole list)
    await _loadDetail(_selectedId!);
  }

  Future<void> _deleteLine(m.SupplierRequestLine line) async {
    await _repo.deleteLine(line.id);
    await _loadDetail(_selectedId!);
    _toast('Line deleted');
  }

  Future<void> _setStatus(String status) async {
    if (_selectedId == null) return;
    await _repo.setStatus(_selectedId!, status);
    _toast('Status set: $status');
    // refresh list header (to reflect status) but keep selection
    await _loadList();
  }

  // ---------- Add items flow ----------
  Future<void> _openAddItemsSheet() async {
    if (_selectedId == null) return;
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _AddItemsSheet(requestId: _selectedId!),
    );
    if (added == true && _selectedId != null) {
      await _loadDetail(_selectedId!);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    final isDesktop = size.width >= 1200;
    final isTablet = size.width >= 800 && size.width < 1200;
    final isMobile = size.width < 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Requests'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Create new request',
            onPressed: _quickAddRequest,
            icon: const Icon(Icons.note_add_outlined),
          ),
          if (_selectedId != null)
            IconButton(
              tooltip: 'Add items to this request',
              onPressed: _openAddItemsSheet,
              icon: const Icon(Icons.add_shopping_cart_outlined),
            ),
          IconButton(
            tooltip: 'Clear filters',
            onPressed: () async {
              setState(() {
                _searchCtrl.clear();
                _dateRange = null;
              });
              await _loadList();
            },
            icon: const Icon(Icons.filter_alt_off_outlined),
          ),
        ],
      ),

      floatingActionButton: isMobile && _selected != null
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
              colors: [cs.surface, cs.surfaceContainerHighest.withOpacity(.35), cs.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 12,
              vertical: isDesktop ? 16 : 8,
            ),
            child: _error != null
                ? Center(
                    child: Text(
                      'Error: $_error',
                      style: TextStyle(color: cs.error),
                      textAlign: TextAlign.center,
                    ),
                  )
                : (isDesktop || isTablet)
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                          Expanded(
                            child: _buildDetailCard(
                              cs: cs,
                              textTheme: textTheme,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: _buildMasterList(
                              cs: cs,
                              textTheme: textTheme,
                              dense: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _buildDetailCard(
                              cs: cs,
                              textTheme: textTheme,
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  // ---------- Master list ----------
  Widget _buildMasterList({
    required ColorScheme cs,
    required TextTheme textTheme,
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
                    onSubmitted: (_) => _loadList(),
                    onChanged: (_) {}, // add debounce if desired
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
                  label: Text(
                    _dateRange == null
                        ? 'Filter dates'
                        : '${_dateRange!.start.toString().substring(0, 10)} → ${_dateRange!.end.toString().substring(0, 10)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loadingList
                  ? const Center(child: CircularProgressIndicator())
                  : _headers.isEmpty
                      ? Center(
                          child: Text(
                            'No supplier requests found',
                            style: textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface.withOpacity(.7),
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _headers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, i) {
                            final r = _headers[i];
                            final selected = _selectedId == r.id;
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _loadDetail(r.id),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: selected
                                      ? cs.primary.withOpacity(.12)
                                      : cs.surfaceContainerHighest.withOpacity(.25),
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
                                          label: Text(r.displayId),
                                          visualDensity: VisualDensity.compact,
                                          side: BorderSide(color: cs.outlineVariant),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.calendar_today,
                                            size: 16, color: cs.onSurface.withOpacity(.7)),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateTime.fromMillisecondsSinceEpoch(r.createdAt)
                                              .toString()
                                              .substring(0, 16),
                                          style: textTheme.bodySmall?.copyWith(
                                            color: cs.onSurface.withOpacity(.75),
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: cs.secondaryContainer,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            r.status,
                                            style: textTheme.labelSmall,
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

  // ---------- Detail ----------
  Widget _buildDetailCard({
    required ColorScheme cs,
    required TextTheme textTheme,
  }) {
    if (_selectedId == null) {
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

    final selected = _selected;
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            if (selected != null) ...[
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
                    label: Text(selected.displayId),
                    side: BorderSide(color: cs.outlineVariant),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.calendar_today, size: 16, color: cs.onSurface.withOpacity(.7)),
                  const SizedBox(width: 4),
                  Text(
                    selected.createdAtDt.toString().substring(0, 16),
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(.75),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _openAddItemsSheet,
                    icon: const Icon(Icons.add),
                    label: const Text('Add items'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Table
            Expanded(
              child: _loadingDetail
                  ? const Center(child: CircularProgressIndicator())
                  : (selected == null || selected.items.isEmpty)
                      ? Center(
                          child: Text(
                            selected == null ? 'Loading…' : 'No items in this request',
                            style: textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface.withOpacity(.7),
                            ),
                          ),
                        )
                      : SingleChildScrollView(
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
                                rows: selected.items.map((line) {
                                  final qtyCtrl = _qtyCtrls[line.id] ??
                                      TextEditingController(text: line.quantity.toString());
                                  _qtyCtrls[line.id] = qtyCtrl;
                                  return DataRow(cells: [
                                    DataCell(Text(line.itemName)),
                                    DataCell(Text('${line.currentStock}')),
                                    DataCell(Text('${line.requestedAmount}')),
                                    DataCell(
                                      SizedBox(
                                        width: 110,
                                        child: TextField(
                                          controller: qtyCtrl,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 8),
                                          ),
                                          onSubmitted: (v) => _updateQty(line, v),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(_money(line.unitPrice))),
                                    DataCell(Text(_money(line.salePrice))),
                                    DataCell(
                                      IconButton(
                                        tooltip: 'Delete row',
                                        icon: Icon(Icons.delete_outline, color: cs.error),
                                        onPressed: () => _deleteLine(line),
                                      ),
                                    ),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
            ),

            // Actions (desktop/tablet inline)
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      side: BorderSide(color: cs.error),
                    ),
                    onPressed: () => _setStatus('REJECTED'),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _setStatus('RESENT'),
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Resend'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _setStatus('ACCEPTED'),
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

  // ---------- Mobile bottom sheet for status only ----------
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
                        _setStatus('REJECTED');
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
                        _setStatus('RESENT');
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
                    _setStatus('ACCEPTED');
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

  // ---------- Quick create request ----------
  Future<void> _quickAddRequest() async {
    final supplierIdCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Create Supplier Request'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: supplierIdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Supplier ID',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final num = int.tryParse((v ?? '').trim());
                if (num == null || num <= 0) return 'Enter a valid supplier id';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(foregroundColor: cs.error),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final supId = int.parse(supplierIdCtrl.text.trim());
    final created = await _repo.create(
      supplierId: supId,
      lines: const [], // start empty (use Add Items to add)
    );
    _toast('Request ${created.displayId} created');

    // reload list and select the new ID
    await _loadList();
    await _loadDetail(created.id);
  }
}

/// Bottom sheet to add items to a request.
class _AddItemsSheet extends StatefulWidget {
  const _AddItemsSheet({required this.requestId});
  final int requestId;

  @override
  State<_AddItemsSheet> createState() => _AddItemsSheetState();
}

class _AddItemsSheetState extends State<_AddItemsSheet> {
  final _repo = SupplierRequestRepository.instance;

  final _search = TextEditingController();
  bool _loading = false;
  bool _addedAny = false;

  // MUST be mutable; each entry is Map<String,Object?>
  List<Map<String, Object?>> _items = <Map<String, Object?>>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await _repo.listItemsForRequest(
      requestId: widget.requestId,
      query: _search.text.trim().isEmpty ? null : _search.text.trim(),
      limit: 200,
    );
    setState(() {
      // make BOTH list and maps mutable to avoid read-only errors
      _items = rows.map((e) => Map<String, Object?>.from(e)).toList(growable: true);
      _loading = false;
    });
  }

  static Widget _kv(String k, String v) => Row(
        children: [
          Text('$k: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Flexible(child: Text(v, overflow: TextOverflow.ellipsis)),
        ],
      );

  Future<void> _addOne(Map<String, Object?> row) async {
    final itemId = (row['item_id'] as num).toInt();
    final name = (row['name'] as String?) ?? 'Item';
    final currentStock = (row['current_stock'] as num?)?.toInt() ?? 0;
    final rl = (row['reorder_level'] as num?)?.toInt() ?? 0;

    final rqCtrl = TextEditingController(text: '0');
    final qtyCtrl = TextEditingController(text: '1');
    final unitCtrl = TextEditingController(text: '0');
    final saleCtrl = TextEditingController(text: '0');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        InputDecoration dec(String label) => InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        );

        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          title: Text('Add "$name"'),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _kv('Current stock', '$currentStock'),
                  _kv('Reorder level', '$rl'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: rqCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: dec('Requested amount'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: dec('Quantity'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: unitCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    decoration: dec('Unit price'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: saleCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    decoration: dec('Sale price'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(foregroundColor: cs.error),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (int.tryParse(rqCtrl.text) == null ||
                    int.tryParse(qtyCtrl.text) == null ||
                    double.tryParse(unitCtrl.text) == null ||
                    double.tryParse(saleCtrl.text) == null) {
                  return;
                }
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add item'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final line = m.CreateSupplierRequestLine(
      itemId: itemId,
      requestedAmount: int.parse(rqCtrl.text),
      quantity: int.parse(qtyCtrl.text),
      unitPrice: double.parse(unitCtrl.text),
      salePrice: double.parse(saleCtrl.text),
    );

    await _repo.addLine(requestId: widget.requestId, line: line);

    // Mark as added inside the current list without mutating a read-only list
    setState(() {
      _addedAny = true;
      // non-mutating reassignment (bulletproof)
      _items = _items.map((e) {
        if ((e['item_id'] as num).toInt() == itemId) {
          final copy = Map<String, Object?>.from(e);
          copy['already_added'] = 1;
          return copy;
        }
        return e;
      }).toList(growable: true);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added "$name" to request')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom, // keyboard safe
      ),
      child: FractionallySizedBox(
        heightFactor: 0.85, // avoid pixel overflow on small screens
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            Text('Add items to request', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _load(),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search items by name or barcode',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? Center(
                          child: Text(
                            'No items for this supplier',
                            style: textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface.withOpacity(.7),
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final r = _items[i];
                            final name = (r['name'] as String?) ?? 'Item';
                            final currentStock = (r['current_stock'] as num?)?.toInt() ?? 0;
                            final rl = (r['reorder_level'] as num?)?.toInt() ?? 0;
                            final already = ((r['already_added'] as num?) ?? 0) != 0;

                            return ListTile(
                              tileColor: cs.surfaceContainerHighest.withOpacity(.25),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: cs.outlineVariant),
                              ),
                              title: Text(name, overflow: TextOverflow.ellipsis),
                              subtitle: Text('Stock: $currentStock • Reorder: $rl'),
                              trailing: already
                                  ? Chip(
                                      label: const Text('Added'),
                                      visualDensity: VisualDensity.compact,
                                    )
                                  : FilledButton.icon(
                                      onPressed: () => _addOne(r),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add'),
                                    ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, _addedAny),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, _addedAny),
                    icon: const Icon(Icons.check),
                    label: const Text('Done'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
