/// App-wide constants.
///
/// IMPORTANT: Replace [fcmServerKey] with your Firebase Cloud Messaging
/// Legacy Server Key from:
/// Firebase Console → Project Settings → Cloud Messaging → Server Key
///
/// This key is used to send push notifications from the app client.
/// For production, move this to a Cloud Functions backend.
class AppConstants {
  AppConstants._();

  /// FCM Legacy Server Key — replace with your actual key.
  static const String fcmServerKey =
      'YOUR_FCM_SERVER_KEY_HERE';

  /// Google Maps / Directions API key.
  /// Same key as in AndroidManifest.xml and AppDelegate.swift.
  static const String googleMapsApiKey =
      'YOUR_GOOGLE_MAPS_API_KEY_HERE';

  /// FCM endpoint for sending messages.
  static const String fcmEndpoint =
      'https://fcm.googleapis.com/fcm/send';

  /// Walking speed used for ETA estimation (km/h).
  static const double walkingSpeedKmh = 5.0;

  /// Riding speed used for ETA estimation (km/h).
  static const double ridingSpeedKmh = 30.0;
}
