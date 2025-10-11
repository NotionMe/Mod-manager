import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'platform_service.dart';

/// Linux-специфічна реалізація PlatformService
class LinuxPlatformService implements PlatformService {
  @override
  Future<bool> sendF10ToGame() async {
    print('LinuxPlatformService: Відправка F10...');

    final displayServer = getDisplayServerType();
    print('LinuxPlatformService: Display server: $displayServer');

    bool success = false;

    // Метод 1: Відправка F10 через відповідний інструмент
    if (displayServer == 'x11') {
      if (await _sendF10ViaXdotool()) {
        success = true;
      }
    } else if (displayServer == 'wayland') {
      if (await _sendF10ViaYdotool()) {
        success = true;
      }
    }

    // Метод 2: Спроба через обидва інструменти (резервний)
    if (!success) {
      if (await _sendF10ViaXdotool() || await _sendF10ViaYdotool()) {
        success = true;
      }
    }

    if (success) {
      print('LinuxPlatformService: F10 успішно відправлено');
    } else {
      print('LinuxPlatformService: Не вдалося відправити F10');
    }

    return success;
  }

  @override
  Future<bool> createModLink(String sourcePath, String linkPath) async {
    try {
      // На Linux використовуємо звичайні symbolic links
      final link = Link(linkPath);

      // Видаляємо якщо вже існує
      if (await link.exists() || await FileSystemEntity.isLink(linkPath)) {
        await removeModLink(linkPath);
      }

      await link.create(sourcePath, recursive: false);
      print('LinuxPlatformService: Symlink створено: $linkPath -> $sourcePath');
      return true;
    } catch (e) {
      print('LinuxPlatformService: Помилка створення symlink: $e');
      return false;
    }
  }

  @override
  Future<bool> removeModLink(String linkPath) async {
    try {
      final isLink = await FileSystemEntity.isLink(linkPath);
      if (!isLink) {
        print('LinuxPlatformService: $linkPath не є symlink');
        return false;
      }

      await Link(linkPath).delete();
      print('LinuxPlatformService: Symlink видалено: $linkPath');
      return true;
    } catch (e) {
      print('LinuxPlatformService: Помилка видалення symlink: $e');
      return false;
    }
  }

  @override
  Future<bool> isModLink(String linkPath) async {
    try {
      return await FileSystemEntity.isLink(linkPath);
    } catch (e) {
      return false;
    }
  }

  @override
  String getAppDataPath() {
    final homeDir = Platform.environment['HOME'];
    if (homeDir == null) {
      throw Exception('HOME environment variable not found');
    }

    // Використовуємо XDG Base Directory Specification
    final xdgDataHome =
        Platform.environment['XDG_DATA_HOME'] ??
        path.join(homeDir, '.local', 'share');

    return path.join(xdgDataHome, 'zzz-mod-manager');
  }

  @override
  void showSetupInstructions() {
    print('\n═══════════════════════════════════════════════════════════');
    print('F10 Auto-Reload Setup Instructions (Linux)');
    print('═══════════════════════════════════════════════════════════\n');

    final displayServer = getDisplayServerType();

    if (displayServer == 'x11') {
      print('X11 detected. Install xdotool:');
      print('  Ubuntu/Debian: sudo apt install xdotool');
      print('  Arch: sudo pacman -S xdotool');
      print('  Fedora: sudo dnf install xdotool');
    } else if (displayServer == 'wayland') {
      print('Wayland detected. Install ydotool and wmctrl:');
      print('  Ubuntu/Debian: sudo apt install ydotool wmctrl');
      print('  Arch: yay -S ydotool wmctrl');
      print('  Fedora: sudo dnf install ydotool wmctrl');
      print('\nAdditional setup for ydotool:');
      print('  sudo usermod -a -G input \$USER');
      print('  sudo systemctl enable --now ydotool.service');
      print('  sudo reboot  # Required!');
    } else {
      print('Unknown display server. Try installing both:');
      print('  xdotool (for X11)');
      print('  ydotool + wmctrl (for Wayland)');
    }

    print('\n═══════════════════════════════════════════════════════════\n');
  }

  @override
  Future<bool> checkDependencies() async {
    print('LinuxPlatformService: Перевірка залежностей...');

    final displayServer = getDisplayServerType();
    bool hasTools = false;

    if (displayServer == 'x11') {
      final result = await Process.run('which', ['xdotool']);
      hasTools = result.exitCode == 0;
      if (hasTools) {
        print('LinuxPlatformService: xdotool встановлений ✓');
      } else {
        print('LinuxPlatformService: xdotool НЕ встановлений ✗');
      }
    } else if (displayServer == 'wayland') {
      final result = await Process.run('which', ['ydotool']);
      hasTools = result.exitCode == 0;
      if (hasTools) {
        print('LinuxPlatformService: ydotool встановлений ✓');
      } else {
        print('LinuxPlatformService: ydotool НЕ встановлений ✗');
      }
    }

    return hasTools;
  }

  @override
  Future<List<String>> findGameProcesses() async {
    try {
      final result = await Process.run('ps', ['aux']);
      final processes = <String>[];

      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (final line in lines) {
          if (line.toLowerCase().contains('zenless') ||
              line.toLowerCase().contains('zzz') ||
              line.contains('ZenlessZoneZero.exe')) {
            processes.add(line.trim());
          }
        }
      }

      print('LinuxPlatformService: Знайдено процесів гри: ${processes.length}');
      return processes;
    } catch (e) {
      print('LinuxPlatformService: Помилка пошуку процесів: $e');
      return [];
    }
  }

  @override
  String getDisplayServerType() {
    final sessionType = Platform.environment['XDG_SESSION_TYPE'];
    final waylandDisplay = Platform.environment['WAYLAND_DISPLAY'];
    final display = Platform.environment['DISPLAY'];

    if (sessionType == 'wayland' || waylandDisplay != null) {
      return 'wayland';
    } else if (display != null) {
      return 'x11';
    }

    return 'unknown';
  }

  @override
  Future<bool> openUrlInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      final canOpen = await canLaunchUrl(uri);

      if (canOpen) {
        final result = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (result) {
          print('LinuxPlatformService: Браузер відкрито: $url');
          return true;
        }
      }

      final xdgResult = await Process.run('xdg-open', [url]);
      if (xdgResult.exitCode == 0) {
        print('LinuxPlatformService: Браузер відкрито через xdg-open: $url');
        return true;
      }

      print('LinuxPlatformService: Не вдалося відкрити браузер');
      return false;
    } catch (e) {
      print('LinuxPlatformService: Помилка відкриття браузера: $e');
      return false;
    }
  }

  @override
  String? getSystemDownloadsPath() {
    try {
      final homeDir = Platform.environment['HOME'];
      if (homeDir == null) return null;

      final xdgDownloadDir = Platform.environment['XDG_DOWNLOAD_DIR'];
      if (xdgDownloadDir != null && xdgDownloadDir.isNotEmpty) {
        return xdgDownloadDir;
      }

      final downloadsDir = path.join(homeDir, 'Downloads');
      if (Directory(downloadsDir).existsSync()) {
        return downloadsDir;
      }

      final ukDownloadsDir = path.join(homeDir, 'Завантаження');
      if (Directory(ukDownloadsDir).existsSync()) {
        return ukDownloadsDir;
      }

      return downloadsDir;
    } catch (e) {
      print('LinuxPlatformService: Помилка отримання Downloads директорії: $e');
      return null;
    }
  }

  // ===== Приватні методи =====

  Future<bool> _sendF10ViaXdotool() async {
    try {
      final checkResult = await Process.run('which', ['xdotool']);
      if (checkResult.exitCode != 0) {
        return false;
      }

      String? windowId;
      final windowNames = ['Zenless', 'ZZZ', 'zenless'];

      for (final name in windowNames) {
        try {
          final windowResult = await Process.run('xdotool', [
            'search',
            '--name',
            '--onlyvisible',
            name,
          ]);

          if (windowResult.exitCode == 0 &&
              windowResult.stdout.toString().trim().isNotEmpty) {
            windowId = windowResult.stdout.toString().trim().split('\n').first;
            print(
              'LinuxPlatformService: Знайдено вікно гри: $name (ID: $windowId)',
            );
            break;
          }
        } catch (e) {
          continue;
        }
      }

      if (windowId == null) {
        await Process.run('xdotool', ['key', 'F10']);
        return true;
      }

      await Process.run('xdotool', ['windowactivate', windowId]);
      await Future.delayed(const Duration(milliseconds: 200));

      final keyResult = await Process.run('xdotool', [
        'key',
        '--window',
        windowId,
        'F10',
      ]);

      return keyResult.exitCode == 0;
    } catch (e) {
      print('LinuxPlatformService: Помилка xdotool: $e');
      return false;
    }
  }

  Future<bool> _sendF10ViaYdotool() async {
    try {
      final checkResult = await Process.run('which', ['ydotool']);
      if (checkResult.exitCode != 0) {
        return false;
      }

      await _focusGameWindow();
      await Future.delayed(const Duration(milliseconds: 200));

      for (int i = 0; i < 2; i++) {
        await Process.run('ydotool', ['key', '67:1', '67:0']);
        if (i < 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      print('LinuxPlatformService: F10 відправлено через ydotool');
      return true;
    } catch (e) {
      print('LinuxPlatformService: Помилка ydotool: $e');
      return false;
    }
  }

  Future<void> _focusGameWindow() async {
    try {
      final wmctrlCheck = await Process.run('which', ['wmctrl']);
      if (wmctrlCheck.exitCode == 0) {
        final windowNames = ['Zenless', 'ZZZ', 'zenless'];
        for (final name in windowNames) {
          try {
            await Process.run('wmctrl', ['-a', name]);
            print('LinuxPlatformService: Активовано вікно через wmctrl: $name');
            return;
          } catch (e) {
            continue;
          }
        }
      }

      final xdotoolCheck = await Process.run('which', ['xdotool']);
      if (xdotoolCheck.exitCode == 0) {
        final windowNames = ['Zenless', 'ZZZ', 'zenless'];
        for (final name in windowNames) {
          try {
            final result = await Process.run('xdotool', [
              'search',
              '--name',
              name,
            ]);

            if (result.exitCode == 0 &&
                result.stdout.toString().trim().isNotEmpty) {
              final windowId = result.stdout
                  .toString()
                  .trim()
                  .split('\n')
                  .first;
              await Process.run('xdotool', ['windowactivate', windowId]);
              print(
                'LinuxPlatformService: Активовано вікно через xdotool: $name',
              );
              return;
            }
          } catch (e) {
            continue;
          }
        }
      }
    } catch (e) {
      print('LinuxPlatformService: Не вдалося активувати вікно гри: $e');
    }
  }
}
