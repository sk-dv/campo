import 'package:hive/hive.dart';

part 'check_record.g.dart';

@HiveType(typeId: 3)
class CheckRecord extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String exerciseId;

  @HiveField(2)
  late String sessionId;

  @HiveField(3)
  late DateTime completedDate;

  @HiveField(4)
  late bool isDone;

  CheckRecord({
    required this.id,
    required this.exerciseId,
    required this.sessionId,
    required this.completedDate,
    required this.isDone,
  });
}
