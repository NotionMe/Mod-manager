import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../core/constants.dart';
import '../services/api_service.dart';
import '../utils/state_providers.dart';
import '../utils/zzz_characters.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with TickerProviderStateMixin {
  final _modsPathController = TextEditingController();
  final _saveModsPathController = TextEditingController();
  bool isLoading = false;
  String _selectedLanguage = 'en';
  bool _isUpdatingLanguage = false;
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
        _selectedLanguage = config['language'] ?? 'en';
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
    final loc = context.loc;
    try {
      await ApiService.updateConfig(
        modsPath: _modsPathController.text,
        saveModsPath: _saveModsPathController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.t('settings.save_success')),
            behavior: SnackBarBehavior.floating,
            width: 200,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.t('settings.errors.generic', params: {'message': '$e'}),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
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
                loc.t('settings.title'),
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
                              loc.t('settings.loading'),
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
                          _buildSectionTitle(loc.t('settings.sections.paths')),
                          const SizedBox(height: 16),
                          _buildPathField(
                            label: loc.t('settings.paths.mods'),
                            hint: loc.t('settings.paths.mods_hint'),
                            controller: _modsPathController,
                            onBrowse: pickModsPath,
                            isDarkMode: isDarkMode,
                            loc: loc,
                          ),
                          const SizedBox(height: 16),
                          _buildPathField(
                            label: loc.t('settings.paths.save_mods'),
                            hint: loc.t('settings.paths.save_mods_hint'),
                            controller: _saveModsPathController,
                            onBrowse: pickSaveModsPath,
                            isDarkMode: isDarkMode,
                            loc: loc,
                          ),
                          const SizedBox(height: 32),
                          // Language Section
                          _buildSectionTitle(loc.t('settings.sections.language')),
                          const SizedBox(height: 16),
                          _buildLanguageSelector(loc, isDarkMode),
                          const SizedBox(height: 32),
                          // Auto-Tagging Section
                          _buildSectionTitle(loc.t('settings.sections.auto_tag')),
                          const SizedBox(height: 16),
                          _buildAutoTagSection(loc, isDarkMode),
                          const SizedBox(height: 32),
                          // F10 Reload Section
                          _buildSectionTitle(loc.t('settings.sections.auto_f10')),
                          const SizedBox(height: 16),
                          _buildF10Section(loc, isDarkMode),
                          const SizedBox(height: 32),
                          // Appearance Section
                          _buildSectionTitle(loc.t('settings.sections.appearance')),
                          const SizedBox(height: 16),
                          _buildSettingRow(
                            label: loc.t('settings.appearance.dark_mode'),
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
                              label: Text(loc.t('settings.actions.save_configuration')),
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
                                    loc.t('settings.info.symlinks'),
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

  Widget _buildLanguageSelector(AppLocalizations loc, bool isDarkMode) {
    final languageItems = {
      'en': loc.t('language_names.en'),
      'uk': loc.t('language_names.uk'),
    };

    return _buildSettingRow(
      label: loc.t('settings.language.label'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              onChanged: _isUpdatingLanguage
                  ? null
                  : (value) => _changeLanguage(value, loc),
              items: languageItems.entries
                  .map(
                    (entry) => DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (_isUpdatingLanguage) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 16,
              height: 16,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
      isDarkMode: isDarkMode,
    );
  }

  Future<void> _changeLanguage(String? languageCode, AppLocalizations loc) async {
    if (languageCode == null || languageCode == _selectedLanguage) {
      return;
    }

    setState(() {
      _selectedLanguage = languageCode;
      _isUpdatingLanguage = true;
    });

    ref.read(localeProvider.notifier).state = Locale(languageCode);

    try {
      await ApiService.setLanguage(languageCode);
      if (mounted) {
        final currentLoc = context.loc;
        final languageName = currentLoc.t('language_names.$languageCode');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLoc.t(
                'settings.language.changed',
                params: {'language': languageName},
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorLoc = context.loc;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorLoc.t(
                'settings.language.error',
                params: {'message': '$e'},
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingLanguage = false);
      }
    }
  }

  Widget _buildAutoTagSection(AppLocalizations loc, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                loc.t('settings.auto_tag.title'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            loc.t('settings.auto_tag.description'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildRequirement('✓', loc.t('settings.auto_tag.import_hint'), Colors.green),
          const SizedBox(height: 8),
          _buildRequirement(
            '✓',
            loc.t(
              'settings.auto_tag.characters_supported',
              params: {'count': '${zzzCharactersData.length}'},
            ),
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildRequirement('✓', loc.t('settings.auto_tag.naming_hint'), Colors.blue),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFF8B5CF6),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    loc.t('settings.auto_tag.example'),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _autoTagAllMods,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(loc.t('settings.auto_tag.run_action')),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.t('settings.auto_tag.note'),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _autoTagAllMods() async {
    final loc = context.loc;
    setState(() => isLoading = true);

    try {
      bool dialogShown = false;
      if (mounted) {
        dialogShown = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    loc.t('settings.auto_tag.dialog_title'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.t('settings.auto_tag.dialog_message'),
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      final autoTags = await ApiService.autoTagAllMods();

      if (mounted && dialogShown) {
        Navigator.of(context).pop();
      }

      if (autoTags.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.t('settings.auto_tag.no_mods')),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          final tagLabel = autoTags.length == 1
              ? loc.t('settings.auto_tag.tag_single')
              : loc.t('settings.auto_tag.tag_plural');
          final summaryText = loc.t(
            'settings.auto_tag.summary',
            params: {
              'count': '${autoTags.length}',
              'plural': tagLabel,
            },
          );

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 28),
                  const SizedBox(width: 8),
                  Text(loc.t('settings.auto_tag.success_title')),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summaryText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.label,
                              color: Color(0xFF8B5CF6),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              loc.t('settings.auto_tag.list_title'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...autoTags.entries.take(5).map(
                              (entry) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Text(
                                  '• ${entry.key} → ${getCharacterDisplayName(entry.value)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                        if (autoTags.length > 5)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              loc.t(
                                'mods.import.auto_tag_and_more',
                                params: {'count': '${autoTags.length - 5}'},
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.t('settings.auto_tag.success_message'),
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                  ),
                  child: Text(loc.t('settings.auto_tag.ok')),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.t('settings.auto_tag.error', params: {'message': '$e'}),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildF10Section(AppLocalizations loc, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.keyboard,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                loc.t('settings.auto_f10.title'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            loc.t('settings.auto_f10.description'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildRequirement(
            '✓',
            loc.t('settings.auto_f10.requirements.launcher'),
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildRequirement(
            '✓',
            loc.t('settings.auto_f10.requirements.config'),
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildRequirement(
            '⚡',
            loc.t('settings.auto_f10.requirements.tools'),
            Colors.orange,
          ),
          const SizedBox(height: 16),
          // Auto F10 Status
          _buildAutoF10Status(loc, isDarkMode),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _installF10Dependencies,
                  icon: const Icon(Icons.download, size: 16),
                  label: Text(loc.t('settings.auto_f10.install_dependencies')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0EA5E9),
                    side: const BorderSide(color: Color(0xFF0EA5E9)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _showF10Instructions,
                  icon: const Icon(Icons.help_outline, size: 16),
                  label: Text(loc.t('settings.auto_f10.show_instructions')),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(String icon, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          alignment: Alignment.center,
          child: Text(
            icon,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoF10Status(AppLocalizations loc, bool isDarkMode) {
    final autoF10Enabled = ref.watch(autoF10ReloadProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: autoF10Enabled 
            ? const Color(0xFF10B981).withOpacity(0.1)
            : const Color(0xFFEF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: autoF10Enabled 
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFFEF4444).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: autoF10Enabled 
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (autoF10Enabled ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              autoF10Enabled ? Icons.power : Icons.power_off,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('settings.auto_f10.status_title'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  autoF10Enabled 
                      ? loc.t('settings.auto_f10.enabled')
                      : loc.t('settings.auto_f10.disabled'),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: autoF10Enabled,
            onChanged: (value) {
              ref.read(autoF10ReloadProvider.notifier).state = value;
            },
            activeColor: const Color(0xFF10B981),
            inactiveThumbColor: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  void _installF10Dependencies() async {
    final modManagerService = await ref.read(modManagerServiceProvider.future);
    await modManagerService.installF10Dependencies();
    
    if (mounted) {
      final loc = context.loc;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.t('settings.dialogs.dependencies_message')),
          backgroundColor: const Color(0xFF0EA5E9),
        ),
      );
    }
  }

  void _showF10Instructions() {
    final loc = context.loc;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.t('settings.dialogs.instructions_title')),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.t('settings.auto_f10.instructions.step1_title'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(loc.t('settings.auto_f10.instructions.step1_link')),
                const SizedBox(height: 16),
                Text(
                  loc.t('settings.auto_f10.instructions.step2_title'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    loc.t('settings.auto_f10.instructions.step2_code'),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  loc.t('settings.auto_f10.instructions.step3_title'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(loc.t('settings.auto_f10.instructions.step3_platform')),
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 4, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    loc.t('settings.auto_f10.instructions.step3_code'),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  loc.t('settings.auto_f10.instructions.step4_title'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    loc.t('settings.auto_f10.instructions.step4_code'),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.t('settings.auto_f10.instructions.warning_title'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              loc.t('settings.auto_f10.instructions.warning_body'),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  loc.t('settings.auto_f10.instructions.workflow_title'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(loc.t('settings.auto_f10.instructions.workflow_step1'), style: const TextStyle(fontSize: 13)),
                Text(loc.t('settings.auto_f10.instructions.workflow_step2'), style: const TextStyle(fontSize: 13)),
                Text(loc.t('settings.auto_f10.instructions.workflow_step3'), style: const TextStyle(fontSize: 13)),
                Text(loc.t('settings.auto_f10.instructions.workflow_step4'), style: const TextStyle(fontSize: 13)),
                Text(loc.t('settings.auto_f10.instructions.workflow_step5'), style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    loc.t('settings.auto_f10.instructions.details_file'),
                    style: TextStyle(color: Colors.blue[900], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.t('settings.dialogs.ok')),
          ),
        ],
      ),
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
    required AppLocalizations loc,
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
              label: Text(loc.t('settings.paths.browse')),
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
