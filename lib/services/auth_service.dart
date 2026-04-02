import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Auth state stream ─────────────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  // ── Password strength validator ───────────────────────────────────────────
  /// Returns null if valid, or a human-readable error string.
  static String? validatePasswordStrength(String password) {
    if (password.length < 8) return 'Password must be at least 8 characters.';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'Add at least one uppercase letter.';
    if (!password.contains(RegExp(r'[a-z]'))) return 'Add at least one lowercase letter.';
    if (!password.contains(RegExp(r'[0-9]'))) return 'Add at least one number.';
    final specials = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\/`~;]');
    final specialCount = password.split('').where((c) => specials.hasMatch(c)).length;
    if (specialCount < 2) return 'Add at least 2 special characters.';
    return null;
  }

  // ── Register ──────────────────────────────────────────────────────────────
  /// Creates a Firebase Auth account then stores the UserModel in Firestore.
  /// Throws a [String] error message on failure.
  Future<UserModel> registerUser({
    required String email,
    required String password,
    required String name,
    required UserType userType,
    String? department,
    String? year,
  }) async {
    if (userType == UserType.admin) {
      throw 'Admin accounts cannot be self-registered. '
          'Please contact the system administrator.';
    }

    // ── Duplicate email check ─────────────────────────────────────────────
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email.trim());
      if (methods.isNotEmpty) {
        if (methods.contains('google.com')) {
          throw 'This email is linked to a Google account. Please sign in with Google.';
        }
        throw 'An account with this email already exists. Please sign in.';
      }
    } on FirebaseAuthException catch (e) {
      throw _authErrorMessage(e.code);
    }

    // ── Strong password check ─────────────────────────────────────────────
    final pwError = validatePasswordStrength(password);
    if (pwError != null) throw pwError;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      final now = DateTime.now();

      final userModel = UserModel(
        uid: uid,
        email: email.trim(),
        name: name.trim(),
        department: department?.trim(),
        year: year?.trim(),
        userType: userType,
        createdAt: now,
        lastLogin: now,
      );

      await _db.collection('users').doc(uid).set(userModel.toFirestore());
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _authErrorMessage(e.code);
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<UserModel> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;

      final model = await getCurrentUserModel();
      if (model == null) {
        throw 'User profile not found. Please contact support or Administrator.';
      }

      // Update lastLogin timestamp
      await _db.collection('users').doc(uid).update({
        'lastLogin': Timestamp.fromDate(DateTime.now()),
      });

      return model;
    } on FirebaseAuthException catch (e) {
      throw _authErrorMessage(e.code);
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
         throw 'User profile not found. Please contact support or Administrator.';
      }
      throw 'Database error: ${e.message}';
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  // ── Fetch current user profile from Firestore ─────────────────────────────
  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists || doc.data() == null) return null;

    return UserModel.fromFirestore(doc.data()!, user.uid);
  }

  // ── Google Sign In ────────────────────────────────────────────────────────
  Future<UserModel> signInWithGoogle() async {
    try {
      debugPrint('Google Sign-In: Starting...');
      final googleSignIn = GoogleSignIn();

      debugPrint('Google Sign-In: Requesting account prompt...');
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw 'Google Sign-In prompt timed out (15s).',
      );

      if (googleSignInAccount == null) {
        debugPrint('Google Sign-In: User cancelled the flow.');
        throw 'Google Sign-In was cancelled.';
      }

      debugPrint('Google Sign-In: Authenticating account...');
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication.timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw 'Google Authentication timed out (15s).',
      );

      debugPrint('Google Sign-In: Exchanging credentials with Firebase...');
      final AuthCredential googleCredential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final email = googleSignInAccount.email.trim();

      // ── First check if a Firestore account exists for this email ─────────
      // (Google Sign-In is only for existing users, not sign-up)
      final existingByEmail = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingByEmail.docs.isEmpty) {
        // No account in Firestore — reject sign-in and clean up
        await googleSignIn.signOut();
        throw 'No account found with this Google account. Please sign up first.';
      }

      // ── Account exists — proceed with Firebase Auth sign-in ──────────────
      UserCredential userCredential;
      try {
        userCredential = await _auth.signInWithCredential(googleCredential)
            .timeout(const Duration(seconds: 15),
                onTimeout: () => throw 'Firebase credential sign-in timed out (15s).');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          // The email was registered with email/password. We need to link.
          // Since we already verified the Firestore doc exists, this is a valid user.
          debugPrint('Google Sign-In: account-exists-with-different-credential, '
              'user needs to sign in with email/password first to link Google.');
          await googleSignIn.signOut();
          throw 'This email is registered with a password. '
              'Please sign in with your email and password.';
        }
        throw _authErrorMessage(e.code);
      }

      final User user = userCredential.user!;

      debugPrint('Google Sign-In: Resolving Firestore user document...');
      final doc = await _db.collection('users').doc(user.uid).get();
      UserModel userModel;

      if (doc.exists && doc.data() != null) {
        // Firestore doc found directly by UID — happy path
        userModel = UserModel.fromFirestore(doc.data()!, user.uid);
        await _db.collection('users').doc(user.uid).update({
          'lastLogin': Timestamp.fromDate(DateTime.now()),
        });
      } else {
        // UID mismatch — the user originally signed up with email/password
        // and got a different UID. Migrate the Firestore doc to the new UID.
        final oldDoc = existingByEmail.docs.first;
        final oldData = oldDoc.data();
        final now = DateTime.now();

        userModel = UserModel.fromFirestore(oldData, user.uid);

        // Create doc under the new UID
        await _db.collection('users').doc(user.uid).set({
          ...oldData,
          'uid': user.uid,
          'lastLogin': Timestamp.fromDate(now),
        });

        // Optionally remove the old doc if it has a different ID
        if (oldDoc.id != user.uid) {
          await _db.collection('users').doc(oldDoc.id).delete();
          debugPrint('Google Sign-In: Migrated Firestore doc from ${oldDoc.id} to ${user.uid}');
        }
      }

      debugPrint('Google Sign-In: Success!');
      return userModel;
    } on FirebaseAuthException catch (e) {
      debugPrint('Google Sign-In FirebaseAuthException: ${e.code} - ${e.message}');
      throw _authErrorMessage(e.code);
    } catch (e, stacktrace) {
      debugPrint('Google Sign-In general exception: $e');
      debugPrint('Stacktrace: $stacktrace');
      if (e is String) rethrow;
      throw 'Google Sign-In failed: $e';
    }
  }

  // ── Update Profile Image (Base64) ─────────────────────────────────────────
  Future<String> updateProfileImage(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';

    try {
      // Read file bytes and encode to base64
      final Uint8List bytes = await imageFile.readAsBytes();

      // Limit size: if image > 800KB, throw a helpful error
      if (bytes.lengthInBytes > 800 * 1024) {
        throw 'Image too large. Please choose a smaller image (under 800 KB).';
      }

      final String base64Image = base64Encode(bytes);

      // Store the base64 string prefixed with data URI for easy decoding
      final String dataUri = 'data:image/jpeg;base64,$base64Image';

      // Update Firestore document
      await _db.collection('users').doc(user.uid).update({
        'profileImageUrl': dataUri,
      });

      debugPrint('Profile image uploaded as base64 (${bytes.lengthInBytes} bytes)');
      return dataUri;
    } catch (e) {
      throw 'Failed to upload profile image: $e';
    }
  }

  // ── Update Profile Details ────────────────────────────────────────────────
  Future<void> updateProfileDetails({
    required String name,
    String? department,
    String? year,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';

    try {
      final Map<String, dynamic> updates = {
        'name': name,
        'department': department,
        'year': year,
      };

      await _db.collection('users').doc(user.uid).update(updates);

      // Also update Firebase Auth display name
      await user.updateDisplayName(name);
    } catch (e) {
      throw 'Failed to update profile: $e';
    }
  }

  // ── Update Preferences ────────────────────────────────────────────────────
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';

    try {
      await _db.collection('users').doc(user.uid).update({
        'preferences': preferences,
      });
    } catch (e) {
      throw 'Failed to update preferences: $e';
    }
  }

  // ── Password Management ───────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _authErrorMessage(e.code);
    }
  }

  Future<void> updatePassword({required String oldPassword, required String newPassword}) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';
    if (user.email == null) throw 'Unable to verify current password. Email not found.';

    try {
      // 1. Re-authenticate to ensure old password is correct
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // 2. Update to new password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw 'Incorrect current password.';
      }
      if (e.code == 'requires-recent-login') {
        throw 'For security reasons, please log out and log back in to change your password.';
      }
      throw _authErrorMessage(e.code);
    }
  }

  // ── Human-readable Firebase error messages ────────────────────────────────
  String _authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      case 'credential-already-in-use':
        return 'This Google account is already linked to another user.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
