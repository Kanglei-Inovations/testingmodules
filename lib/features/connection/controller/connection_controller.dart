import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:isar/isar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' hide MessageType;
import 'package:get/get.dart' hide navigator;
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../../models/transfer_packet.dart';
import '../../../services/file_transfer_manager.dart';
import '../../../services/thumbnail_service.dart';
import 'settings_controller.dart';
import '../../../data/collections/message_collection.dart';
import '../../../data/collections/peer_session_collection.dart';
import '../../../data/collections/user_collection.dart';
import '../../../services/database_service.dart';
import '../../../services/sync/sync_engine.dart';
import '../../../core/network/discovery_manager.dart';
import '../../../core/network/webrtc_manager.dart';
import '../../../core/network/transport_manager.dart';
import '../../../core/network/call_manager.dart';
import '../../../core/network/lan_signaling_provider.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/incoming_call_dialog.dart';
import '../../../pages/call_page.dart';
import '../../../utils/sdp_compressor.dart';

enum DiscoveryMode { manual, lan, global }

enum PeerState {
  idle,
  discovering,
  signaling,
  gatheringIce,
  connecting,
  connected,
  syncing,
  reconnecting,
  stale,
  offline,
  failed,
}

enum HandshakeStage {
  none,
  initializing,    
  discovering,     
  analyzing,       
  generating,      
  ready,
  waitingForResponse
}

enum ReceiveStage {
  none,
  receiving,       
  validating,      
  generatingResponse, 
  preparingTunnel, 
  ready,
  failed            
}

enum CompletionStage {
  none,
  verifying,
  synchronizing,
  establishing,
  openingChannel,
  ready,
  failed
}

class ConnectionController extends GetxController {
  final _uuid = const Uuid();
  final SettingsController _settings = Get.find<SettingsController>();
  final DatabaseService _db = Get.find<DatabaseService>();
  final SyncEngine _syncEngine = Get.find<SyncEngine>();
  final DiscoveryManager _discovery = Get.find<DiscoveryManager>();
  final TransportManager _transport = Get.find<TransportManager>();
  final WebRtcManager _webrtc = Get.find<WebRtcManager>();
  final NotificationService _notifications = Get.find<NotificationService>();
  final CallManager _callManager = Get.find<CallManager>();

  final _fileManager = FileTransferManager();
  
  // Observables
  var peerState = PeerState.idle.obs;
  var discoveryMode = DiscoveryMode.lan.obs;
  var handshakeStage = HandshakeStage.none.obs;
  var receiveStage = ReceiveStage.none.obs;
  var completionStage = CompletionStage.none.obs;
  var networkStatus = "Healthy".obs;

  // Proxy getters for UI compatibility
  RxString get localSdp => _webrtc.localSdp;
  RxBool get isSdpReady => _webrtc.isSdpReady;
  RxString get transportSpeed => _transport.transferSpeed;
  RxString get discoveryStatus => _discovery.discoveryStatus;

  // Call Proxy Getters
  RxBool get isInCall => _callManager.isInCall;
  RxBool get isIncomingCall => _callManager.isIncomingCall;
  RxBool get isVideoCall => _callManager.isVideoCall;
  RxBool get isMuted => _callManager.isMuted;
  RxBool get isCameraOff => _callManager.isCameraOff;
  RxString get remoteCallerName => _callManager.remoteCallerName;
  Rxn<MediaStream> get localStream => _callManager.localStream;
  Rxn<MediaStream> get remoteStream => _callManager.remoteStream;
  RTCVideoRenderer get localRenderer => _callManager.localRenderer;
  RTCVideoRenderer get remoteRenderer => _callManager.remoteRenderer;

  // Local state
  UserCollection? localUser;
  var messages = <MessageCollection>[].obs;
  var logs = <String>[].obs;
  var activePeerSession = Rxn<PeerSessionCollection>();
  var peersFound = 0.obs;
  var checkedNodes = 0.obs;

  Map<String, dynamic> get _configuration => {
    'iceServers': [{'urls': _settings.activeStunUrls}],
    'iceCandidatePoolSize': 10,
  };

  @override
  void onInit() async {
    super.onInit();
    try {
      print("[DEBUG-CTRL] Initializing ConnectionController...");
      localUser = await _db.getUser();
      
      _initManagers();
      _bindMessages();
      _loadLastSession();

      // React to WebRtcManager state changes
      _webrtc.state.listen((state) {
        _updatePeerState(state);
      });

      // React to WebRtcManager handshake helpers
      _webrtc.isSdpReady.listen((ready) {
        if (ready && handshakeStage.value == HandshakeStage.generating) {
          handshakeStage.value = HandshakeStage.ready;
        }
      });

      _discovery.discoveredNodes.listen((nodes) {
        peersFound.value = nodes.length;
        checkedNodes.value = nodes.length * 15 + 3;
      });

      await initNode();
      print("[DEBUG-CTRL] ConnectionController Ready.");
    } catch (e) {
      print("[DEBUG-CTRL] Initialization Error: $e");
    }
  }

  void _initManagers() {
    _webrtc.init(LanSignalingProvider(), _transport, localPeerId: localUser?.peerId);
    
    _discovery.onKnownPeerDiscovered = (peerId, ip) {
      if (peerState.value == PeerState.idle || peerState.value == PeerState.offline) {
        print("[DEBUG-CTRL] Auto-reconnecting to known peer: $peerId at $ip");
        resumeSession(peerId, ip: ip);
      }
    };

    _transport.onSyncPacketReceived = (payload) async {
      peerState.value = PeerState.syncing;
      await _syncEngine.processSyncPacket(jsonDecode(payload));
      peerState.value = PeerState.connected;
    };

    _transport.onCallPacketReceived = (json) => _handleIncomingCallPacket(json);

    _transport.onTransferProgress = (id, p, isIncoming, type, msgId) => 
        _updateProgress(id, p, isIncoming: isIncoming, type: type, messageId: msgId);

    _transport.onTransferComplete = (id, {imageUrl, filePath, text}) => 
        _updateMessageForTransfer(id, imageUrl: imageUrl, filePath: filePath, text: text);

    _transport.lastHeartbeatReceived.listen((_) {
      if (peerState.value == PeerState.stale) peerState.value = PeerState.connected;
    });
  }

  Future<void> resumeSession(String peerId, {String? ip}) async {
    final session = await _db.isar.peerSessionCollections.filter().peerIdEqualTo(peerId).findFirst();
    if (session == null) return;

    print("[DEBUG-CTRL] Attempting to resume session for $peerId");
    peerState.value = PeerState.reconnecting;
    
    // 1. Validate peer availability (if IP is provided, use it)
    final targetIp = ip ?? session.address;
    if (targetIp == null) {
      print("[DEBUG-CTRL] No IP for resumption. Falling back to discovery.");
      startLanDiscovery();
      return;
    }

    // 2. Attempt reconnect
    try {
      addLog("Resuming connection to $peerId...");
      await _webrtc.dispose();
      await initNode();
      
      // Use stored STUN if available
      if (session.activeStunServers != null && session.activeStunServers!.isNotEmpty) {
        // Temporary override of configuration for this attempt
      }

      await _webrtc.createOffer();
      
      // 3. Timeout after 15 seconds
      Timer(const Duration(seconds: 15), () {
        if (peerState.value != PeerState.connected && peerState.value != PeerState.syncing) {
          print("[DEBUG-CTRL] Resumption timed out.");
          if (peerState.value == PeerState.reconnecting) {
            peerState.value = PeerState.failed;
            addLog("Resumption timed out. Fallback required.");
          }
        }
      });
      
    } catch (e) {
      print("[DEBUG-CTRL] Resumption failed: $e");
      peerState.value = PeerState.failed;
    }
  }

  void _updatePeerState(WebRtcState state) {
    switch (state) {
      case WebRtcState.connected: peerState.value = PeerState.connected; break;
      case WebRtcState.connecting: peerState.value = PeerState.connecting; break;
      case WebRtcState.gathering: peerState.value = PeerState.gatheringIce; break;
      case WebRtcState.signaling: peerState.value = PeerState.signaling; break;
      case WebRtcState.reconnecting: peerState.value = PeerState.reconnecting; break;
      case WebRtcState.offline: peerState.value = PeerState.offline; break;
      case WebRtcState.failed: peerState.value = PeerState.failed; break;
      case WebRtcState.idle: peerState.value = PeerState.idle; break;
    }
  }

  Future<void> initNode() async {
    await _webrtc.initialize(_configuration);
    if (localUser != null) {
      _discovery.startBroadcast(localUser!.peerId, localUser!.name ?? "Unknown");
      _discovery.startDiscovery();
    }
  }

  Future<void> createOffer() async {
    handshakeStage.value = HandshakeStage.initializing;
    await _webrtc.dispose();
    await initNode();
    handshakeStage.value = HandshakeStage.generating;
    await _webrtc.createOffer();
  }

  Future<void> handleRemoteSdp(String rawSdp, {Function? onAnswerGenerated}) async {
    if (peerState.value == PeerState.connecting || peerState.value == PeerState.connected) return;
    
    addLog("Processing remote SDP...");
    if (rawSdp.contains('"type":"offer"')) {
      receiveStage.value = ReceiveStage.receiving;
    } else {
      completionStage.value = CompletionStage.verifying;
    }

    await _webrtc.handleRemoteSdp(rawSdp);
    
    if (rawSdp.contains('"type":"offer"')) {
      receiveStage.value = ReceiveStage.ready;
      if (onAnswerGenerated != null) onAnswerGenerated();
    } else {
      completionStage.value = CompletionStage.ready;
      await Future.delayed(const Duration(seconds: 1));
      Get.until((route) => route.isFirst);
      completionStage.value = CompletionStage.none;
    }
  }

  void startLanDiscovery() {
    peersFound.value = 0;
    checkedNodes.value = 0;
    _discovery.startDiscovery();
  }

  void connectToPeer(String peerId, String ip) {
    addLog("Connecting to $peerId at $ip");
    _webrtc.dispose();
    initNode().then((_) => _webrtc.createOffer());
  }

  // --- ACTIONS ---

  void sendMessage(String text, {MessageType type = MessageType.text}) async {
    if (text.trim().isEmpty || peerState.value != PeerState.connected) return;
    final msgId = _uuid.v4();
    final msg = MessageCollection()
      ..messageId = msgId
      ..text = text
      ..type = type
      ..isMe = true
      ..timestamp = DateTime.now()
      ..progress = 1.0
      ..originPeerId = localUser?.peerId ?? "me"
      ..isSynced = false;
    await _db.saveMessage(msg);
    
    final packet = TransferPacket(type: PacketType.text_msg, transferId: _uuid.v4(), messageId: msgId, data: text);
    _transport.sendPacket(packet.encode(), channel: TransportChannel.control);
  }

  Future<void> sendImage({ImageSource source = ImageSource.gallery}) async {
    if (peerState.value != PeerState.connected) return;
    final msgId = _uuid.v4();
    await _fileManager.sendImage(
      messageId: msgId,
      source: source,
      sendPacket: (p, isBinary) => _transport.sendPacket(p, channel: TransportChannel.media, isBinary: isBinary),
      onProgress: (id, p, mId) => _updateProgress(id, p, isIncoming: false, type: MessageType.image, messageId: mId),
    );
  }

  Future<void> sendFile() async {
    if (peerState.value != PeerState.connected) return;
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      String? thumbPath;
      if (ThumbnailService.isVideo(file.path)) {
        thumbPath = await ThumbnailService.generateVideoThumbnail(file.path);
      } else if (ThumbnailService.isPdf(file.path)) {
        thumbPath = await ThumbnailService.generatePdfThumbnail(file.path);
      }
      
      final msgId = _uuid.v4();
      final transferId = await _fileManager.sendFile(
        messageId: msgId,
        file: file,
        sendPacket: (p, isBinary) => _transport.sendPacket(p, channel: TransportChannel.media, isBinary: isBinary),
        onProgress: (id, p, mId) => _updateProgress(id, p, isIncoming: false, type: MessageType.file, messageId: mId),
      );
      
      if (transferId != null) {
        _updateMessageForTransfer(transferId, imageUrl: thumbPath ?? file.path, filePath: file.path, text: file.path.split(Platform.pathSeparator).last);
      }
    }
  }

  Future<void> sendLocation() async {
    if (peerState.value != PeerState.connected) return;
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    Position pos = await Geolocator.getCurrentPosition();
    sendMessage("LAT: ${pos.latitude.toStringAsFixed(4)}, LNG: ${pos.longitude.toStringAsFixed(4)}", type: MessageType.location);
  }

  // --- CALL MEDIA HANDLING ---

  void _handleIncomingCallPacket(Map<String, dynamic> json) async {
    final type = json['type'] as String;
    final wasAlreadyInCall = _callManager.isInCall.value;
    
    _callManager.handleIncomingCallPacket(json);
    
    if (type == PacketType.call_request.name && !wasAlreadyInCall) {
      Get.dialog(const IncomingCallDialog(), barrierDismissible: false);
    } else if (type == PacketType.call_accept.name) {
      Get.to(() => const CallPage());
    } else if (type == PacketType.call_reject.name || type == PacketType.call_end.name) {
      Get.back();
    }
  }

  Future<void> startCall(bool video) async {
    if (peerState.value != PeerState.connected || isInCall.value) return;
    await _callManager.startCall(video, localUser?.name ?? "Unknown");
    Get.to(() => const CallPage());
  }

  Future<void> acceptCall() async {
    Get.back();
    await _callManager.acceptCall();
    Get.to(() => const CallPage());
  }

  void rejectCall() {
    Get.back();
    _callManager.rejectCall();
  }

  void toggleMute() => _callManager.toggleMute();
  void toggleCamera() => _callManager.toggleCamera();

  void endCall() {
    _callManager.endCall();
    Get.back();
  }

  // --- LOGS & DB ---

  void addLog(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1].substring(0, 8);
    logs.add("[$timestamp] $message");
    _db.saveLog(message);
  }

  void _bindMessages() async {
    messages.value = await _db.getMessages();
    _db.watchMessagesLazy().listen((_) async => messages.value = await _db.getMessages());
  }

  Future<void> _loadLastSession() async {
    final session = await _db.getLastSession();
    if (session != null) activePeerSession.value = session;
  }

  void _updateProgress(String id, double p, {required bool isIncoming, MessageType type = MessageType.image, String? messageId}) async {
    var existing = messages.firstWhereOrNull((m) => m.transferId == id) ?? 
                   await _db.isar.messageCollections.filter().transferIdEqualTo(id).findFirst();
    if (existing != null) {
      await _db.isar.writeTxn(() async { existing.progress = p; await _db.isar.messageCollections.put(existing); });
    } else {
      final msg = MessageCollection()..messageId = messageId ?? _uuid.v4()..transferId = id..type = type..isMe = !isIncoming..timestamp = DateTime.now()..progress = p..originPeerId = isIncoming ? "peer" : (localUser?.peerId ?? "me")..isSynced = false;
      await _db.saveMessage(msg);
    }
  }

  void _updateMessageForTransfer(String id, {String? imageUrl, String? filePath, String? text}) async {
    var existing = messages.firstWhereOrNull((m) => m.transferId == id) ?? 
                   await _db.isar.messageCollections.filter().transferIdEqualTo(id).findFirst();
    if (existing != null) {
      await _db.isar.writeTxn(() async { existing.progress = 1.0; if (imageUrl != null) existing.imageUrl = imageUrl; if (filePath != null) existing.filePath = filePath; if (text != null) existing.text = text; await _db.isar.messageCollections.put(existing); });
    }
  }

  void reset() async { addLog("Emergency Node Reset..."); await _webrtc.dispose(); messages.clear(); peerState.value = PeerState.idle; await initNode(); }
  
  @override
  void onClose() { _discovery.stopDiscovery(); _webrtc.dispose(); super.onClose(); }
}
