import 'dart:io';

/// Абстрактний клас для платформно-специфічних операцій
abstract class PlatformService {
  /// Відправляє F10 у вікно гри для перезавантаження модів
  Future<bool> sendF10ToGame();

  /// Створює symbolic link або його аналог (junction на Windows)
  Future<bool> createModLink(String sourcePath, String linkPath);

  /// Видаляє symbolic link або його аналог
  Future<bool> removeModLink(String linkPath);

  /// Перевіряє чи є шлях symbolic link
  Future<bool> isModLink(String linkPath);

  /// Отримує шлях до директорії даних додатку
  String getAppDataPath();

  /// Показує інструкції по налаштуванню для конкретної платформи
  void showSetupInstructions();

  /// Перевіряє наявність необхідних інструментів/залежностей
  Future<bool> checkDependencies();

  /// Знаходить процеси гри
  Future<List<String>> findGameProcesses();

  /// Визначає тип дисплейного сервера (для Linux)
  String getDisplayServerType() => 'unknown';

  /// Відкриває URL у зовнішньому браузері
  Future<bool> openUrlInBrowser(String url);

  /// Отримує шлях до системної Downloads директорії користувача
  String? getSystemDownloadsPath();
}
