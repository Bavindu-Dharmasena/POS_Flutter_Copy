import 'package:flutter/material.dart';
import 'widgets.dart';

// Sample audit log model
class AuditLog {
  final String id;
  final String user;
  final String action;
  final String resource;
  final DateTime timestamp;
  final String status;
  final String? details;
  final String ipAddress;

  AuditLog({
    required this.id,
    required this.user,
    required this.action,
    required this.resource,
    required this.timestamp,
    required this.status,
    this.details,
    required this.ipAddress,
  });
}

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  String period = 'Day';
  String searchQuery = '';
  String selectedStatus = 'All';
  String selectedAction = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = false;

  // Sample data - replace with your actual data source
  final List<AuditLog> _allLogs = [
    AuditLog(
      id: '1',
      user: 'john.doe@company.com',
      action: 'LOGIN',
      resource: 'Dashboard',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      status: 'SUCCESS',
      details: 'User logged in successfully',
      ipAddress: '192.168.1.100',
    ),
    AuditLog(
      id: '2',
      user: 'jane.smith@company.com',
      action: 'UPDATE',
      resource: 'User Profile',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      status: 'SUCCESS',
      details: 'Updated profile information',
      ipAddress: '192.168.1.101',
    ),
    AuditLog(
      id: '3',
      user: 'admin@company.com',
      action: 'DELETE',
      resource: 'Document #12345',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      status: 'SUCCESS',
      details: 'Document permanently deleted',
      ipAddress: '192.168.1.102',
    ),
    AuditLog(
      id: '4',
      user: 'user@company.com',
      action: 'LOGIN',
      resource: 'Mobile App',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      status: 'FAILED',
      details: 'Invalid credentials provided',
      ipAddress: '192.168.1.103',
    ),
    AuditLog(
      id: '5',
      user: 'manager@company.com',
      action: 'CREATE',
      resource: 'New Project',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      status: 'SUCCESS',
      details: 'Created project "Q4 Analytics"',
      ipAddress: '192.168.1.104',
    ),
  ];

  List<AuditLog> get filteredLogs {
    return _allLogs.where((log) {
      final matchesSearch = searchQuery.isEmpty ||
          log.user.toLowerCase().contains(searchQuery.toLowerCase()) ||
          log.action.toLowerCase().contains(searchQuery.toLowerCase()) ||
          log.resource.toLowerCase().contains(searchQuery.toLowerCase()) ||
          log.details?.toLowerCase().contains(searchQuery.toLowerCase()) == true;

      final matchesStatus = selectedStatus == 'All' || log.status == selectedStatus;
      final matchesAction = selectedAction == 'All' || log.action == selectedAction;

      return matchesSearch && matchesStatus && matchesAction;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshLogs() {
    setState(() {
      isLoading = true;
    });
    
    // Simulate loading
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  void _exportLogs() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting audit logs...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLogs,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportLogs,
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Period Filter
                PeriodFilterRow(
                  options: const ['Day', 'Week', 'Month', 'Customize'],
                  value: period,
                  onChanged: (v) => setState(() => period = v),
                ),
                const SizedBox(height: 16),
                
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search logs by user, action, or resource...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onChanged: (value) => setState(() => searchQuery = value),
                ),
                const SizedBox(height: 16),
                
                // Status and Action Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        items: ['All', 'SUCCESS', 'FAILED']
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => selectedStatus = value!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedAction,
                        decoration: InputDecoration(
                          labelText: 'Action',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        items: ['All', 'LOGIN', 'UPDATE', 'DELETE', 'CREATE']
                            .map((action) => DropdownMenuItem(
                                  value: action,
                                  child: Text(action),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => selectedAction = value!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Results Summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Showing ${filteredLogs.length} of ${_allLogs.length} logs',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          
          // Logs List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No audit logs found',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters or search criteria',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index];
                          return AuditLogCard(
                            log: log,
                            onTap: () => _showLogDetails(log),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showLogDetails(AuditLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return LogDetailsSheet(log: log, scrollController: scrollController);
        },
      ),
    );
  }
}

class AuditLogCard extends StatelessWidget {
  final AuditLog log;
  final VoidCallback onTap;

  const AuditLogCard({
    super.key,
    required this.log,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getActionIcon(log.action),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${log.action} - ${log.resource}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          log.user,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  _getStatusChip(context, log.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimestamp(log.timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    log.ipAddress,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (log.details != null) ...[
                const SizedBox(height: 8),
                Text(
                  log.details!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _getActionIcon(String action) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getActionColor(action).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(_getActionIconData(action), color: _getActionColor(action), size: 20),
    );
  }



  IconData _getActionIconData(String action) {
    switch (action) {
      case 'LOGIN':
        return Icons.login;
      case 'UPDATE':
        return Icons.edit;
      case 'DELETE':
        return Icons.delete;
      case 'CREATE':
        return Icons.add_circle;
      default:
        return Icons.info;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'LOGIN':
        return Colors.blue;
      case 'UPDATE':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      case 'CREATE':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _getStatusChip(BuildContext context, String status) {
    final isSuccess = status == 'SUCCESS';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

class LogDetailsSheet extends StatelessWidget {
  final AuditLog log;
  final ScrollController scrollController;

  const LogDetailsSheet({
    super.key,
    required this.log,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Audit Log Details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                _buildDetailRow(context, 'ID', log.id),
                _buildDetailRow(context, 'User', log.user),
                _buildDetailRow(context, 'Action', log.action),
                _buildDetailRow(context, 'Resource', log.resource),
                _buildDetailRow(context, 'Status', log.status),
                _buildDetailRow(context, 'IP Address', log.ipAddress),
                _buildDetailRow(context, 'Timestamp', log.timestamp.toString()),
                if (log.details != null)
                  _buildDetailRow(context, 'Details', log.details!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}