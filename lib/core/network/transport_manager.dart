import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart' hide MessageType;
import 'package:get/get.dart';
import '../../models/transfer_packet.dart';
import '../../services/file_transfer_manager.dart';
import '../../services/thumbnail_service.dart';
import '../../data/collections/message_collection.dart';
import 'security_manager.dart';

enum TransportChannel { control, sync, media, heartbeat }

class TransportManager extends GetxService {
  // Dedicated Channels
  final _controlChannel = Rxn<RTCDataChannel>();
  final _syncChannel = Rxn<RTCDataChannel>();
  final _mediaChannel = Rxn<RTCDataChannel>();
  final _heartbeatChannel = Rxn<RTCDataChannel>();
  final _fileManager = FileTransferManager();
  
  // Stats
  final transferSpeed = "0 KB/s".obs;
  DateTime? _lastSpeedUpdate;
  int _bytesSinceLastUpdate = 0;
  
  // Heartbeat & Presence
  Timer? _heartbeatTimer;
  final lastHeartbeatReceived = Rxn<DateTime>();
  final peerOnline = false.obs;

  // Flow Control State
  final Map<TransportChannel, bool> _channelPaused = {
    TransportChannel.control: false,
    TransportChannel.sync: false,
    TransportChannel.media: false,
    TransportChannel.heartbeat: false,
  };
  
  static const int maxBufferSize = 8 * 1024 * 1024; // 8MB

  // Handlers
  Function(Map<String, dynamic> json)? onHeartbeatReceived;
  Function(String payload)? onSyncPacketReceived;
  Function(Map<String, dynamic> json)? onCallPacketReceived;
  Function(String transferId, double progress, bool isIncoming, MessageType type, String? messageId)? onTransferProgress;
  Function(String transferId, {String? imageUrl, String? filePath, String? text})? onTransferComplete;

  void setChannel(RTCDataChannel channel) {
    print("[TRANSPORT] Mounting channel: ${channel.label}");
    switch (channel.label) {
      case 'control': _controlChannel.value = channel; break;
      case 'sync': _syncChannel.value = channel; break;
      case 'media': _mediaChannel.value = channel; break;
      case 'heartbeat': _heartbeatChannel.value = channel; break;
      default: 
        print("[TRANSPORT] Unknown channel label: ${channel.label}. Defaulting to control.");
        _controlChannel.value = channel;
    }
    _setupDataChannel(channel);
    
    if (channel.label == 'heartbeat') {
      _startHeartbeat();
    }
  }

  void _setupDataChannel(RTCDataChannel channel) {
    channel.onDataChannelState = (state) {
      print("[TRANSPORT] Channel ${channel.label} state: $state");
      if (channel.label == 'control') {
        peerOnline.value = (state == RTCDataChannelState.RTCDataChannelOpen);
      }
    };

    channel.onBufferedAmountLow = (amount) {
       final type = _getChannelType(channel.label);
       _channelPaused[type] = false;
       print("[TRANSPORT] Channel ${channel.label} buffer cleared. Resuming...");
    };

    channel.onMessage = (message) async {
      try {
        final processedMessage = SecurityManager.decryptPayload(message) as RTCDataChannelMessage;
        if (processedMessage.isBinary) {
          _bytesSinceLastUpdate += processedMessage.binary.length;
          _updateSpeed();
        }
        if (channel.label == 'heartbeat') {
          _handleHeartbeat(processedMessage);
          return;
        }
        
        if (channel.label == 'media') {
          _handleMediaPacket(processedMessage);
          return;
        }

        if (channel.label == 'sync') {
          final Map<String, dynamic> json = jsonDecode(processedMessage.text);
          if (onSyncPacketReceived != null) onSyncPacketReceived!(json['payload']);
          return;
        }

        // Control Channel logic
        if (channel.label == 'control' || !processedMessage.isBinary) {
          final Map<String, dynamic> json = jsonDecode(processedMessage.text);
          final typeStr = json['type'] as String;
          
          if (typeStr.startsWith('call_')) {
            if (onCallPacketReceived != null) onCallPacketReceived!(json);
          } else if (typeStr == PacketType.text_msg.name) {
            // Legacy/Direct routing for control-based text
            _handleControlMessage(json);
          }
        }
      } catch (e) {
        print("[TRANSPORT] Error on channel ${channel.label}: $e");
      }
    };
  }

  void _handleHeartbeat(RTCDataChannelMessage message) {
    lastHeartbeatReceived.value = DateTime.now();
    peerOnline.value = true;
    try {
      final json = jsonDecode(message.text);
      if (onHeartbeatReceived != null) onHeartbeatReceived!(json);
    } catch (_) {}
  }

  void _updateSpeed() {
    final now = DateTime.now();
    if (_lastSpeedUpdate == null) {
      _lastSpeedUpdate = now;
      return;
    }

    final diff = now.difference(_lastSpeedUpdate!).inMilliseconds;
    if (diff > 1000) {
      final speedKbs = (_bytesSinceLastUpdate / 1024) / (diff / 1000);
      transferSpeed.value = speedKbs > 1024 
          ? "${(speedKbs / 1024).toStringAsFixed(2)} MB/s" 
          : "${speedKbs.toStringAsFixed(1)} KB/s";
      
      _bytesSinceLastUpdate = 0;
      _lastSpeedUpdate = now;
    }
  }

  Future<void> _handleMediaPacket(RTCDataChannelMessage message) async {
    final rawData = message.isBinary ? message.binary : message.text;
    final file = await _fileManager.handleIncomingPacket(
      rawData, 
      onProgress: (id, p, msgId) {
        if (onTransferProgress != null) {
          onTransferProgress!(id, p, true, MessageType.file, msgId);
        }
      }
    );

    if (file != null && onTransferComplete != null) {
      final fileName = file.path.split(Platform.pathSeparator).last;
      final transferId = fileName.startsWith('temp_') ? fileName.split('_')[1] : "completed";
      
      String? thumbPath;
      if (ThumbnailService.isVideo(file.path)) {
        thumbPath = await ThumbnailService.generateVideoThumbnail(file.path);
      } else if (ThumbnailService.isPdf(file.path)) {
        thumbPath = await ThumbnailService.generatePdfThumbnail(file.path);
      }
      onTransferComplete!(
        transferId, 
        imageUrl: thumbPath ?? file.path, 
        filePath: file.path, 
        text: file.path.split(Platform.pathSeparator).last
      );
    }
  }

  void _handleControlMessage(Map<String, dynamic> json) {
     // Re-route to UI or Sync if needed
  }

  TransportChannel _getChannelType(String? label) {
    if (label == 'sync') return TransportChannel.sync;
    if (label == 'media') return TransportChannel.media;
    if (label == 'heartbeat') return TransportChannel.heartbeat;
    return TransportChannel.control;
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_heartbeatChannel.value?.state == RTCDataChannelState.RTCDataChannelOpen) {
        final packet = {
          "type": PacketType.heartbeat.name,
          "timestamp": DateTime.now().millisecondsSinceEpoch
        };
        sendPacket(jsonEncode(packet), channel: TransportChannel.heartbeat);
      } else if (peerOnline.value == false) {
        timer.cancel();
      }
    });
  }

  /// Sends a packet with flow control. Returns false if the buffer is full.
  bool sendPacket(dynamic payload, {TransportChannel channel = TransportChannel.control, bool isBinary = false}) {
    final signedPayload = SecurityManager.signPacket(payload);
    final target = _getRTCChannel(channel);
    if (target == null || target.state != RTCDataChannelState.RTCDataChannelOpen) return false;

    // Flow Control: Pause if buffer > 8MB
    if ((target.bufferedAmount ?? 0) > maxBufferSize) {
      _channelPaused[channel] = true;
      print("[TRANSPORT] Channel ${target.label} buffer saturated (${target.bufferedAmount} bytes). Pausing...");
      return false;
    }

    final message = isBinary
        ? RTCDataChannelMessage.fromBinary(signedPayload as Uint8List)
        : RTCDataChannelMessage(signedPayload as String);

    target.send(message);
    return true;
  }

  RTCDataChannel? _getRTCChannel(TransportChannel type) {
    switch (type) {
      case TransportChannel.control: return _controlChannel.value;
      case TransportChannel.sync: return _syncChannel.value;
      case TransportChannel.media: return _mediaChannel.value;
      case TransportChannel.heartbeat: return _heartbeatChannel.value;
    }
  }

  Future<void> close() async {
    _heartbeatTimer?.cancel();
    await _controlChannel.value?.close();
    await _syncChannel.value?.close();
    await _mediaChannel.value?.close();
    await _heartbeatChannel.value?.close();
    _controlChannel.value = null;
    _syncChannel.value = null;
    _mediaChannel.value = null;
    _heartbeatChannel.value = null;
    peerOnline.value = false;
  }
}
