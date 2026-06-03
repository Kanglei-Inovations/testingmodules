import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../data/collections/message_collection.dart';
import '../data/collections/peer_collection.dart';
import '../data/collections/log_collection.dart';
import '../data/collections/user_collection.dart';
import '../data/collections/peer_session_collection.dart';
import '../data/collections/stun_collection.dart';
import '../data/collections/sync_queue_collection.dart';

class DatabaseService {
  late Isar isar;

  Future<void> init() async {
    try {
      if (Isar.instanceNames.isNotEmpty) {
        isar = Isar.getInstance()!;
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      isar = await Isar.open(
        [
          MessageCollectionSchema,
          PeerCollectionSchema,
          LogCollectionSchema,
          UserCollectionSchema,
          PeerSessionCollectionSchema,
          StunCollectionSchema,
          SyncQueueCollectionSchema,
        ],
        directory: dir.path,
        inspector: false, // Disabled for production stability
      );
    } catch (e) {
      print("[DATABASE-ERROR] Isar initialization failed: $e");
      rethrow;
    }
  }

  Future<void> pruneData({int daysToKeep = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysToKeep));
    
    await isar.writeTxn(() async {
      final messagesToDelete = await isar.messageCollections
          .filter()
          .timestampLessThan(cutoff)
          .findAll();
      
      final logsToDelete = await isar.logCollections
          .filter()
          .timestampLessThan(cutoff)
          .findAll();
          
      // Also delete physical files for messages being deleted
      for (var msg in messagesToDelete) {
        if (msg.filePath != null) {
          final file = File(msg.filePath!);
          if (await file.exists()) {
            try {
              await file.delete();
            } catch (e) {
              print("[DATABASE-PRUNE] Error deleting file ${msg.filePath}: $e");
            }
          }
        }
      }

      await isar.messageCollections.deleteAll(messagesToDelete.map((e) => e.id).toList());
      await isar.logCollections.deleteAll(logsToDelete.map((e) => e.id).toList());
      
      print("[DATABASE] Pruned ${messagesToDelete.length} messages and ${logsToDelete.length} logs older than $daysToKeep days.");
    });
  }

  // STUN Management
  Future<void> saveStun(StunCollection stun) async {
    await isar.writeTxn(() async {
      await isar.stunCollections.put(stun);
    });
  }

  Future<List<StunCollection>> getStuns() async {
    return await isar.stunCollections.where().findAll();
  }

  Future<void> deleteStun(int id) async {
    await isar.writeTxn(() async {
      await isar.stunCollections.delete(id);
    });
  }

  // User Identity
  Future<UserCollection?> getUser() async {
    return await isar.userCollections.where().findFirst();
  }

  Future<void> saveUser(UserCollection user) async {
    await isar.writeTxn(() async {
      await isar.userCollections.put(user);
    });
  }

  // Peer Sessions
  Future<void> savePeerSession(PeerSessionCollection session) async {
    await isar.writeTxn(() async {
      await isar.peerSessionCollections.putByPeerId(session);
    });
  }

  Future<PeerSessionCollection?> getLastSession() async {
    return await isar.peerSessionCollections.where().sortByLastConnectedAtDesc().findFirst();
  }

  Stream<void> watchSessionsLazy() {
    return isar.peerSessionCollections.watchLazy();
  }

  // Messaging
  Future<void> saveMessage(MessageCollection message) async {
    await isar.writeTxn(() async {
      await isar.messageCollections.put(message);
    });
  }

  Future<List<MessageCollection>> getMessages() async {
    return await isar.messageCollections.where().sortByTimestamp().findAll();
  }

  Stream<void> watchMessagesLazy() {
    return isar.messageCollections.watchLazy();
  }

  Stream<void> watchLogsLazy() {
    return isar.logCollections.watchLazy();
  }

  // Logs
  Future<void> saveLog(String message, {String level = "INFO"}) async {
    await isar.writeTxn(() async {
      final log = LogCollection()
        ..timestamp = DateTime.now()
        ..message = message
        ..level = level;
      await isar.logCollections.put(log);
    });
  }
}
