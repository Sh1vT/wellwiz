import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:wellwiz/features/reminder/notification_service.dart';
import 'package:wellwiz/features/reminder/thoughts_service.dart';

const String reminderTaskName = 'reminderTask';
const String thoughtTaskName = 'thoughtTask';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Create NotificationService and ThoughtsService instances
    final notificationService = NotificationService();
    final thoughtsService = ThoughtsService();

    if (task == reminderTaskName) {
      // Handle reminder task
      final int id = inputData!['id'];
      final String title = inputData['title'];
      final String description = inputData['description'];

      // Show the notification for reminders
      await notificationService.showHardcodedNotification(id, title, description);
      
    } else if (task == thoughtTaskName) {
      // Handle thought task
      final thought = await thoughtsService.fetchPositiveThought();

      // Generate a unique ID for the thought notification
      final int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      // Show the notification for thoughts with a fixed title
      await notificationService.showHardcodedNotification(id, "Thought for Today", thought);
    }

    return Future.value(true); // Return true when done
  });
}
