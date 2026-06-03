import 'dart:convert';
import 'dart:typed_data';

enum PacketType { 
  image_meta, 
  image_chunk, 
  file_meta, 
  file_chunk, 
  text_msg, 
  heartbeat,
  call_request,
  call_accept,
  call_reject,
  call_end,
  call_sdp
}

class TransferPacket {
  final PacketType type;
  final String transferId;
  final String? messageId;
  final String? data; // For text/JSON data
  final Uint8List? binaryData; // For raw binary chunks
  final int? index;
  final int? totalChunks;
  final String? fileName;
  final int? fileSize;
  final int? chunkSize;
  final String? hash;

  TransferPacket({
    required this.type,
    required this.transferId,
    this.messageId,
    this.data,
    this.binaryData,
    this.index,
    this.totalChunks,
    this.fileName,
    this.fileSize,
    this.chunkSize,
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
        if (chunkSize != null) 'chunkSize': chunkSize,
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
        chunkSize: json['chunkSize'],
        hash: json['hash'],
      );

  String encode() => jsonEncode(toJson());

  /// Encodes a binary chunk packet for high-efficiency transfer.
  /// Format: [Type (1B)][TransferId (36B UTF8)][Index (4B BE)][Payload (Remainder)]
  Uint8List encodeBinary() {
    final idBytes = utf8.encode(transferId);
    final totalSize = 1 + 1 + idBytes.length + 4 + (binaryData?.length ?? 0);
    final result = Uint8List(totalSize);
    final data = ByteData.view(result.buffer);

    int offset = 0;
    data.setUint8(offset++, type.index);
    data.setUint8(offset++, idBytes.length);
    result.setRange(offset, offset + idBytes.length, idBytes);
    offset += idBytes.length;
    data.setUint32(offset, index ?? 0, Endian.big);
    offset += 4;
    if (binaryData != null) {
      result.setRange(offset, result.length, binaryData!);
    }
    return result;
  }

  /// Decodes a binary packet.
  factory TransferPacket.decodeBinary(Uint8List bytes) {
    final data = ByteData.view(bytes.buffer);
    int offset = 0;
    final typeIndex = data.getUint8(offset++);
    final idLen = data.getUint8(offset++);
    final transferId = utf8.decode(bytes.sublist(offset, offset + idLen));
    offset += idLen;
    final index = data.getUint32(offset, Endian.big);
    offset += 4;
    final binaryData = bytes.sublist(offset);

    return TransferPacket(
      type: PacketType.values[typeIndex],
      transferId: transferId,
      index: index,
      binaryData: binaryData,
    );
  }
}
