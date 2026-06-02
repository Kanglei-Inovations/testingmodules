import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Compresses and decompresses SDP payloads for QR transfer.
/// Standard SDPs can exceed QR capacities. We use gzip + base64 to ensure
/// high-density QR compatibility. Offloaded to background isolates to prevent UI jank.
class SdpCompressor {
  static const String _prefix = "NEURAL_SDP:";

  static Future<String> encode(String rawSdp) async {
    try {
      return await compute(_encodeSync, rawSdp);
    } catch (e) {
      // Fallback to raw if compression fails
      return rawSdp;
    }
  }

  static String _encodeSync(String rawSdp) {
    final bytes = utf8.encode(rawSdp);
    final gzipped = gzip.encode(bytes);
    final b64 = base64Encode(gzipped);
    return "$_prefix$b64";
  }

  static bool isCompressed(String data) => data.startsWith(_prefix);

  static Future<String> decode(String compressed) async {
    if (!isCompressed(compressed)) {
      return compressed; // Assume raw JSON if no prefix
    }
    try {
      return await compute(_decodeSync, compressed);
    } catch (e) {
      throw Exception("Failed to decode Neural SDP payload: $e");
    }
  }

  static String _decodeSync(String compressed) {
    final b64 = compressed.replaceFirst(_prefix, "").trim();
    final gzipped = base64Decode(b64);
    final bytes = gzip.decode(gzipped);
    return utf8.decode(bytes);
  }
}
