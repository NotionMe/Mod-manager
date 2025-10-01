/// Constants for the application
class AppConstants {
  // UI Scaling
  static const double minScale = 0.8;
  static const double maxScale = 1.5;
  static const int scaleSteps = 7;

  // UI Dimensions
  static const double tabBarTopPadding = 25;
  static const double tabBarWidth = 300;
  static const double tabBarHeight = 42;
  static const double tabBarBorderWidth = 3;
  
  static const double characterCardSize = 80;
  static const double characterCardBorderWidth = 3;
  static const double characterCardBorderWidthSelected = 4;
  static const double characterCardBlurRadius = 15;
  static const double characterCardSpreadRadius = 3;
  
  static const double skinCardWidth = 240;
  static const double skinCardHeight = 360;
  static const double skinCardBorderWidth = 3;
  static const double skinCardBorderRadius = 20;
  static const double skinCardBlurRadius = 15;
  static const double skinCardSpreadRadius = 3;
  
  // Animation Durations
  static const Duration snackBarDuration = Duration(seconds: 1);
  static const Duration imageSavedSnackBarDuration = Duration(seconds: 2);
  
  // File Names
  static const List<String> imageFileNames = [
    'Preview.png',
    'preview.png',
    'thumbnail.png',
    'icon.png',
  ];
  
  // Paths (note: assetsCharactersPath is relative to Flutter assets bundle)
  static const String assetsCharactersPath = 'assets/characters/';
  // Note: For mod_images path, use PathHelper.getModImagesPath() instead
  // of a hardcoded constant, as it needs to work in different environments
  static const String configFileName = 'config.json';
}
