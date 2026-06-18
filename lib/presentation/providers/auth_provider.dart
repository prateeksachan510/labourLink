import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:labour_link/data/models/app_user.dart';
import 'package:labour_link/data/services/cloudinary_service.dart';
import 'package:labour_link/data/services/profile_media_service.dart';
import 'package:labour_link/data/services/verification_service.dart';
import 'package:labour_link/domain/repositories/auth_repository.dart';
import 'package:labour_link/domain/repositories/user_repository.dart';
import 'package:image_picker/image_picker.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authRepository, this._userRepository) {
    _authRepository.authChanges().listen((_) => _loadCurrentUser());
  }

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  AppUser? currentUser;
  bool isLoading = false;
  String? error;

  User? get firebaseUser => _authRepository.currentUser();
  bool get isLoggedIn => firebaseUser != null;

  Future<void> _loadCurrentUser() async {
    final user = firebaseUser;
    if (user == null) {
      currentUser = null;
      notifyListeners();
      return;
    }
    currentUser = await _userRepository.getUserById(user.uid);
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      await _authRepository.signIn(email, password);
      await _loadCurrentUser();
      return true;
    } on FirebaseAuthException catch (e) {
      error = e.message ?? 'Unable to sign in';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    required String profession,
    required String location,
    required String bio,
    double latitude = 0.0,
    double longitude = 0.0,
  }) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      final credential = await _authRepository.signUp(email, password);
      final appUser = AppUser(
        uid: credential.user!.uid,
        email: email.trim(),
        name: name.trim(),
        phone: phone.trim(),
        role: role,
        profession: profession.trim(),
        bio: bio.trim(),
        location: location.trim(),
        latitude: latitude,
        longitude: longitude,
      );
      await _userRepository.saveUser(appUser);
      currentUser = appUser;
      return true;
    } on FirebaseAuthException catch (e) {
      error = e.message ?? 'Unable to register';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCurrentUser() => _loadCurrentUser();

  Future<void> updateProfile(AppUser user) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _userRepository.updateUser(user);
      currentUser = user;
    } catch (_) {
      error = 'Failed to update profile';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authRepository.signOut();
    currentUser = null;
    notifyListeners();
  }

  Future<bool> submitIdVerification({
    required String idType,
    required XFile image,
  }) async {
    final user = currentUser;
    if (user == null) {
      error = 'You must be signed in to verify your account.';
      notifyListeners();
      return false;
    }
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      final downloadUrl = await VerificationService.uploadIdProof(
        uid: user.uid,
        image: image,
      );
      await _userRepository.updateVerification(
        uid: user.uid,
        idProofUrl: downloadUrl,
        idType: idType,
        verificationStatus: 'pending',
      );
      currentUser = user.copyWith(
        idProofUrl: downloadUrl,
        idType: idType,
        verificationStatus: 'pending',
      );
      debugPrint('[AuthProvider] verificationStatus=pending uid=${user.uid}');
      return true;
    } catch (e, st) {
      debugPrint('[AuthProvider] submitIdVerification error: $e\n$st');
      error = CloudinaryService.formatError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadProfilePhoto(XFile image) async {
    final user = currentUser;
    if (user == null) {
      error = 'You must be signed in to update profile photo.';
      notifyListeners();
      return false;
    }
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      final downloadUrl = await ProfileMediaService.uploadProfilePhoto(
        uid: user.uid,
        image: image,
      );
      await _userRepository.updateProfileImage(
        uid: user.uid,
        profileImageUrl: downloadUrl,
      );
      currentUser = user.copyWith(profileImageUrl: downloadUrl);
      debugPrint('[AuthProvider] profile photo upload success uid=${user.uid}');
      return true;
    } catch (e, st) {
      debugPrint('[AuthProvider] uploadProfilePhoto error: $e\n$st');
      error = CloudinaryService.formatError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> savePaymentSetup({
    required String paymentMethod,
    required String upiId,
    required String bankAccountNumber,
    required String bankIfsc,
    required String bankAccountName,
  }) async {
    final user = currentUser;
    if (user == null) {
      error = 'You must be signed in to update payment setup.';
      notifyListeners();
      return false;
    }
    final method = paymentMethod.toLowerCase();
    if (method == 'upi' && !upiId.contains('@')) {
      error = 'Please enter a valid UPI ID.';
      notifyListeners();
      return false;
    }
    if (method == 'bank' &&
        (bankAccountNumber.trim().isEmpty ||
            bankIfsc.trim().isEmpty ||
            bankAccountName.trim().isEmpty)) {
      error = 'All bank fields are required.';
      notifyListeners();
      return false;
    }
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      await _userRepository.updatePaymentSetup(
        uid: user.uid,
        paymentMethod: method,
        upiId: method == 'upi' ? upiId.trim() : '',
        bankAccountNumber: method == 'bank' ? bankAccountNumber.trim() : '',
        bankIfsc: method == 'bank' ? bankIfsc.trim().toUpperCase() : '',
        bankAccountName: method == 'bank' ? bankAccountName.trim() : '',
      );
      currentUser = user.copyWith(
        paymentMethod: method,
        upiId: method == 'upi' ? upiId.trim() : '',
        bankAccountNumber: method == 'bank' ? bankAccountNumber.trim() : '',
        bankIfsc: method == 'bank' ? bankIfsc.trim().toUpperCase() : '',
        bankAccountName: method == 'bank' ? bankAccountName.trim() : '',
      );
      return true;
    } catch (e) {
      error = 'Failed to save payment setup.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
