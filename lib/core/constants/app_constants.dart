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

class MapStyle {
  // Official OSM Raster Tiles for the exact classic look the user requested
  static const String standard = '''
{
  "version": 8,
  "sources": {
    "osm-raster-tiles": {
      "type": "raster",
      "tiles": [
        "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
      ],
      "tileSize": 256,
      "attribution": "© OpenStreetMap contributors"
    }
  },
  "layers": [
    {
      "id": "osm-layer",
      "type": "raster",
      "source": "osm-raster-tiles",
      "minzoom": 0,
      "maxzoom": 19
    }
  ]
}
''';
  
  // Clean greyish vector style for "Bright"
  static const String bright = 'https://tiles.openfreemap.org/styles/positron';
  
  // Valid MapLibre style JSON for ArcGIS Satellite tiles
  static const String satellite = '''
{
  "version": 8,
  "sources": {
    "arcgis-satellite": {
      "type": "raster",
      "tiles": [
        "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"
      ],
      "tileSize": 256,
      "attribution": "Esri, Maxar, Earthstar Geographics"
    }
  },
  "layers": [
    {
      "id": "satellite-layer",
      "type": "raster",
      "source": "arcgis-satellite",
      "minzoom": 0,
      "maxzoom": 20
    }
  ]
}
''';
  
  // For easy mapping from preference string
  static String getStyle(String? theme) {
    switch (theme?.toLowerCase()) {
      case 'bright':
        return bright;
      case 'satellite':
        return satellite;
      case 'standard':
      default:
        return standard;
    }
  }
}

class SharedPrefKeys {
  static const String recentSearches = 'recent_searches';
  static const String savedLocations = 'saved_locations';
}