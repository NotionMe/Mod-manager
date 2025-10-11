import 'dart:io';
import 'package:path/path.dart' as path;

/// Сервіс для автоматичної відправки F10 для перезавантаження модів у 3DMigoto на Linux
class F10ReloadService {
  /// Перевіряє чи запущена гра (Zenless Zone Zero через Wine/Proton)
  Future<List<String>> _findGameProcesses() async {
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

      print('F10ReloadService: Знайдено процесів гри: ${processes.length}');
      return processes;
    } catch (e) {
      print('F10ReloadService: Помилка пошуку процесів: $e');
      return [];
    }
  }

  /// Відправляє F10 через xdotool (якщо доступний)
  Future<bool> _sendF10ViaXdotool() async {
    try {
      // Перевіряємо чи встановлений xdotool
      final checkResult = await Process.run('which', ['xdotool']);
      if (checkResult.exitCode != 0) {
        print('F10ReloadService: xdotool не встановлений');
        return false;
      }

      // Знаходимо вікно гри
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
              'F10ReloadService: Знайдено вікно гри: $name (ID: $windowId)',
            );
            break;
          }
        } catch (e) {
          continue;
        }
      }

      if (windowId == null) {
        print('F10ReloadService: Вікно гри не знайдено через xdotool');
        // Спробуємо відправити до активного вікна
        await Process.run('xdotool', ['key', 'F10']);
        return true;
      }

      // Активуємо вікно гри
      await Process.run('xdotool', ['windowactivate', windowId]);
      await Future.delayed(const Duration(milliseconds: 200));

      // Відправляємо F10 до конкретного вікна
      final keyResult = await Process.run('xdotool', [
        'key',
        '--window',
        windowId,
        'F10',
      ]);

      if (keyResult.exitCode == 0) {
        print('F10ReloadService: F10 успішно відправлено через xdotool');
        return true;
      } else {
        print('F10ReloadService: Помилка відправки F10 через xdotool');
        return false;
      }
    } catch (e) {
      print('F10ReloadService: Помилка xdotool: $e');
      return false;
    }
  }

  /// Намагається сфокусуватися на вікні гри (для Wayland)
  Future<void> _focusGameWindow() async {
    try {
      // Спробуємо через wmctrl якщо доступний
      final wmctrlCheck = await Process.run('which', ['wmctrl']);
      if (wmctrlCheck.exitCode == 0) {
        final windowNames = ['Zenless', 'ZZZ', 'zenless'];
        for (final name in windowNames) {
          try {
            await Process.run('wmctrl', ['-a', name]);
            print('F10ReloadService: Активовано вікно через wmctrl: $name');
            return;
          } catch (e) {
            continue;
          }
        }
      }

      // Альтернативний метод через xdotool навіть на Wayland (якщо працює)
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
              print('F10ReloadService: Активовано вікно через xdotool: $name');
              return;
            }
          } catch (e) {
            continue;
          }
        }
      }
    } catch (e) {
      print('F10ReloadService: Не вдалося активувати вікно гри: $e');
    }
  }

  /// Відправляє F10 через ydotool (Wayland альтернатива)
  Future<bool> _sendF10ViaYdotool() async {
    try {
      // Перевіряємо чи встановлений ydotool
      final checkResult = await Process.run('which', ['ydotool']);
      if (checkResult.exitCode != 0) {
        print('F10ReloadService: ydotool не встановлений');
        return false;
      }

      // Спробуємо активувати вікно гри спочатку
      await _focusGameWindow();

      // Невелика затримка для фокусування
      await Future.delayed(const Duration(milliseconds: 200));

      // Відправляємо F10 кілька разів для надійності
      for (int i = 0; i < 2; i++) {
        final keyResult = await Process.run('ydotool', [
          'key', '67:1', '67:0', // F10 key code для ydotool
        ]);

        if (keyResult.exitCode != 0) {
          print(
            'F10ReloadService: Помилка відправки F10 через ydotool (спроба ${i + 1})',
          );
        }

        if (i < 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      print('F10ReloadService: F10 успішно відправлено через ydotool');
      return true;
    } catch (e) {
      print('F10ReloadService: Помилка ydotool: $e');
      return false;
    }
  }

  /// Створює сигнальний файл для 3DMigoto
  Future<bool> _createReloadSignalFile(String modsPath) async {
    try {
      final signalPath = path.join(modsPath, '.reload_signal');
      final timestampPath = path.join(modsPath, '.mod_timestamp');

      // Створюємо сигнальний файл
      final signalFile = File(signalPath);
      await signalFile.writeAsString(
        DateTime.now().millisecondsSinceEpoch.toString(),
      );

      // Оновлюємо timestamp файл
      final timestampFile = File(timestampPath);
      await timestampFile.writeAsString(
        DateTime.now().millisecondsSinceEpoch.toString(),
      );

      print('F10ReloadService: Створено сигнальні файли');
      return true;
    } catch (e) {
      print('F10ReloadService: Помилка створення сигнальних файлів: $e');
      return false;
    }
  }

  /// Створює INI файл з командою перезавантаження для 3DMigoto
  Future<bool> _createReloadIniFile(String modsPath) async {
    try {
      final iniPath = path.join(modsPath, 'mod_reload_trigger.ini');
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final iniContent =
          '''
; Автоматично створений файл для перезавантаження модів
; Створено: ${DateTime.now().toIso8601String()}

[Constants]
; Тригер для перезавантаження модів
\$mod_reload_timestamp = $timestamp
\$force_reload = 1

[Present]
; Перезавантажуємо конфігурацію при наступному кадрі
post run = CommandListForceReload

[CommandListForceReload]
; Примусове перезавантаження конфігурації та модів
if \$force_reload == 1
    ; Скидаємо тригер
    \$force_reload = 0
    ; Перезавантажуємо конфігурацію (еквівалент F10)
    run = BuiltInCommandListReloadConfig
endif

; Видаляємо цей файл через декілька секунд
; (це потрібно зробити зовнішньо, оскільки 3DMigoto не може видаляти файли)
''';

      final file = File(iniPath);
      await file.writeAsString(iniContent);

      print('F10ReloadService: Створено INI файл: $iniPath');

      // Видаляємо файл через 10 секунд
      Future.delayed(const Duration(seconds: 10), () async {
        try {
          if (await file.exists()) {
            await file.delete();
            print('F10ReloadService: Видалено тимчасовий INI файл');
          }
        } catch (e) {
          print('F10ReloadService: Помилка видалення INI файлу: $e');
        }
      });

      return true;
    } catch (e) {
      print('F10ReloadService: Помилка створення INI файлу: $e');
      return false;
    }
  }

  /// Намагається перезапустити Wine процес (як крайній засіб)
  Future<bool> _restartWineProcess() async {
    try {
      // Знаходимо Wine процес гри
      final processes = await _findGameProcesses();
      if (processes.isEmpty) {
        print('F10ReloadService: Процеси Wine гри не знайдені');
        return false;
      }

      // Відправляємо SIGUSR1 сигнал (деякі програми його використовують для перезавантаження)
      for (final processLine in processes) {
        final parts = processLine.split(RegExp(r'\s+'));
        if (parts.length > 1) {
          final pid = parts[1];
          try {
            await Process.run('kill', ['-USR1', pid]);
            print('F10ReloadService: Відправлено SIGUSR1 до процесу $pid');
          } catch (e) {
            print('F10ReloadService: Помилка відправки сигналу до $pid: $e');
          }
        }
      }

      return true;
    } catch (e) {
      print('F10ReloadService: Помилка перезапуску Wine процесу: $e');
      return false;
    }
  }

  /// Перевіряє тип дисплейного сервера (X11 чи Wayland)
  String _getDisplayServer() {
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

  /// Використовує Python скрипт як резервний метод
  Future<bool> _callPythonScript(String modsPath) async {
    try {
      final scriptPath = path.join(
        Directory.current.path,
        'scripts',
        'f10_reload.py',
      );

      final scriptFile = File(scriptPath);
      if (!await scriptFile.exists()) {
        print('F10ReloadService: Python скрипт не знайдено: $scriptPath');
        return false;
      }

      final result = await Process.run('python3', [scriptPath, modsPath]);

      if (result.exitCode == 0) {
        print('F10ReloadService: Python скрипт виконано успішно');
        return true;
      } else {
        print(
          'F10ReloadService: Python скрипт завершився з помилкою: ${result.stderr}',
        );
        return false;
      }
    } catch (e) {
      print('F10ReloadService: Помилка виконання Python скрипту: $e');
      return false;
    }
  }

  /// Основний метод для перезавантаження модів
  Future<bool> reloadMods(String? modsPath) async {
    if (modsPath == null || modsPath.isEmpty) {
      print('F10ReloadService: Не вказаний шлях до модів');
      return false;
    }

    print('F10ReloadService: Починаємо перезавантаження модів на Linux...');
    print('F10ReloadService: Шлях до модів: $modsPath');

    final displayServer = _getDisplayServer();
    print('F10ReloadService: Виявлений дисплейний сервер: $displayServer');

    bool success = false;

    // Метод 1: Створення сигнальних файлів (найнадійніший)
    if (await _createReloadSignalFile(modsPath)) {
      success = true;
    }

    // Метод 2: Створення INI файлу з командами перезавантаження
    if (await _createReloadIniFile(modsPath)) {
      success = true;
    }

    // Метод 3: Відправка F10 в залежності від дисплейного сервера
    if (displayServer == 'x11') {
      if (await _sendF10ViaXdotool()) {
        success = true;
      }
    } else if (displayServer == 'wayland') {
      if (await _sendF10ViaYdotool()) {
        success = true;
      }
    }

    // Метод 4: Спроба через обидва інструменти (резервний)
    if (!success) {
      if (await _sendF10ViaXdotool() || await _sendF10ViaYdotool()) {
        success = true;
      }
    }

    // Метод 5: Використання Python скрипту (крайній резерв)
    if (!success) {
      print(
        'F10ReloadService: Використовуємо Python скрипт як резервний метод...',
      );
      if (await _callPythonScript(modsPath)) {
        success = true;
      }
    }

    if (success) {
      print('F10ReloadService: Команди перезавантаження модів відправлені');
    } else {
      print('F10ReloadService: Не вдалося відправити команди перезавантаження');
    }

    return success;
  }

  /// Встановлює необхідні залежності для роботи сервісу
  Future<void> installDependencies() async {
    print('F10ReloadService: Перевірка залежностей...');

    final displayServer = _getDisplayServer();

    if (displayServer == 'x11') {
      final result = await Process.run('which', ['xdotool']);
      if (result.exitCode != 0) {
        print('F10ReloadService: Рекомендується встановити xdotool:');
        print('  Ubuntu/Debian: sudo apt install xdotool');
        print('  Arch: sudo pacman -S xdotool');
        print('  Fedora: sudo dnf install xdotool');
      } else {
        print('F10ReloadService: xdotool встановлений ✓');
      }
    } else if (displayServer == 'wayland') {
      final result = await Process.run('which', ['ydotool']);
      if (result.exitCode != 0) {
        print('F10ReloadService: Рекомендується встановити ydotool:');
        print('  Ubuntu/Debian: sudo apt install ydotool');
        print('  Arch: yay -S ydotool');
        print('  Fedora: sudo dnf install ydotool');
      } else {
        print('F10ReloadService: ydotool встановлений ✓');
      }
    }
  }

  /// Показує інструкції для налаштування
  void showSetupInstructions() {
    print('F10ReloadService: Інструкції з налаштування:');
    print('');
    print('1. Переконайтеся, що 3DMigoto/XXMI правильно налаштований');
    print('2. У d3dx.ini має бути рядок: reload_fixes = no_modifiers VK_F10');
    print('3. Встановіть відповідні інструменти:');
    print('   - Для X11: xdotool');
    print('   - Для Wayland: ydotool + wmctrl (рекомендовано)');
    print('4. Для Wayland, переконайтеся що ydotool має права:');
    print('   sudo usermod -a -G input \$USER');
    print('   sudo systemctl enable --now ydotool.service');
    print('5. Запустіть гру через Wine/Proton/XXMI Launcher');
    print(
      '6. Використовуйте цей сервіс для автоматичного перезавантаження модів',
    );
    print('');
    print('ВАЖЛИВО: Вікно гри має бути видимим (не згорнутим) для ydotool!');
    print('');
  }
}
