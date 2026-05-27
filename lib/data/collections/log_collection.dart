import 'package:isar/isar.dart';

part 'log_collection.g.dart';

@collection
class LogCollection {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime timestamp;

  late String message;
  late String level; // INFO, DEBUG, ERROR
}
