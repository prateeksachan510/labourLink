import 'package:firebase_auth/firebase_auth.dart';
import 'package:labour_link/data/services/firebase_service.dart';
import 'package:labour_link/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Stream<User?> authChanges() => FirebaseService.auth.authStateChanges();

  @override
  User? currentUser() => FirebaseService.auth.currentUser;

  @override
  Future<UserCredential> signIn(String email, String password) {
    return FirebaseService.auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<UserCredential> signUp(String email, String password) {
    return FirebaseService.auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signOut() => FirebaseService.auth.signOut();
}
