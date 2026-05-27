import 'dart:convert';

enum SyncOperation { upsert, delete }

class SyncPacket {
  final String collection;
  final SyncOperation operation;
  final Map<String, dynamic> data;
  final String originPeerId;
  final int timestamp;

  SyncPacket({
    required this.collection,
    required this.operation,
    required this.data,
    required this.originPeerId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'collection': collection,
        'operation': operation.name,
        'data': data,
        'originPeerId': originPeerId,
        'timestamp': timestamp,
      };

  factory SyncPacket.fromJson(Map<String, dynamic> json) => SyncPacket(
        collection: json['collection'],
        operation: SyncOperation.values.byName(json['operation']),
        data: Map<String, dynamic>.from(json['data']),
        originPeerId: json['originPeerId'],
        timestamp: json['timestamp'],
      );

  String encode() => jsonEncode({'type': 'db_sync', 'payload': toJson()});
}
