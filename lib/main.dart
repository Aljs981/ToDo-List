import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'task.dart';
import 'task.g.dart';

const String boxName = 'taskBox';

// A second, tiny box that remembers how many tasks were added and deleted.
const String statsBoxName = 'statsBox';

// ---------------------------------------------------------------------------
// COLOR PALETTE - black and blue
// ---------------------------------------------------------------------------
const Color kBlack = Color(0xFF05070D); // screen background
const Color kSurface = Color(0xFF0D1426); // cards and text boxes
const Color kBlue = Color(0xFF2F80FF); // main blue
const Color kGlow = Color(0xFF4DA3FF); // lighter blue for highlights

// A soft blue glow to put behind things (cards, buttons).
List<BoxShadow> glow({double opacity = 0.35, double blur = 18}) => [
      BoxShadow(
        color: Color.fromRGBO(47, 128, 255, opacity),
        blurRadius: blur,
      ),
    ];

// Blue text glow, used for titles.
const List<Shadow> textGlow = [Shadow(color: kBlue, blurRadius: 14)];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  await Hive.openBox<Task>(boxName);
  await Hive.openBox(statsBoxName);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hive To-Do',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBlack,
        colorScheme: const ColorScheme.dark(
          primary: kBlue,
          secondary: kGlow,
          surface: kSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kBlack,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
        ),
        dividerTheme: const DividerThemeData(
          color: Color.fromRGBO(47, 128, 255, 0.3),
        ),
        // Style for all 7 text boxes.
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kSurface,
          labelStyle: const TextStyle(color: Colors.white60),
          floatingLabelStyle: const TextStyle(color: kGlow),
          hintStyle: const TextStyle(color: Colors.white30),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color.fromRGBO(47, 128, 255, 0.35),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kGlow, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kGlow,
            side: const BorderSide(color: kBlue),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

String formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ---------------------------------------------------------------------------
// HOME SCREEN - the 7 text boxes are on the screen itself (no dialog).
// ---------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();

  // 7 text boxes = 7 controllers.
  final _titleC = TextEditingController();
  final _nameC = TextEditingController();
  final _ageC = TextEditingController();
  final _yearC = TextEditingController();
  final _hobbyC = TextEditingController();
  final _genderC = TextEditingController();
  final _dateC = TextEditingController();

  // null = adding a new task, not null = editing this task.
  Task? _editingTask;

  Box<Task> get box => Hive.box<Task>(boxName);

  // Adds 1 to the 'added' or 'deleted' counter and saves it in Hive.
  void _bump(String key) {
    final stats = Hive.box(statsBoxName);
    final current = stats.get(key, defaultValue: 0) as int;
    stats.put(key, current + 1);
  }

  // A small glowing box showing one number, e.g. "3 / Added".
  Widget _counter(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromRGBO(47, 128, 255, 0.45)),
        boxShadow: glow(opacity: 0.22, blur: 16),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              shadows: textGlow,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _dateC.text = formatDate(DateTime.now());
  }

  @override
  void dispose() {
    _titleC.dispose();
    _nameC.dispose();
    _ageC.dispose();
    _yearC.dispose();
    _hobbyC.dispose();
    _genderC.dispose();
    _dateC.dispose();
    super.dispose();
  }

  // Empties the 7 boxes and goes back to "add" mode.
  void _clearForm() {
    _formKey.currentState?.reset();
    _titleC.clear();
    _nameC.clear();
    _ageC.clear();
    _yearC.clear();
    _hobbyC.clear();
    _genderC.clear();
    _dateC.text = formatDate(DateTime.now());
    _editingTask = null;
  }

  // CREATE or UPDATE, depending on whether we are editing a task.
  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleC.text.trim();
    final name = _nameC.text.trim();
    final age = _ageC.text.trim();
    final year = _yearC.text.trim();
    final hobby = _hobbyC.text.trim();
    final gender = _genderC.text.trim();
    final date = DateTime.parse(_dateC.text.trim());

    final editing = _editingTask;
    if (editing == null) {
      // CREATE
      await box.add(Task(
        title: title,
        name: name,
        age: age,
        year: year,
        hobby: hobby,
        gender: gender,
        date: date,
      ));
      _bump('added');
    } else {
      // UPDATE
      editing.title = title;
      editing.name = name;
      editing.age = age;
      editing.year = year;
      editing.hobby = hobby;
      editing.gender = gender;
      editing.date = date;
      await editing.save();
    }

    if (!mounted) return;
    setState(_clearForm);
  }

  // Tapping a task in the list copies its values back into the 7 boxes.
  void _startEdit(Task task) {
    setState(() {
      _editingTask = task;
      _titleC.text = task.title;
      _nameC.text = task.name;
      _ageC.text = task.age;
      _yearC.text = task.year;
      _hobbyC.text = task.hobby;
      _genderC.text = task.gender;
      _dateC.text = formatDate(task.date);
    });
  }

  // DELETE
  void _deleteTask(Task task) {
    final wasEditing = identical(task, _editingTask);
    task.delete();
    _bump('deleted');
    if (wasEditing) setState(_clearForm);
  }

  // Opens the calendar and puts the chosen date into the Date box.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateC.text.trim()) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _dateC.text = formatDate(picked);
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
      ),
    );
  }

  // One line of text in the list, e.g. "Name: Kaz".
  Widget _line(String label, String value) {
    return Text(
      '$label: ${value.isEmpty ? '-' : value}',
      style: const TextStyle(color: Colors.white70),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editingTask != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Tasks',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            shadows: textGlow,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------- the 7 text boxes ----------------
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _field('Title', _titleC, validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title cannot be empty';
                    }
                    return null;
                  }),
                  _field('Name', _nameC),
                  _field('Age', _ageC, keyboardType: TextInputType.number),
                  _field('Year', _yearC, keyboardType: TextInputType.number),
                  _field('Hobby', _hobbyC),
                  _field('Gender', _genderC),
                  // 7th text box: tap it to pick a date from the calendar.
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _dateC,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        suffixIcon: Icon(Icons.calendar_today, color: kGlow),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ---------------- buttons ----------------
            Row(
              children: [
                Expanded(
                  // The glow sits behind the button.
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: glow(opacity: 0.5, blur: 20),
                    ),
                    child: FilledButton(
                      onPressed: _saveTask,
                      child: Text(isEditing ? 'Update Task' : 'Add to List'),
                    ),
                  ),
                ),
                if (isEditing) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => setState(_clearForm),
                    child: const Text('Cancel'),
                  ),
                ],
              ],
            ),

            // ---------------- counters ----------------
            const SizedBox(height: 20),
            ValueListenableBuilder<Box>(
              valueListenable: Hive.box(statsBoxName).listenable(),
              builder: (context, stats, _) {
                return Row(
                  children: [
                    Expanded(
                      child: _counter(
                        'Added',
                        stats.get('added', defaultValue: 0) as int,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _counter(
                        'Deleted',
                        stats.get('deleted', defaultValue: 0) as int,
                      ),
                    ),
                  ],
                );
              },
            ),

            const Divider(height: 32),
            Text(
              'Your Tasks',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    shadows: textGlow,
                  ),
            ),
            const SizedBox(height: 8),

            // ---------------- the list (READ) ----------------
            // Rebuilds automatically whenever the box changes.
            ValueListenableBuilder<Box<Task>>(
              valueListenable: box.listenable(),
              builder: (context, box, _) {
                final tasks = box.values.toList();

                if (tasks.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No tasks yet.')),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Dismissible(
                      key: ValueKey(task.key),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteTask(task),
                      // Dark card with a thin blue border and a soft glow.
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: kSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color.fromRGBO(47, 128, 255, 0.45),
                          ),
                          boxShadow: glow(opacity: 0.22, blur: 16),
                        ),
                        child: Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            // All 7 values are displayed.
                            title: Text(
                              task.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _line('Name', task.name),
                                  _line('Age', task.age),
                                  _line('Year', task.year),
                                  _line('Hobby', task.hobby),
                                  _line('Gender', task.gender),
                                  _line('Date', formatDate(task.date)),
                                ],
                              ),
                            ),
                            trailing: const Icon(Icons.edit, color: kGlow),
                            onTap: () => _startEdit(task),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
