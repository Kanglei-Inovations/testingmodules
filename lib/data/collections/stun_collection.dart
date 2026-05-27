import 'package:isar/isar.dart';

part 'stun_collection.g.dart';

@collection
class StunCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String url;

  late bool isEnabled;
  
  // Track latency for speed test
  int? latency;
}
