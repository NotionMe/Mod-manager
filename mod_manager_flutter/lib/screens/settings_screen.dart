import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../utils/state_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _modsPathController = TextEditingController();
  final _saveModsPathController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadConfig();
  }

  @override
  void dispose() {
    _modsPathController.dispose();
    _saveModsPathController.dispose();
    super.dispose();
  }

  Future<void> loadConfig() async {
    setState(() => isLoading = true);
    try {
      final config = await ApiService.getConfig();
      setState(() {
        _modsPathController.text = config['mods_path'] ?? '';
        _saveModsPathController.text = config['save_mods_path'] ?? '';
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> pickModsPath() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() => _modsPathController.text = result);
    }
  }

  Future<void> pickSaveModsPath() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() => _saveModsPathController.text = result);
    }
  }

  Future<void> saveConfig() async {
    try {
      await ApiService.updateConfig(
        modsPath: _modsPathController.text,
        saveModsPath: _saveModsPathController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Збережено')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Помилка: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sss = ref.watch(zoomScaleProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Padding(
      padding: EdgeInsets.only(
        top: 100 * sss,
        left: 40 * sss,
        right: 40 * sss,
        bottom: 20 * sss,
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Шляхи до папок', sss),
                  SizedBox(height: 20 * sss),

                  _buildPathSetting(
                    label: 'SaveMods Path',
                    controller: _modsPathController,
                    onPickPath: pickModsPath,
                    sss: sss,
                  ),

                  SizedBox(height: 30 * sss),

                  _buildPathSetting(
                    label: 'Mods Path',
                    controller: _saveModsPathController,
                    onPickPath: pickSaveModsPath,
                    sss: sss,
                  ),

                  SizedBox(height: 40 * sss),

                  _buildSectionTitle('Зовнішній вигляд', sss),
                  SizedBox(height: 20 * sss),

                  _buildSettingRow(
                    'Темна тема',
                    Switch(
                      value: isDarkMode,
                      onChanged: (value) {
                        ref.read(isDarkModeProvider.notifier).state = value;
                      },
                    ),
                    sss,
                  ),

                  SizedBox(height: 20 * sss),

                  _buildSettingRow(
                    'Масштаб інтерфейсу',
                    Slider(
                      value: sss,
                      min: 0.8,
                      max: 1.5,
                      divisions: 7,
                      label: '${(sss * 100).round()}%',
                      onChanged: (value) {
                        ref.read(zoomScaleProvider.notifier).state = value;
                      },
                    ),
                    sss,
                  ),

                  SizedBox(height: 40 * sss),

                  Center(
                    child: SizedBox(
                      width: 200 * sss,
                      height: 50 * sss,
                      child: ElevatedButton.icon(
                        onPressed: saveConfig,
                        icon: Icon(Icons.save, size: 20 * sss),
                        label: Text(
                          'Зберегти',
                          style: GoogleFonts.poppins(
                            fontSize: 16 * sss,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25 * sss),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, double sss) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 20 * sss,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildPathSetting({
    required String label,
    required TextEditingController controller,
    required VoidCallback onPickPath,
    required double sss,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14 * sss,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        SizedBox(height: 8 * sss),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 15 * sss),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10 * sss),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  style: GoogleFonts.poppins(
                    fontSize: 13 * sss,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Виберіть папку...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 13 * sss,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10 * sss),
            ElevatedButton(
              onPressed: onPickPath,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 20 * sss,
                  vertical: 15 * sss,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10 * sss),
                ),
              ),
              child: Text(
                'Вибрати',
                style: GoogleFonts.poppins(fontSize: 13 * sss),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingRow(String label, Widget trailing, double sss) {
    return Container(
      padding: EdgeInsets.all(15 * sss),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10 * sss),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14 * sss, color: Colors.white),
          ),
          trailing,
        ],
      ),
    );
  }
}
