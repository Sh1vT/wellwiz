import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const sendReminderNotifications = functions.pubsub
  .schedule("every 1 minutes")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();

    // Fetch reminders that are due for notification
    const remindersSnapshot = await admin.firestore().collection("reminders")
      .where("scheduledTime", "<=", now)
      .get();

    const promises: Promise<any>[] = []; // Use any if you cannot specify a type

    remindersSnapshot.forEach((doc) => {
      const reminder = doc.data();
      const userId = reminder.userId;
      const title = reminder.title;
      const body = reminder.description;

      // Send notification logic
      const message = {
        notification: {
          title: title,
          body: body,
        },
        topic: userId, // Subscribe users to topics based on userId
      };

      promises.push(
        admin.messaging().send(message)
          .then(() => {
            console.log(`Notification sent to ${userId}: ${title}`);
            return doc.ref.delete();
          })
          .catch((error) => {
            console.error(`Error sending notification to ${userId}:`, error);
          })
      );
    });

    await Promise.all(promises);
    return null;
  });
