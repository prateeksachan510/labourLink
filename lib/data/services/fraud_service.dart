import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:labour_link/core/constants/firebase_paths.dart';
import 'package:labour_link/data/services/firebase_service.dart';
import 'package:uuid/uuid.dart';

/// Rate-limiting, cooldown checks, and fraud logging.
/// Logs are stored at FraudLogs/{uid}/{logId} per spec.
class FraudService {
  FraudService._();

  static DatabaseReference get _logsRoot =>
      FirebaseService.db.ref(FirebasePaths.fraudLogs);

  static DatabaseReference get _usersRef =>
      FirebaseService.db.ref(FirebasePaths.users);

  // ── Cooldown ──────────────────────────────────────────────────────────────

  static Future<bool> isInCooldown(
    String userId,
    String action, {
    int cooldownMs = 60000,
  }) async {
    try {
      final snap = await FirebaseService.db
          .ref('${FirebasePaths.users}/$userId/lastAction_$action')
          .get();
      if (!snap.exists || snap.value == null) return false;
      final lastMs = int.tryParse(snap.value.toString()) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final inCooldown = (nowMs - lastMs) < cooldownMs;
      debugPrint(
        '[FraudService] isInCooldown userId=$userId action=$action '
        'diff=${nowMs - lastMs}ms cooldown=${cooldownMs}ms → $inCooldown',
      );
      return inCooldown;
    } catch (e) {
      debugPrint('[FraudService] isInCooldown error: $e');
      return false;
    }
  }

  static Future<void> stampAction(String userId, String action) async {
    try {
      await FirebaseService.db
          .ref('${FirebasePaths.users}/$userId/lastAction_$action')
          .set(DateTime.now().millisecondsSinceEpoch);
      debugPrint('[FraudService] stampAction userId=$userId action=$action');
    } catch (e) {
      debugPrint('[FraudService] stampAction error: $e');
    }
  }

  // ── Count-based limits ────────────────────────────────────────────────────

  static Future<int> countRecentActions(
    String userId,
    String action, {
    int windowMs = 86400000,
  }) async {
    try {
      final cutoff = DateTime.now().millisecondsSinceEpoch - windowMs;
      final snap = await _logsRoot.child(userId).get();
      if (!snap.exists || snap.value == null) return 0;
      final map = (snap.value as Map).cast<Object?, Object?>();
      int count = 0;
      for (final entry in map.values) {
        if (entry is! Map) continue;
        final m = entry.cast<Object?, Object?>();
        final ts =
            int.tryParse((m['timestamp'] ?? '0').toString()) ?? 0;
        final act = (m['action'] ?? '').toString();
        if (act == action && ts >= cutoff) count++;
      }
      debugPrint(
        '[FraudService] countRecentActions userId=$userId action=$action '
        'window=${windowMs}ms → $count',
      );
      return count;
    } catch (e) {
      debugPrint('[FraudService] countRecentActions error: $e');
      return 0;
    }
  }

  // ── OTP attempt tracking ──────────────────────────────────────────────────

  static Future<bool> recordOtpAttempt({
    required String userId,
    required String jobId,
    required bool success,
    int maxAttempts = 5,
    int windowMs = 3600000,
  }) async {
    try {
      if (success) {
        await FirebaseService.db
            .ref('${FirebasePaths.users}/$userId/otpAttempts_$jobId')
            .remove();
        return true;
      }

      final attemptKey = 'otpAttempts_$jobId';
      final ref =
          FirebaseService.db.ref('${FirebasePaths.users}/$userId/$attemptKey');
      final snap = await ref.get();
      int count = 0;
      int firstMs = DateTime.now().millisecondsSinceEpoch;

      if (snap.exists && snap.value is Map) {
        final m = (snap.value as Map).cast<Object?, Object?>();
        count = int.tryParse((m['count'] ?? '0').toString()) ?? 0;
        firstMs =
            int.tryParse((m['firstAt'] ?? '0').toString()) ?? firstMs;
      }

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (nowMs - firstMs > windowMs) {
        count = 0;
        firstMs = nowMs;
      }

      count++;
      await ref.set({'count': count, 'firstAt': firstMs});

      if (count >= maxAttempts) {
        debugPrint(
          '[FraudService] OTP max attempts reached userId=$userId jobId=$jobId',
        );
        await logEvent(
          userId: userId,
          action: 'otp_max_attempts',
          reason: 'Exceeded $maxAttempts OTP attempts for jobId=$jobId',
        );
        return false;
      }

      await logEvent(
        userId: userId,
        action: 'otp_failed',
        reason: 'Wrong OTP attempt $count for jobId=$jobId',
      );
      return true;
    } catch (e) {
      debugPrint('[FraudService] recordOtpAttempt error: $e');
      return true;
    }
  }

  static Future<bool> hasExceededOtpAttempts({
    required String userId,
    required String jobId,
    int maxAttempts = 5,
    int windowMs = 3600000,
  }) async {
    try {
      final snap = await FirebaseService.db
          .ref('${FirebasePaths.users}/$userId/otpAttempts_$jobId')
          .get();
      if (!snap.exists || snap.value is! Map) return false;
      final m = (snap.value as Map).cast<Object?, Object?>();
      final count = int.tryParse((m['count'] ?? '0').toString()) ?? 0;
      final firstMs =
          int.tryParse((m['firstAt'] ?? '0').toString()) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (nowMs - firstMs > windowMs) return false;
      return count >= maxAttempts;
    } catch (e) {
      return false;
    }
  }

  // ── Block check ───────────────────────────────────────────────────────────

  static Future<bool> isUserBlocked(String userId) async {
    try {
      final snap = await _usersRef.child(userId).child('isBlocked').get();
      if (!snap.exists || snap.value == null) return false;
      return snap.value.toString() == 'true';
    } catch (e) {
      debugPrint('[FraudService] isUserBlocked error: $e');
      return false;
    }
  }

  // ── OTP expiry ────────────────────────────────────────────────────────────

  static bool isOtpExpired(String otpCreatedAt, {int expiryMinutes = 30}) {
    try {
      final created = DateTime.parse(otpCreatedAt);
      final expired =
          DateTime.now().difference(created).inMinutes >= expiryMinutes;
      debugPrint(
        '[FraudService] isOtpExpired otpCreatedAt=$otpCreatedAt → $expired',
      );
      return expired;
    } catch (e) {
      debugPrint(
          '[FraudService] isOtpExpired error (treating as not expired): $e');
      return false;
    }
  }

  // ── Logging (FraudLogs/{uid}/{logId}) ─────────────────────────────────────

  static Future<void> logEvent({
    required String userId,
    required String action,
    required String reason,
  }) async {
    try {
      final logId = const Uuid().v4();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await _logsRoot.child(userId).child(logId).set({
        'logId': logId,
        'userId': userId,
        'action': action,
        'timestamp': timestamp,
        'reason': reason,
      });
      debugPrint(
        '[FraudService] logEvent userId=$userId action=$action reason=$reason',
      );
    } catch (e) {
      debugPrint('[FraudService] logEvent error: $e');
    }
  }
}
