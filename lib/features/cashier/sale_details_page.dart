import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/cashier/cashier_repository.dart';

class SaleDetailsPage extends StatefulWidget {
  final String saleInvoiceId;
  const SaleDetailsPage({super.key, required this.saleInvoiceId});

  @override
  State<SaleDetailsPage> createState() => _SaleDetailsPageState();
}

class _SaleDetailsPageState extends State<SaleDetailsPage> {
  static final CashierRepository _repo = CashierRepository();

  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getSaleBundleList(widget.saleInvoiceId);
  }

  String _fmtMoney(num v) =>
      NumberFormat.currency(locale: 'en_US', symbol: 'Rs. ').format(v);

  String _fmtDate(int millis) => DateFormat(
    'yyyy-MM-dd • hh:mm a',
  ).format(DateTime.fromMillisecondsSinceEpoch(millis));

  double _sumLineTotals(List<Map<String, dynamic>> items) => items.fold<double>(
    0.0,
    (sum, e) => sum + ((e['line_total'] as num?)?.toDouble() ?? 0.0),
  );

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bill Details'),
          backgroundColor: const Color(0xFF0D1B2A),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }
            final data = snap.data ?? const <Map<String, dynamic>>[];
            if (data.isEmpty) {
              return const Center(child: Text('No details for this bill.'));
            }

            // data[0] is the header; 1..N are items
            final header = data.first;
            final items = data.length > 1
                ? data.sublist(1)
                : <Map<String, dynamic>>[];

            final String saleId = (header['sale_invoice_id'] ?? '').toString();
            final double paymentAmount =
                (header['payment_amount'] as num?)?.toDouble() ?? 0.0;
            final double paymentRemain =
                (header['payment_remain_amount'] as num?)?.toDouble() ?? 0.0;
            final int paymentDate = header['payment_date'] is int
                ? header['payment_date'] as int
                : int.tryParse('${header['payment_date']}') ?? 0;
            final String paymentType = (header['payment_type'] ?? '')
                .toString();
            final String fileName = (header['payment_file_name'] ?? '')
                .toString();
            final String contact = (header['customer_contact'] ?? '')
                .toString();

            final double subtotal = _sumLineTotals(items);
            final double discountValue =
                (header['discount_value'] as num?)?.toDouble() ?? 0.0;
            final String discountType = (header['discount_type'] ?? 'no')
                .toString();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ===== Header / Summary =====
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _listTile('Bill No', saleId),
                        _listTile(
                          'Date',
                          paymentDate > 0 ? _fmtDate(paymentDate) : '-',
                        ),
                        _listTile('Type', paymentType),
                        _listTile('Customer', contact.isEmpty ? '-' : contact),
                        _listTile('File', fileName),
                        const Divider(height: 24),
                        if (discountValue > 0)
                          if (discountType == 'percentage')
                            _listTile(
                              'Overall Discount (%)',
                              _fmtMoney(discountValue),
                            )
                          else
                            _listTile(
                              'Overall Discount (Rs)',
                              _fmtMoney(discountValue),
                          ),
                        _listTile(
                          'Subtotal (items total)',
                          _fmtMoney(subtotal),
                        ),
                        _listTile('Paid Amount', _fmtMoney(paymentAmount)),
                        _listTile('Remain Amount', _fmtMoney(paymentRemain)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 8),

                if (items.isEmpty)
                  const Text(
                    'No items found.',
                    style: TextStyle(color: Colors.white70),
                  )
                else
                  ...items.map((it) {
                    final String name = (it['item_name'] ?? 'Item').toString();
                    final String barcode = (it['item_barcode'] ?? '')
                        .toString();
                    final String batchId = (it['batch_id'] ?? '').toString();

                    final int invoiceId =
                        (it['invoice_id'] as num?)?.toInt() ?? 0;
                    final int itemId = (it['item_id'] as num?)?.toInt() ?? 0;
                    final int qty = (it['quantity'] as num?)?.toInt() ?? 0;

                    final double unitPrice =
                        (it['unit_price'] as num?)?.toDouble() ?? 0.0;
                    final double sellPrice =
                        (it['sell_price'] as num?)?.toDouble() ?? 0.0;
                    final double discount =
                        (it['discount_amount'] as num?)?.toDouble() ?? 0.0;

                    // From invoice.unit_saled_price -> exposed as saled_unit_price
                    final double saledUnitPrice =
                        (it['saled_unit_price'] as num?)?.toDouble() ?? 0.0;

                    // Prefer SQL-calculated values; fallback to computed
                    final double finalUnit =
                        (it['final_unit_price'] as num?)?.toDouble() ??
                        (sellPrice - discount);

                    final double lineTotal =
                        (it['line_total'] as num?)?.toDouble() ??
                        (finalUnit * qty);

                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title row with line total at the end
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.inventory_2),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  _fmtMoney(lineTotal),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Item details list
                            _listTile('Item ID', '$itemId'),
                            _listTile('Qty', '$qty'),
                            _listTile('Batch', batchId),
                            if (barcode.isNotEmpty)
                              _listTile('Barcode', barcode),
                            _listTile(
                              'Saled Unit Price',
                              _fmtMoney(saledUnitPrice),
                            ),
                            _listTile('Sell Price', _fmtMoney(sellPrice)),
                            _listTile(
                              'Promotion Discount',
                              _fmtMoney(discount),
                            ),
                            _listTile('Line Total', _fmtMoney(saledUnitPrice * qty)),

                            // Return Button for each item
                            // const SizedBox(height: 8),
                            // Align(
                            //   alignment: Alignment.center,
                            //   child: ElevatedButton(
                            //     onPressed: () {
                            //       // Handle the item return action here
                            //       // For example, you could navigate back or handle item-specific logic
                            //       ScaffoldMessenger.of(context).showSnackBar(
                            //         SnackBar(
                            //           content: Text('Item $name returned'),
                            //         ),
                            //       );
                            //     },
                            //     style: ElevatedButton.styleFrom(
                            //       backgroundColor:
                            //           const Color.fromARGB(255, 237, 23, 16), // Background color
                            //       foregroundColor: Colors.white, // Text color
                            //     ),
                            //     child: const Text('Return Item'), // Button text
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _listTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
