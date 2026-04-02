import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

// Key must match the one in main.dart
const String _kHasSeenOnboarding = 'hasSeenOnboarding';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _initialized = false; 
  bool _isGuest = false; // guest mode flag
  String? _errorMessage;

  /// Firestore real-time listener for the current user document.
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSubscription;

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
      // Firebase signed out — cancel live listener and clear user.
      _stopUserDocListener();
      _currentUser = null;
      _isGuest = false;
    } else {
      // Firebase Auth has a persisted session (app restart, token refresh etc.).
      // Only trust it if the user has a valid Firestore document.
      try {
        _currentUser = await _authService.getCurrentUserModel();
        if (_currentUser == null) {
          // Ghost/orphaned Firebase session — no Firestore account exists.
          debugPrint('AuthProvider: Orphaned Firebase session detected.');
        } else {
          // Start real-time listener so any Firestore write is reflected instantly.
          _startUserDocListener(firebaseUser.uid);
        }
      } catch (e) {
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
    String? department,
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
        department: department,
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
      if (_currentUser != null) {
        _startUserDocListener(_currentUser!.uid);
      }
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
    String? department,
    String? year,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.updateProfileDetails(
        name: name,
        department: department,
        year: year,
      );
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          name: name,
          department: department,
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

  // ── Preferences Management ────────────────────────────────────────────────
  Future<bool> updatePreferences(Map<String, dynamic> preferences) async {
    if (_currentUser == null) return false;
    _setLoading(true);
    _clearError();
    try {
      await _authService.updatePreferences(preferences);
      _currentUser = _currentUser!.copyWith(preferences: preferences);
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
    _stopUserDocListener();
    await _authService.signOut();
    _currentUser = null;
    _isGuest = false;
    // Reset onboarding flag: next cold start after logout will show onboarding.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHasSeenOnboarding);
    notifyListeners();
  }

  void setGuestMode(bool value) {
    _isGuest = value;
    if (value) {
      _stopUserDocListener();
      _currentUser = null;
    }
    if (!value) {
      // Exiting guest mode — reset onboarding so full flow runs on next launch.
      SharedPreferences.getInstance().then(
        (prefs) => prefs.remove(_kHasSeenOnboarding),
      );
    }
    notifyListeners();
  }

  void clearError() => _clearError();

  // ── Search History Management ──────────────────────────────────────────
  Future<void> addRecentSearch(String locationId) async {
    if (_currentUser == null) return;

    try {
      final FirestoreService firestoreService = FirestoreService();
      await firestoreService.addRecentSearch(_currentUser!.uid, locationId);
      
      // Update local state
      List<String> recent = List<String>.from(_currentUser!.recentSearches);
      // Ensure absolute uniqueness: remove all occurrences before inserting at front
      recent.removeWhere((id) => id == locationId);
      recent.insert(0, locationId);
      
      // Limit to 8
      if (recent.length > 8) {
        recent = recent.sublist(0, 8);
      }
      
      debugPrint('AuthProvider: Updated recentSearches locally: $recent');
      _currentUser = _currentUser!.copyWith(recentSearches: recent);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding recent search: $e');
    }
  }

  Future<void> removeRecentSearch(String locationId) async {
    if (_currentUser == null) return;

    try {
      final FirestoreService firestoreService = FirestoreService();
      await firestoreService.removeRecentSearch(_currentUser!.uid, locationId);
      
      // Update local state
      List<String> recent = List<String>.from(_currentUser!.recentSearches);
      recent.removeWhere((id) => id == locationId);
      
      _currentUser = _currentUser!.copyWith(recentSearches: recent);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing recent search: $e');
    }
  }

  Future<void> clearRecentSearches() async {
    if (_currentUser == null) return;

    try {
      final FirestoreService firestoreService = FirestoreService();
      await firestoreService.clearAllRecentSearches(_currentUser!.uid);
      
      // Update local state
      _currentUser = _currentUser!.copyWith(recentSearches: []);
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing recent searches: $e');
    }
  }

  // ── Real-Time Firestore Listener ──────────────────────────────────────────
  void _startUserDocListener(String uid) {
    _userDocSubscription?.cancel(); // Cancel any previous listener first
    _userDocSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((DocumentSnapshot<Map<String, dynamic>> snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return;
      final updated = UserModel.fromFirestore(snapshot.data()!, uid);
      _currentUser = updated;
      notifyListeners(); // Propagates instantly to all Consumer widgets
    }, onError: (e) {
      debugPrint('AuthProvider: Firestore stream error: $e');
    });
    debugPrint('AuthProvider: Started real-time listener for user/$uid');
  }

  void _stopUserDocListener() {
    _userDocSubscription?.cancel();
    _userDocSubscription = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
