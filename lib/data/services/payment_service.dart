import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

enum UpiLaunchResult {
  launched,
  unavailable,
  failed,
}

class PaymentService {
  /// Launches UPI payment intent.
  /// [upiId] — recipient UPI ID (e.g., worker@upi)
  /// [name] — payee name shown in UPI app
  /// [amount] — amount in INR
  /// [note] — transaction note
  static Future<UpiLaunchResult> payViaUpi({
    required String upiId,
    required String name,
    required int amount,
    String note = 'LabourLink Payment',
  }) async {
    try {
      final uri = Uri(
        scheme: 'upi',
        host: 'pay',
        queryParameters: {
          'pa': upiId,
          'pn': name,
          'am': amount.toStringAsFixed(2),
          'cu': 'INR',
          'tn': note,
        },
      );
      debugPrint('[PaymentService] payment start uri=$uri');

      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        debugPrint('[PaymentService] No app can handle UPI intent');
        return UpiLaunchResult.unavailable;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return UpiLaunchResult.launched;
    } catch (e) {
      debugPrint('[PaymentService] UPI transaction error: $e');
      return UpiLaunchResult.failed;
    }
  }

  /// Generates a 4-digit numeric OTP string.
  static String generateOtp() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ((now % 9000) + 1000).toString();
  }
}
