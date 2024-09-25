import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:wellwiz/features/reminder/notification_service.dart';

const String taskName = 'reminderTask';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Get the notification details from inputData
    final int id = inputData!['id'];
    final String title = inputData['title'];
    final String description = inputData['description'];
    final DateTime scheduledTime = DateTime.fromMillisecondsSinceEpoch(inputData['scheduledTime']);

    // Create a NotificationService instance
    final notificationService = NotificationService();

    // Schedule the notification
    await notificationService.scheduleNotification(
      id: id,
      title: title,         // Use only the title
      body: description,    // And the description
      scheduledTime: scheduledTime,
    );

    return Future.value(true); // Return true when done
  });
}

