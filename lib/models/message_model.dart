import 'package:uuid/uuid.dart';

enum MessageType { text, image, sync, system }

class MessageModel {
  final String id;
  final String? text;
  final String? imageUrl;
  final MessageType type;
  final bool isMe;
  final DateTime timestamp;
  final String? transferId;
  final double progress; // For transfers

  MessageModel({
    String? id,
    this.text,
    this.imageUrl,
    required this.type,
    required this.isMe,
    DateTime? timestamp,
    this.transferId,
    this.progress = 0.0,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  MessageModel copyWith({
    double? progress,
    String? imageUrl,
    String? text,
  }) {
    return MessageModel(
      id: id,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type,
      isMe: isMe,
      timestamp: timestamp,
      transferId: transferId,
      progress: progress ?? this.progress,
    );
  }
}
