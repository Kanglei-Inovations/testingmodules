import 'dart:convert';
import 'dart:io';

/// Compresses and decompresses SDP payloads for QR transfer.
/// Standard SDPs can exceed QR capacities. We use gzip + base64 to ensure
/// high-density QR compatibility.
class SdpCompressor {
  static const String _prefix = "NEURAL_SDP:";

  static String encode(String rawSdp) {
    try {
      final bytes = utf8.encode(rawSdp);
      final gzipped = gzip.encode(bytes);
      final b64 = base64Encode(gzipped);
      return "$_prefix$b64";
    } catch (e) {
      // Fallback to raw if compression fails
      return rawSdp;
    }
  }

  static bool isCompressed(String data) => data.startsWith(_prefix);

  static String decode(String compressed) {
    if (!isCompressed(compressed)) {
      return compressed; // Assume raw JSON if no prefix
    }
    try {
      final b64 = compressed.replaceFirst(_prefix, "").trim();
      final gzipped = base64Decode(b64);
      final bytes = gzip.decode(gzipped);
      return utf8.decode(bytes);
    } catch (e) {
      throw Exception("Failed to decode Neural SDP payload: $e");
    }
  }
}
