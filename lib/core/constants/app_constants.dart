class AppConstants {
  static const String appName = 'NITC Campus Navigator';
  
  // Shared Preferences Keys
  static const String prefUserLoggedIn = 'user_logged_in';
  static const String prefUserId = 'user_id';
  static const String prefUserEmail = 'user_email';
  static const String prefUserName = 'user_name';
  static const String prefUserType = 'user_type';
  
  // GraphHopper Server
  // For local testing (physical device): use your PC's IP (e.g. http://192.168.1.5:8989)
  // For local testing (emulator): use http://10.0.2.2:8989
  static const String graphHopperBaseUrl = 'https://group1-departmentalnavigation.onrender.com';
  static const String graphHopperApiKey = ''; // Not needed for self-hosted
  
  // Map Defaults
  static const double defaultMapZoom = 17.0;
  static const double campusLat = 11.319972; // NITC exact latitude
  static const double campusLng = 75.932639; // NITC exact longitude
  
  // Navigation
  static const double entryPointRadius = 20.0; // meters
}

class SharedPrefKeys {
  static const String recentSearches = 'recent_searches';
  static const String savedLocations = 'saved_locations';
}