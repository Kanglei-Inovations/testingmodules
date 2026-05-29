import 'dart:convert';
import 'dart:io';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import '../utils/sdp_compressor.dart';

enum SignalingType { manual, auto }

class SignalingService extends GetxService {
  ServerSocket? _server;
  final int _port = 8888;
  
  Function(String rawSdp, String sourceIp)? onRemoteSdpReceived;

  @override
  void onInit() {
    super.onInit();
    _startSignalingServer();
  }

  @override
  void onClose() {
    _server?.close();
    super.onClose();
  }

  /// Starts a TCP server to listen for automated signaling requests.
  Future<void> _startSignalingServer() async {
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, _port);
      print("DEBUG: Signaling Server active on port $_port");
      _server!.listen((Socket client) {
        final sourceIp = client.remoteAddress.address;
        client.listen((List<int> data) {
          final message = utf8.decode(data);
          print("DEBUG: Received network signal from $sourceIp.");
          if (onRemoteSdpReceived != null) {
            onRemoteSdpReceived!(message, sourceIp);
          }
        }, onDone: () => client.close());
      });
    } catch (e) {
      print("DEBUG: Signaling Server Error: $e");
    }
  }

  /// Sends an SDP to a specific remote IP.
  Future<bool> sendSdpToPeer(String ip, String compressedSdp) async {
    try {
      final socket = await Socket.connect(ip, _port, timeout: const Duration(seconds: 3));
      socket.write(compressedSdp);
      await socket.flush();
      await socket.close();
      print("DEBUG: Dispatched signal to $ip");
      return true;
    } catch (e) {
      print("DEBUG: Failed to send signal to $ip: $e");
      return false;
    }
  }

  /// Compresses a local SDP for transmission.
  String prepareSdpForSharing(RTCSessionDescription description) {
    final sdpJson = jsonEncode({
      "sdp": description.sdp,
      "type": description.type,
    });
    return SdpCompressor.encode(sdpJson);
  }

  /// Decompresses and parses a remote SDP.
  Map<String, dynamic>? parseRemoteSdp(String rawSdp) {
    try {
      final decoded = SdpCompressor.decode(rawSdp.trim());
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      print("Error parsing remote SDP: $e");
      return null;
    }
  }

  /// Validates if an SDP transition is valid for the current signaling state.
  bool isValidTransition(RTCSignalingState? currentState, String remoteType) {
    if (remoteType == "answer") {
      return currentState == RTCSignalingState.RTCSignalingStateHaveLocalOffer;
    }
    return true;
  }
}
