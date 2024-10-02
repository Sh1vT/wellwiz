import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/features/navbar/navbar.dart';
import 'package:wellwiz/features/reminder/reminder_model.dart';
import 'reminder_logic.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wellwiz/features/reminder/thoughts_service.dart';

class ReminderPage extends StatefulWidget {
  final String userId;

  const ReminderPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ReminderPageState createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final ReminderLogic _reminderLogic = ReminderLogic();
  final ThoughtsService _thoughtsService = ThoughtsService();
  List<Reminder> _reminders = [];
  FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String username = "";
  String userimg = "";

  void _getUserInfo() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      username = pref.getString('username')!;
      userimg = pref.getString('userimg')!;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchReminders();
    _getUserInfo();
  }

  Future<void> _fetchReminders() async {
    final reminders = await _reminderLogic.fetchReminders(widget.userId);
    setState(() {
      _reminders = reminders;
    });

    await _reminderLogic.scheduleReminders(_reminders);
  }

  Future<void> _addReminder(
      String title, String description, DateTime scheduledTime) async {
    await _reminderLogic.addReminder(
        widget.userId, title, description, scheduledTime);
    _fetchReminders();
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    await _reminderLogic.deleteReminder(reminder.id);
    _fetchReminders();
  }

  Future<void> _pickTimeAndScheduleDailyThought() async {
    final TimeOfDay? selectedTime = await showTimePicker(
      helpText: "Choose time for daily positive thoughts!",
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color.fromRGBO(
                106, 172, 67, 1), // Change the primary color to green
            colorScheme: ColorScheme.light(
                primary:
                    Color.fromRGBO(106, 172, 67, 1)), // Change color scheme
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      final int hour = selectedTime.hour;
      final int minute = selectedTime.minute;

      await _thoughtsService.scheduleDailyThoughtNotification(hour, minute);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Daily positive thought scheduled for ${selectedTime.format(context)}!"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Row(
            children: [
              IconButton(
                  onPressed: _pickTimeAndScheduleDailyThought,
                  icon: Icon(Icons.schedule_rounded)),
              SizedBox(
                width: 10,
              )
            ],
          )
        ],
      ),
      drawer: Navbar(
        userId: _auth.currentUser?.uid ?? '',
        username: username,
        userimg: userimg,
      ),
      body: Column(
        children: [
          // Title section
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Your",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mulish',
                    fontSize: 40,
                    color: Color.fromRGBO(106, 172, 67, 1)),
              ),
              Text(
                " Reminders",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mulish',
                    fontSize: 40,
                    color: const Color.fromRGBO(97, 97, 97, 1)),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Container for ListView with a fixed height
          Container(
            height: 120, // Adjust the height as needed
            child: _reminders.isEmpty
                ? Container(
                    margin: const EdgeInsets.all(16),
                    height: 10, // Adjust the height here
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.green.shade100,
                    ),
                    child: const Center(
                      child: Text(
                        'Add some reminders!',
                        style: TextStyle(fontFamily: 'Mulish'),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = _reminders[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: ListTile(
                            trailing: IconButton(
                              icon: Icon(Icons.delete,
                                  color: Colors.grey.shade700),
                              onPressed: () => _deleteReminder(reminder),
                            ),
                            leading: Icon(
                              Icons
                                  .alarm, // Use an appropriate icon for reminders
                              size: 30,
                              color: Color.fromRGBO(106, 172, 67, 1),
                            ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reminder.title,
                                  style: const TextStyle(
                                    fontFamily: 'Mulish',
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.bold, // Added bold for title
                                  ),
                                ),
                                SizedBox(
                                    height:
                                        4), // Spacing between title and description
                                Text(
                                  reminder.description,
                                  style: const TextStyle(
                                    fontFamily: 'Mulish',
                                    fontSize: 14,
                                    color: Colors
                                        .black54, // Lighter color for description
                                  ),
                                ),
                                SizedBox(
                                    height:
                                        4), // Additional spacing for visual clarity
                                Text(
                                  '${DateFormat.yMMMd().add_jm().format(reminder.scheduledTime)}', // Assuming your Reminder model has a scheduledTime field
                                  style: const TextStyle(
                                    fontFamily: 'Mulish',
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Add reminder button
          Padding(
            padding: const EdgeInsets.all(16), // Add padding for better spacing
            child: Container(
              height: 42,
              width: 42,
              child: DottedBorder(
                color: Colors.green.shade500,
                strokeWidth: 1,
                borderType: BorderType.Circle,
                dashPattern: const [8, 4],
                child: IconButton(
                  color: Colors.green.shade500,
                  onPressed: () {
                    _showAddReminderDialog(); // Open dialog to add reminder
                  },
                  icon: const Icon(
                    Icons.add,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
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
                if (title.isNotEmpty &&
                    description.isNotEmpty &&
                    scheduledTime != null) {
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
