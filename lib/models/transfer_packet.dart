import 'dart:convert';

enum PacketType { image_meta, image_chunk, file_meta, file_chunk, text_msg, heartbeat }

class TransferPacket {
  final PacketType type;
  final String transferId;
  final String? messageId;
  final String? data; // Base64 data for chunks or raw text for messages
  final int? index;
  final int? totalChunks;
  final String? fileName;
  final int? fileSize;
  final String? hash;

  TransferPacket({
    required this.type,
    required this.transferId,
    this.messageId,
    this.data,
    this.index,
    this.totalChunks,
    this.fileName,
    this.fileSize,
    this.hash,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'transferId': transferId,
        if (messageId != null) 'messageId': messageId,
        if (data != null) 'data': data,
        if (index != null) 'index': index,
        if (totalChunks != null) 'totalChunks': totalChunks,
        if (fileName != null) 'fileName': fileName,
        if (fileSize != null) 'fileSize': fileSize,
        if (hash != null) 'hash': hash,
      };

  factory TransferPacket.fromJson(Map<String, dynamic> json) => TransferPacket(
        type: PacketType.values.byName(json['type']),
        transferId: json['transferId'],
        messageId: json['messageId'],
        data: json['data'],
        index: json['index'],
        totalChunks: json['totalChunks'],
        fileName: json['fileName'],
        fileSize: json['fileSize'],
        hash: json['hash'],
      );

  String encode() => jsonEncode(toJson());
}
