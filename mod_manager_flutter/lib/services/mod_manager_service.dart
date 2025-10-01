import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/character_info.dart';
import 'config_service.dart';

/// Головний сервіс для керування модами через symbolic links
class ModManagerService {
  final ConfigService _configService;

  ModManagerService(this._configService);

  /// Отримати шлях до папки з оригінальними модами (SaveMods)
  String? get modsPath => _configService.modsPath;

  /// Отримати шлях до папки куди створювати links (Mods)
  String? get saveModsPath => _configService.saveModsPath;

  /// Перевірка чи шляхи налаштовані і валідні
  Future<(bool, String)> validatePaths() async {
    final mods = modsPath;
    final saveMods = saveModsPath;

    if (mods == null || mods.isEmpty || saveMods == null || saveMods.isEmpty) {
      return (
        false,
        'Шляхи не налаштовані. Будь ласка, налаштуйте їх у Налаштуваннях.',
      );
    }

    final modsDir = Directory(mods);
    if (!await modsDir.exists()) {
      return (false, 'Папка з модами не існує: $mods');
    }

    final saveModsDir = Directory(saveMods);
    // Папка для links може не існувати - створимо при потребі
    if (await saveModsDir.exists()) {
      final stat = await saveModsDir.stat();
      if (stat.type != FileSystemEntityType.directory) {
        return (false, 'Шлях для links існує але не є папкою: $saveMods');
      }
    }

    return (true, '');
  }

  /// Сканує папку з оригінальними модами і повертає список доступних модів
  Future<List<String>> scanMods() async {
    try {
      final (valid, error) = await validatePaths();
      if (!valid) {
        print('Невалідні шляхи: $error');
        return [];
      }

      final modsDir = Directory(modsPath!);
      if (!await modsDir.exists()) {
        print('Папка з модами не існує: $modsPath');
        return [];
      }

      final mods = <String>[];
      await for (final entity in modsDir.list()) {
        if (entity is Directory) {
          // Пропускаємо системні/приховані папки
          final name = path.basename(entity.path);
          if (!name.startsWith('.') && !name.startsWith('__')) {
            mods.add(name);
          }
        }
      }

      print('Знайдено модів: ${mods.length}');
      return mods;
    } catch (e) {
      print('Помилка сканування модів: $e');
      return [];
    }
  }

  /// Отримати інформацію про всі моди
  Future<List<ModInfo>> getModsInfo() async {
    try {
      final modNames = await scanMods();
      final modsInfo = <ModInfo>[];

      for (final modName in modNames) {
        final isActive = await isModActive(modName);
        final imagePath = await _findModImage(modName);

        modsInfo.add(
          ModInfo(
            id: modName,
            name: modName,
            characterId: 'unknown',
            isActive: isActive,
            imagePath: imagePath,
          ),
        );
      }

      return modsInfo;
    } catch (e) {
      print('Помилка отримання інформації про моди: $e');
      return [];
    }
  }

  /// Перевіряє чи мод активний (чи існує symlink)
  Future<bool> isModActive(String modName) async {
    try {
      if (saveModsPath == null) return false;

      final linkPath = path.join(saveModsPath!, modName);

      // Перевіряємо чи існує файл/папка за цим шляхом
      final exists =
          await FileSystemEntity.type(linkPath) !=
          FileSystemEntityType.notFound;
      if (!exists) return false;

      // Перевіряємо чи це саме symlink
      final isLink = await FileSystemEntity.isLink(linkPath);
      return isLink;
    } catch (e) {
      print('Помилка перевірки активності моду: $e');
      return false;
    }
  }

  /// Активувати мод (створити symbolic link)
  Future<bool> activateMod(String modName) async {
    try {
      final (valid, error) = await validatePaths();
      if (!valid) {
        print('Помилка валідації шляхів: $error');
        return false;
      }

      final srcPath = path.join(modsPath!, modName);
      final dstPath = path.join(saveModsPath!, modName);

      // Перевіряємо чи джерело існує
      final srcDir = Directory(srcPath);
      if (!await srcDir.exists()) {
        print('Папка моду не існує: $srcPath');
        return false;
      }

      // Створюємо папку SaveMods якщо не існує
      final saveModsDir = Directory(saveModsPath!);
      if (!await saveModsDir.exists()) {
        await saveModsDir.create(recursive: true);
      }

      // Видаляємо якщо вже існує щось за цим шляхом
      final dst = Link(dstPath);
      if (await dst.exists() || await FileSystemEntity.isLink(dstPath)) {
        await _safeRemove(dstPath);
      }

      // Створюємо symlink
      await Link(dstPath).create(srcPath, recursive: false);
      print('Створено symlink: $dstPath -> $srcPath');

      // Оновлюємо конфігурацію
      await _configService.addActiveMod(modName);

      return true;
    } catch (e) {
      print('Помилка активації моду: $e');
      return false;
    }
  }

  /// Деактивувати мод (видалити symbolic link)
  Future<bool> deactivateMod(String modName) async {
    try {
      if (saveModsPath == null) {
        print('❌ Шлях SaveMods не налаштований');
        return false;
      }

      final linkPath = path.join(saveModsPath!, modName);

      // Перевіряємо чи існує
      final exists =
          await FileSystemEntity.type(linkPath) !=
          FileSystemEntityType.notFound;
      print('🔍 Перевірка існування: $linkPath - exists: $exists');

      if (!exists) {
        print('⚠️ Файл не існує: $linkPath');
        return false;
      }

      // Перевіряємо чи це symlink
      final isLink = await FileSystemEntity.isLink(linkPath);
      print('🔍 Перевірка типу: isLink: $isLink');

      if (!isLink) {
        print('❌ Це не symlink: $linkPath');
        return false;
      }

      // Видаляємо symlink
      final link = Link(linkPath);
      await link.delete();
      print('✅ Видалено symlink: $linkPath');

      // Перевіряємо чи видалено
      final stillExists =
          await FileSystemEntity.type(linkPath) !=
          FileSystemEntityType.notFound;
      print('🔍 Після видалення - stillExists: $stillExists');

      // Оновлюємо конфігурацію
      await _configService.removeActiveMod(modName);

      return true;
    } catch (e) {
      print('❌ Помилка деактивації моду: $e');
      return false;
    }
  }

  /// Переключити стан моду (активувати/деактивувати)
  Future<bool> toggleMod(String modName) async {
    final isActive = await isModActive(modName);
    print(
      '🔄 Toggle мод: $modName, поточний стан: ${isActive ? "активний" : "неактивний"}',
    );

    if (isActive) {
      print('➡️ Деактивація...');
      final result = await deactivateMod(modName);
      print('Результат деактивації: $result');
      return result;
    } else {
      print('➡️ Активація...');
      final result = await activateMod(modName);
      print('Результат активації: $result');
      return result;
    }
  }

  /// Знайти зображення для моду
  Future<String?> _findModImage(String modName) async {
    try {
      final modPath = path.join(modsPath!, modName);
      final modDir = Directory(modPath);

      if (!await modDir.exists()) return null;

      // Шукаємо Preview.png або інші зображення
      final imageNames = [
        'Preview.png',
        'preview.png',
        'thumbnail.png',
        'icon.png',
      ];

      for (final imageName in imageNames) {
        final imagePath = path.join(modPath, imageName);
        final imageFile = File(imagePath);
        if (await imageFile.exists()) {
          return imagePath;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Безпечно видалити файл/symlink
  Future<void> _safeRemove(String filePath) async {
    try {
      final entity = await FileSystemEntity.type(filePath);

      if (entity == FileSystemEntityType.link) {
        await Link(filePath).delete();
      } else if (entity == FileSystemEntityType.directory) {
        await Directory(filePath).delete(recursive: true);
      } else if (entity == FileSystemEntityType.file) {
        await File(filePath).delete();
      }
    } catch (e) {
      print('Помилка видалення: $e');
    }
  }
}
