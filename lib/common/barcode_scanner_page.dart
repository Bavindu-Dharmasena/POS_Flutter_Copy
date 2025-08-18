import "package:flutter/material.dart";
import "package:mobile_scanner/mobile_scanner.dart";

class BarcodeScannerPage extends StatelessWidget {
  const BarcodeScannerPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      title: const Text("Scan QR / Barcode"),
      backgroundColor: Colors.black,
    ),
    body: MobileScanner(
      controller: MobileScannerController(),
      onDetect: (capture) {
        List<Barcode> barcodes = capture.barcodes;
        if (barcodes.isNotEmpty) {
          String? code = barcodes.first.rawValue;
          if (code != null) {
            Navigator.pop(context, code);
          }
        }
      },
    ),
  );
}
