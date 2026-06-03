import 'package:isar/isar.dart';

part 'peer_session_collection.g.dart';

@collection
class PeerSessionCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String peerId;
  
  String? peerName;
  String? peerPhoto;
  String? address;
  double? latitude;
  double? longitude;
  late DateTime lastConnectedAt;
  double? lastKnownSignal;
  late bool reconnectEnabled;
  late DateTime lastSeen;
  String? lastSdp;
  String? connectionMethod; // 'lan', 'manual', 'global'
  String? lastSignalState;
  List<String>? activeStunServers;
  
  @enumerated
  late SessionState sessionState;

  String? originPeerId;
  late bool isSynced;
}

enum SessionState { online, lastSeen, reconnecting, offline, unknown }
