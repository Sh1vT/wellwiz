import 'package:flutter/material.dart';
import 'package:wellwiz/features/reminder/reminder_model.dart';
import 'reminder_logic.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wellwiz/features/reminder/thoughts_service.dart'; // Import the ThoughtsService

class ReminderPage extends StatefulWidget {
  final String userId;

  const ReminderPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ReminderPageState createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final ReminderLogic _reminderLogic = ReminderLogic();
  final ThoughtsService _thoughtsService = ThoughtsService(); // Instance of ThoughtsService
  List<Reminder> _reminders = [];
  FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _fetchReminders(); // Fetch reminders on init
  }

  Future<void> _fetchReminders() async {
    final reminders = await _reminderLogic.fetchReminders(widget.userId);
    setState(() {
      _reminders = reminders;
    });

    await _reminderLogic.scheduleReminders(_reminders);
  }

  Future<void> _addReminder(String title, String description, DateTime scheduledTime) async {
    await _reminderLogic.addReminder(widget.userId, title, description, scheduledTime);
    _fetchReminders(); // Refresh the reminders list
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    await _reminderLogic.deleteReminder(reminder.id);
    _fetchReminders(); // Refresh the reminders list
  }

  // Function to pick a time and schedule the daily thought notification
  Future<void> _pickTimeAndScheduleDailyThought() async {
  final TimeOfDay? selectedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );

  if (selectedTime != null) {
    // Extract hour and minute from TimeOfDay
    final int hour = selectedTime.hour;
    final int minute = selectedTime.minute;

    // Schedule the daily thought with extracted hour and minute
    await _thoughtsService.scheduleDailyThoughtNotification(hour, minute);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Daily positive thought scheduled for ${selectedTime.format(context)}!")),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop(); // Navigate back
          },
        ),
        backgroundColor: Colors.green.shade400,
        title: const Text(
          'Reminders',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddReminderDialog(),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _reminders.length,
        itemBuilder: (context, index) {
          final reminder = _reminders[index];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color.fromARGB(255, 42, 119, 72),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: const TextStyle(
                            fontFamily: 'Mulish',
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          reminder.description,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 42, 119, 72),
                            fontFamily: 'Mulish',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.yellow.shade700),
                    onPressed: () => _deleteReminder(reminder),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickTimeAndScheduleDailyThought, // Trigger the time picker and scheduling
        child: const Icon(Icons.notifications),
        tooltip: 'Schedule Daily Thought',
      ),
    );
  }

  void _showAddReminderDialog() {
    String title = '';
    String description = '';
    DateTime? scheduledTime;
    TextEditingController titleController = TextEditingController();
    TextEditingController descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Title'),
                controller: titleController,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Description'),
                controller: descController,
              ),
              TextButton(
                child: const Text('Select Date & Time'),
                onPressed: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (selectedDate != null) {
                    final selectedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (selectedTime != null) {
                      scheduledTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                setState(() {
                  title = titleController.text;
                  description = descController.text;
                });
                if (title.isNotEmpty && description.isNotEmpty && scheduledTime != null) {
                  _addReminder(title, description, scheduledTime!);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
