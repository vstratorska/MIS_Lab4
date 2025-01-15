// location_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocationService {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Initialize notifications
  void initializeNotifications() async {
    AndroidInitializationSettings initializationSettingsAndroid = const AndroidInitializationSettings('app_icon.png');
    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
    onDidReceiveBackgroundNotificationResponse: (NotificationResponse notificationResponse) async {});
  }

  notificationDetails()
  {
    return const NotificationDetails(
      android: AndroidNotificationDetails('exam_reminders', 'Exam Reminders', importance: Importance.max)
    );
  }

  // Show notification
  Future<void> _showNotification(String subject) async {
    return flutterLocalNotificationsPlugin.show(
        0, 'Reminder', 'You are near the $subject exam location!', await notificationDetails());
  }

  // Check proximity to exam location
  Future<void> checkProximityAndNotify(double targetLat, double targetLng, String subject) async {
    Position currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    double distanceInMeters = Geolocator.distanceBetween(currentPosition.latitude, currentPosition.longitude, targetLat, targetLng);
print("TUKAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
    print('Distance to exam: $distanceInMeters meters'); // Log the distance
    // Trigger notification if the user is within 100 meters of the exam location
    if (distanceInMeters < 500) {
      _showNotification(subject);
    }
  }
}
