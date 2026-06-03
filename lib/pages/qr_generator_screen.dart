import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/sdp_compressor.dart';

class QrGeneratorScreen extends StatefulWidget {
  final String sdpData;

  const QrGeneratorScreen({super.key, required this.sdpData});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  String? _compressedData;

  @override
  void initState() {
    super.initState();
    _compressData();
  }

  void _compressData() async {
    final compressed = await SdpCompressor.encode(widget.sdpData);
    if (mounted) {
      setState(() {
        _compressedData = compressed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: neonCyan.withValues(alpha: 0.5), width: 2),
                boxShadow: [
                  BoxShadow(color: neonCyan.withValues(alpha: 0.2), blurRadius: 20)
                ],
              ),
              child: _compressedData == null 
                ? const SizedBox(
                    width: 350, height: 350, 
                    child: Center(child: CircularProgressIndicator(color: neonCyan))
                  )
                : QrImageView(
                    data: _compressedData!,
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
