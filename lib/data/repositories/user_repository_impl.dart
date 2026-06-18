import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:labour_link/core/constants/firebase_paths.dart';
import 'package:labour_link/data/models/app_user.dart';
import 'package:labour_link/data/models/live_location.dart';
import 'package:labour_link/data/services/firebase_service.dart';
import 'package:labour_link/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  DatabaseReference get _usersRef =>
      FirebaseService.db.ref(FirebasePaths.users);

  DatabaseReference get _seekersRef =>
      FirebaseService.db.ref(FirebasePaths.seeker);

  @override
  Future<void> saveUser(AppUser user) async {
    await _usersRef.child(user.uid).set(user.toMap());
    if (user.isSeeker && user.profession.isNotEmpty) {
      await _seekersRef
          .child(user.profession)
          .child(user.uid)
          .set(user.toMap());
    }
  }

  @override
  Future<AppUser?> getUserById(String uid) async {
    final snapshot = await _usersRef.child(uid).get();
    if (!snapshot.exists || snapshot.value == null) {
      return null;
    }
    return AppUser.fromMap((snapshot.value as Map).cast<Object?, Object?>());
  }

  @override
  Future<void> updateUser(AppUser user) async {
    await _usersRef.child(user.uid).update(user.toMap());

    final seekerSnapshot = await _seekersRef.get();
    if (seekerSnapshot.exists && seekerSnapshot.value is Map) {
      final all = (seekerSnapshot.value as Map).cast<Object?, Object?>();
      for (final profession in all.keys) {
        await _seekersRef.child(profession.toString()).child(user.uid).remove();
      }
    }

    if (user.isSeeker && user.profession.isNotEmpty) {
      await _seekersRef
          .child(user.profession)
          .child(user.uid)
          .set(user.toMap());
    }
  }

  @override
  Future<void> updateVerification({
    required String uid,
    required String idProofUrl,
    required String idType,
    required String verificationStatus,
  }) async {
    final payload = {
      'idProofUrl': idProofUrl,
      'idType': idType,
      'verificationStatus': verificationStatus,
    };
    await _updateUserAndSeekerCopies(uid: uid, payload: payload);
  }

  @override
  Future<void> updateProfileImage({
    required String uid,
    required String profileImageUrl,
  }) async {
    await _updateUserAndSeekerCopies(
      uid: uid,
      payload: {'profileImageUrl': profileImageUrl},
    );
  }

  @override
  Future<void> updatePaymentSetup({
    required String uid,
    required String paymentMethod,
    required String upiId,
    required String bankAccountNumber,
    required String bankIfsc,
    required String bankAccountName,
  }) async {
    final payload = {
      'paymentMethod': paymentMethod,
      'upiId': upiId,
      'bankAccountNumber': bankAccountNumber,
      'bankIfsc': bankIfsc,
      'bankAccountName': bankAccountName,
    };
    await _updateUserAndSeekerCopies(uid: uid, payload: payload);
  }

  @override
  Future<List<AppUser>> getSeekersByProfession(String profession) async {
    final snapshot = await _seekersRef.child(profession).get();
    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }
    final map = (snapshot.value as Map).cast<Object?, Object?>();
    return map.values
        .map((e) => AppUser.fromMap((e as Map).cast<Object?, Object?>()))
        .toList();
  }

  @override
  Future<List<AppUser>> getSeekersByCity(String city) async {
    final snapshot = await _seekersRef.get();
    if (!snapshot.exists || snapshot.value == null) return [];
    final professions = (snapshot.value as Map).cast<Object?, Object?>();
    final results = <AppUser>[];
    final q = city.trim().toLowerCase();
    for (final entry in professions.entries) {
      final workers = (entry.value as Map).cast<Object?, Object?>();
      for (final w in workers.values) {
        final user = AppUser.fromMap((w as Map).cast<Object?, Object?>());
        if (user.location.toLowerCase().contains(q)) {
          results.add(user);
        }
      }
    }
    return results;
  }

  @override
  Future<List<AppUser>> searchSeekers({
    required String profession,
    required String query,
  }) async {
    final users = await getSeekersByProfession(profession);
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return users;
    }
    return users
        .where(
          (u) =>
              u.name.toLowerCase().contains(q) ||
              u.location.toLowerCase().contains(q) ||
              u.profession.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Future<void> updateLiveLocation({
    required String uid,
    required double lat,
    required double lng,
    required String updatedAt,
  }) async {
    try {
      debugPrint(
        '[UserRepo] updateLiveLocation uid=$uid lat=$lat lng=$lng updatedAt=$updatedAt',
      );
      await _usersRef.child(uid).child('location').set({
        'lat': lat,
        'lng': lng,
        'updatedAt': updatedAt,
      });
    } catch (e) {
      debugPrint('[UserRepo] updateLiveLocation error: $e');
      rethrow;
    }
  }

  @override
  Stream<LiveLocation?> watchLiveLocation(String uid) {
    return _usersRef.child(uid).child('location').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return null;
      }
      if (event.snapshot.value is! Map) {
        return null;
      }
      final map = (event.snapshot.value as Map).cast<Object?, Object?>();
      final loc = LiveLocation.fromMap(map);
      debugPrint(
        '[UserRepo] watchLiveLocation uid=$uid lat=${loc.lat} lng=${loc.lng}',
      );
      return loc;
    });
  }

  Future<void> _updateUserAndSeekerCopies({
    required String uid,
    required Map<String, Object?> payload,
  }) async {
    await _usersRef.child(uid).update(payload);
    final seekerSnapshot = await _seekersRef.get();
    if (seekerSnapshot.exists && seekerSnapshot.value is Map) {
      final all = (seekerSnapshot.value as Map).cast<Object?, Object?>();
      for (final profession in all.keys) {
        final workerRef = _seekersRef.child(profession.toString()).child(uid);
        final workerSnapshot = await workerRef.get();
        if (workerSnapshot.exists) {
          await workerRef.update(payload);
        }
      }
    }
  }
}

