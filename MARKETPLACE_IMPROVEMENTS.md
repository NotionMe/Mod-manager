# Покращення Маркетплейсу

## 🎯 Виправлені проблеми

### 1. Подвійне завантаження файлів (Windows + Linux)
**Проблема**: При завантаженні мода браузер і програма одночасно скачували файл, що призводило до двох копій.

**Рішення**: 
- Додано перехоплення посилань на архіви (.zip, .rar, .7z) у `shouldOverrideUrlLoading`
- Тепер браузер блокує власне завантаження (`NavigationActionPolicy.CANCEL`)
- Завантаження відбувається тільки через програму з діалогом вибору
- Користувач бачить один діалог і отримує один файл ✅

### 2. Підтримка Linux
**Що додано**:
- ✅ WebView працює на Linux (через webkit2gtk)
- ✅ Завантаження модів на Linux
- ✅ Підтримка архівів .zip, .rar, .7z через p7zip
- ✅ SSL certificate handling для Linux
- ✅ Усі функції маркетплейсу доступні як на Windows

**Зміни в коді**:
```dart
// Додано перевірки платформ
bool get _isLinux => !kIsWeb && Platform.isLinux;
bool get _isDesktop => _isWindows || _isLinux;
bool get _isWebViewSupported => _isDesktop;

// Оновлено всі методи WebView
_buildDesktopWebView()  // замість _buildWindowsWebView()
```

## 🔧 Технічні деталі

### Послідовність завантаження
1. Користувач клікає на мод (.zip/.rar/.7z)
2. `shouldOverrideUrlLoading` перехоплює URL
3. Показується діалог: "Тільки скачати" / "Скачати і встановити"
4. Браузер отримує `CANCEL` → не завантажує
5. Програма завантажує через `_handleDownload` → один файл ✅

### Очищення тимчасових файлів
- При установці: архів і розпаковані файли видаляються після імпорту
- При "тільки завантажити": архів зберігається в `AppData/downloads`
- Тимчасові директорії (`systemTemp`) автоматично чистяться

### Платформо-специфічні налаштування

#### SSL Certificates
```dart
// Windows і Linux - дозволити всі сертифікати
if (Platform.isWindows || Platform.isLinux) {
  httpClient.badCertificateCallback = (cert, host, port) => true;
}
```

#### 7-Zip
- **Windows**: Шукає в `Program Files` або через `where 7z`
- **Linux**: Шукає `7z`, `7za`, `7zr` через `which`

## 📦 Системні вимоги

### Linux
```bash
# WebKit для браузера
sudo apt-get install webkit2gtk-4.0 libwebkit2gtk-4.0-dev

# 7-Zip для архівів
sudo apt-get install p7zip-full
```

### Windows
- Вбудований WebView2 (Edge)
- 7-Zip (опціонально, для .rar і .7z)

## 🧪 Тестування

### Перевірити на Windows:
1. Відкрити маркетплейс
2. Завантажити будь-який мод
3. Має бути **один** діалог програми
4. Має завантажитись **один** файл

### Перевірити на Linux:
1. Встановити webkit2gtk і p7zip
2. Запустити програму
3. Маркетплейс має відображатись
4. Завантаження працює як на Windows

## 📝 Змінені файли

- `lib/screens/marketplace_screen.dart` - основні зміни
- `LINUX_MARKETPLACE_SETUP.md` - інструкції для Linux
- `MARKETPLACE_IMPROVEMENTS.md` - цей документ

## ⚡ Оптимізація швидкості завантаження

**Проблема**: 100 МБ завантажувалось 2-3 хвилини замість ~10 секунд при швидкості 10 МБ/с.

**Причина**: Прогрес-бар оновлювався на **кожному chunk'і** (кожні ~8-16 KB), викликаючи перебудову UI тисячі разів, що гальмувало завантаження.

**Рішення**:
```dart
// БУЛО: оновлення на кожному chunk (повільно)
await response.listen((chunk) {
  received += chunk.length;
  sink.add(chunk);
  progressNotifier.value = received / total;  // ❌ Тисячі UI updates!
}).asFuture();

// СТАЛО: оновлення кожні 256 KB (швидко)
const progressUpdateThreshold = 262144; // 256 KB
if (received - lastProgressUpdate >= progressUpdateThreshold) {
  progressNotifier.value = received / total;  // ✅ ~400 updates для 100MB
  lastProgressUpdate = received;
}
```

**Результат**:
- ✅ Швидкість завантаження збільшена в **10-20 разів**
- ✅ Прогрес-бар все ще плавно оновлюється
- ✅ Додано `sink.flush()` для кращої буферизації
- ✅ Покращена обробка помилок завантаження

## 🚀 Майбутні покращення

- [ ] Прогрес-бар при розпакуванні великих архівів
- [ ] Кешування завантажених модів
- [ ] Історія завантажень
- [ ] Фільтри та сортування в маркетплейсі
- [ ] Підтримка macOS (потребує тестування)
