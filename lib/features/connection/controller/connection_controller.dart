import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:isar/isar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' hide MessageType;
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../../models/transfer_packet.dart';
import '../../../services/file_transfer_manager.dart';
import '../../../services/thumbnail_service.dart';
import '../../../utils/sdp_compressor.dart';
import '../../../features/connection/controller/settings_controller.dart';
import '../../../data/collections/message_collection.dart';
import '../../../data/collections/peer_session_collection.dart';
import '../../../data/collections/user_collection.dart';
import '../../../services/database_service.dart';
import '../../../services/sync/sync_engine.dart';
import '../../../services/background_service.dart';
import '../../../services/signaling_service.dart';
import '../../../services/discovery_service.dart';

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
  waitingForResponse // Device A waiting for Device B's answer
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
  final _peerConnection = Rxn<RTCPeerConnection>();
  final _dataChannel = Rxn<RTCDataChannel>();
  final _fileManager = FileTransferManager();
  final _uuid = const Uuid();
  final SettingsController _settings = Get.find<SettingsController>();
  final DatabaseService _db = Get.find<DatabaseService>();
  final SyncEngine _syncEngine = Get.put(SyncEngine());
  final SignalingService _signaling = Get.put(SignalingService());
  final DiscoveryService _discovery = Get.put(DiscoveryService());

  bool _isProcessingSdp = false;

  // Heartbeat & Presence
  Timer? _heartbeatTimer;
  Timer? _presenceMonitor;
  final _lastHeartbeatReceived = Rxn<DateTime>();

  // User Info
  UserCollection? localUser;

  // Observables
  var peerState = PeerState.idle.obs;
  var handshakeStage = HandshakeStage.none.obs;
  var receiveStage = ReceiveStage.none.obs;
  var completionStage = CompletionStage.none.obs;

  var messages = <MessageCollection>[].obs;
  var logs = <String>[].obs;
  var localSdp = "".obs;
  var remoteSdp = "".obs;
  var iceCandidates = <String>[].obs;
  var isSdpReady = false.obs;
  
  // Peer Resume State
  var activePeerSession = Rxn<PeerSessionCollection>();
  var _activePeerIp = Rxn<String>();

  Map<String, dynamic> get _configuration => {
    'iceServers': [
      {'urls': _settings.activeStunUrls}
    ],
    'iceCandidatePoolSize': 10,
  };

  @override
  void onInit() async {
    super.onInit();
    localUser = await _db.getUser();
    _bindMessages();
    _loadLastSession();
    _initPresenceMonitor();

    ever(_settings.activeStunUrls, (_) {
      if (peerState.value == PeerState.idle || peerState.value == PeerState.offline) {
        disposeNode().then((_) => initNode());
      }
    });

    // Start background service when connected
    ever(peerState, (state) {
      if (state == PeerState.connected) {
        Get.find<BackgroundService>().startService();
      } else if (state == PeerState.idle || state == PeerState.offline || state == PeerState.failed) {
        Get.find<BackgroundService>().stopService();
      }
    });

    // Automated Signaling Listeners
    _signaling.onRemoteSdpReceived = (sdp, ip) {
      _activePeerIp.value = ip;
      handleRemoteSdp(sdp);
    };
    
    _discovery.onKnownPeerDiscovered = (peerId, ip) {
      if (peerState.value == PeerState.idle || peerState.value == PeerState.offline) {
        addLog("Auto-Discovery: Initiating link with known node $peerId at $ip");
        _activePeerIp.value = ip;
        createOffer();
      }
    };

    // Auto-send local SDP if we have an active peer IP
    ever(localSdp, (sdp) {
      if (sdp.isNotEmpty && _activePeerIp.value != null) {
        _signaling.sendSdpToPeer(_activePeerIp.value!, sdp);
      }
    });

    initNode();
  }

  @override
  void onClose() {
    _heartbeatTimer?.cancel();
    _presenceMonitor?.cancel();
    _discovery.stopDiscovery();
    disposeNode();
    super.onClose();
  }

  void _bindMessages() async {
    messages.value = await _db.getMessages();
    _db.watchMessagesLazy().listen((_) async {
      messages.value = await _db.getMessages();
    });
  }

  Future<void> _loadLastSession() async {
    final session = await _db.getLastSession();
    if (session != null) {
      activePeerSession.value = session;
      addLog("Restored session metadata for node: ${session.peerId}");
    }
  }

  void addLog(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1].substring(0, 8);
    logs.add("[$timestamp] $message");
    _db.saveLog(message);
    print("DEBUG: $message");
  }

  // --- NODE LIFECYCLE ---

  Future<void> initNode() async {
    if (_peerConnection.value != null) return;
    peerState.value = PeerState.idle;
    
    try {
      _peerConnection.value = await createPeerConnection(_configuration);

      _peerConnection.value!.onIceGatheringState = (state) {
        if (state == RTCIceGatheringState.RTCIceGatheringStateGathering) {
          peerState.value = PeerState.gatheringIce;
          if (handshakeStage.value != HandshakeStage.none && handshakeStage.value.index < HandshakeStage.discovering.index) {
            handshakeStage.value = HandshakeStage.discovering;
          }
        }
        if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
          isSdpReady.value = true;
          if (handshakeStage.value != HandshakeStage.none && handshakeStage.value.index < HandshakeStage.ready.index) {
            handshakeStage.value = HandshakeStage.ready;
          }
          if (receiveStage.value != ReceiveStage.none && receiveStage.value.index < ReceiveStage.ready.index) {
            receiveStage.value = ReceiveStage.ready;
          }
        }
      };

      _peerConnection.value!.onIceCandidate = (candidate) async {
        iceCandidates.add(candidate.candidate ?? "");
        if (handshakeStage.value != HandshakeStage.none && handshakeStage.value.index < HandshakeStage.analyzing.index) {
          handshakeStage.value = HandshakeStage.analyzing;
        }

        RTCSessionDescription? localDescription = await _peerConnection.value!.getLocalDescription();
        if (localDescription != null) {
          localSdp.value = _signaling.prepareSdpForSharing(localDescription);
          if (iceCandidates.length >= 2) {
             isSdpReady.value = true;
             if (handshakeStage.value != HandshakeStage.none && handshakeStage.value.index < HandshakeStage.ready.index) {
               handshakeStage.value = HandshakeStage.ready;
             }
             if (receiveStage.value != ReceiveStage.none && receiveStage.value.index < ReceiveStage.ready.index) {
               receiveStage.value = ReceiveStage.ready;
             }
          }
        }
      };

      _peerConnection.value!.onConnectionState = (state) {
        _handleConnectionStateChange(state);
      };

      _peerConnection.value!.onDataChannel = (channel) {
        _dataChannel.value = channel;
        _setupDataChannel();
      };

      // Start Discovery & Broadcast
      if (localUser != null) {
        _discovery.startBroadcast(localUser!.peerId);
        _discovery.startDiscovery();
      }
    } catch (e) {
      addLog("Node Init Failure: $e");
      peerState.value = PeerState.failed;
    }
  }

  Future<void> disposeNode() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _dataChannel.value?.close();
    await _peerConnection.value?.close();
    _dataChannel.value = null;
    _peerConnection.value = null;
    localSdp.value = "";
    isSdpReady.value = false;
    iceCandidates.clear();
    handshakeStage.value = HandshakeStage.none;
    receiveStage.value = ReceiveStage.none;
    completionStage.value = CompletionStage.none;
  }

  // --- CONNECTION HANDLING ---

  void _handleConnectionStateChange(RTCPeerConnectionState state) {
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        peerState.value = PeerState.connected;
        _handleSuccessfulConnection();
        _startHeartbeat();
        
        // Auto-close for Device B when connection establishes
        if (receiveStage.value == ReceiveStage.ready && completionStage.value == CompletionStage.none) {
          Get.until((route) => route.isFirst);
          Get.snackbar(
            "NEURAL LINK ESTABLISHED",
            "Node synchronized successfully.",
            backgroundColor: const Color(0xFF00FF41).withOpacity(0.5),
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
          receiveStage.value = ReceiveStage.none;
          handshakeStage.value = HandshakeStage.none;
        }
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        peerState.value = PeerState.connecting;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        peerState.value = PeerState.reconnecting;
        _heartbeatTimer?.cancel();
        _heartbeatTimer = null;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        peerState.value = PeerState.offline;
        break;
      default:
        break;
    }
  }

  void _setupDataChannel() {
    if (_dataChannel.value == null) return;

    _dataChannel.value!.onMessage = (message) async {
      try {
        final Map<String, dynamic> json = jsonDecode(message.text);
        if (json['type'] == PacketType.heartbeat.name) {
          _lastHeartbeatReceived.value = DateTime.now();
          if (peerState.value == PeerState.stale || peerState.value == PeerState.reconnecting) {
            peerState.value = PeerState.connected;
          }
          return;
        }
        if (json['type'] == 'db_sync') {
          peerState.value = PeerState.syncing;
          await _syncEngine.processSyncPacket(json['payload']);
          peerState.value = PeerState.connected;
          return;
        }
        final packet = TransferPacket.fromJson(json);
        if (packet.type == PacketType.image_meta || packet.type == PacketType.image_chunk ||
            packet.type == PacketType.file_meta || packet.type == PacketType.file_chunk) {
          final file = await _fileManager.handleIncomingPacket(
            message.text, 
            onProgress: (id, p, msgId) => _updateProgress(id, p, isIncoming: true, type: (packet.type == PacketType.image_meta || packet.type == PacketType.image_chunk) ? MessageType.image : MessageType.file, messageId: msgId)
          );
          if (file != null) {
            String? thumbPath;
            if (ThumbnailService.isVideo(file.path)) {
              thumbPath = await ThumbnailService.generateVideoThumbnail(file.path);
            } else if (ThumbnailService.isPdf(file.path)) {
              thumbPath = await ThumbnailService.generatePdfThumbnail(file.path);
            }
            _updateMessageForTransfer(packet.transferId, imageUrl: thumbPath ?? file.path, filePath: file.path, text: file.path.split(Platform.pathSeparator).last);
          }
        }
      } catch (e) {
        addLog("Data Stream Error: $e");
      }
    };
    
    _dataChannel.value!.onDataChannelState = (state) {
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        peerState.value = PeerState.connected;
        if (localUser != null) {
          _syncEngine.init(localUser!.peerId, (payload) {
            _dataChannel.value?.send(RTCDataChannelMessage(payload));
          });
        }
        _startHeartbeat();
      }
    };
  }

  // --- HEARTBEAT & PRESENCE ---

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (peerState.value == PeerState.connected || peerState.value == PeerState.syncing) {
        _sendHeartbeat();
      }
    });
  }

  void _sendHeartbeat() {
    if (_dataChannel.value?.state == RTCDataChannelState.RTCDataChannelOpen) {
      final packet = {
        "type": PacketType.heartbeat.name,
        "peerId": localUser?.peerId,
        "timestamp": DateTime.now().millisecondsSinceEpoch
      };
      _dataChannel.value?.send(RTCDataChannelMessage(jsonEncode(packet)));
    }
  }

  void _initPresenceMonitor() {
    _presenceMonitor = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (peerState.value == PeerState.idle || peerState.value == PeerState.offline) return;
      final lastSeen = _lastHeartbeatReceived.value;
      if (lastSeen == null) return;
      final diff = DateTime.now().difference(lastSeen).inSeconds;
      if (diff > 60) {
        if (peerState.value != PeerState.offline) {
          peerState.value = PeerState.offline;
        }
      } else if (diff > 30) {
        if (peerState.value != PeerState.stale) {
          peerState.value = PeerState.stale;
        }
      }
    });
  }

  // --- ACTIONS ---

  Future<void> createOffer() async {
    handshakeStage.value = HandshakeStage.initializing;
    await disposeNode();
    await initNode();
    
    peerState.value = PeerState.signaling;
    RTCDataChannelInit init = RTCDataChannelInit();
    _dataChannel.value = await _peerConnection.value!.createDataChannel("chat", init);
    _setupDataChannel();

    handshakeStage.value = HandshakeStage.generating;
    RTCSessionDescription offer = await _peerConnection.value!.createOffer();
    await _peerConnection.value!.setLocalDescription(offer);
  }

  Future<void> handleRemoteSdp(String rawSdp, {Function? onAnswerGenerated}) async {
    if (_isProcessingSdp) return;
    _isProcessingSdp = true;

    try {
      final decoded = SdpCompressor.decode(rawSdp.trim());
      Map<String, dynamic> sdpMap = jsonDecode(decoded);
      final type = sdpMap["type"];
      final sdp = sdpMap["sdp"];

      addLog("Processing remote $type. Current Signaling State: ${_peerConnection.value?.signalingState}");

      if (type == "answer") {
        if (_peerConnection.value?.signalingState != RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
          addLog("Aborting: Received answer while in state ${_peerConnection.value?.signalingState}");
          completionStage.value = CompletionStage.failed;
          return;
        }
        completionStage.value = CompletionStage.verifying;
      } else {
        receiveStage.value = ReceiveStage.receiving;
      }
      
      remoteSdp.value = decoded;
      peerState.value = PeerState.signaling;
      
      await _peerConnection.value!.setRemoteDescription(RTCSessionDescription(sdp, type));
      addLog("Remote description set successfully. State: ${_peerConnection.value?.signalingState}");

      if (type == "offer") {
        receiveStage.value = ReceiveStage.generatingResponse;
        RTCSessionDescription answer = await _peerConnection.value!.createAnswer();
        await _peerConnection.value!.setLocalDescription(answer);
        
        receiveStage.value = ReceiveStage.preparingTunnel;
        receiveStage.value = ReceiveStage.ready;
        if (onAnswerGenerated != null) onAnswerGenerated();
      } else {
        // Device A receiving Answer - Cinematic Handshake
        completionStage.value = CompletionStage.synchronizing;
        await Future.delayed(const Duration(milliseconds: 800));
        
        completionStage.value = CompletionStage.establishing;
        await Future.delayed(const Duration(milliseconds: 800));
        
        completionStage.value = CompletionStage.openingChannel;
        await Future.delayed(const Duration(milliseconds: 800));
        
        completionStage.value = CompletionStage.ready;
        await Future.delayed(const Duration(seconds: 2));
        
        Get.until((route) => route.isFirst);
        
        completionStage.value = CompletionStage.none; 
        handshakeStage.value = HandshakeStage.none;
      }
    } catch (e) {
      addLog("Handshake Error: $e");
      peerState.value = PeerState.failed;
      if (completionStage.value != CompletionStage.none) completionStage.value = CompletionStage.failed;
      if (receiveStage.value != ReceiveStage.none) receiveStage.value = ReceiveStage.failed;
    } finally {
      _isProcessingSdp = false;
    }
  }

  void sendMessage(String text, {MessageType type = MessageType.text}) async {
    if (text.trim().isEmpty || (peerState.value != PeerState.connected && peerState.value != PeerState.syncing)) return;
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
  }

  Future<void> sendImage({ImageSource source = ImageSource.gallery}) async {
    if (peerState.value != PeerState.connected) return;
    final msgId = _uuid.v4();
    await _fileManager.sendImage(
      messageId: msgId,
      source: source,
      sendPacket: (p) => _dataChannel.value?.send(RTCDataChannelMessage(p)),
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
        sendPacket: (p) => _dataChannel.value?.send(RTCDataChannelMessage(p)),
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

    Position position = await Geolocator.getCurrentPosition();
    final locStr = "LAT: ${position.latitude.toStringAsFixed(4)}, LNG: ${position.longitude.toStringAsFixed(4)}";
    sendMessage(locStr, type: MessageType.location);
  }

  Future<void> sendContact() async {
    if (peerState.value != PeerState.connected) return;
    // Mocking contact for now as per "before" logic or simple prompt
    sendMessage("Shared Contact: Node Admin (+91 9481924680)", type: MessageType.contact);
  }

  Future<void> sendCode(String code) async {
    sendMessage(code, type: MessageType.code);
  }

  void _handleSuccessfulConnection() async {
    _lastHeartbeatReceived.value = DateTime.now();
  }

  void _updateProgress(String transferId, double progress, {required bool isIncoming, MessageType type = MessageType.image, String? messageId}) async {
    // 1. Try memory lookup
    var existing = messages.firstWhereOrNull((m) => m.transferId == transferId);
    
    // 2. Try DB lookup (crucial for the first chunk/meta)
    if (existing == null) {
      if (messageId != null) {
        existing = await _db.isar.messageCollections.filter().messageIdEqualTo(messageId).findFirst();
      }
      if (existing == null) {
        existing = await _db.isar.messageCollections.filter().transferIdEqualTo(transferId).findFirst();
      }
    }

    if (existing != null) {
      await _db.isar.writeTxn(() async {
        existing!.progress = progress;
        if (existing!.transferId == null) existing!.transferId = transferId;
        await _db.isar.messageCollections.put(existing!);
      });
    } else {
      final msg = MessageCollection()
        ..messageId = messageId ?? _uuid.v4()
        ..transferId = transferId
        ..type = type
        ..isMe = !isIncoming
        ..timestamp = DateTime.now()
        ..progress = progress
        ..originPeerId = isIncoming ? "peer" : (localUser?.peerId ?? "me")
        ..isSynced = false;
      await _db.saveMessage(msg);
    }
  }

  void _updateMessageForTransfer(String transferId, {String? imageUrl, String? filePath, String? text}) async {
    var existing = messages.firstWhereOrNull((m) => m.transferId == transferId);
    
    if (existing == null) {
      existing = await _db.isar.messageCollections.filter().transferIdEqualTo(transferId).findFirst();
    }

    if (existing != null) {
      await _db.isar.writeTxn(() async {
        existing!.progress = 1.0;
        if (imageUrl != null) existing!.imageUrl = imageUrl;
        if (filePath != null) existing!.filePath = filePath;
        if (text != null) existing!.text = text;
        await _db.isar.messageCollections.put(existing!);
      });
    }
  }

  void reset() async {
    addLog("Emergency Node Reset...");
    await disposeNode();
    messages.clear();
    peerState.value = PeerState.idle;
    await initNode();
  }
}
