# Аналіз можливості портування ZZZ Mod Manager на Windows

## 📊 Загальний висновок

**✅ ТАК, проект можна портувати на Windows з помірними зусиллями**

Проект написаний на Flutter, що є кросплатформним фреймворком, і вже має підтримку Linux. Портування на Windows цілком можливе, але потребує деяких модифікацій.

## 🎯 Рівень складності: **СЕРЕДНІЙ** (6/10)

---

## 📝 Детальний аналіз

### ✅ Що вже працює кросплатформно:

1. **Flutter Framework** (3.8.1+)
   - ✅ Flutter підтримує Windows нативно
   - ✅ Dart код працює однаково на всіх платформах
   - ✅ UI компоненти Material Design працюють на Windows

2. **Залежності (pubspec.yaml)**
   - ✅ `flutter_riverpod` - кросплатформний
   - ✅ `file_picker` - підтримує Windows
   - ✅ `window_manager` - підтримує Windows
   - ✅ `desktop_drop` - підтримує Windows
   - ✅ `shared_preferences` - підтримує Windows
   - ✅ `http` - кросплатформний
   - ✅ `path` - кросплатформний
   - ⚠️ `pasteboard` - потрібна перевірка для Windows

3. **Symbolic Links (Основна функціональність)**
   - ✅ Dart `Link` клас підтримує Windows
   - ⚠️ **ВАЖЛИВО**: На Windows потрібні права адміністратора для створення symlinks
   - ✅ Альтернатива: можна використати Directory Junctions (не потребують прав адміна)

4. **Файлова система**
   - ✅ `dart:io` працює на Windows
   - ✅ Пакет `path` автоматично обробляє Windows-шляхи
   - ✅ Всі операції з файлами сумісні

---

### ⚠️ Що потребує адаптації:

#### 1. **F10 Auto-Reload сервіс** (Критично)

**Поточна реалізація (Linux-specific):**
```dart
// lib/services/f10_reload_service.dart
- Використовує xdotool (X11) - НЕ працює на Windows
- Використовує ydotool (Wayland) - НЕ працює на Windows
- Використовує wmctrl - НЕ працює на Windows
- Python скрипт з Linux-командами - НЕ працює на Windows
```

**Рішення для Windows:**
```dart
// Використовувати Windows API через FFI або пакет
import 'package:win32/win32.dart';

// Або проще - використати пакет keyboard_event
import 'package:keyboard_event/keyboard_event.dart';

// Альтернатива 1: SendInput API
void sendF10Windows() {
  // Знайти вікно гри через FindWindow
  final hwnd = FindWindow(null, TEXT("Zenless Zone Zero"));
  if (hwnd != 0) {
    // Відправити F10 через PostMessage/SendMessage
    PostMessage(hwnd, WM_KEYDOWN, VK_F10, 0);
    PostMessage(hwnd, WM_KEYUP, VK_F10, 0);
  }
}

// Альтернатива 2: Простіше через keyboard_event пакет
Future<void> sendF10Simple() async {
  // Використати готовий пакет для симуляції клавіш
}
```

**Необхідні пакети:**
- `win32` (для Windows API)
- `ffi` (для викликів нативного коду)
- Альтернатива: `keyboard_event` або `hotkey_manager`

#### 2. **Шляхи та environment variables**

**Поточний код:**
```dart
// lib/utils/path_helper.dart
final homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
final xdgDataHome = Platform.environment['XDG_DATA_HOME'] ?? 
                    path.join(homeDir, '.local', 'share');
```

**Адаптація для Windows:**
```dart
String getDataPath() {
  if (Platform.isWindows) {
    // Windows: %APPDATA%\zzz-mod-manager
    final appData = Platform.environment['APPDATA'];
    return path.join(appData!, 'zzz-mod-manager');
  } else {
    // Linux: ~/.local/share/zzz-mod-manager
    final homeDir = Platform.environment['HOME'];
    final xdgDataHome = Platform.environment['XDG_DATA_HOME'] ?? 
                        path.join(homeDir!, '.local', 'share');
    return path.join(xdgDataHome, 'zzz-mod-manager');
  }
}
```

#### 3. **Process calls та Linux-команди**

**Проблемні місця:**
```dart
// Всі виклики Linux-команд у f10_reload_service.dart
await Process.run('ps', ['aux']);          // Linux-only
await Process.run('which', ['xdotool']);   // Linux-only
await Process.run('wmctrl', ['-a', name]); // Linux-only
```

**Рішення:**
- Додати Platform.isWindows перевірки
- Використати Windows-еквіваленти:
  - `ps` → `tasklist` або Windows API
  - `which` → `where` або перевірка через PATH
  - Пошук вікна → `FindWindow` з win32

#### 4. **Symbolic Links vs Directory Junctions**

**Проблема:**
Windows вимагає права адміністратора для створення symlinks на директорії.

**Рішення:**
```dart
Future<bool> createLinkWindows(String target, String link) async {
  if (Platform.isWindows) {
    // Спочатку спробувати symlink
    try {
      await Link(link).create(target, recursive: false);
      return true;
    } catch (e) {
      // Якщо не вдалося (немає прав), використати mklink /J (junction)
      try {
        final result = await Process.run('cmd', [
          '/c', 'mklink', '/J', link, target
        ]);
        return result.exitCode == 0;
      } catch (e) {
        print('Не вдалося створити junction: $e');
        return false;
      }
    }
  } else {
    // Linux - звичайний symlink
    await Link(link).create(target, recursive: false);
    return true;
  }
}
```

**Альтернатива (краща):**
Попросити користувача запустити програму один раз як адміністратор для активації Developer Mode:
```powershell
# В Developer Mode не потрібні права адміна для symlinks
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowDevelopmentWithoutDevLicense" /d "1"
```

---

### 🔧 Необхідні зміни в коді

#### Файли що потребують модифікації:

1. **`lib/services/f10_reload_service.dart`** - КРИТИЧНО
   - Повна переробка для Windows
   - Додати Platform.isWindows перевірки
   - Реалізувати Windows-версію відправки F10

2. **`lib/services/mod_manager_service.dart`** - СЕРЕДНЬО
   - Адаптувати створення symlinks
   - Додати fallback на junctions

3. **`lib/utils/path_helper.dart`** - ЛЕГКО
   - Змінити шляхи для Windows (APPDATA замість XDG)

4. **`scripts/f10_reload.py`** - НЕ ПОТРІБНО
   - На Windows можна не використовувати
   - Або переписати для Windows (PowerShell)

---

## 📋 План портування

### Етап 1: Базова підтримка Windows (Пріоритет: ВИСОКИЙ)

```bash
# Крок 1: Додати Windows платформу
cd mod_manager_flutter
flutter create --platforms=windows .

# Крок 2: Перевірити збірку
flutter build windows --release
```

### Етап 2: Адаптація коду (Пріоритет: ВИСОКИЙ)

1. **Модифікувати `lib/utils/path_helper.dart`**
   - Додати Windows-шляхи
   - Використовувати `Platform.isWindows`

2. **Створити `lib/services/f10_reload_service_windows.dart`**
   - Окремий файл для Windows-реалізації
   - Використати win32 або keyboard_event

3. **Оновити `lib/services/mod_manager_service.dart`**
   - Додати підтримку junctions
   - Fallback для користувачів без прав

### Етап 3: Тестування (Пріоритет: СЕРЕДНІЙ)

1. Протестувати на Windows 10/11
2. Перевірити роботу з правами адміністратора
3. Протестувати з Developer Mode
4. Перевірити роботу з 3DMigoto/XXMI на Windows

### Етап 4: Документація (Пріоритет: СЕРЕДНІЙ)

1. Оновити README з інструкціями для Windows
2. Додати Windows-specific налаштування
3. Пояснити про права адміністратора

---

## 💡 Рекомендації

### Варіант 1: Повна кросплатформність (Рекомендовано)

```dart
// lib/services/platform_service.dart
abstract class PlatformService {
  Future<bool> sendF10();
  Future<bool> createModLink(String source, String target);
  String getDataPath();
}

// lib/services/platform_service_linux.dart
class LinuxPlatformService implements PlatformService {
  // Поточна реалізація
}

// lib/services/platform_service_windows.dart
class WindowsPlatformService implements PlatformService {
  @override
  Future<bool> sendF10() async {
    // Windows реалізація через win32
  }
  
  @override
  Future<bool> createModLink(String source, String target) async {
    // Спочатку symlink, потім junction fallback
  }
  
  @override
  String getDataPath() {
    return path.join(Platform.environment['APPDATA']!, 'zzz-mod-manager');
  }
}

// lib/services/platform_service_factory.dart
PlatformService getPlatformService() {
  if (Platform.isWindows) {
    return WindowsPlatformService();
  } else if (Platform.isLinux) {
    return LinuxPlatformService();
  }
  throw UnsupportedError('Platform not supported');
}
```

### Варіант 2: Мінімальна адаптація

1. Додати Platform.isWindows перевірки
2. Вимкнути F10 auto-reload на Windows (manual F10 тільки)
3. Використовувати cmd mklink для junctions
4. Змінити шляхи на APPDATA

---

## 📦 Додаткові залежності для Windows

```yaml
# pubspec.yaml
dependencies:
  # Існуючі залежності...
  
  # Windows-specific
  win32: ^5.0.0              # Для Windows API
  ffi: ^2.1.0                # Для нативних викликів
  
  # Опціонально (для спрощення роботи з клавішами)
  hotkey_manager: ^0.2.0     # Глобальні гарячі клавіші
  # або
  keyboard_event: ^0.3.0     # Симуляція клавіш
```

---

## ⚠️ Важливі зауваження

### 1. Права адміністратора на Windows

**Проблема:** Symbolic links на Windows вимагають прав адміна (якщо не ввімкнено Developer Mode)

**Рішення:**
- **Варіант A**: Просити користувача увімкнути Developer Mode (Windows 10+)
  ```
  Settings → Update & Security → For developers → Developer Mode (ON)
  ```
  
- **Варіант B**: Використовувати Directory Junctions замість symlinks
  ```
  mklink /J <link> <target>  # Не потребує прав адміна
  ```
  
- **Варіант C**: Запускати програму як адміністратор (не рекомендовано)

### 2. 3DMigoto на Windows

- 3DMigoto працює на Windows нативно
- Потрібно підтримати шляхи Windows (C:\Games\...)
- F10 працює так само як на Linux (просто натискання клавіші)

### 3. Wine/Proton

- На Linux використовується Wine/Proton
- На Windows гра запускається нативно
- Пошук процесу простіше (не потрібно шукати wine процеси)

---

## 🎯 Оцінка часу розробки

| Задача | Складність | Час |
|--------|-----------|------|
| Додати Windows platform | Легко | 30 хв |
| Адаптувати path_helper | Легко | 1 год |
| Реалізувати Windows F10 service | Середньо | 4-6 год |
| Адаптувати symlinks/junctions | Середньо | 2-3 год |
| Тестування на Windows | Середньо | 3-4 год |
| Документація | Легко | 1-2 год |
| **ЗАГАЛОМ** | | **12-17 год** |

---

## ✅ Висновок

### Можливість реалізації: **ТАК (95%)**

**Переваги:**
- ✅ Flutter вже підтримує Windows
- ✅ Більшість коду кросплатформна
- ✅ Symbolic links працюють на Windows
- ✅ Всі UI компоненти сумісні

**Виклики:**
- ⚠️ Потрібно переписати F10 reload service
- ⚠️ Права адміністратора для symlinks (але є рішення)
- ⚠️ Тестування на реальному Windows

**Рекомендація:**
Портування цілком здійсненне та доцільне. Більшість часу піде на:
1. Реалізацію Windows F10 service (40%)
2. Тестування та відладку (30%)
3. Адаптацію файлової системи (20%)
4. Документацію (10%)

**Наступні кроки:**
1. Створити Windows platform через flutter create
2. Додати win32 залежність
3. Реалізувати WindowsPlatformService
4. Протестувати на Windows 10/11
5. Оновити документацію

---

## 📚 Корисні ресурси

- [Flutter Windows Desktop](https://docs.flutter.dev/platform-integration/windows/building)
- [win32 package](https://pub.dev/packages/win32)
- [Windows Symbolic Links](https://learn.microsoft.com/en-us/windows/win32/fileio/symbolic-links)
- [Directory Junctions](https://learn.microsoft.com/en-us/windows/win32/fileio/hard-links-and-junctions)
- [SendInput API](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendinput)

---

**Автор аналізу:** GitHub Copilot CLI  
**Дата:** 3 жовтня 2025  
**Версія проекту:** 1.0.0+1
