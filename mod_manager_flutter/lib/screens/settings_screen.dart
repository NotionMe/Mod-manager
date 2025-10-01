import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../core/constants.dart';
import '../services/api_service.dart';
import '../utils/state_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with TickerProviderStateMixin {
  final _modsPathController = TextEditingController();
  final _saveModsPathController = TextEditingController();
  bool isLoading = false;
  late AnimationController _loadingAnimationController;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingAnimationController,
      curve: Curves.easeInOut,
    ));
    loadConfig();
  }

  @override
  void dispose() {
    _loadingAnimationController.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration saved'),
            behavior: SnackBarBehavior.floating,
            width: 200,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(AppConstants.defaultPadding * 1.5),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(
                color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: AppConstants.headerTextSize + 4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _loadingAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 0.8 + (_loadingAnimation.value * 0.2),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0EA5E9).withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      AnimatedBuilder(
                        animation: _loadingAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _loadingAnimation.value,
                            child: Text(
                              'Завантаження налаштувань...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                )
              : AnimationLimiter(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 375),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          // Paths Section
                          _buildSectionTitle('Mod Directories'),
                          const SizedBox(height: 16),
                          _buildPathField(
                            label: 'SaveMods Path',
                            hint: 'Path where original mods are stored',
                            controller: _modsPathController,
                            onBrowse: pickModsPath,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 16),
                          _buildPathField(
                            label: 'Mods Path',
                            hint: 'Path where symlinks will be created',
                            controller: _saveModsPathController,
                            onBrowse: pickSaveModsPath,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 32),
                          // Appearance Section
                          _buildSectionTitle('Appearance'),
                          const SizedBox(height: 16),
                          _buildSettingRow(
                            label: 'Dark Mode',
                            trailing: Switch(
                              value: isDarkMode,
                              onChanged: (value) {
                                ref.read(isDarkModeProvider.notifier).state = value;
                              },
                              activeColor: const Color(0xFF0EA5E9),
                            ),
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 32),
                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: saveConfig,
                              icon: const Icon(Icons.save_outlined, size: 18),
                              label: const Text('Save Configuration'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF0EA5E9),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Info Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0EA5E9).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF0EA5E9).withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: const Color(0xFF0EA5E9),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'This app uses symbolic links to safely manage mods without copying files.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildPathField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required VoidCallback onBrowse,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF0EA5E9)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onBrowse,
              icon: const Icon(Icons.folder_outlined, size: 18),
              label: const Text('Browse'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingRow({
    required String label,
    required Widget trailing,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          trailing,
        ],
      ),
    );
  }
}
