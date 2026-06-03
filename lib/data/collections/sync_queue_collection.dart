import 'package:isar/isar.dart';

part 'sync_queue_collection.g.dart';

@collection
class SyncQueueCollection {
  Id id = Isar.autoIncrement;

  late String targetPeerId;
  late String operation; // 'put', 'delete'
  late String collectionName;
  late String recordId; // messageId, peerId, etc.
  
  @Index()
  late DateTime createdAt;
  
  int retryCount = 0;
}
