// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CheckRecordAdapter extends TypeAdapter<CheckRecord> {
  @override
  final int typeId = 3;

  @override
  CheckRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CheckRecord(
      id: fields[0] as String,
      exerciseId: fields[1] as String,
      sessionId: fields[2] as String,
      completedDate: fields[3] as DateTime,
      isDone: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CheckRecord obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.exerciseId)
      ..writeByte(2)
      ..write(obj.sessionId)
      ..writeByte(3)
      ..write(obj.completedDate)
      ..writeByte(4)
      ..write(obj.isDone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
