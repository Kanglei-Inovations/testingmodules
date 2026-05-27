import 'package:isar/isar.dart';

part 'message_collection.g.dart';

@collection
class MessageCollection {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String messageId;

  String? text;
  String? imageUrl;
  String? filePath;
  
  @enumerated
  late MessageType type;

  late bool isMe;

  @Index()
  late DateTime timestamp;

  String? transferId;
  late double progress;

  String? peerId; // Foreign key-like
  String? originPeerId; // Who created this message
  
  DateTime? deliveredAt;
  DateTime? seenAt;

  @Index()
  late bool isSynced;
}

enum MessageType { text, image, file, location, contact, code, sync, system }
