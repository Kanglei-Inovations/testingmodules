import 'package:flutter_webrtc/flutter_webrtc.dart';

abstract class SignalingProvider {
  Function(String rawSdp, String sourceIp)? onRemoteSdpReceived;
  
  Future<void> start();
  Future<void> stop();
  Future<bool> sendSdp(String target, String compressedSdp);
  
  // Helpers moved from SignalingService
  Future<String> prepareSdpForSharing(RTCSessionDescription description, {String? peerId});
  Future<Map<String, dynamic>?> parseRemoteSdp(String rawSdp);
}
