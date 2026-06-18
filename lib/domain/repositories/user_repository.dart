import 'package:labour_link/data/models/app_user.dart';
import 'package:labour_link/data/models/live_location.dart';

abstract class UserRepository {
  Future<void> saveUser(AppUser user);
  Future<AppUser?> getUserById(String uid);
  Future<void> updateUser(AppUser user);
  Future<void> updateVerification({
    required String uid,
    required String idProofUrl,
    required String idType,
    required String verificationStatus,
  });
  Future<void> updateProfileImage({
    required String uid,
    required String profileImageUrl,
  });
  Future<void> updatePaymentSetup({
    required String uid,
    required String paymentMethod,
    required String upiId,
    required String bankAccountNumber,
    required String bankIfsc,
    required String bankAccountName,
  });
  Future<List<AppUser>> getSeekersByProfession(String profession);
  Future<List<AppUser>> getSeekersByCity(String city);
  Future<List<AppUser>> searchSeekers({
    required String profession,
    required String query,
  });

  Future<void> updateLiveLocation({
    required String uid,
    required double lat,
    required double lng,
    required String updatedAt,
  });

  Stream<LiveLocation?> watchLiveLocation(String uid);
}

