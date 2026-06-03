import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
import 'webrtc_manager.dart';
import 'transport_manager.dart';
import 'lan_signaling_provider.dart';
import '../../models/transfer_packet.dart';
import '../../services/notification_service.dart';
import '../../utils/sdp_compressor.dart';
import 'dart:convert';

class CallManager extends GetxService {
  final WebRtcManager _webrtc = Get.find<WebRtcManager>();
  final TransportManager _transport = Get.find<TransportManager>();
  final NotificationService _notifications = Get.find<NotificationService>();

  var isInCall = false.obs;
  var isIncomingCall = false.obs;
  var isVideoCall = false.obs;
  var remoteCallerName = "".obs;
  var isMuted = false.obs;
  var isCameraOff = false.obs;

  final localStream = Rxn<webrtc.MediaStream>();
  final remoteStream = Rxn<webrtc.MediaStream>();
  final webrtc.RTCVideoRenderer localRenderer = webrtc.RTCVideoRenderer();
  final webrtc.RTCVideoRenderer remoteRenderer = webrtc.RTCVideoRenderer();

  Future<void> init() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    
    _webrtc.onRemoteStreamAdded = (stream) {
      remoteStream.value = stream;
      remoteRenderer.srcObject = remoteStream.value;
    };
  }

  void handleIncomingCallPacket(Map<String, dynamic> json) async {
    final type = json['type'] as String;
    if (type == PacketType.call_request.name) {
      if (isInCall.value) { _sendCallPacket(PacketType.call_reject); return; }
      isVideoCall.value = json['data'] == 'video';
      remoteCallerName.value = json['fileName'] ?? "Unknown Node";
      isIncomingCall.value = true;
      _notifications.showCallNotification(remoteCallerName.value, isVideoCall.value);
    } else if (type == PacketType.call_accept.name) {
      _notifications.cancelCallNotification();
      await setupMedia(isVideoCall.value);
      localStream.value?.getTracks().forEach((track) => _webrtc.addTrack(track, localStream.value!));
      _renegotiateCall();
    } else if (type == PacketType.call_reject.name || type == PacketType.call_end.name) {
      _notifications.cancelCallNotification();
      _disposeMedia();
    } else if (type == PacketType.call_sdp.name) {
      final rawSdp = json['data'] as String;
      final decoded = await SdpCompressor.decode(rawSdp.trim());
      Map<String, dynamic> sdpMap = jsonDecode(decoded);
      await _webrtc.setRemoteDescription(webrtc.RTCSessionDescription(sdpMap["sdp"], sdpMap["type"]));
      if (sdpMap["type"] == "offer") {
        final answer = await _webrtc.createAnswer();
        await _webrtc.setLocalDescription(answer!);
        final encodedAnswer = await LanSignalingProvider().prepareSdpForSharing(answer);
        _sendCallPacket(PacketType.call_sdp, data: encodedAnswer);
      }
    }
  }

  void _sendCallPacket(PacketType type, {String? data, String? fileName}) {
    final packet = TransferPacket(type: type, transferId: "call-${DateTime.now().millisecondsSinceEpoch}", data: data, fileName: fileName);
    _transport.sendPacket(packet.encode(), channel: TransportChannel.control);
  }

  Future<void> setupMedia(bool video) async {
    try {
      localStream.value = await webrtc.navigator.mediaDevices.getUserMedia({'audio': true, 'video': video ? {'facingMode': 'user'} : false});
      localRenderer.srcObject = localStream.value;
      isInCall.value = true;
    } catch (e) {
      print("[CALL-MANAGER] Media Error: $e");
    }
  }

  Future<void> _renegotiateCall() async {
    final offer = await _webrtc.createOfferForRenegotiation();
    if (offer != null) {
      final encodedOffer = await LanSignalingProvider().prepareSdpForSharing(offer);
      _sendCallPacket(PacketType.call_sdp, data: encodedOffer);
    }
  }

  void toggleMute() {
    if (localStream.value == null) return;
    isMuted.value = !isMuted.value;
    for (var track in localStream.value!.getAudioTracks()) {
      track.enabled = !isMuted.value;
    }
  }

  void toggleCamera() async {
    if (localStream.value == null) return;
    
    if (!isVideoCall.value) {
      // Switch from Voice to Video (Requires renegotiation)
      isVideoCall.value = true;
      _disposeMedia(); // Reset current stream
      await setupMedia(true);
      localStream.value?.getTracks().forEach((track) => _webrtc.addTrack(track, localStream.value!));
      _renegotiateCall();
      return;
    }

    isCameraOff.value = !isCameraOff.value;
    for (var track in localStream.value!.getVideoTracks()) {
      track.enabled = !isCameraOff.value;
    }
  }

  void _disposeMedia() {
    localStream.value?.getTracks().forEach((track) => track.stop());
    localStream.value?.dispose();
    localStream.value = null;
    remoteStream.value = null;
    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
    isInCall.value = false;
    isIncomingCall.value = false;
    isMuted.value = false;
    isCameraOff.value = false;
  }

  Future<void> startCall(bool video, String localName) async {
    if (isInCall.value) return;
    isVideoCall.value = video;
    _sendCallPacket(PacketType.call_request, data: video ? 'video' : 'voice', fileName: localName);
  }

  void endCall() {
    _disposeMedia();
    _sendCallPacket(PacketType.call_end);
  }

  Future<void> acceptCall() async {
    await setupMedia(isVideoCall.value);
    localStream.value?.getTracks().forEach((track) => _webrtc.addTrack(track, localStream.value!));
    _sendCallPacket(PacketType.call_accept);
  }

  void rejectCall() {
    isIncomingCall.value = false;
    _sendCallPacket(PacketType.call_reject);
  }

  @override
  void onClose() {
    _disposeMedia();
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.onClose();
  }
}
