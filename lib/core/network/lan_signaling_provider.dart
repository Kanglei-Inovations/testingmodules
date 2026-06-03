import 'dart:convert';
import 'dart:io';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'signaling_provider.dart';
import '../../utils/sdp_compressor.dart';

class LanSignalingProvider implements SignalingProvider {
  ServerSocket? _server;
  final int _port = 8888;
  
  @override
  Function(String rawSdp, String sourceIp)? onRemoteSdpReceived;

  @override
  Future<void> start() async {
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, _port);
      print("[DEBUG-SIG-LAN] Signaling Server active on port $_port");
      _server!.listen((Socket client) {
        final sourceIp = client.remoteAddress.address;
        print("[DEBUG-SIG-LAN] TCP Connection accepted from: $sourceIp");
        client.listen((List<int> data) {
          final message = utf8.decode(data);
          print("[DEBUG-SIG-LAN] Received SDP data chunk from $sourceIp. Length: ${message.length}");
          if (onRemoteSdpReceived != null) {
            onRemoteSdpReceived!(message, sourceIp);
          }
        }, onDone: () => client.close());
      });
    } catch (e) {
      print("[DEBUG-SIG-LAN] Signaling Server Error: $e");
    }
  }

  @override
  Future<void> stop() async {
    await _server?.close();
    _server = null;
  }

  @override
  Future<bool> sendSdp(String target, String compressedSdp) async {
    print("[DEBUG-SIG-LAN] sendSdp() called. Target IP: $target, Data Length: ${compressedSdp.length}");
    try {
      final socket = await Socket.connect(target, _port, timeout: const Duration(seconds: 3));
      print("[DEBUG-SIG-LAN] Socket connected successfully to $target:$_port");
      socket.write(compressedSdp);
      await socket.flush();
      await socket.close();
      print("[DEBUG-SIG-LAN] Data flushed and socket closed for $target");
      return true;
    } catch (e) {
      print("[DEBUG-SIG-LAN] Failed to send signal to $target: $e");
      return false;
    }
  }

  @override
  Future<String> prepareSdpForSharing(RTCSessionDescription description, {String? peerId}) async {
    final sdpJson = jsonEncode({
      "sdp": description.sdp,
      "type": description.type,
      "originPeerId": peerId,
    });
    return await SdpCompressor.encode(sdpJson);
  }

  @override
  Future<Map<String, dynamic>?> parseRemoteSdp(String rawSdp) async {
    try {
      final decoded = await SdpCompressor.decode(rawSdp.trim());
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      print("[DEBUG-SIG-LAN] Error parsing remote SDP: $e");
      return null;
    }
  }
}
