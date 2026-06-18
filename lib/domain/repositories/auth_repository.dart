import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Stream<User?> authChanges();
  User? currentUser();
  Future<UserCredential> signIn(String email, String password);
  Future<UserCredential> signUp(String email, String password);
  Future<void> signOut();
}
