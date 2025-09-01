import 'dart:math';
import 'package:flutter/material.dart';

enum RuleType { percentageDiscount, fixedDiscount, markup, bogo }

extension RuleTypeLabel on RuleType {
  String get label {
    switch (this) {
      case RuleType.percentageDiscount:
        return 'Percentage Discount';
      case RuleType.fixedDiscount:
        return 'Fixed Discount';
      case RuleType.markup:
        return 'Markup';
      case RuleType.bogo:
        return 'BOGO';
    }
  }

  IconData get icon {
    switch (this) {
      case RuleType.percentageDiscount:
        return Icons.percent;
      case RuleType.fixedDiscount:
        return Icons.price_check;
      case RuleType.markup:
        return Icons.trending_up;
      case RuleType.bogo:
        return Icons.local_offer;
    }
  }
}

enum ScopeKind { all, category, product, customerGroup }

class PriceRule {
  String id;
  String name;
  RuleType type;
  ScopeKind scopeKind;
  String scopeValue; // e.g. "Beverages" or "SKU-123" or "VIP"
  double value; // % for percentage/markup; amount for fixed
  bool stackable;
  bool active;
  int priority; // lower runs first
  int? perCustomerLimit;
  TimeOfDay? startTime; // optional daily window
  TimeOfDay? endTime;
  DateTime? startDate; // optional date window
  DateTime? endDate;
  Set<int> daysOfWeek; // 1=Mon..7=Sun, empty = all days

  PriceRule({
    required this.id,
    required this.name,
    required this.type,
    required this.scopeKind,
    required this.scopeValue,
    required this.value,
    required this.stackable,
    required this.active,
    required this.priority,
    this.perCustomerLimit,
    this.startTime,
    this.endTime,
    this.startDate,
    this.endDate,
    Set<int>? daysOfWeek,
  }) : daysOfWeek = daysOfWeek ?? <int>{};

  bool get isScheduled =>
      startDate != null || endDate != null || startTime != null || endTime != null || daysOfWeek.isNotEmpty;

  bool get isCurrentlyEffective {
    final now = DateTime.now();
    if (!active) return false;

    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;

    if (daysOfWeek.isNotEmpty) {
      final dow = now.weekday; // 1..7
      if (!daysOfWeek.contains(dow)) return false;
    }

    if (startTime != null && endTime != null) {
      final nowTOD = TimeOfDay(hour: now.hour, minute: now.minute);
      bool afterStart = _compareTOD(nowTOD, startTime!) >= 0;
      bool beforeEnd = _compareTOD(nowTOD, endTime!) <= 0;
      if (!(afterStart && beforeEnd)) return false;
    }
    return true;
  }
}

int _compareTOD(TimeOfDay a, TimeOfDay b) {
  if (a.hour != b.hour) return a.hour.compareTo(b.hour);
  return a.minute.compareTo(b.minute);
}

class PriceRulesPage extends StatefulWidget {
  const PriceRulesPage({super.key});

  @override
  State<PriceRulesPage> createState() => _PriceRulesPageState();
}

class _PriceRulesPageState extends State<PriceRulesPage> with TickerProviderStateMixin {
  final TextEditingController _search = TextEditingController();
  final List<PriceRule> _rules = [];
  String _statusFilter = 'All'; // All / Active / Scheduled / Inactive
  RuleType? _typeFilter;
  bool _sortAscending = true;
  String _sortBy = 'priority'; // priority | name | type | status

  // FAB anim
  late final AnimationController _fabCtrl;
  late final Animation<double> _fabScale;

  // horizontal pager (mobile)
  final PageController _pageCtrl = PageController(viewportFraction: 0.9);
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _seedData();
    _fabCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fabScale = CurvedAnimation(parent: _fabCtrl, curve: Curves.easeOutBack);
    _fabCtrl.forward();

    _pageCtrl.addListener(() {
      final i = _pageCtrl.page ?? 0;
      final next = i.round();
      if (next != _pageIndex) {
        setState(() => _pageIndex = next);
      }
    });
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    _search.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _seedData() {
    _rules.addAll([
      PriceRule(
        id: 'r1',
        name: 'Happy Hour - Drinks',
        type: RuleType.percentageDiscount,
        scopeKind: ScopeKind.category,
        scopeValue: 'Beverages',
        value: 20,
        stackable: false,
        active: true,
        priority: 10,
        startTime: const TimeOfDay(hour: 16, minute: 0),
        endTime: const TimeOfDay(hour: 18, minute: 0),
        daysOfWeek: {5, 6, 7}, // Fri-Sun
      ),
      PriceRule(
        id: 'r2',
        name: 'Clearance - SKU-AX12',
        type: RuleType.fixedDiscount,
        scopeKind: ScopeKind.product,
        scopeValue: 'SKU-AX12',
        value: 250.0,
        stackable: true,
        active: true,
        priority: 5,
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 10)),
      ),
      PriceRule(
        id: 'r3',
        name: 'VIP Markup Waiver',
        type: RuleType.markup,
        scopeKind: ScopeKind.customerGroup,
        scopeValue: 'VIP',
        value: -5,
        stackable: true,
        active: false,
        priority: 50,
      ),
      PriceRule(
        id: 'r4',
        name: 'Buy 1 Get 1 Free - Soap',
        type: RuleType.bogo,
        scopeKind: ScopeKind.product,
        scopeValue: 'SKU-SOAP',
        value: 0,
        stackable: false,
        active: true,
        priority: 15,
      ),
    ]);
  }

  List<PriceRule> get _filtered {
    final q = _search.text.trim().toLowerCase();
    List<PriceRule> list = _rules.where((r) {
      final matchesSearch = q.isEmpty ||
          r.name.toLowerCase().contains(q) ||
          r.scopeValue.toLowerCase().contains(q) ||
          r.type.label.toLowerCase().contains(q);
      final matchesType = _typeFilter == null || r.type == _typeFilter;
      final status = r.active
          ? (r.isScheduled ? 'Scheduled' : 'Active')
          : 'Inactive';
      final matchesStatus = _statusFilter == 'All' || _statusFilter == status;
      return matchesSearch && matchesType && matchesStatus;
    }).toList();

    int cmp(PriceRule a, PriceRule b) {
      switch (_sortBy) {
        case 'name':
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'type':
          return a.type.index.compareTo(b.type.index);
        case 'status':
          final sa = a.active ? (a.isScheduled ? 1 : 0) : 2;
          final sb = b.active ? (b.isScheduled ? 1 : 0) : 2;
          return sa.compareTo(sb);
        case 'priority':
        default:
          return a.priority.compareTo(b.priority);
      }
    }

    list.sort(cmp);
    if (!_sortAscending) list = list.reversed.toList();
    return list;
  }

  void _upsertRule({PriceRule? existing}) async {
    final result = await showModalBottomSheet<PriceRule>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RuleEditorSheet(existing: existing),
    );
    if (result == null) return;

    setState(() {
      if (existing == null) {
        _rules.add(result);
      } else {
        final i = _rules.indexWhere((r) => r.id == existing.id);
        if (i != -1) _rules[i] = result;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(existing == null ? 'Rule created' : 'Rule updated')),
    );
  }

  void _deleteRule(PriceRule r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete rule?'),
        content: Text('Are you sure you want to delete “${r.name}”?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _rules.removeWhere((e) => e.id == r.id));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rule deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Rules'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Sort',
            onSelected: (v) => setState(() {
              if (v == _sortBy) {
                _sortAscending = !_sortAscending;
              } else {
                _sortBy = v;
                _sortAscending = true;
              }
            }),
            itemBuilder: (_) => [
              _menuItem('priority', 'Priority'),
              _menuItem('name', 'Name'),
              _menuItem('type', 'Type'),
              _menuItem('status', 'Status'),
            ],
            icon: const Icon(Icons.sort),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton.extended(
          onPressed: () => _upsertRule(),
          icon: const Icon(Icons.add),
          label: const Text('New Rule'),
        ),
      ),
      body: Column(
        children: [
          _FilterBar(
            searchController: _search,
            statusValue: _statusFilter,
            onStatusChanged: (v) => setState(() => _statusFilter = v),
            typeValue: _typeFilter,
            onTypeChanged: (v) => setState(() => _typeFilter = v),
            onSearchChanged: (_) => setState(() {}),
            onClearFilters: () => setState(() {
              _statusFilter = 'All';
              _typeFilter = null;
              _search.clear();
            }),
          ),
          Expanded(child: _buildRulesList(context, cs)),
        ],
      ),
    );
  }

  // —— horizontal on mobile, vertical on wide ——
  Widget _buildRulesList(BuildContext context, ColorScheme cs) {
    final list = _filtered;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rule, size: 48),
            const SizedBox(height: 8),
            Text('No matching rules', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Try adjusting filters or create a new rule.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    if (!isMobile) {
      // desktop/tablet: vertical list
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) => _RuleCard(
          rule: list[i],
          onToggle: (on) => setState(() => list[i].active = on),
          onEdit: () => _upsertRule(existing: list[i]),
          onDelete: () => _deleteRule(list[i]),
        ),
      );
    }

    // mobile: horizontal page view
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: list.length,
            padEnds: true,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (_, i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: _RuleCard(
                      rule: list[i],
                      onToggle: (on) => setState(() => list[i].active = on),
                      onEdit: () => _upsertRule(existing: list[i]),
                      onDelete: () => _deleteRule(list[i]),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        _DotsIndicator(
          count: list.length,
          index: _pageIndex.clamp(0, list.length - 1),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          if (_sortBy == value)
            Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16)
          else
            const SizedBox(width: 16),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int index;
  const _DotsIndicator({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: active ? 20 : 8,
          decoration: BoxDecoration(
            color: active ? cs.primary : cs.outlineVariant,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String statusValue;
  final ValueChanged<String> onStatusChanged;
  final RuleType? typeValue;
  final ValueChanged<RuleType?> onTypeChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearFilters;

  const _FilterBar({
    required this.searchController,
    required this.statusValue,
    required this.onStatusChanged,
    required this.typeValue,
    required this.onTypeChanged,
    required this.onSearchChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 220, maxWidth: 420),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by name, SKU, category…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          onPressed: () {
                            searchController.clear();
                            onSearchChanged('');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: statusValue,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All status')),
                  DropdownMenuItem(value: 'Active', child: Text('Active (now)')),
                  DropdownMenuItem(value: 'Scheduled', child: Text('Scheduled')),
                  DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                ],
                onChanged: (v) => v != null ? onStatusChanged(v) : null,
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<RuleType?>(
                value: typeValue,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All types')),
                  ...RuleType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))),
                ],
                onChanged: onTypeChanged,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Clear'),
              style: TextButton.styleFrom(
                foregroundColor: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final PriceRule rule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RuleCard({
    required this.rule,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  Color _chipColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!rule.active) return cs.errorContainer.withOpacity(0.35);
    return rule.isCurrentlyEffective ? cs.primaryContainer : cs.secondaryContainer;
  }

  String _statusLabel() {
    if (!rule.active) return 'Inactive';
    return rule.isCurrentlyEffective ? 'Active now' : 'Scheduled';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header row
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: cs.primaryContainer,
                  child: Icon(rule.type.icon, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(rule.name, style: Theme.of(context).textTheme.titleMedium),
                ),
                Switch.adaptive(
                  value: rule.active,
                  onChanged: onToggle,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // info row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(context, _statusLabel(), icon: Icons.bolt),
                _chip(context, 'Type: ${rule.type.label}', icon: Icons.rule_folder),
                _chip(context, 'Scope: ${_scopeText(rule)}', icon: Icons.segment),
                if (rule.type == RuleType.percentageDiscount || rule.type == RuleType.markup)
                  _chip(context, 'Value: ${rule.value.toStringAsFixed(2)}%', icon: Icons.percent),
                if (rule.type == RuleType.fixedDiscount)
                  _chip(context, 'Value: ${rule.value.toStringAsFixed(2)}', icon: Icons.attach_money),
                _chip(context, 'Priority: ${rule.priority}', icon: Icons.low_priority),
                _chip(context, rule.stackable ? 'Stackable' : 'Not stackable', icon: Icons.layers),
                if (rule.perCustomerLimit != null)
                  _chip(context, 'Per-customer: ${rule.perCustomerLimit}', icon: Icons.person),
                if (rule.startDate != null || rule.endDate != null)
                  _chip(
                    context,
                    '${rule.startDate != null ? _d(rule.startDate!) : 'Now'} → ${rule.endDate != null ? _d(rule.endDate!) : 'No end'}',
                    icon: Icons.date_range,
                  ),
                if (rule.startTime != null && rule.endTime != null)
                  _chip(context, '${_t(rule.startTime!)}–${_t(rule.endTime!)}', icon: Icons.schedule),
                if (rule.daysOfWeek.isNotEmpty)
                  _chip(context, _dow(rule.daysOfWeek), icon: Icons.calendar_view_week),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _scopeText(PriceRule r) {
    switch (r.scopeKind) {
      case ScopeKind.all:
        return 'All items';
      case ScopeKind.category:
        return 'Category: ${r.scopeValue}';
      case ScopeKind.product:
        return 'Product: ${r.scopeValue}';
      case ScopeKind.customerGroup:
        return 'Customer Group: ${r.scopeValue}';
    }
  }

  Widget _chip(BuildContext context, String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _chipColor(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 16),
          if (icon != null) const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  String _d(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _t(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  String _dow(Set<int> days) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => names[(d - 1).clamp(0, 6)]).join(',');
  }
}

class _RuleEditorSheet extends StatefulWidget {
  final PriceRule? existing;
  const _RuleEditorSheet({this.existing});

  @override
  State<_RuleEditorSheet> createState() => _RuleEditorSheetState();
}

class _RuleEditorSheetState extends State<_RuleEditorSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  RuleType _type = RuleType.percentageDiscount;
  ScopeKind _scopeKind = ScopeKind.all;
  final TextEditingController _scopeValue = TextEditingController();
  final TextEditingController _value = TextEditingController(text: '10');
  final TextEditingController _priority = TextEditingController(text: '10');
  final TextEditingController _perCustomer = TextEditingController();
  bool _stackable = true;
  bool _active = true;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  DateTime? _startDate;
  DateTime? _endDate;
  final Set<int> _days = {};

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    if (widget.existing != null) {
      final r = widget.existing!;
      _type = r.type;
      _scopeKind = r.scopeKind;
      _scopeValue.text = r.scopeValue;
      _value.text = r.value.toStringAsFixed(2);
      _priority.text = r.priority.toString();
      _stackable = r.stackable;
      _active = r.active;
      _perCustomer.text = r.perCustomerLimit?.toString() ?? '';
      _startTime = r.startTime;
      _endTime = r.endTime;
      _startDate = r.startDate;
      _endDate = r.endDate;
      _days.addAll(r.daysOfWeek);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _scopeValue.dispose();
    _value.dispose();
    _priority.dispose();
    _perCustomer.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final init = isStart ? (_startDate ?? now) : (_endDate ?? now.add(const Duration(days: 7)));
    final res = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (res != null) {
      setState(() {
        if (isStart) {
          _startDate = res;
        } else {
          _endDate = res;
        }
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final init = isStart ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0)) : (_endTime ?? const TimeOfDay(hour: 18, minute: 0));
    final res = await showTimePicker(context: context, initialTime: init);
    if (res != null) {
      setState(() {
        if (isStart) {
          _startTime = res;
        } else {
          _endTime = res;
        }
      });
    }
  }

  void _toggleDay(int d) {
    setState(() {
      if (_days.contains(d)) {
        _days.remove(d);
      } else {
        _days.add(d);
      }
    });
  }

  void _save() {
    if (!_form.currentState!.validate()) return;

    final rule = PriceRule(
      id: widget.existing?.id ?? 'r${Random().nextInt(999999)}',
      name: _name.text.trim(),
      type: _type,
      scopeKind: _scopeKind,
      scopeValue: _scopeKind == ScopeKind.all ? '' : _scopeValue.text.trim(),
      value: double.tryParse(_value.text.trim()) ?? 0,
      stackable: _stackable,
      active: _active,
      priority: int.tryParse(_priority.text.trim()) ?? 10,
      perCustomerLimit: _perCustomer.text.trim().isEmpty ? null : int.tryParse(_perCustomer.text.trim()),
      startDate: _startDate,
      endDate: _endDate,
      startTime: _startTime,
      endTime: _endTime,
      daysOfWeek: _days,
    );

    Navigator.pop(context, rule);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(widget.existing == null ? Icons.add_circle : Icons.edit, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(widget.existing == null ? 'Create Price Rule' : 'Edit Price Rule',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  )
                ],
              ),
              const SizedBox(height: 12),

              // Basics
              _sectionTitle(context, 'Basics'),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Rule name', prefixIcon: Icon(Icons.label_outline)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _dropdown<RuleType>(
                      label: 'Rule type',
                      value: _type,
                      items: RuleType.values,
                      toText: (t) => t.label,
                      icon: Icons.rule,
                      onChanged: (v) => setState(() => _type = v ?? _type),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dropdown<ScopeKind>(
                      label: 'Scope',
                      value: _scopeKind,
                      items: ScopeKind.values,
                      toText: (s) {
                        switch (s) {
                          case ScopeKind.all:
                            return 'All items';
                          case ScopeKind.category:
                            return 'Category';
                          case ScopeKind.product:
                            return 'Product (SKU)';
                          case ScopeKind.customerGroup:
                            return 'Customer group';
                        }
                      },
                      icon: Icons.segment,
                      onChanged: (v) => setState(() => _scopeKind = v ?? _scopeKind),
                    ),
                  ),
                ],
              ),
              if (_scopeKind != ScopeKind.all) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _scopeValue,
                  decoration: InputDecoration(
                    labelText: _scopeKind == ScopeKind.product
                        ? 'Product code / SKU'
                        : _scopeKind == ScopeKind.category
                            ? 'Category'
                            : 'Customer group',
                    prefixIcon: const Icon(Icons.filter_alt),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ],
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _value,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: _type == RuleType.fixedDiscount ? 'Amount' : 'Value (%)',
                        prefixIcon: Icon(_type == RuleType.fixedDiscount ? Icons.attach_money : Icons.percent),
                      ),
                      validator: (v) {
                        final d = double.tryParse((v ?? '').trim());
                        if (d == null) return 'Enter a number';
                        if (_type == RuleType.percentageDiscount || _type == RuleType.markup) {
                          if (d < -100 || d > 100) return 'Must be between -100 and 100';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priority,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Priority (lower runs first)',
                        prefixIcon: Icon(Icons.low_priority),
                      ),
                      validator: (v) => (int.tryParse((v ?? '').trim()) == null) ? 'Enter an integer' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      value: _stackable,
                      onChanged: (v) => setState(() => _stackable = v),
                      title: const Text('Stackable with other rules'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: SwitchListTile(
                      value: _active,
                      onChanged: (v) => setState(() => _active = v),
                      title: const Text('Active'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _perCustomer,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Per-customer limit (optional)',
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 16),
              _sectionTitle(context, 'Schedule (optional)'),
              Row(
                children: [
                  Expanded(
                    child: _inlinePickerButton(
                      context: context,
                      label: 'Start date',
                      value: _startDate == null ? 'Not set' : _fmtDate(_startDate!),
                      icon: Icons.calendar_today,
                      onTap: () => _pickDate(true),
                      onClear: _startDate == null ? null : () => setState(() => _startDate = null),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _inlinePickerButton(
                      context: context,
                      label: 'End date',
                      value: _endDate == null ? 'Not set' : _fmtDate(_endDate!),
                      icon: Icons.event,
                      onTap: () => _pickDate(false),
                      onClear: _endDate == null ? null : () => setState(() => _endDate = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _inlinePickerButton(
                      context: context,
                      label: 'Start time',
                      value: _startTime == null ? 'Not set' : _fmtTime(_startTime!),
                      icon: Icons.access_time,
                      onTap: () => _pickTime(true),
                      onClear: _startTime == null ? null : () => setState(() => _startTime = null),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _inlinePickerButton(
                      context: context,
                      label: 'End time',
                      value: _endTime == null ? 'Not set' : _fmtTime(_endTime!),
                      icon: Icons.schedule,
                      onTap: () => _pickTime(false),
                      onClear: _endTime == null ? null : () => setState(() => _endTime = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (i) {
                  final idx = i + 1; // 1..7
                  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  final selected = _days.contains(idx);
                  return FilterChip(
                    label: Text(names[i]),
                    selected: selected,
                    onSelected: (_) => _toggleDay(idx),
                  );
                }),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('Save rule'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) toText,
    required IconData icon,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(toText(e)))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _inlinePickerButton({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecorator(
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      child: Row(
        children: [
          Expanded(child: Text(value)),
          if (onClear != null)
            IconButton(
              tooltip: 'Clear',
              onPressed: onClear,
              icon: Icon(Icons.clear, color: cs.error),
            ),
          FilledButton.tonal(
            onPressed: onTap,
            child: const Text('Pick'),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _fmtTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
