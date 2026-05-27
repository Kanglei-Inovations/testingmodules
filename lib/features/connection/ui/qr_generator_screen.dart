import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../utils/sdp_compressor.dart';


class QrGeneratorScreen extends StatelessWidget {
  final String sdpData;

  const QrGeneratorScreen({super.key, required this.sdpData});

  @override
  Widget build(BuildContext context) {
    // Compress data to ensure it fits in the QR safely
    final compressedData = SdpCompressor.encode(sdpData);
    const neonCyan = Color(0xFF00FFFF);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: neonCyan),
        title: const Text(
          "SYNC NODE QR",
          style: TextStyle(
            color: neonCyan,
            letterSpacing: 2,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: neonCyan.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(color: neonCyan.withOpacity(0.2), blurRadius: 20)
                ],
              ),
              child: QrImageView(
                data: compressedData,
                version: QrVersions.auto,
                size: 350.0,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.L,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "SCAN FROM TARGET DEVICE",
              style: TextStyle(
                color: Colors.white70,
                letterSpacing: 3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
