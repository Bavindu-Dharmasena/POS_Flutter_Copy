import 'package:flutter/material.dart';
import 'widgets.dart';

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  String period = 'Day';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Logs')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            PeriodFilterRow(
              options: const ['Day', 'Week', 'Month', 'Customize'],
              value: period,
              onChanged: (v) => setState(() => period = v),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(child: Text('TODO: Load $period audit logs')),
            ),
          ],
        ),
      ),
    );
  }
}
