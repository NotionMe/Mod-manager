/// Constants for the application
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // UI Scaling
  static const double minScale = 0.8;
  static const double maxScale = 1.5;
  static const int scaleSteps = 7;

  // UI Dimensions
  static const double tabBarTopPadding = 25;
  static const double tabBarWidth = 300;
  static const double tabBarHeight = 42;
  static const double tabBarBorderWidth = 3;

  // Character Card Dimensions
  static const double characterCardWidth = 50;
  static const double characterCardHeight = 50;
  static const double characterCardBorderWidth = 2;
  static const double characterCardBorderWidthSelected = 3;
  static const double characterCardBorderWidthHover = 4;
  static const double characterCardBlurRadius = 12;
  static const double characterCardSpreadRadiusSelected = 2;
  static const double characterCardSpreadRadiusHover = 3;
  static const double characterCardMarginRight = 12;

  // Mod Card Dimensions
  static const double modCardWidth = 320;
  static const double modCardBorderRadius = 12;
  static const double modCardBorderWidthActive = 2;
  static const double modCardBorderWidthInactive = 1;
  static const double modCardBlurRadiusActive = 12;
  static const double modCardBlurRadiusInactive = 8;
  static const double modCardSpreadRadiusActive = 1;
  static const double modCardPadding = 16;
  static const double modCardImageHeight = 280;

  // Drag and Drop
  static const Duration dragDelay = Duration(milliseconds: 500);
  static const double dragFeedbackElevation = 8;
  static const double dragFeedbackOpacity = 0.5;

  // Colors
  static const int primaryColor = 0xFF0EA5E9;
  static const int secondaryColor = 0xFF06B6D4;
  static const int activeModBorderColor = 0xFF6366F1;
  static const int activeModCountColor = 0xFF10B981;

  // Animation Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);
  static const Duration snackBarDuration = Duration(milliseconds: 800);
  static const Duration imageSavedSnackBarDuration = Duration(seconds: 2);

  // Debounce delays
  static const Duration modToggleDebounceDelay = Duration(milliseconds: 200);
  static const Duration characterSelectionDebounceDelay = Duration(milliseconds: 100);
  static const Duration modeSwitchDebounceDelay = Duration(milliseconds: 100);

  // Layout Spacing
  static const double defaultPadding = 16;
  static const double smallPadding = 8;
  static const double tinyPadding = 4;
  static const double defaultMargin = 12;
  static const double smallMargin = 6;

  // Text Sizes
  static const double headerTextSize = 16;
  static const double titleTextSize = 14;
  static const double bodyTextSize = 13;
  static const double captionTextSize = 12;
  static const double smallCaptionTextSize = 10;

  // File Names
  static const List<String> imageFileNames = [
    'Preview.png',
    'preview.png',
    'thumbnail.png',
    'icon.png',
  ];

  // Paths (note: assetsCharactersPath is relative to Flutter assets bundle)
  static const String assetsCharactersPath = 'assets/characters/';
  static const String assetsIconPath = 'assets/icon.png';
  // Note: For mod_images path, use PathHelper.getModImagesPath() instead
  // of a hardcoded constant, as it needs to work in different environments
  static const String configFileName = 'config.json';

  // Window dimensions
  static const double minWindowWidth = 900;
  static const double minWindowHeight = 600;
  static const double defaultWindowWidth = 1000;
  static const double defaultWindowHeight = 700;
  static const double maxWindowWidth = 1200;
  static const double maxWindowHeight = 800;
}
