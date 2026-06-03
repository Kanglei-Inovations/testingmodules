import 'package:isar/isar.dart';

part 'stun_collection.g.dart';

@collection
class StunCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String url;

  late bool isEnabled;
  
  // Ranking Metrics
  int? latency;
  int successCount = 0;
  int failureCount = 0;
  DateTime? lastUsedAt;
}
