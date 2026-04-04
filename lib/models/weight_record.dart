import 'package:hive/hive.dart';

class WeightRecord extends HiveObject {
  late String id;
  late DateTime date;
  late double weightKg;

  WeightRecord({
    required this.id,
    required this.date,
    required this.weightKg,
  });
}

class WeightRecordAdapter extends TypeAdapter<WeightRecord> {
  @override
  final int typeId = 4;

  @override
  WeightRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeightRecord(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      weightKg: (fields[2] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, WeightRecord obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.weightKg);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeightRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
