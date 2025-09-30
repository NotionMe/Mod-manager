import 'dart:convert';
import 'dart:io';
import '../models/mod_info.dart';

class ApiService {
  static const String pythonScript = '/home/notion/Repos/fork/mod_cli.py';
  static const String python = 'python3';

  static Future<Map<String, dynamic>> _runPython(List<String> args) async {
    try {
      final result = await Process.run(python, [
        pythonScript,
        ...args,
      ], workingDirectory: '/home/notion/Repos/fork');

      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        if (output.isEmpty) {
          throw Exception('Empty response');
        }
        return jsonDecode(output);
      } else {
        throw Exception('Python error: ${result.stderr}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<List<ModInfo>> getMods() async {
    try {
      final data = await _runPython(['get_mods']);
      if (data['success'] == true) {
        final List<dynamic> modsJson = data['mods'];
        return modsJson.map((json) => ModInfo.fromJson(json)).toList();
      } else {
        throw Exception(data['error'] ?? 'Error');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  static Future<bool> toggleMod(String modId) async {
    try {
      final data = await _runPython(['toggle_mod', modId]);
      return data['success'] == true;
    } catch (e) {
      throw Exception('$e');
    }
  }

  static Future<String> clearAll() async {
    try {
      final data = await _runPython(['clear_all']);
      return data['message'] ?? 'Done';
    } catch (e) {
      throw Exception('$e');
    }
  }

  static Future<Map<String, String>> getConfig() async {
    try {
      final data = await _runPython(['get_config']);
      return {
        'mods_path': data['mods_path'] ?? '',
        'save_mods_path': data['save_mods_path'] ?? '',
      };
    } catch (e) {
      throw Exception('$e');
    }
  }

  static Future<String> updateConfig({
    required String modsPath,
    required String saveModsPath,
  }) async {
    try {
      final data = await _runPython(['update_config', modsPath, saveModsPath]);
      return data['message'] ?? 'Saved';
    } catch (e) {
      throw Exception('$e');
    }
  }

  static Future<bool> updateMod(ModInfo mod) async {
    try {
      final data = await _runPython([
        'update_mod',
        mod.id,
        '--image-path',
        mod.imagePath ?? '',
      ]);
      return data['success'] == true;
    } catch (e) {
      throw Exception('$e');
    }
  }
}
