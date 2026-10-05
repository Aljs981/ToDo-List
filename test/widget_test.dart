import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:to_do_list/main.dart';
import 'package:to_do_list/task.dart';
import 'package:to_do_list/task.g.dart';

void main() {
  late Directory tempDir;

  // Hive needs a real folder, so use a temporary one for tests.
  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
    Hive.registerAdapter(TaskAdapter());
    await Hive.openBox<Task>(boxName);
    await Hive.openBox(statsBoxName);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  // Start every test with an empty box.
  setUp(() async {
    await Hive.box<Task>(boxName).clear();
    await Hive.box(statsBoxName).clear();
  });

  // Make the fake screen tall so the whole form fits without scrolling.
  void useTallScreen(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 2000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('screen shows 7 text boxes and an empty list',
      (WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const MainApp());

    expect(find.byType(TextFormField), findsNWidgets(7));
    expect(find.text('Add to List'), findsOneWidget);
    expect(find.text('No tasks yet.'), findsOneWidget);

    // Both counters start at 0.
    expect(find.text('Added'), findsOneWidget);
    expect(find.text('Deleted'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('shows all 7 values of a task that is already in the box',
      (WidgetTester tester) async {
    useTallScreen(tester);

    // Hive does real file I/O, so it must run inside runAsync.
    await tester.runAsync(() async {
      await Hive.box<Task>(boxName).add(
        Task(
          title: 'Finish networking lab',
          name: 'Kaz',
          age: '20',
          year: '3',
          hobby: 'Coding',
          gender: 'Male',
          date: DateTime(2026, 10, 5),
        ),
      );
    });

    await tester.pumpWidget(const MainApp());

    expect(find.text('Finish networking lab'), findsOneWidget);
    expect(find.text('Name: Kaz'), findsOneWidget);
    expect(find.text('Age: 20'), findsOneWidget);
    expect(find.text('Year: 3'), findsOneWidget);
    expect(find.text('Hobby: Coding'), findsOneWidget);
    expect(find.text('Gender: Male'), findsOneWidget);
    expect(find.text('Date: 2026-10-05'), findsOneWidget);
  });

  testWidgets('empty title shows a validation error',
      (WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const MainApp());

    await tester.tap(find.text('Add to List'));
    await tester.pump();

    expect(find.text('Title cannot be empty'), findsOneWidget);
  });

  testWidgets('Add to List saves the task and shows it',
      (WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const MainApp());

    // The first text box is the title.
    await tester.enterText(find.byType(TextFormField).first, 'Study subnetting');
    await tester.tap(find.text('Add to List'));

    // Give Hive a moment to finish writing to disk.
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Study subnetting'), findsOneWidget);

    // The "Added" counter went from 0 to 1 (the "Deleted" one is still 0).
    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });
}