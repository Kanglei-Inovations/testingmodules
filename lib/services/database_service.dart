import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../data/collections/message_collection.dart';
import '../data/collections/peer_collection.dart';
import '../data/collections/log_collection.dart';
import '../data/collections/user_collection.dart';
import '../data/collections/peer_session_collection.dart';
import '../data/collections/stun_collection.dart';

class DatabaseService {
  late Isar isar;

  Future<void> init() async {
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
      ],
      directory: dir.path,
      inspector: true,
    );
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
