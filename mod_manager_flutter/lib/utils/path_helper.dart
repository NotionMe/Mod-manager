import 'dart:io';
import 'package:path/path.dart' as path;

/// Helper class to get correct paths for assets depending on the environment
class PathHelper {
  static String? _modImagesPath;

  /// Get the path for mod_images directory
  /// This uses user's home directory to ensure write permissions
  /// Path: ~/.local/share/zzz-mod-manager/mod_images
  static String getModImagesPath() {
    if (_modImagesPath != null) {
      return _modImagesPath!;
    }

    // Try different possible locations in order of preference
    final homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    
    if (homeDir != null) {
      // Use XDG data directory for user data
      final xdgDataHome = Platform.environment['XDG_DATA_HOME'] ?? path.join(homeDir, '.local', 'share');
      _modImagesPath = path.join(xdgDataHome, 'zzz-mod-manager', 'mod_images');
    } else {
      // Fallback for development (relative to current directory)
      final possiblePaths = [
        path.join(Directory.current.path, '..', 'assets', 'mod_images'),
        path.join(Directory.current.path, 'assets', 'mod_images'),
        path.join(Directory.current.path, '..', '..', 'assets', 'mod_images'),
      ];

      for (final possiblePath in possiblePaths) {
        final dir = Directory(possiblePath);
        if (dir.existsSync()) {
          _modImagesPath = possiblePath;
          return _modImagesPath!;
        }
      }
      
      // Last resort fallback
      _modImagesPath = path.join(Directory.current.path, '..', 'assets', 'mod_images');
    }

    return _modImagesPath!;
  }

  /// Ensure the mod_images directory exists
  static Future<void> ensureModImagesDirectoryExists() async {
    final dir = Directory(getModImagesPath());
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// Reset cached paths (useful for testing)
  static void resetCache() {
    _modImagesPath = null;
  }
}
