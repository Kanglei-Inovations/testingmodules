import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../data/collections/message_collection.dart';
import '../../data/collections/peer_session_collection.dart';
import '../../features/connection/controller/connection_controller.dart';
import '../../models/sync_packet.dart';
import '../database_service.dart';

class SyncEngine extends GetxService {
  final DatabaseService _db = Get.find<DatabaseService>();
  
  Function(String payload)? onSendData;
  String? _localPeerId;
  bool _isSyncing = false;

  void init(String localPeerId, Function(String payload) sender) {
    _localPeerId = localPeerId;
    onSendData = sender;
    _startWatching();
    triggerFullSync(); // Initial sync when connection established
    _sendMyProfile();
  }

  void _startWatching() {
    _db.watchMessagesLazy().listen((_) => triggerFullSync());
    _db.watchSessionsLazy().listen((_) => triggerFullSync());
  }

  Future<void> _sendMyProfile() async {
    final user = await _db.getUser();
    if (user == null || onSendData == null || _localPeerId == null) return;
    
    final packet = SyncPacket(
      collection: 'user_profile',
      operation: SyncOperation.upsert,
      data: {
        'peerId': user.peerId,
        'name': user.name,
        'profilePhotoPath': user.profilePhotoPath,
        'address': user.address,
        'latitude': user.latitude,
        'longitude': user.longitude,
      },
      originPeerId: _localPeerId!,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    onSendData!(packet.encode());
  }

  Future<void> triggerFullSync() async {
    // ... rest of triggerFullSync remains same
    if (_isSyncing || onSendData == null || _localPeerId == null) return;
    _isSyncing = true;

    try {
      // 1. Sync unsynced messages created by us
      final unsyncedMessages = await _db.isar.messageCollections
          .filter()
          .isSyncedEqualTo(false)
          .originPeerIdEqualTo(_localPeerId)
          .findAll();

      for (var msg in unsyncedMessages) {
        _syncMessage(msg);
        await _db.isar.writeTxn(() async {
          msg.isSynced = true;
          await _db.isar.messageCollections.put(msg);
        });
      }

      // 2. Sync unsynced peer sessions created/updated by us
      final unsyncedSessions = await _db.isar.peerSessionCollections
          .filter()
          .isSyncedEqualTo(false)
          .originPeerIdEqualTo(_localPeerId)
          .findAll();

      for (var session in unsyncedSessions) {
        _syncSession(session);
        await _db.isar.writeTxn(() async {
          session.isSynced = true;
          await _db.isar.peerSessionCollections.put(session);
        });
      }
    } catch (e) {
      print("DEBUG: [SYNC_ENGINE] Sync error: $e");
    } finally {
      _isSyncing = false;
    }
  }

  void _syncMessage(MessageCollection msg) {
    final packet = SyncPacket(
      collection: 'messages',
      operation: SyncOperation.upsert,
      data: {
        'messageId': msg.messageId,
        'text': msg.text,
        'imageUrl': msg.imageUrl,
        'filePath': msg.filePath,
        'type': msg.type.name,
        'timestamp': msg.timestamp.millisecondsSinceEpoch,
        'isMe': false,
        'transferId': msg.transferId,
        'progress': msg.progress,
      },
      originPeerId: _localPeerId!,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    onSendData!(packet.encode());
  }

  void _syncSession(PeerSessionCollection session) {
    final packet = SyncPacket(
      collection: 'peer_sessions',
      operation: SyncOperation.upsert,
      data: {
        'peerId': session.peerId,
        'peerName': session.peerName,
        'peerPhoto': session.peerPhoto,
        'address': session.address,
        'latitude': session.latitude,
        'longitude': session.longitude,
        'lastConnectedAt': session.lastConnectedAt.millisecondsSinceEpoch,
        'sessionState': session.sessionState.name,
      },
      originPeerId: _localPeerId!,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    onSendData!(packet.encode());
  }

  Future<void> processSyncPacket(Map<String, dynamic> payload) async {
    final packet = SyncPacket.fromJson(payload);
    if (packet.originPeerId == _localPeerId) return;

    if (packet.collection == 'messages') {
      await _handleMessageSync(packet);
    } else if (packet.collection == 'peer_sessions') {
      await _handleSessionSync(packet);
    } else if (packet.collection == 'user_profile') {
      await _handleUserProfileSync(packet);
    }
  }

  Future<void> _handleMessageSync(SyncPacket packet) async {
    final data = packet.data;
    final msgId = data['messageId'];
    final existing = await _db.isar.messageCollections.filter().messageIdEqualTo(msgId).findFirst();
    
    if (existing != null && packet.timestamp <= existing.timestamp.millisecondsSinceEpoch) return;

    final msg = MessageCollection()
      ..id = existing?.id ?? Isar.autoIncrement
      ..messageId = msgId
      ..text = data['text']
      ..imageUrl = data['imageUrl']
      ..filePath = data['filePath']
      ..type = MessageType.values.byName(data['type'])
      ..isMe = false
      ..timestamp = DateTime.fromMillisecondsSinceEpoch(data['timestamp'])
      ..transferId = data['transferId']
      ..progress = data['progress']
      ..originPeerId = packet.originPeerId
      ..isSynced = true;

    await _db.isar.writeTxn(() async {
      await _db.isar.messageCollections.put(msg);
    });
  }

  Future<void> _handleSessionSync(SyncPacket packet) async {
    final data = packet.data;
    final pId = data['peerId'];
    final existing = await _db.isar.peerSessionCollections.filter().peerIdEqualTo(pId).findFirst();

    final session = PeerSessionCollection()
      ..id = existing?.id ?? Isar.autoIncrement
      ..peerId = pId
      ..peerName = data['peerName']
      ..peerPhoto = data['peerPhoto']
      ..address = data['address']
      ..latitude = data['latitude']
      ..longitude = data['longitude']
      ..lastConnectedAt = DateTime.fromMillisecondsSinceEpoch(data['lastConnectedAt'])
      ..lastSeen = DateTime.now()
      ..reconnectEnabled = true
      ..sessionState = SessionState.values.byName(data['sessionState'])
      ..originPeerId = packet.originPeerId
      ..isSynced = true;

    await _db.isar.writeTxn(() async {
      await _db.isar.peerSessionCollections.put(session);
    });
  }

  Future<void> _handleUserProfileSync(SyncPacket packet) async {
    final data = packet.data;
    final pId = data['peerId'];
    final existing = await _db.isar.peerSessionCollections.filter().peerIdEqualTo(pId).findFirst();

    final session = PeerSessionCollection()
      ..id = existing?.id ?? Isar.autoIncrement
      ..peerId = pId
      ..peerName = data['name']
      ..peerPhoto = data['profilePhotoPath']
      ..address = data['address']
      ..latitude = data['latitude']
      ..longitude = data['longitude']
      ..lastConnectedAt = DateTime.now()
      ..lastSeen = DateTime.now()
      ..reconnectEnabled = true
      ..sessionState = SessionState.online
      ..originPeerId = packet.originPeerId
      ..isSynced = true;

    await _db.isar.writeTxn(() async {
      await _db.isar.peerSessionCollections.put(session);
    });

    // Update active session in controller if it matches
    try {
      final connController = Get.find<ConnectionController>();
      if (connController.activePeerSession.value?.peerId == pId || connController.activePeerSession.value == null) {
        connController.activePeerSession.value = session;
      }
    } catch (_) {}
  }
}
