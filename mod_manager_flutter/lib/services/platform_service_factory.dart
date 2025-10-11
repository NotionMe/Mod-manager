import 'dart:io';
import 'platform_service.dart';
import 'platform_service_linux.dart';
import 'platform_service_windows.dart';

/// Factory для створення платформно-специфічного сервісу
class PlatformServiceFactory {
  static PlatformService? _instance;

  /// Отримати singleton instance платформного сервісу
  static PlatformService getInstance() {
    _instance ??= _createService();
    return _instance!;
  }

  /// Створити новий instance (для тестування)
  static PlatformService createNew() {
    return _createService();
  }

  /// Скинути singleton (для тестування)
  static void reset() {
    _instance = null;
  }

  static PlatformService _createService() {
    if (Platform.isWindows) {
      print('PlatformServiceFactory: Creating Windows service');
      return WindowsPlatformService();
    } else if (Platform.isLinux) {
      print('PlatformServiceFactory: Creating Linux service');
      return LinuxPlatformService();
    } else if (Platform.isMacOS) {
      throw UnsupportedError('MacOS is not supported yet. Please contribute!');
    } else {
      throw UnsupportedError(
        'Platform ${Platform.operatingSystem} is not supported',
      );
    }
  }
}
