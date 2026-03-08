import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with Email/Password and store additional user details
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String role,
    required Map<String, dynamic> additionalData,
  }) async {
    try {
      // 1. Create the user in Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Save the user details array to Cloud Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'role': role,
          'uid': userCredential.user!.uid,
          'createdAt': FieldValue.serverTimestamp(),
          ...additionalData,
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('An account already exists for that email.');
      } else {
        throw Exception(
            e.message ?? 'An unknown error occurred during sign up.');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Sign in with Email/Password
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password provided for that user.');
      } else if (e.code == 'invalid-credential') {
        throw Exception('Invalid login credentials.');
      } else {
        throw Exception(
            e.message ?? 'An unknown error occurred during sign in.');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get Current User stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get Current User data
  User? get currentUser => _auth.currentUser;
}
