import 'package:hive/hive.dart';

import 'task.dart';

// ---------------------------------------------------------------------------
// ADAPTER (hand-written, so no build_runner / part file is needed)
// Layout in the box: [number of fields] then [field id, value] for each field.
//   0 = title   1 = date (DateTime)   2 = name   3 = age   4 = year
//   5 = hobby   6 = gender
// write() and read() must use the same field ids.
// (title and date keep ids 0 and 1, so tasks saved by the older 2-field
// version of the app still load.)
// ---------------------------------------------------------------------------
class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    // "?? ''" keeps older saved tasks (which had fewer fields) working.
    return Task(
      title: fields[0] as String,
      date: fields[1] as DateTime,
      name: fields[2] as String? ?? '',
      age: fields[3] as String? ?? '',
      year: fields[4] as String? ?? '',
      hobby: fields[5] as String? ?? '',
      gender: fields[6] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(7) // seven fields
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.age)
      ..writeByte(4)
      ..write(obj.year)
      ..writeByte(5)
      ..write(obj.hobby)
      ..writeByte(6)
      ..write(obj.gender);
  }
}
