import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../utils/notification_helper.dart';
import '../tracking/tracking_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool isScanned = false; // biar tidak scan berkali-kali

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Barcode"),
        backgroundColor: const Color(0xFF624D42),
      ),
      body: MobileScanner(
        onDetect: (barcodeCapture) {
          if (isScanned) return;

          final List<Barcode> barcodes = barcodeCapture.barcodes;

          if (barcodes.isNotEmpty) {
            final String? code = barcodes.first.rawValue;

            if (code != null) {
              isScanned = true;

              // tampilkan hasil scan
              NotificationHelper.show(context, "Kode: $code", isError: false);

              // pindah ke tracking
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrackingPage(),
                ),
              );
            }
          }
        },
      ),
    );
  }
}