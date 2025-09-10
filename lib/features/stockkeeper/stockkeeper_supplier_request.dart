// lib/features/stockkeeper/requests/stockkeeper_supplier_request.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// <- DB models & repo you added earlier
import 'package:pos_system/data/models/stockkeeper/supplier_request_model.dart' as m;
import 'package:pos_system/data/repositories/stockkeeper/supplier_request_repository.dart' hide Row;

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

  // ---------- Quick add ----------
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
      lines: const [], // start empty (you can add a line editor later)
    );
    _toast('Request ${created.displayId} created');

    // reload list and select the new ID
    await _loadList();
    await _loadDetail(created.id);
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
            tooltip: 'Add request',
            onPressed: _quickAddRequest,
            icon: const Icon(Icons.add),
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
                    onChanged: (_) {}, // keep responsive? call _loadList with debounce if you like
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

  // ---------- Mobile bottom sheet ----------
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
}
