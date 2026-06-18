import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseDatabase db = FirebaseDatabase.instance;
}
