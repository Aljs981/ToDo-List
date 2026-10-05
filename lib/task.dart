import 'package:hive/hive.dart';

// ---------------------------------------------------------------------------
// MODEL - 7 fields, one for each text box on the screen.
// Extending HiveObject gives each task a `key`, plus save() and delete().
// ---------------------------------------------------------------------------
class Task extends HiveObject {
  String title;
  String name;
  String age;
  String year;
  String hobby;
  String gender;
  DateTime date;

  Task({
    required this.title,
    this.name = '',
    this.age = '',
    this.year = '',
    this.hobby = '',
    this.gender = '',
    required this.date,
  });
}
