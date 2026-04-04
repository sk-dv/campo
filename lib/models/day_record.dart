import 'package:hive/hive.dart';

/// Registro informal de un día de actividad (pre-ciclo o general).
/// Se usa para el timeline del historial.
class DayRecord extends HiveObject {
  late String id;
  late DateTime date;
  late String activityType; // partido, correr, futbol_tecnico, fuerza, descanso
  late bool completed;
  late bool partialCompletion;
  late String notes;

  DayRecord({
    required this.id,
    required this.date,
    required this.activityType,
    required this.completed,
    this.partialCompletion = false,
    this.notes = '',
  });
}

class DayRecordAdapter extends TypeAdapter<DayRecord> {
  @override
  final int typeId = 6;

  @override
  DayRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DayRecord(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      activityType: fields[2] as String,
      completed: fields[3] as bool,
      partialCompletion: fields[4] as bool? ?? false,
      notes: fields[5] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, DayRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.activityType)
      ..writeByte(3)
      ..write(obj.completed)
      ..writeByte(4)
      ..write(obj.partialCompletion)
      ..writeByte(5)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
