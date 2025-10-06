# Windows Installer для ZZZ Mod Manager

Ця директорія містить все необхідне для створення Windows installer (.exe).

## Вимоги

1. **Inno Setup 6** або новіше
   - Завантажити: https://jrsoftware.org/isdl.php
   - Безкоштовний та open-source інструмент для створення Windows installers
   - Встановити з опцією "Compiler" (за замовчуванням)

2. **Flutter SDK** (якщо ще не встановлений)
   - Завантажити: https://docs.flutter.dev/get-started/install/windows
   - Додати до PATH системи

## Швидкий старт

### Автоматична побудова (рекомендовано)

Просто запустіть:
```cmd
build_installer.bat
```

Цей скрипт автоматично:
1. Збілдить Flutter додаток для Windows (Release)
2. Перевірить наявність Inno Setup
3. Створить installer

### Ручна побудова

Якщо потрібно більше контролю:

1. **Білд Flutter додатку:**
   ```cmd
   cd mod_manager_flutter
   flutter build windows --release
   cd ..
   ```

2. **Створення installer:**
   - Відкрийте `setup.iss` у Inno Setup Compiler
   - Або виконайте з командного рядка:
     ```cmd
     "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" windows_installer\setup.iss
     ```

3. **Результат:**
   Installer буде створений у `windows_installer/output/`

## Структура файлів

```
windows_installer/
├── setup.iss              # Основний скрипт Inno Setup
├── build_installer.bat    # Автоматичний білд скрипт
├── README.md             # Ця документація
└── output/               # Директорія з результатами (створюється автоматично)
    └── ZZZ-Mod-Manager-Setup-1.0.0.exe
```

## Налаштування installer

Відкрийте `setup.iss` для налаштування:

### Основні параметри (вгорі файлу):

```pascal
#define MyAppName "ZZZ Mod Manager"
#define MyAppVersion "1.0.0"          // Змініть версію
#define MyAppPublisher "NotionMe"
#define MyAppURL "https://github.com/NotionMe/Mod-manager"
```

### Додаткові опції:

- **Іконка installer**: Розкоментуйте та вкажіть шлях до .ico файлу
  ```pascal
  SetupIconFile=..\assets\icon.ico
  ```

- **Мови**: Додайте більше мов у секції `[Languages]`
  ```pascal
  Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
  ```

- **Компресія**: Змініть у секції `[Setup]`
  ```pascal
  Compression=lzma2/max       // Максимальна компресія
  Compression=lzma2/fast      // Швидша компресія
  ```

## Розповсюдження

Створений `.exe` файл:
- ✅ Не потребує розпакування
- ✅ Містить повну версію додатку
- ✅ Автоматично створює ярлики
- ✅ Додає в меню Пуск
- ✅ Включає деінсталятор
- ✅ Працює на Windows 10/11 (x64)

### Завантаження на GitHub Releases:

1. Створіть новий Release на GitHub
2. Завантажте `.exe` файл з `output/`
3. Користувачі зможуть завантажити та встановити одним кліком

## Особливості

### Права адміністратора

Installer вимагає права адміністратора, оскільки:
- Програма використовує symbolic links (симлінки)
- На Windows для створення симлінків потрібні підвищені права

Користувач побачить UAC prompt при установці.

### Системні вимоги

Installer автоматично перевіряє:
- Windows 10 або новіше
- x64 архітектура

### Після установки

Програма буде встановлена в:
- `C:\Program Files\ZZZ Mod Manager\` (за замовчуванням)
- Ярлики в меню Пуск
- Опціонально: ярлик на робочому столі

## Альтернативи

Якщо Inno Setup не підходить, є інші варіанти:

### 1. MSIX Package (Microsoft Store)
- Офіційний формат Microsoft
- Потребує цифровий підпис
- [Інструкція для Flutter](https://docs.flutter.dev/deployment/windows#msix-packaging)

### 2. WiX Toolset
- Більш складний, але потужніший
- Створює .msi файли
- [WiX Toolset](https://wixtoolset.org/)

### 3. Advanced Installer
- Комерційний (є безкоштовна версія)
- GUI-based
- [Advanced Installer](https://www.advancedinstaller.com/)

### 4. Portable ZIP
- Найпростіше рішення
- Просто запакуйте `build\windows\x64\runner\Release\` у ZIP
- Не потребує установки, але без інтеграції з системою

## Troubleshooting

### Помилка: "Inno Setup не знайдено"
- Встановіть Inno Setup з офіційного сайту
- Або змініть шлях у `build_installer.bat`

### Помилка: "Source file not found"
- Перевірте, що Flutter build успішний
- Перевірте шляхи у `setup.iss` секції `[Files]`

### Installer не запускається на Windows
- Перевірте антивірус (може блокувати)
- Перевірте, що файл не пошкоджений
- Спробуйте запустити від імені адміністратора

## Корисні посилання

- [Inno Setup Documentation](https://jrsoftware.org/ishelp/)
- [Flutter Windows Deployment](https://docs.flutter.dev/deployment/windows)
- [Inno Setup Examples](https://jrsoftware.org/isinfo.php)

## Ліцензія

Цей скрипт installer розповсюджується під тією ж ліцензією, що і основний проект.
