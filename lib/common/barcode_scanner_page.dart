import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A page that opens the camera and scans QR codes / barcodes using
/// `mobile_scanner`. When a code is detected, it returns the value to
/// the previous route via `Navigator.pop(context, code)`.
class BarcodeScannerPage extends StatefulWidget {
  /// Creates a barcode/QR scanner page.
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  /// Controller for the mobile scanner. Kept as a field so it can be disposed.
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
  );

  /// Guards against multiple pops if the callback fires more than once.
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      title: const Text('Scan QR / Barcode'),
      backgroundColor: Colors.black,
    ),
    body: MobileScanner(
      controller: _controller,
      onDetect: (capture) {
        if (_handled) return;

        final List<Barcode> barcodes = capture.barcodes;
        if (barcodes.isEmpty) return;

        final String? code = barcodes.first.rawValue;
        if (code == null || code.isEmpty) return;

        _handled = true;
        _controller.stop();
        Navigator.pop(context, code);
      },
    ),
  );
}
