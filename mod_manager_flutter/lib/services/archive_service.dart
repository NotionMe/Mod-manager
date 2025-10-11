import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

class ArchiveExtractionResult {
  final bool success;
  final String? error;
  final List<String>? extractedFolders;

  const ArchiveExtractionResult({
    required this.success,
    this.error,
    this.extractedFolders,
  });

  factory ArchiveExtractionResult.successResult(List<String> folders) =>
      ArchiveExtractionResult(success: true, extractedFolders: folders);

  factory ArchiveExtractionResult.failure(String error) =>
      ArchiveExtractionResult(success: false, error: error);
}

class ArchiveService {
  static bool isArchiveFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return extension == '.zip' || extension == '.rar' || extension == '.7z';
  }

  static Future<ArchiveExtractionResult> extractArchive({
    required File archiveFile,
    Directory? destinationDir,
  }) async {
    try {
      print('ArchiveService: Розархівування ${archiveFile.path}');

      final tempExtractDir =
          destinationDir ??
          await Directory.systemTemp.createTemp('zzz_archive_extract_');

      final extension = path.extension(archiveFile.path).toLowerCase();
      bool isExtracted = false;
      String? extractionError;

      if (extension == '.zip') {
        print('ArchiveService: ZIP архів');
        isExtracted = await _extractZip(archiveFile, tempExtractDir);
      } else if (extension == '.rar' || extension == '.7z') {
        print('ArchiveService: RAR/7Z архів');
        final result = await _extractWith7Zip(archiveFile, tempExtractDir);
        isExtracted = result.success;
        extractionError = result.error;
      }

      if (!isExtracted) {
        final error = extractionError ?? 'Формат архіву не підтримується';
        print('ArchiveService: Помилка: $error');
        return ArchiveExtractionResult.failure(error);
      }

      final directories = await _prepareDirectoriesForImport(
        tempExtractDir,
        archiveFile,
      );

      if (directories.isEmpty) {
        print('ArchiveService: Архів порожній');
        return ArchiveExtractionResult.failure('Архів не містить папок модів');
      }

      print('ArchiveService: Знайдено ${directories.length} папок');
      return ArchiveExtractionResult.successResult(directories);
    } catch (e) {
      print('ArchiveService: Виняток: $e');
      return ArchiveExtractionResult.failure('Помилка розархівування: $e');
    }
  }

  static Future<bool> _extractZip(
    File archiveFile,
    Directory destination,
  ) async {
    try {
      print('ArchiveService: Читання ZIP файлу...');
      final bytes = await archiveFile.readAsBytes();
      print('ArchiveService: Прочитано ${bytes.length} bytes');

      print('ArchiveService: Декодування ZIP...');
      final archive = ZipDecoder().decodeBytes(bytes, verify: true);
      print('ArchiveService: ZIP містить ${archive.length} файлів');

      int extracted = 0;
      for (final file in archive) {
        final sanitizedPath = _sanitizeArchivePath(destination.path, file.name);
        if (sanitizedPath == null) {
          print('ArchiveService: Пропущено небезпечний шлях: ${file.name}');
          continue;
        }

        if (file.isFile) {
          final outFile = File(sanitizedPath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
          extracted++;
        } else {
          final dir = Directory(sanitizedPath);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
        }
      }

      print('ArchiveService: ZIP успішно розархівовано, файлів: $extracted');
      return true;
    } catch (e) {
      print('ArchiveService: Помилка розархівування ZIP: $e');
      return false;
    }
  }

  static Future<_7ZipResult> _extractWith7Zip(
    File archiveFile,
    Directory destination,
  ) async {
    final sevenZipPath = await _locate7Zip();
    if (sevenZipPath == null) {
      return _7ZipResult(
        false,
        '7-Zip не знайдено. Встановіть 7-Zip для розпаковки RAR/7z.',
      );
    }

    print('ArchiveService: Використання 7-Zip: $sevenZipPath');

    final result = await Process.run(sevenZipPath, [
      'x',
      archiveFile.path,
      '-o${destination.path}',
      '-y',
    ]);

    if (result.exitCode != 0) {
      final errorOutput = result.stderr.toString().trim();
      print('ArchiveService: 7-Zip помилка: $errorOutput');
      return _7ZipResult(
        false,
        errorOutput.isNotEmpty ? errorOutput : 'Не вдалося розпакувати архів',
      );
    }

    print('ArchiveService: 7-Zip успішно розпакував');
    return const _7ZipResult(true);
  }

  static Future<String?> _locate7Zip() async {
    if (Platform.isWindows) {
      final whereResult = await Process.run('where', ['7z']);
      if (whereResult.exitCode == 0) {
        final lines = whereResult.stdout
            .toString()
            .split(RegExp(r'[\r\n]+'))
            .where((line) => line.trim().isNotEmpty);
        if (lines.isNotEmpty) {
          return lines.first.trim();
        }
      }

      final candidates = [
        path.join(
          Platform.environment['ProgramFiles'] ?? '',
          '7-Zip',
          '7z.exe',
        ),
        path.join(
          Platform.environment['ProgramFiles(x86)'] ?? '',
          '7-Zip',
          '7z.exe',
        ),
      ];

      for (final candidate in candidates) {
        if (candidate.trim().isEmpty) continue;
        final file = File(candidate);
        if (await file.exists()) {
          return file.path;
        }
      }
      return null;
    }

    if (Platform.isLinux || Platform.isMacOS) {
      final commands = ['7z', '7za', '7zr'];
      for (final command in commands) {
        try {
          final whichResult = await Process.run('which', [command]);
          if (whichResult.exitCode == 0) {
            final pathResult = whichResult.stdout
                .toString()
                .split(RegExp(r'[\r\n]+'))
                .firstWhere((line) => line.trim().isNotEmpty, orElse: () => '')
                .trim();
            if (pathResult.isNotEmpty) {
              return pathResult;
            }
          }
        } catch (_) {
          continue;
        }
      }
    }

    return null;
  }

  static Future<List<String>> _prepareDirectoriesForImport(
    Directory extractDir,
    File archiveFile,
  ) async {
    final entries = extractDir.listSync();
    final directories = <String>[];

    if (entries.isEmpty) {
      return directories;
    }

    final dirEntries = entries.whereType<Directory>().toList();
    if (dirEntries.isEmpty) {
      final baseName = path.basenameWithoutExtension(archiveFile.path);
      final wrapperDir = Directory(path.join(extractDir.path, baseName));
      await wrapperDir.create(recursive: true);

      for (final entity in entries) {
        final targetPath = path.join(
          wrapperDir.path,
          path.basename(entity.path),
        );
        if (entity is File) {
          await entity.copy(targetPath);
          await entity.delete();
        } else if (entity is Directory) {
          await Directory(entity.path).rename(targetPath);
        }
      }
      directories.add(wrapperDir.path);
      return directories;
    }

    for (final dir in dirEntries) {
      directories.add(dir.path);
    }

    return directories;
  }

  static String? _sanitizeArchivePath(String base, String relativePath) {
    final normalized = path.normalize(relativePath);
    if (normalized.contains('..')) {
      return null;
    }
    final fullPath = path.join(base, normalized);
    if (!path.isWithin(base, fullPath)) {
      return null;
    }
    return fullPath;
  }
}

class _7ZipResult {
  final bool success;
  final String? error;

  const _7ZipResult(this.success, [this.error]);
}
