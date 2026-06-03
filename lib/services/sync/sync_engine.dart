import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../data/collections/message_collection.dart';
import '../../data/collections/peer_session_collection.dart';
import '../../data/collections/sync_queue_collection.dart';
import '../../features/connection/controller/connection_controller.dart';
import '../../models/sync_packet.dart';
import '../database_service.dart';
import '../notification_service.dart';

class SyncEngine extends GetxService {
  final DatabaseService _db = Get.find<DatabaseService>();
  
  Function(String payload)? onSendData;
  String? _localPeerId;
  bool _isSyncing = false;
  
  static const int batchSize = 100;
  
  final List<StreamSubscription> _subscriptions = [];
  Timer? _queueTimer;

  void init(String localPeerId, Function(String payload) sender) {
    _localPeerId = localPeerId;
    onSendData = sender;
    _startWatching();
    triggerFullSync(); 
    _sendMyProfile();
    processQueue(); // Process any pending operations from previous sessions
  }

  void _startWatching() {
    // Watch for local changes to queue them
    _subscriptions.add(_db.isar.messageCollections.watchLazy().listen((_) => _queueLocalChanges('messages')));
    _subscriptions.add(_db.isar.peerSessionCollections.watchLazy().listen((_) => _queueLocalChanges('peer_sessions')));
    
    // Periodically try to flush the queue if connected
    _queueTimer = Timer.periodic(const Duration(seconds: 30), (_) => processQueue());
  }

  @override
  void onClose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _queueTimer?.cancel();
    super.onClose();
  }

  Future<void> _queueLocalChanges(String collection) async {
    if (_localPeerId == null) return;

    final List<dynamic> unsynced;
    if (collection == 'messages') {
      unsynced = await _db.isar.messageCollections
          .filter()
          .isSyncedEqualTo(false)
          .originPeerIdEqualTo(_localPeerId)
          .findAll();
    } else {
      unsynced = await _db.isar.peerSessionCollections
          .filter()
          .isSyncedEqualTo(false)
          .originPeerIdEqualTo(_localPeerId)
          .findAll();
    }

    if (unsynced.isEmpty) return;

    await _db.isar.writeTxn(() async {
      for (var item in unsynced) {
        final recordId = collection == 'messages' ? item.messageId : item.peerId;
        
        // Check if already in queue
        final existing = await _db.isar.syncQueueCollections
            .filter()
            .recordIdEqualTo(recordId)
            .collectionNameEqualTo(collection)
            .findFirst();

        if (existing == null) {
          final entry = SyncQueueCollection()
            ..targetPeerId = "ALL" // Gossip to everyone
            ..operation = "upsert"
            ..collectionName = collection
            ..recordId = recordId
            ..createdAt = DateTime.now()
            ..retryCount = 0;
          await _db.isar.syncQueueCollections.put(entry);
        }
      }
    });

    processQueue();
  }

  Future<void> processQueue() async {
    if (_isSyncing || onSendData == null || _localPeerId == null) return;
    _isSyncing = true;

    try {
      final queue = await _db.isar.syncQueueCollections
          .where()
          .sortByCreatedAt()
          .limit(batchSize)
          .findAll();

      if (queue.isEmpty) {
        _isSyncing = false;
        return;
      }

      print("[SYNC_ENGINE] Processing ${queue.length} queued operations.");

      for (var entry in queue) {
        bool success = false;
        if (entry.collectionName == 'messages') {
          final msg = await _db.isar.messageCollections
              .filter()
              .messageIdEqualTo(entry.recordId)
              .findFirst();
          if (msg != null) {
            _syncMessage(msg);
            success = true;
          } else {
            success = true; // Record gone, remove from queue
          }
        } else if (entry.collectionName == 'peer_sessions') {
          final session = await _db.isar.peerSessionCollections
              .filter()
              .peerIdEqualTo(entry.recordId)
              .findFirst();
          if (session != null) {
            _syncSession(session);
            success = true;
          } else {
            success = true;
          }
        }

        if (success) {
          await _db.isar.writeTxn(() async {
            await _db.isar.syncQueueCollections.delete(entry.id);
            // Mark as synced in original collection
            if (entry.collectionName == 'messages') {
              final msg = await _db.isar.messageCollections.filter().messageIdEqualTo(entry.recordId).findFirst();
              if (msg != null) {
                msg.isSynced = true;
                await _db.isar.messageCollections.put(msg);
              }
            } else {
               final session = await _db.isar.peerSessionCollections.filter().peerIdEqualTo(entry.recordId).findFirst();
               if (session != null) {
                 session.isSynced = true;
                 await _db.isar.peerSessionCollections.put(session);
               }
            }
          });
        }
      }
    } catch (e) {
      print("[SYNC_ENGINE] Queue processing error: $e");
    } finally {
      _isSyncing = false;
    }
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
    if (_isSyncing || onSendData == null || _localPeerId == null) return;
    
    // For full sync, we ensure everything unsynced is in the queue
    await _queueLocalChanges('messages');
    await _queueLocalChanges('peer_sessions');
    await processQueue();
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

    if (existing == null) {
      try {
        final connController = Get.find<ConnectionController>();
        final senderName = connController.activePeerSession.value?.peerName ?? "New Node";
        Get.find<NotificationService>().showMessageNotification(senderName, msg.text ?? "Received a file");
      } catch (_) {}
    }
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

    try {
      final connController = Get.find<ConnectionController>();
      if (connController.activePeerSession.value?.peerId == pId || connController.activePeerSession.value == null) {
        connController.activePeerSession.value = session;
      }
    } catch (_) {}
  }
}
