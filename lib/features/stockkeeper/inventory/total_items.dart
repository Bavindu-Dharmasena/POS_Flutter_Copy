// lib/features/stockkeeper/total_items.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show ActivateIntent; // for the Shortcuts/Actions ActivateIntent
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

// ✅ import your repository
import 'package:pos_system/data/repositories/stockkeeper/item_repository.dart';

class TotalItems extends StatefulWidget {
  const TotalItems({super.key});

  @override
  State<TotalItems> createState() => _TotalItemsState();
}

class _TotalItemsState extends State<TotalItems> {
  final FocusNode _focusNode = FocusNode();

  // Loaded from DB
  List<_Item> _items = <_Item>[];

  // UI state
  String _search = '';
  int _sortColumnIndex = 1;
  bool _sortAscending = true;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await ItemRepository.instance.fetchItemsForTotals();
      final parsed = rows.map((r) => _Item.fromRow(r)).toList();
      setState(() {
        _items = parsed;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load items: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Filter + sort
    final filtered = _items.where((e) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase().trim();
      return e.name.toLowerCase().contains(q) || e.id.toLowerCase().contains(q);
    }).toList();

    filtered.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.id.compareTo(b.id);
          break;
        case 1:
          cmp = a.name.compareTo(b.name);
          break;
        case 2:
          cmp = a.qty.compareTo(b.qty);
          break;
        case 3:
          cmp = a.unitCost.compareTo(b.unitCost);
          break;
        case 4:
          cmp = a.salesPrice.compareTo(b.salesPrice);
          break;
        case 5:
          cmp = a.totalSalesValue.compareTo(b.totalSalesValue);
          break;
        default:
          cmp = a.name.compareTo(b.name);
      }
      return _sortAscending ? cmp : -cmp;
    });

    final totalItemsCount =
        filtered.fold<int>(0, (s, e) => s + e.qty);
    final totalCostValue =
        filtered.fold<double>(0, (s, e) => s + (e.qty * e.unitCost));
    final totalSalesValue =
        filtered.fold<double>(0, (s, e) => s + (e.qty * e.salesPrice));

    return Shortcuts(
      shortcuts: {
        // Esc to close, if possible
        LogicalKeySet(LogicalKeyboardKey.escape): const ActivateIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Total Items'),
              centerTitle: true,
              backgroundColor: cs.surface,
              elevation: 0,
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Feather.refresh_ccw),
                  onPressed: _load,
                ),
                IconButton(
                  tooltip: 'Copy totals (CSV)',
                  icon: const Icon(Feather.clipboard),
                  onPressed: _loading
                      ? null
                      : () async {
                          final csv = _toCsv(filtered);
                          await Clipboard.setData(ClipboardData(text: csv));
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Copied table (CSV) to clipboard')),
                          );
                        },
                ),
              ],
            ),
            body: Container(
              width: double.infinity,
              height: double.infinity,
              color: cs.surface,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Feather.alert_triangle, size: 36),
                                const SizedBox(height: 12),
                                Text(
                                  'Could not load items.\n$_error',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: _load,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            // 🔎 Search
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      onChanged: (v) =>
                                          setState(() => _search = v),
                                      decoration: InputDecoration(
                                        prefixIcon:
                                            const Icon(Feather.search),
                                        hintText:
                                            'Search by Item ID or Name...',
                                        filled: true,
                                        fillColor: cs
                                            .surfaceContainerHighest
                                            .withOpacity(.2),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: cs.outline
                                                  .withOpacity(.2)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide:
                                              BorderSide(color: cs.primary),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 0),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Tooltip(
                                    message: 'Clear',
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      onPressed: () =>
                                          setState(() => _search = ''),
                                      child: const Icon(Feather.x),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 📊 Table
                            Expanded(
                              child: Card(
                                color: cs.surfaceContainerHighest
                                    .withOpacity(.2),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                      color:
                                          cs.outline.withOpacity(.15)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                              minWidth: math.max(
                                                  constraints.maxWidth,
                                                  900)),
                                          child: SingleChildScrollView(
                                            child: DataTable(
                                              headingRowHeight: 48,
                                              dataRowMinHeight: 48,
                                              dataRowMaxHeight: 56,
                                              headingRowColor:
                                                  WidgetStatePropertyAll(
                                                cs.surfaceTint
                                                    .withOpacity(.07),
                                              ),
                                              showCheckboxColumn: false,
                                              sortAscending:
                                                  _sortAscending,
                                              sortColumnIndex:
                                                  _sortColumnIndex,
                                              columns: [
                                                DataColumn(
                                                  label: const Text(
                                                      'Item ID'),
                                                  onSort: (i, asc) =>
                                                      setState(() {
                                                    _sortColumnIndex = i;
                                                    _sortAscending = asc;
                                                  }),
                                                ),
                                                DataColumn(
                                                  label:
                                                      const Text('Name'),
                                                  onSort: (i, asc) =>
                                                      setState(() {
                                                    _sortColumnIndex = i;
                                                    _sortAscending = asc;
                                                  }),
                                                ),
                                                DataColumn(
                                                  numeric: true,
                                                  label:
                                                      const Text('Qty'),
                                                  onSort: (i, asc) =>
                                                      setState(() {
                                                    _sortColumnIndex = i;
                                                    _sortAscending = asc;
                                                  }),
                                                ),
                                                DataColumn(
                                                  numeric: true,
                                                  label: const Text(
                                                      'Unit Cost (LKR)'),
                                                  onSort: (i, asc) =>
                                                      setState(() {
                                                    _sortColumnIndex = i;
                                                    _sortAscending = asc;
                                                  }),
                                                ),
                                                DataColumn(
                                                  numeric: true,
                                                  label: const Text(
                                                      'Sales Price (LKR)'),
                                                  onSort: (i, asc) =>
                                                      setState(() {
                                                    _sortColumnIndex = i;
                                                    _sortAscending = asc;
                                                  }),
                                                ),
                                                DataColumn(
                                                  numeric: true,
                                                  label: const Text(
                                                      'Total (Qty × Sales)'),
                                                  onSort: (i, asc) =>
                                                      setState(() {
                                                    _sortColumnIndex = i;
                                                    _sortAscending = asc;
                                                  }),
                                                ),
                                              ],
                                              rows: [
                                                for (final e in filtered)
                                                  DataRow(cells: [
                                                    DataCell(Text(e.id)),
                                                    DataCell(Text(e.name)),
                                                    DataCell(
                                                        Text('${e.qty}')),
                                                    DataCell(Text(
                                                        _fmt(e.unitCost))),
                                                    DataCell(Text(_fmt(
                                                        e.salesPrice))),
                                                    DataCell(Text(
                                                      _fmt(e
                                                          .totalSalesValue),
                                                      style:
                                                          const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                    )),
                                                  ]),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),

                            // 📌 Totals
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 8, 16, 16),
                              child: _TotalsBar(
                                totalItemsCount: totalItemsCount,
                                totalCostValue: totalCostValue,
                                totalSalesValue: totalSalesValue,
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

  String _toCsv(List<_Item> items) {
    final buf = StringBuffer();
    buf.writeln(
        'Item ID,Name,Qty,Unit Cost,Sales Price,Total (Qty x Sales)');
    for (final e in items) {
      buf.writeln([
        e.id,
        e.name.replaceAll(',', ' '),
        e.qty,
        e.unitCost.toStringAsFixed(2),
        e.salesPrice.toStringAsFixed(2),
        e.totalSalesValue.toStringAsFixed(2),
      ].join(','));
    }
    return buf.toString();
  }

  String _fmt(double v) => v.toStringAsFixed(2);
}

// ===== Models & UI helpers =====

class _Item {
  final String id;      // we’ll use item.id as string for display
  final String name;
  final int qty;
  final double unitCost;
  final double salesPrice;

  const _Item({
    required this.id,
    required this.name,
    required this.qty,
    required this.unitCost,
    required this.salesPrice,
  });

  double get totalSalesValue => qty * salesPrice;
  double get totalCostValue => qty * unitCost;

  /// Map row -> _Item
  factory _Item.fromRow(Map<String, Object?> r) {
    // SQLite returns numbers as int or num; ensure double via (as num).toDouble()
    final qty = (r['qty'] as num?)?.toInt() ?? 0;
    final unitCost = (r['unit_cost'] as num?)?.toDouble() ?? 0.0;
    final salesPrice = (r['sales_price'] as num?)?.toDouble() ?? 0.0;

    return _Item(
      id: (r['id'] as int?)?.toString() ?? '', // show numeric id as text
      name: (r['name'] as String?) ?? '',
      qty: qty,
      unitCost: unitCost,
      salesPrice: salesPrice,
    );
  }
}

class _TotalsBar extends StatelessWidget {
  final int totalItemsCount;
  final double totalCostValue;
  final double totalSalesValue;

  const _TotalsBar({
    required this.totalItemsCount,
    required this.totalCostValue,
    required this.totalSalesValue,
  });

  @override
  Widget build(BuildContext context) {
    final profit = totalSalesValue - totalCostValue;

    Widget pill(String label, String value,
        {IconData? icon, Color? color}) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color ?? Colors.grey.shade600,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Text('$label: ',
                style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      );
    }

    return Wrap(
      runSpacing: 8,
      spacing: 8,
      children: [
        pill('Total Quantity', '$totalItemsCount',
            icon: Feather.archive, color: Colors.blue),
        pill('Total Cost Value (LKR)',
            totalCostValue.toStringAsFixed(2),
            icon: Feather.tag, color: Colors.orange),
        pill('Total Sales Value (LKR)',
            totalSalesValue.toStringAsFixed(2),
            icon: Feather.credit_card, color: Colors.green),
        pill('Estimated Profit (LKR)', profit.toStringAsFixed(2),
            icon: Feather.trending_up,
            color: profit >= 0 ? Colors.teal : Colors.red),
      ],
    );
  }
}
