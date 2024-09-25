
import 'package:flutter/material.dart';
import 'package:wellwiz/features/reminder/reminder_model.dart';
import 'reminder_logic.dart';

class ReminderPage extends StatefulWidget {
  final String userId;

  const ReminderPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ReminderPageState createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final ReminderLogic _reminderLogic = ReminderLogic();
  List<Reminder> _reminders = [];

  @override
  void initState() {
    super.initState();
    _fetchReminders(); // Fetch reminders on init
  }

  Future<void> _fetchReminders() async {
    // Fetch reminders from Firestore
    final reminders = await _reminderLogic.fetchReminders(widget.userId);
    setState(() {
      _reminders = reminders;
    });

    // Schedule notifications for each reminder
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
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
          return ListTile(
            title: Text(reminder.title),
            subtitle: Text(reminder.description),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(reminder.scheduledTime.toString()),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteReminder(reminder),
                ),
              ],
            ),
          );
        },
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
                // onChanged: (value) => title = value,
                controller: titleController,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Description'),
                // onChanged: (value) => description = value,
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
                  title=titleController.text;
                  description=descController.text;
                });
                print(title);
                print(description);
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