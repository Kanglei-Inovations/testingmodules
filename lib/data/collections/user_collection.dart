import 'package:isar/isar.dart';

part 'user_collection.g.dart';

@collection
class UserCollection {
  Id id = Isar.autoIncrement;

  late String name;
  late String phone;
  late String address;
  late double latitude;
  late double longitude;
  String? profilePhotoPath;
  
  @Index(unique: true)
  late String peerId;
  
  String? publicKey;
  late DateTime createdAt;
  late DateTime updatedAt;
}
