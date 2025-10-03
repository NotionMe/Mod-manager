import 'dart:io';
import 'package:path/path.dart' as path;

/// Helper class to get correct paths for assets depending on the environment
class PathHelper {
  static String? _modImagesPath;
  static String? _appDataPath;

  /// Get the path for application data directory
  /// Platform-aware: uses APPDATA on Windows, XDG on Linux
  static String getAppDataPath() {
    if (_appDataPath != null) {
      return _appDataPath!;
    }

    if (Platform.isWindows) {
      // Windows: %APPDATA%\zzz-mod-manager
      final appData = Platform.environment['APPDATA'];
      if (appData != null) {
        _appDataPath = path.join(appData, 'zzz-mod-manager');
      } else {
        // Fallback на USERPROFILE\AppData\Roaming
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          _appDataPath = path.join(userProfile, 'AppData', 'Roaming', 'zzz-mod-manager');
        } else {
          throw Exception('Cannot find Windows user directory');
        }
      }
    } else {
      // Linux: ~/.local/share/zzz-mod-manager
      final homeDir = Platform.environment['HOME'];
      if (homeDir != null) {
        final xdgDataHome = Platform.environment['XDG_DATA_HOME'] ?? 
                            path.join(homeDir, '.local', 'share');
        _appDataPath = path.join(xdgDataHome, 'zzz-mod-manager');
      } else {
        throw Exception('Cannot find Linux home directory');
      }
    }

    return _appDataPath!;
  }

  /// Get the path for mod_images directory
  /// This uses user's home directory to ensure write permissions
  /// Path: 
  ///   Windows: %APPDATA%\zzz-mod-manager\mod_images
  ///   Linux: ~/.local/share/zzz-mod-manager/mod_images
  static String getModImagesPath() {
    if (_modImagesPath != null) {
      return _modImagesPath!;
    }

    try {
      _modImagesPath = path.join(getAppDataPath(), 'mod_images');
    } catch (e) {
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
    _appDataPath = null;
  }
}
