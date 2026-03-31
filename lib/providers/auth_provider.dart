import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

// Key must match the one in main.dart
const String _kHasSeenOnboarding = 'hasSeenOnboarding';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _initialized = false; 
  bool _isGuest = false; // guest mode flag
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _initialized;
  bool get isGuest => _isGuest;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null || _isGuest;

  AuthProvider() {
    // Listen to Firebase auth state changes
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      // Firebase signed out (explicit logout, or token expired).
      _currentUser = null;
      _isGuest = false;
    } else {
      // Firebase Auth has a persisted session (app restart, token refresh etc.).
      // Only trust it if the user has a valid Firestore document.
      try {
        _currentUser = await _authService.getCurrentUserModel();
        if (_currentUser == null) {
          // Ghost/orphaned Firebase session — no Firestore account exists.
          // Silently sign it out so the user lands on the login screen cleanly.
          debugPrint('AuthProvider: Orphaned Firebase session — signing out ghost user.');
          _authService.signOut().ignore();
        }
      } catch (e) {
        // Firestore error — do not create a fallback, just show login.
        debugPrint('AuthProvider: Firestore read error on session restore: $e');
        _currentUser = null;
      }
    }

    _initialized = true;
    notifyListeners();
  }


  // ── Register ─────────────────────────────────────────────────────────────
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required UserType userType,
    String? branch,
    String? year,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await _authService.registerUser(
        email: email,
        password: password,
        name: name,
        userType: userType,
        branch: branch,
        year: year,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await _authService.loginUser(
        email: email,
        password: password,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Google Sign In ────────────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await _authService.signInWithGoogle();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Update Profile Image ──────────────────────────────────────────────────
  Future<bool> updateProfileImage(File imageFile) async {
    _setLoading(true);
    _clearError();
    try {
      final newUrl = await _authService.updateProfileImage(imageFile);
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(profileImageUrl: newUrl);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Update Profile Details ────────────────────────────────────────────────
  Future<bool> updateProfile({
    required String name,
    String? branch,
    String? year,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.updateProfileDetails(
        name: name,
        branch: branch,
        year: year,
      );
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          name: name,
          branch: branch,
          year: year,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Password Management ───────────────────────────────────────────────────
  Future<bool> resetPassword({required String email}) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword({required String oldPassword, required String newPassword}) async {
    if (oldPassword == newPassword) {
      _errorMessage = "New password cannot be the same as your current password.";
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _clearError();
    try {
      await _authService.updatePassword(oldPassword: oldPassword, newPassword: newPassword);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _authService.signOut();
    _currentUser = null;
    _isGuest = false;
    // Reset onboarding flag: next cold start after logout will show onboarding.
    // Flow: logout → swipe-out app → reopen → onboarding → login → home.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHasSeenOnboarding);
    notifyListeners();
  }

  void setGuestMode(bool value) {
    _isGuest = value;
    if (value) _currentUser = null;
    if (!value) {
      // Exiting guest mode — reset onboarding so full flow runs on next launch.
      SharedPreferences.getInstance().then(
        (prefs) => prefs.remove(_kHasSeenOnboarding),
      );
    }
    notifyListeners();
  }

  void clearError() => _clearError();

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
