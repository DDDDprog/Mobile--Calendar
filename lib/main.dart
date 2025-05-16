import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(const CalendarProApp());
}

class CalendarProApp extends StatelessWidget {
  const CalendarProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendar Pro',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const CalendarHomePage(),
    );
  }
}

class CalendarHomePage extends StatefulWidget {
  const CalendarHomePage({super.key});

  @override
  State<CalendarHomePage> createState() => _CalendarHomePageState();
}

class _CalendarHomePageState extends State<CalendarHomePage> {
  late final FlutterLocalNotificationsPlugin _notificationsPlugin;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidInit);

    await _notificationsPlugin.initialize(settings);
  }

  void _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails('calendar_channel', 'Calendar Notifications',
            importance: Importance.max, priority: Priority.high);

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(0, title, body, details);
  }

  void _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('events');
    if (data != null) {
      setState(() {
        _events = Map<String, List<String>>.from(json.decode(data));
      });
    }
  }

  void _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('events', json.encode(_events));
  }

  void _addEvent(DateTime day) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Event'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Event name'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final text = controller.text;
              if (text.isNotEmpty) {
                final key = DateFormat('yyyy-MM-dd').format(day);
                if (_events[key] == null) {
                  _events[key] = [];
                }
                _events[key]!.add(text);
                _saveEvents();
                _showNotification('Event Added', 'Event "$text" added on $key');
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  List<String> _getEventsForDay(DateTime day) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    return _events[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📅 Calendar Pro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.light_mode),
            onPressed: () => setState(() {
              // Toggle theme manually if needed
            }),
          )
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2000),
            lastDay: DateTime.utc(2100),
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) => setState(() => _calendarFormat = format),
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            eventLoader: _getEventsForDay,
          ),
          const SizedBox(height: 8),
          if (_selectedDay != null) ...[
            Text(
              'Events on ${DateFormat.yMMMd().format(_selectedDay!)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ..._getEventsForDay(_selectedDay!).map((e) => ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(e),
                )),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addEvent(_selectedDay!),
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
      ),
    );
  }
}
