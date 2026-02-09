import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String keyUserName = 'user_name';
  static const String keyUserDept = 'user_department';
  static const String keyUserYear = 'user_year';
  static const String keyUserProgram = 'user_program';
  static const String keyProfileImage = 'profile_image_path';
  static const String keyAppLock = 'app_lock_enabled';
  static const String keyAccessibleRoutes = 'accessible_routes';
  static const String keyDistanceUnit = 'distance_unit';

  static Future<Map<String, dynamic>> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      keyUserName: prefs.getString(keyUserName) ?? "Alex Rivera",
      keyUserDept: prefs.getString(keyUserDept) ?? "Computer Science Department",
      keyUserYear: prefs.getString(keyUserYear) ?? "3rd year",
      keyUserProgram: prefs.getString(keyUserProgram) ?? "B.Tech",
      keyProfileImage: prefs.getString(keyProfileImage),
      keyAppLock: prefs.getBool(keyAppLock) ?? false,
      keyAccessibleRoutes: prefs.getBool(keyAccessibleRoutes) ?? false,
      keyDistanceUnit: prefs.getString(keyDistanceUnit) ?? "Meters",
    };
  }

  static Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<void> saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // Helper for profile image specifically
  static Future<void> saveProfileImage(String path) async {
    await saveString(keyProfileImage, path);
  }

  // NOTE: Future Database Sync point
  // To sync with a real DB, you would add a method here:
  // static Future<void> syncWithServer() async { ... }
}
