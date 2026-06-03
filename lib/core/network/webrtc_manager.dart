import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'signaling_provider.dart';
import 'transport_manager.dart';
import 'package:testingmodules/features/connection/controller/settings_controller.dart';
import 'package:testingmodules/services/database_service.dart';

enum WebRtcState {
  idle,
  gathering,
  signaling,
  connecting,
  connected,
  reconnecting,
  offline,
  failed
}

class WebRtcManager extends GetxService {
  final _peerConnection = Rxn<RTCPeerConnection>();
  final state = WebRtcState.idle.obs;
  
  SignalingProvider? _signalingProvider;
  TransportManager? _transportManager;

  // Handshake State tracking (for UI)
  final localSdp = "".obs;
  final isSdpReady = false.obs;
  final iceCandidates = <String>[].obs;
  
  String? _activePeerIp;
  String? _localPeerId;

  Function(RTCPeerConnectionState state)? onConnectionStateChange;
  Function(MediaStream stream)? onRemoteStreamAdded;

  void init(SignalingProvider signaling, TransportManager transport, {String? localPeerId}) {
    _signalingProvider = signaling;
    _transportManager = transport;
    _localPeerId = localPeerId;
    
    _signalingProvider!.onRemoteSdpReceived = (sdp, ip) {
      print("[WEBRTC] Remote SDP received from $ip");
      _activePeerIp = ip;
      handleRemoteSdp(sdp);
    };
  }

  Future<RTCPeerConnection> initialize(Map<String, dynamic> configuration) async {
    if (_peerConnection.value != null) return _peerConnection.value!;
    
    try {
      _peerConnection.value = await createPeerConnection(configuration);

      _peerConnection.value!.onIceGatheringState = (gatheringState) {
        if (gatheringState == RTCIceGatheringState.RTCIceGatheringStateGathering) {
          state.value = WebRtcState.gathering;
        }
        if (gatheringState == RTCIceGatheringState.RTCIceGatheringStateComplete) {
          isSdpReady.value = true;
        }
      };

      _peerConnection.value!.onIceCandidate = (candidate) async {
        if (candidate.candidate != null) {
          iceCandidates.add(candidate.candidate!);
        }

        RTCSessionDescription? localDescription = await _peerConnection.value!.getLocalDescription();
        if (localDescription != null) {
          localSdp.value = await _signalingProvider!.prepareSdpForSharing(localDescription, peerId: _localPeerId);
          if (iceCandidates.length >= 2) {
             isSdpReady.value = true;
          }
        }
      };

      _peerConnection.value!.onConnectionState = (peerState) {
        _updateStateFromPeerState(peerState);
        if (onConnectionStateChange != null) onConnectionStateChange!(peerState);
      };

      _peerConnection.value!.onDataChannel = (channel) {
        print("[WEBRTC] Remote DataChannel received: ${channel.label}");
        _transportManager?.setChannel(channel);
      };

      _peerConnection.value!.onTrack = (event) {
        if (onRemoteStreamAdded != null && event.streams.isNotEmpty) {
          onRemoteStreamAdded!(event.streams[0]);
        }
      };

      return _peerConnection.value!;
    } catch (e) {
      print("[WEBRTC] PeerConnection Init Error: $e");
      state.value = WebRtcState.failed;
      rethrow;
    }
  }

  void _updateStateFromPeerState(RTCPeerConnectionState peerState) {
    switch (peerState) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        state.value = WebRtcState.connected;
        _reportStunMetrics(true);
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        state.value = WebRtcState.connecting;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        state.value = WebRtcState.reconnecting;
        if (peerState == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
           _reportStunMetrics(false);
        }
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        state.value = WebRtcState.offline;
        break;
      default:
        break;
    }
  }

  void _reportStunMetrics(bool success) {
    try {
      final settings = Get.find<SettingsController>();
      final activeUrls = settings.activeStunUrls;
      for (var url in activeUrls) {
        final stun = settings.stunServers.firstWhereOrNull((s) => s.url == url);
        if (stun != null) {
          if (success) {
            stun.successCount++;
          } else {
            stun.failureCount++;
          }
          stun.lastUsedAt = DateTime.now();
          Get.find<DatabaseService>().saveStun(stun);
        }
      }
    } catch (_) {}
  }

  Future<void> createOffer() async {
    if (_peerConnection.value == null) return;
    
    print("[WEBRTC] Creating local offer with multi-channel lanes...");
    state.value = WebRtcState.signaling;

    // Phase 3: Create 4 Dedicated Lanes
    final channels = ['control', 'sync', 'media', 'heartbeat'];
    for (final label in channels) {
      final init = RTCDataChannelInit()
        ..ordered = true
        ..maxRetransmits = 30; // Reliability over speed for control/sync
      
      if (label == 'media') {
         init.maxRetransmits = 10; // Allow some loss for faster recovery on bulk
      }

      final channel = await _peerConnection.value!.createDataChannel(label, init);
      _transportManager?.setChannel(channel);
    }

    RTCSessionDescription offer = await _peerConnection.value!.createOffer();
    await _peerConnection.value!.setLocalDescription(offer);
  }

  Future<void> handleRemoteSdp(String rawSdp) async {
    if (_peerConnection.value == null) return;

    try {
      final sdpMap = await _signalingProvider!.parseRemoteSdp(rawSdp);
      if (sdpMap == null) return;

      final type = sdpMap["type"];
      final sdp = sdpMap["sdp"];
      final remotePeerId = sdpMap["originPeerId"];

      // Glare Resolution (Polite/Impolite)
      if (type == "offer" && _peerConnection.value?.signalingState == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
        final isPolite = (_localPeerId ?? "").compareTo(remotePeerId ?? "") < 0;
        if (isPolite) {
          print("[WEBRTC] Glare: I am POLITE. Rolling back.");
          await dispose();
          return; 
        } else {
          print("[WEBRTC] Glare: I am IMPOLITE. Ignoring.");
          return;
        }
      }

      await _peerConnection.value!.setRemoteDescription(RTCSessionDescription(sdp, type));

      if (type == "offer") {
        print("[WEBRTC] Generating answer for remote offer...");
        RTCSessionDescription answer = await _peerConnection.value!.createAnswer();
        await _peerConnection.value!.setLocalDescription(answer);
        
        if (_activePeerIp != null) {
          final compressedAnswer = await _signalingProvider!.prepareSdpForSharing(answer, peerId: _localPeerId);
          await _signalingProvider!.sendSdp(_activePeerIp!, compressedAnswer);
        }
      }
    } catch (e) {
      print("[WEBRTC] Remote SDP Error: $e");
    }
  }

  Future<void> addTrack(MediaStreamTrack track, MediaStream stream) async {
    await _peerConnection.value?.addTrack(track, stream);
  }

  Future<RTCSessionDescription?> createOfferForRenegotiation() async {
    final offer = await _peerConnection.value?.createOffer();
    if (offer != null) {
      await _peerConnection.value?.setLocalDescription(offer);
    }
    return offer;
  }

  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    await _peerConnection.value?.setRemoteDescription(description);
  }

  Future<void> setLocalDescription(RTCSessionDescription description) async {
    await _peerConnection.value?.setLocalDescription(description);
  }

  Future<RTCSessionDescription?> createAnswer() async {
    return await _peerConnection.value?.createAnswer();
  }

  Future<void> dispose() async {
    await _peerConnection.value?.close();
    _peerConnection.value = null;
    state.value = WebRtcState.idle;
    localSdp.value = "";
    isSdpReady.value = false;
    iceCandidates.clear();
    _activePeerIp = null;
  }

  RTCPeerConnection? get peerConnection => _peerConnection.value;
}
