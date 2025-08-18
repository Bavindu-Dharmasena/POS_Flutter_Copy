import "package:flutter/material.dart";
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
  );

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
