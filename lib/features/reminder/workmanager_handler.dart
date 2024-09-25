import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:wellwiz/features/reminder/notification_service.dart';

const String taskName = 'reminderTask';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Get the notification ID, title, and description from inputData
    final int id = inputData!['id'];
    final String title = inputData['title']; // Get title from inputData
    final String description = inputData['description']; // Get description from inputData

    // Create a NotificationService instance
    final notificationService = NotificationService();

    // Show the hardcoded notification with the title and description
    await notificationService.showHardcodedNotification(id, title, description);

    return Future.value(true); // Return true when done
  });
}


