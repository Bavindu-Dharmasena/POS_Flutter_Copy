import 'package:flutter/material.dart';
import 'widgets.dart';

class ProfitMarginsReportPage extends StatefulWidget {
  const ProfitMarginsReportPage({super.key});

  @override
  State<ProfitMarginsReportPage> createState() => _ProfitMarginsReportPageState();
}

class _ProfitMarginsReportPageState extends State<ProfitMarginsReportPage> {
  String period = 'Day';
  String method = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports • Profit Margins')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            PeriodFilterRow(
              options: const ['Day', 'Month', 'Year'],
              value: period,
              onChanged: (v) => setState(() => period = v),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 12),
                  const Text('Payment:'),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: method,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All')),
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'Card', child: Text('Card')),
                    ],
                    onChanged: (v) => setState(() => method = v ?? 'All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Text('TODO: Show $period profit margins ($method)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
