import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;
import 'package:win32/win32.dart';
import 'package:url_launcher/url_launcher.dart';
import 'platform_service.dart';

/// Windows-специфічна реалізація PlatformService
class WindowsPlatformService implements PlatformService {
  @override
  Future<bool> sendF10ToGame() async {
    print('WindowsPlatformService: Відправка F10...');

    try {
      // Знаходимо вікно гри через FindWindow
      final windowNames = [
        'Zenless Zone Zero',
        'ZenlessZoneZero',
        'Zenless',
        'ZZZ',
      ];

      int hwnd = 0;
      for (final name in windowNames) {
        final namePtr = name.toNativeUtf16();
        try {
          hwnd = FindWindow(nullptr, namePtr);
          if (hwnd != 0) {
            print(
              'WindowsPlatformService: Знайдено вікно гри: $name (HWND: $hwnd)',
            );
            break;
          }
        } finally {
          calloc.free(namePtr);
        }
      }

      if (hwnd == 0) {
        print('WindowsPlatformService: Вікно гри не знайдено');
        // Спробуємо відправити до активного вікна
        return await _sendF10ToForegroundWindow();
      }

      // Перевіряємо чи вікно видиме
      final isVisible = IsWindowVisible(hwnd);
      if (isVisible == FALSE) {
        print('WindowsPlatformService: Вікно гри не видиме');
        return false;
      }

      // Активуємо вікно
      SetForegroundWindow(hwnd);
      await Future.delayed(const Duration(milliseconds: 100));

      // Відправляємо F10 (VK_F10 = 0x79)
      // Натискання клавіші
      PostMessage(hwnd, WM_KEYDOWN, VK_F10, 0);
      await Future.delayed(const Duration(milliseconds: 50));
      // Відпускання клавіші
      PostMessage(hwnd, WM_KEYUP, VK_F10, 0);

      print('WindowsPlatformService: F10 успішно відправлено');
      return true;
    } catch (e) {
      print('WindowsPlatformService: Помилка відправки F10: $e');
      return false;
    }
  }

  @override
  Future<bool> createModLink(String sourcePath, String linkPath) async {
    try {
      print('WindowsPlatformService: Створення link: $linkPath -> $sourcePath');

      // Спочатку видаляємо якщо вже існує
      if (await Directory(linkPath).exists() || await File(linkPath).exists()) {
        await removeModLink(linkPath);
      }

      // Спроба 1: Звичайний symbolic link (потребує Developer Mode або прав адміна)
      try {
        final link = Link(linkPath);
        await link.create(sourcePath, recursive: false);
        print('WindowsPlatformService: Symlink створено успішно');
        return true;
      } catch (e) {
        print('WindowsPlatformService: Не вдалося створити symlink: $e');
        print('WindowsPlatformService: Спроба створити Junction...');
      }

      // Спроба 2: Directory Junction (не потребує прав адміна)
      final result = await Process.run('cmd', [
        '/c',
        'mklink',
        '/J',
        linkPath,
        sourcePath,
      ], runInShell: true);

      if (result.exitCode == 0) {
        print('WindowsPlatformService: Junction створено успішно');
        return true;
      } else {
        print(
          'WindowsPlatformService: Помилка створення Junction: ${result.stderr}',
        );
        return false;
      }
    } catch (e) {
      print('WindowsPlatformService: Помилка створення link: $e');
      return false;
    }
  }

  @override
  Future<bool> removeModLink(String linkPath) async {
    try {
      // Перевіряємо чи це link/junction
      final isLink = await isModLink(linkPath);
      if (!isLink) {
        // Можливо це звичайна директорія, видаляємо її
        final dir = Directory(linkPath);
        if (await dir.exists()) {
          await dir.delete(recursive: false);
          print('WindowsPlatformService: Директорію видалено: $linkPath');
          return true;
        }
        return false;
      }

      // Для junction/symlink використовуємо Link
      final link = Link(linkPath);
      if (await link.exists()) {
        await link.delete();
        print('WindowsPlatformService: Link видалено: $linkPath');
        return true;
      }

      return false;
    } catch (e) {
      print('WindowsPlatformService: Помилка видалення link: $e');
      return false;
    }
  }

  @override
  Future<bool> isModLink(String linkPath) async {
    try {
      // Перевіряємо через FileSystemEntity.isLink
      final isLink = await FileSystemEntity.isLink(linkPath);
      if (isLink) return true;

      // Додатково перевіряємо через Windows API для junction
      return await _isJunction(linkPath);
    } catch (e) {
      return false;
    }
  }

  @override
  String getAppDataPath() {
    final appData = Platform.environment['APPDATA'];
    if (appData == null) {
      // Fallback на USERPROFILE\AppData\Roaming
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile == null) {
        throw Exception(
          'APPDATA and USERPROFILE environment variables not found',
        );
      }
      return path.join(userProfile, 'AppData', 'Roaming', 'zzz-mod-manager');
    }

    return path.join(appData, 'zzz-mod-manager');
  }

  @override
  void showSetupInstructions() {
    print('\n═══════════════════════════════════════════════════════════');
    print('F10 Auto-Reload Setup Instructions (Windows)');
    print('═══════════════════════════════════════════════════════════\n');
    print('✓ F10 auto-reload працює через Windows API');
    print('✓ Не потребує додаткових інструментів\n');
    print('Для роботи Symbolic Links:');
    print('  Варіант 1 (Рекомендовано): Увімкніть Developer Mode');
    print('    Settings → Update & Security → For developers');
    print('    → Developer Mode (ON)');
    print('\n  Варіант 2: Програма автоматично використає Directory Junctions');
    print('    (працюють без прав адміністратора)\n');
    print('  Варіант 3: Запустіть програму як адміністратор');
    print('    (правий клік → Run as administrator)');
    print('\n═══════════════════════════════════════════════════════════\n');
  }

  @override
  Future<bool> checkDependencies() async {
    print('WindowsPlatformService: Перевірка залежностей...');

    // На Windows всі необхідні API вже є в системі
    try {
      // Перевіряємо чи можемо викликати Windows API
      final hwnd = GetForegroundWindow();
      if (hwnd != 0) {
        print('WindowsPlatformService: Windows API доступний ✓');
        return true;
      }
    } catch (e) {
      print('WindowsPlatformService: Помилка доступу до Windows API: $e');
      return false;
    }

    print('WindowsPlatformService: Всі залежності доступні ✓');
    return true;
  }

  @override
  Future<List<String>> findGameProcesses() async {
    try {
      // Використовуємо tasklist для пошуку процесів
      final result = await Process.run('tasklist', [
        '/FI',
        'IMAGENAME eq ZenlessZoneZero.exe',
      ]);
      final processes = <String>[];

      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (final line in lines) {
          if (line.toLowerCase().contains('zenless') ||
              line.toLowerCase().contains('zzz')) {
            processes.add(line.trim());
          }
        }
      }

      print(
        'WindowsPlatformService: Знайдено процесів гри: ${processes.length}',
      );
      return processes;
    } catch (e) {
      print('WindowsPlatformService: Помилка пошуку процесів: $e');
      return [];
    }
  }

  @override
  String getDisplayServerType() {
    // Windows завжди використовує DWM (Desktop Window Manager)
    return 'windows-dwm';
  }

  @override
  Future<bool> openUrlInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      final result = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (result) {
        print('WindowsPlatformService: Браузер відкрито: $url');
        return true;
      }

      print('WindowsPlatformService: Не вдалося відкрити браузер');
      return false;
    } catch (e) {
      print('WindowsPlatformService: Помилка відкриття браузера: $e');
      return false;
    }
  }

  @override
  String? getSystemDownloadsPath() {
    try {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile == null) return null;

      return path.join(userProfile, 'Downloads');
    } catch (e) {
      print(
        'WindowsPlatformService: Помилка отримання Downloads директорії: $e',
      );
      return null;
    }
  }

  // ===== Приватні методи =====

  Future<bool> _sendF10ToForegroundWindow() async {
    try {
      // Відправляємо F10 до активного вікна
      final hwnd = GetForegroundWindow();
      if (hwnd == 0) {
        print('WindowsPlatformService: Не вдалося отримати активне вікно');
        return false;
      }

      PostMessage(hwnd, WM_KEYDOWN, VK_F10, 0);
      await Future.delayed(const Duration(milliseconds: 50));
      PostMessage(hwnd, WM_KEYUP, VK_F10, 0);

      print('WindowsPlatformService: F10 відправлено до активного вікна');
      return true;
    } catch (e) {
      print('WindowsPlatformService: Помилка: $e');
      return false;
    }
  }

  Future<bool> _isJunction(String dirPath) async {
    try {
      // Використовуємо cmd для перевірки junction
      final result = await Process.run('cmd', [
        '/c',
        'dir',
        '/AL',
        dirPath,
      ], runInShell: true);

      // Якщо це junction, у виводі буде "<JUNCTION>"
      return result.stdout.toString().contains('JUNCTION');
    } catch (e) {
      return false;
    }
  }
}
