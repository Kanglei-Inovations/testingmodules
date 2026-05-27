import 'package:isar/isar.dart';

part 'peer_collection.g.dart';

@collection
class PeerCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String peerId;

  String? alias;
  late DateTime lastSeen;
  String? lastSdp;
  late bool isBlocked;
}
