import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character_info.dart';
import '../models/keybind_info.dart';
import '../core/constants.dart';
import '../utils/state_providers.dart';
import '../utils/genshin_characters.dart';
import 'config_service.dart';
import 'platform_service.dart';
import 'platform_service_factory.dart';
import 'ini_parser_service.dart';

/// Головний сервіс для керування модами через symbolic links
class ModManagerService {
  final ConfigService _configService;
  final PlatformService _platformService;
  final ProviderContainer _container;
  final IniParserService _iniParser;

  ModManagerService(this._configService, this._container)
    : _platformService = PlatformServiceFactory.getInstance(),
      _iniParser = IniParserService();

  String? get modsPath => _configService.modsPath;
  String? get saveModsPath => _configService.saveModsPath;

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
    if (await saveModsDir.exists()) {
      final stat = await saveModsDir.stat();
      if (stat.type != FileSystemEntityType.directory) {
        return (false, 'Шлях для links існує але не є папкою: $saveMods');
      }
    }

    return (true, '');
  }

  Future<List<String>> scanMods() async {
    try {
      final (valid, _) = await validatePaths();
      if (!valid) return [];

      final modsDir = Directory(modsPath!);
      if (!await modsDir.exists()) return [];

      final mods = <String>[];
      await for (final entity in modsDir.list()) {
        if (entity is Directory) {
          final name = path.basename(entity.path);
          if (!name.startsWith('.') && !name.startsWith('__')) {
            mods.add(name);
          }
        }
      }

      return mods;
    } catch (e) {
      return [];
    }
  }

  Future<List<ModInfo>> getModsInfo() async {
    try {
      final modNames = await scanMods();
      final modsInfo = <ModInfo>[];
      final favoriteSet = _configService.favoriteMods.toSet();

      // Очищуємо символічні посилання на неіснуючі моди
      await _cleanupInvalidLinks();

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
            isFavorite: favoriteSet.contains(modName),
          ),
        );
      }

      return modsInfo;
    } catch (e) {
      return [];
    }
  }

  /// Видаляє символічні посилання на моди, які більше не існують
  Future<void> _cleanupInvalidLinks() async {
    try {
      if (saveModsPath == null) return;

      final saveModsDir = Directory(saveModsPath!);
      if (!await saveModsDir.exists()) return;

      final modNames = await scanMods();
      final validModNames = Set<String>.from(modNames);

      await for (final entity in saveModsDir.list()) {
        if (entity is Link) {
          final linkName = path.basename(entity.path);

          // Якщо мод більше не існує в папці модів - видаляємо символічне посилання
          if (!validModNames.contains(linkName)) {
            try {
              await entity.delete();
              await _configService.removeActiveMod(linkName);
            } catch (e) {
              // Ігноруємо помилки при видаленні
            }
          }
        }
      }
    } catch (e) {
      // Ігноруємо помилки
    }
  }

  Future<bool> isModActive(String modName) async {
    try {
      if (saveModsPath == null) return false;

      final linkPath = path.join(saveModsPath!, modName);
      final exists =
          await FileSystemEntity.type(linkPath) !=
          FileSystemEntityType.notFound;
      if (!exists) return false;

      // Використовуємо platformService для перевірки
      return await _platformService.isModLink(linkPath);
    } catch (e) {
      return false;
    }
  }

  Future<bool> activateMod(String modName) async {
    try {
      final (valid, _) = await validatePaths();
      if (!valid) return false;

      final srcPath = path.join(modsPath!, modName);
      final dstPath = path.join(saveModsPath!, modName);

      final srcDir = Directory(srcPath);
      if (!await srcDir.exists()) return false;

      final saveModsDir = Directory(saveModsPath!);
      if (!await saveModsDir.exists()) {
        await saveModsDir.create(recursive: true);
      }

      // Використовуємо platformService для створення link
      final success = await _platformService.createModLink(srcPath, dstPath);
      if (!success) {
        print('ModManagerService: Не вдалося створити link для $modName');
        return false;
      }

      await _configService.addActiveMod(modName);

      // Автоматично перезавантажуємо моди після активації (якщо увімкнено)
      final autoF10Enabled = _container.read(autoF10ReloadProvider);
      if (autoF10Enabled) {
        await _platformService.sendF10ToGame();
      }

      return true;
    } catch (e) {
      print('ModManagerService: Помилка активації мода: $e');
      return false;
    }
  }

  Future<bool> deactivateMod(String modName) async {
    try {
      if (saveModsPath == null) return false;

      final linkPath = path.join(saveModsPath!, modName);
      final exists =
          await FileSystemEntity.type(linkPath) !=
          FileSystemEntityType.notFound;
      if (!exists) return false;

      // Використовуємо platformService для видалення link
      final success = await _platformService.removeModLink(linkPath);
      if (!success) {
        print('ModManagerService: Не вдалося видалити link для $modName');
        return false;
      }

      await _configService.removeActiveMod(modName);

      // Автоматично перезавантажуємо моди після деактивації (якщо увімкнено)
      final autoF10Enabled = _container.read(autoF10ReloadProvider);
      if (autoF10Enabled) {
        await _platformService.sendF10ToGame();
      }

      return true;
    } catch (e) {
      print('ModManagerService: Помилка деактивації мода: $e');
      return false;
    }
  }

  Future<bool> toggleMod(String modName) async {
    final isActive = await isModActive(modName);
    return isActive ? await deactivateMod(modName) : await activateMod(modName);
  }

  Future<String?> _findModImage(String modName) async {
    try {
      final modPath = path.join(modsPath!, modName);
      final modDir = Directory(modPath);
      if (!await modDir.exists()) return null;

      for (final imageName in AppConstants.imageFileNames) {
        final imagePath = path.join(modPath, imageName);
        final imageFile = File(imagePath);
        if (await imageFile.exists()) return imagePath;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Ручне перезавантаження модів (натискання F10)
  Future<bool> reloadMods() async {
    return await _platformService.sendF10ToGame();
  }

  /// Показує інструкції налаштування F10 сервісу
  void showF10SetupInstructions() {
    _platformService.showSetupInstructions();
  }

  /// Встановлює залежності для F10 сервісу
  Future<void> installF10Dependencies() async {
    await _platformService.checkDependencies();
  }

  Future<void> _safeRemove(String filePath) async {
    try {
      // Використовуємо platformService для видалення links
      final isLink = await _platformService.isModLink(filePath);

      if (isLink) {
        await _platformService.removeModLink(filePath);
        return;
      }

      // Якщо це не link, видаляємо звичайним способом
      final entity = await FileSystemEntity.type(filePath);
      if (entity == FileSystemEntityType.directory) {
        await Directory(filePath).delete(recursive: true);
      } else if (entity == FileSystemEntityType.file) {
        await File(filePath).delete();
      }
    } catch (e) {
      print('ModManagerService: Помилка _safeRemove: $e');
    }
  }

  /// Імпортує нові моди з вказаних папок
  /// Повертає список імпортованих модів та їх автоматично визначених тегів персонажів
  Future<(List<String>, Map<String, String>)> importMods(
    List<String> folderPaths,
  ) async {
    try {
      final (valid, _) = await validatePaths();
      if (!valid) return (<String>[], <String, String>{});

      final importedMods = <String>[];
      final autoTags = <String, String>{};
      final modsDir = Directory(modsPath!);

      if (!await modsDir.exists()) {
        await modsDir.create(recursive: true);
      }

      for (final folderPath in folderPaths) {
        final sourceDir = Directory(folderPath);
        if (!await sourceDir.exists()) continue;

        final modName = path.basename(folderPath);
        final targetPath = path.join(modsPath!, modName);
        final targetDir = Directory(targetPath);

        // Якщо мод вже існує, пропускаємо
        if (await targetDir.exists()) {
          continue;
        }

        // Копіюємо папку з модом
        await _copyDirectory(sourceDir, targetDir);
        importedMods.add(modName);

        // Автоматично визначаємо тег персонажа з назви папки
        final detectedChar = await _detectCharacterFromName(modName);
        if (detectedChar != null) {
          autoTags[modName] = detectedChar;
        }
      }

      return (importedMods, autoTags);
    } catch (e) {
      return (<String>[], <String, String>{});
    }
  }

  /// Визначає персонажа з назви моду
  Future<String?> _detectCharacterFromName(String modName) async {
    final nameLower = modName.toLowerCase();
    final hookType = _configService.currentProfile?.hookType ?? 'zzz';

    // Спробуємо знайти персонажа в INI файлах моду
    try {
      final modsPath = _configService.modsPath;
      if (modsPath == null || modsPath.isEmpty) {
        // Якщо шлях не налаштовано, просто шукаємо в назві
      } else {
        final modPath = path.join(modsPath, modName);
        final modDir = Directory(modPath);

        if (await modDir.exists()) {
          // Шукаємо INI файли
          final iniFiles = await modDir
              .list(recursive: true)
              .where(
                (entity) =>
                    entity is File &&
                    path.extension(entity.path).toLowerCase() == '.ini',
              )
              .cast<File>()
              .toList();

          for (final iniFile in iniFiles) {
            try {
              final content = await iniFile.readAsString();
              final contentLower = content.toLowerCase();

              // Шукаємо в Header або секціях INI
              final charFromIni = _findCharacterInText(contentLower, hookType);
              if (charFromIni != null) {
                print(
                  'ModManager: Виявлено персонажа "$charFromIni" в INI файлі ${path.basename(iniFile.path)} моду "$modName"',
                );
                return charFromIni;
              }
            } catch (e) {
              // Ігноруємо помилки читання окремих файлів
            }
          }

          // Також перевіряємо імена папок всередині моду
          final subdirs = await modDir
              .list(recursive: false)
              .where((entity) => entity is Directory)
              .cast<Directory>()
              .toList();

          for (final subdir in subdirs) {
            final subdirName = path.basename(subdir.path).toLowerCase();
            final charFromSubdir = _findCharacterInText(subdirName, hookType);
            if (charFromSubdir != null) {
              print(
                'ModManager: Виявлено персонажа "$charFromSubdir" в папці "$subdirName" моду "$modName"',
              );
              return charFromSubdir;
            }
          }
        }
      }
    } catch (e) {
      print('ModManager: Помилка пошуку в файлах моду "$modName": $e');
    }

    // Отримуємо мапу персонажів залежно від типу гри
    final characterAliases = _getCharacterAliases(hookType);

    // Спочатку шукаємо повні збіги для точності
    for (final entry in characterAliases.entries) {
      final charId = entry.key;
      final aliases = entry.value;

      for (final alias in aliases) {
        // Шукаємо як окреме слово з границями
        final pattern = RegExp(
          r'\b' + RegExp.escape(alias) + r'\b',
          caseSensitive: false,
        );
        if (pattern.hasMatch(nameLower)) {
          print(
            'ModManager: Виявлено персонажа "$charId" (збіг: "$alias") в "$modName"',
          );
          return charId;
        }
      }
    }

    // Якщо не знайшли повну збіг, шукаємо часткові збіги (як раніше)
    for (final entry in characterAliases.entries) {
      final charId = entry.key;
      final aliases = entry.value;

      for (final alias in aliases) {
        if (nameLower.contains(alias)) {
          print(
            'ModManager: Виявлено персонажа "$charId" (частковий збіг: "$alias") в "$modName"',
          );
          return charId;
        }
      }
    }

    print('ModManager: Не вдалося визначити персонажа для "$modName"');
    return null;
  }

  /// Повертає мапу псевдонімів персонажів залежно від типу гри
  Map<String, List<String>> _getCharacterAliases(String hookType) {
    if (hookType == 'genshin') {
      return _getGenshinCharacterAliases();
    }
    return _getZZZCharacterAliases();
  }

  /// Мапа персонажів ZZZ з альтернативними іменами
  Map<String, List<String>> _getZZZCharacterAliases() {
    return <String, List<String>>{
      'alice': ['alice'],
      'anby': ['anby'],
      'anton': ['anton'],
      'astra': ['astra', 'astrayao', 'astra yao'],
      'belle': ['belle'],
      'ben': ['ben', 'bigger', 'ben bigger'],
      'billy': ['billy', 'billyherinkton', 'billy kid'],
      'burnice': ['burnice', 'burnice white'],
      'caesar': ['caesar', 'caesar king'],
      'corin': ['corin', 'corin wickes'],
      'ellen': ['ellen', 'ellen joe'],
      'evelyn': ['evelyn'],
      'grace': ['grace', 'grace howard'],
      'harumasa': ['harumasa', 'asaba harumasa'],
      'hugo': ['hugo'],
      'jane': ['jane', 'janedoe', 'jane doe'],
      'jufufu': ['jufufu', 'ju fufu'],
      'koleda': ['koleda', 'koleda belobog'],
      'lighter': ['lighter', 'lighter lorenz'],
      'lucy': ['lucy', 'lucy kushinada'],
      'lycaon': ['lycaon', 'von lycaon', 'vonlycaon'],
      'miyabi': ['miyabi', 'hoshimi miyabi'],
      'nekomata': ['nekomata', 'nekomiya mana'],
      'nicole': ['nicole', 'nicole demara'],
      'orphie': ['orphie', 'orphiemagus', 'orphie magus'],
      'panyinhu': ['panyinhu', 'pan yinhu'],
      'piper': ['piper', 'piper wheel'],
      'pulchra': ['pulchra'],
      'quinqiy': ['quinqiy', 'qingyi'],
      'rina': ['rina', 'alexandrina'],
      'seed': ['seed'],
      'seth': ['seth', 'seth lowell'],
      'solder0anby': ['solder0anby', 'soldier 0', 'soldier0'],
      'solder11': ['solder11', 'soldier 11', 'soldier11'],
      'soukaku': ['soukaku'],
      'trigger': ['trigger'],
      'vivian': ['vivian'],
      'wise': ['wise'],
      'yanagi': ['yanagi', 'tsukishiro yanagi'],
      'yixuan': ['yixuan'],
      'yuzuha': ['yuzuha'],
      'zhuyuan': ['zhuyuan', 'zhu yuan'],
    };
  }

  /// Мапа персонажів Genshin Impact з альтернативними іменами
  Map<String, List<String>> _getGenshinCharacterAliases() {
    return <String, List<String>>{
      'albedo': ['albedo'],
      'alhaitham': ['alhaitham', 'al haitham', 'al-haitham'],
      'aloy': ['aloy'],
      'arlecchino': ['arlecchino', 'arleccino'],
      'ayaka': ['ayaka', 'kamisato ayaka', 'kamisatoayaka'],
      'ayato': ['ayato', 'kamisato ayato', 'kamisatoayato'],
      'baizhu': ['baizhu', 'bai zhu'],
      'chasca': ['chasca'],
      'chiori': ['chiori'],
      'citlali': ['citlali'],
      'clorinde': ['clorinde'],
      'cyno': ['cyno'],
      'dehya': ['dehya'],
      'diluc': ['diluc'],
      'emilie': ['emilie'],
      'escoffier': ['escoffier'],
      'eula': ['eula'],
      'flins': ['flins'],
      'furina': ['furina', 'focalors'],
      'ganyu': ['ganyu', 'gan yu'],
      'hutao': ['hutao', 'hu tao', 'hu-tao', 'hutau'],
      'itto': ['itto', 'arataki itto', 'aratakiitto', 'arataki'],
      'jean': ['jean'],
      'kazuha': ['kazuha', 'kaedehara kazuha', 'kaedeharakazuha', 'kaedehara'],
      'keqing': ['keqing', 'ke qing', 'keching'],
      'kinich': ['kinich'],
      'klee': ['klee'],
      'kokomi': [
        'kokomi',
        'sangonomiya kokomi',
        'sangonomiyakokomi',
        'sangonomiya',
      ],
      'lyney': ['lyney'],
      'mavuika': ['mavuika'],
      'mona': ['mona'],
      'mualani': ['mualani'],
      'nahida': ['nahida'],
      'navia': ['navia'],
      'neuvillette': ['neuvillette', 'neuvilette'],
      'nilou': ['nilou', 'ni lou'],
      'qiqi': ['qiqi', 'qi qi'],
      'raiden': ['raiden', 'raiden shogun', 'ei', 'shogun', 'baal'],
      'shenhe': ['shenhe', 'shen he'],
      'sigewinne': ['sigewinne'],
      'tartaglia': ['tartaglia', 'childe'],
      'tighnari': ['tighnari'],
      'venti': ['venti'],
      'wanderer': ['wanderer', 'scaramouche', 'scara'],
      'wriothesley': ['wriothesley'],
      'xiao': ['xiao'],
      'xianyun': ['xianyun', 'cloud retainer', 'cloudretainer'],
      'xilonen': ['xilonen'],
      'yae': ['yae', 'yae miko', 'yaemiko'],
      'yelan': ['yelan'],
      'yoimiya': ['yoimiya'],
      'zhongli': ['zhongli'],
      'aino': ['aino'],
      'amber': ['amber'],
      'barbara': ['barbara', 'barbruh'],
      'beidou': ['beidou', 'bei dou'],
      'bennett': ['bennett', 'bennet', 'benny'],
      'candace': ['candace'],
      'charlotte': ['charlotte'],
      'chevreuse': ['chevreuse'],
      'chongyun': ['chongyun'],
      'collei': ['collei'],
      'dahlia': ['dahlia'],
      'diona': ['diona'],
      'dori': ['dori'],
      'faruzan': ['faruzan'],
      'fischl': ['fischl', 'fishl'],
      'freminet': ['freminet'],
      'gaming': ['gaming'],
      'gorou': ['gorou'],
      'heizou': ['heizou', 'shikanoin heizou', 'shikanoinheizou'],
      'kachina': ['kachina'],
      'kaeya': ['kaeya'],
      'kaveh': ['kaveh'],
      'kujou': ['kujou', 'kujou sara', 'sara'],
      'kuki': ['kuki', 'kuki shinobu', 'shinobu'],
      'layla': ['layla'],
      'lisa': ['lisa'],
      'lynette': ['lynette'],
      'mika': ['mika'],
      'ningguang': ['ningguang', 'ning guang'],
      'noelle': ['noelle'],
      'ororon': ['ororon'],
      'razor': ['razor'],
      'rosaria': ['rosaria'],
      'sayu': ['sayu'],
      'sethos': ['sethos'],
      'sucrose': ['sucrose'],
      'thoma': ['thoma'],
      'traveler': ['traveler', 'aether', 'lumine'],
      'xiangling': ['xiangling', 'xiang ling', 'xiang-ling'],
      'xingqiu': ['xingqiu', 'xing qiu', 'xing-qiu', 'xingqui'],
      'xinyan': ['xinyan', 'xin yan'],
      'yaoyao': ['yaoyao', 'yao yao'],
      'yunjin': ['yunjin', 'yun jin'],
    };
  }

  /// Допоміжний метод для пошуку персонажа в тексті
  String? _findCharacterInText(String text, String hookType) {
    final textLower = text.toLowerCase();
    final characterAliases = _getCharacterAliases(hookType);

    // Спочатку шукаємо повні збіги
    for (final entry in characterAliases.entries) {
      final charId = entry.key;
      final aliases = entry.value;

      for (final alias in aliases) {
        final pattern = RegExp(
          r'\b' + RegExp.escape(alias) + r'\b',
          caseSensitive: false,
        );
        if (pattern.hasMatch(textLower)) {
          return charId;
        }
      }
    }

    // Часткові збіги
    for (final entry in characterAliases.entries) {
      final charId = entry.key;
      final aliases = entry.value;

      for (final alias in aliases) {
        if (textLower.contains(alias)) {
          return charId;
        }
      }
    }

    return null;
  }

  /// Автоматично визначає та встановлює теги для всіх модів
  /// Повертає кількість модів з визначеними тегами
  Future<Map<String, String>> autoTagAllMods() async {
    try {
      final modNames = await scanMods();
      final autoTags = <String, String>{};

      for (final modName in modNames) {
        // Перевіряємо чи вже є тег для цього моду
        final existingTag = _configService.modCharacterTags[modName];

        // Якщо тег вже є і він не 'unknown', пропускаємо
        if (existingTag != null && existingTag != 'unknown') {
          continue;
        }

        // Автоматично визначаємо тег з назви
        final detectedChar = await _detectCharacterFromName(modName);
        if (detectedChar != null) {
          await _configService.setModCharacterTag(modName, detectedChar);
          autoTags[modName] = detectedChar;
        }
      }

      return autoTags;
    } catch (e) {
      return {};
    }
  }

  /// Рекурсивно копіює директорію
  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);

    await for (final entity in source.list(recursive: false)) {
      if (entity is Directory) {
        final newDirectory = Directory(
          path.join(destination.path, path.basename(entity.path)),
        );
        await _copyDirectory(entity, newDirectory);
      } else if (entity is File) {
        final newFile = File(
          path.join(destination.path, path.basename(entity.path)),
        );
        await entity.copy(newFile.path);
      }
    }
  }

  /// Зчитує keybinds для конкретного персонажа (моду)
  /// characterId - назва папки персонажа в modsPath
  Future<CharacterKeybinds?> getCharacterKeybinds(String characterId) async {
    try {
      if (modsPath == null) return null;

      final characterPath = path.join(modsPath!, characterId);
      final characterDir = Directory(characterPath);

      if (!await characterDir.exists()) return null;

      return await _iniParser.parseCharacterDirectory(
        characterId,
        characterPath,
      );
    } catch (e) {
      print(
        'ModManagerService: Помилка зчитування keybinds для $characterId: $e',
      );
      return null;
    }
  }

  /// Зчитує keybinds для всіх персонажів в modsPath
  /// Повертає мапу characterId -> CharacterKeybinds
  Future<Map<String, CharacterKeybinds>> getAllCharactersKeybinds() async {
    try {
      if (modsPath == null) return {};

      return await _iniParser.parseAllCharacters(modsPath!);
    } catch (e) {
      print(
        'ModManagerService: Помилка зчитування keybinds для всіх персонажів: $e',
      );
      return {};
    }
  }

  /// Завантажує keybinds для конкретного моду
  /// modId - назва папки моду в modsPath
  Future<List<KeybindInfo>?> getModKeybinds(String modId) async {
    try {
      if (modsPath == null) return null;
      final modPath = path.join(modsPath!, modId);
      final keybindsData = await _iniParser.parseCharacterDirectory(
        modId,
        modPath,
      );
      return keybindsData?.keybinds;
    } catch (e) {
      print(
        'ModManagerService: Помилка завантаження keybinds для моду $modId: $e',
      );
      return null;
    }
  }

  /// Оновлює інформацію про персонажів, додаючи keybinds до модів
  /// Приймає список персонажів і додає keybinds до кожного моду
  Future<List<CharacterInfo>> enrichCharactersWithKeybinds(
    List<CharacterInfo> characters,
  ) async {
    try {
      print('ModManagerService: Завантаження keybinds для модів...');

      final updatedCharacters = <CharacterInfo>[];

      for (final character in characters) {
        final updatedMods = <ModInfo>[];

        for (final mod in character.skins) {
          final keybinds = await getModKeybinds(mod.id);
          if (keybinds != null && keybinds.isNotEmpty) {
            print(
              'ModManagerService: Знайдено ${keybinds.length} keybinds для моду ${mod.id}',
            );
            updatedMods.add(mod.copyWith(keybinds: keybinds));
          } else {
            updatedMods.add(mod);
          }
        }

        updatedCharacters.add(character.copyWith(skins: updatedMods));
      }

      return updatedCharacters;
    } catch (e) {
      print('ModManagerService: Помилка збагачення модів keybinds: $e');
      return characters;
    }
  }
}
