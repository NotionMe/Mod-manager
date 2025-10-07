import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/mod_manager_service.dart';
import '../utils/path_helper.dart';
import '../utils/state_providers.dart';

enum _MarketplaceDownloadChoice { cancel, downloadOnly, downloadAndInstall }

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  static final WebUri _homeUri = WebUri('https://gamebanana.com/games/19567');

  InAppWebViewController? _inAppWebViewController;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  double _progress = 0;

  bool get _isWindows => !kIsWeb && Platform.isWindows;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  AppLocalizations get loc => context.loc;
  bool get _isWebViewSupported => _isWindows;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final isSupported = _isWebViewSupported;

    return Column(
      children: [
        _buildToolbar(isDarkMode, isSupported),
        if (_isLoading && isSupported) _buildProgressBar(),
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: isSupported
                ? _buildWebView(isDarkMode)
                : _buildUnsupportedView(isDarkMode),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(bool isDarkMode, bool isEnabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildIconButton(
            icon: Icons.arrow_back,
            tooltip: loc.t('marketplace.back'),
            enabled: isEnabled,
            onPressed: () {
              _handleBackNavigation();
            },
          ),
          const SizedBox(width: 8),
          _buildIconButton(
            icon: Icons.arrow_forward,
            tooltip: loc.t('marketplace.forward'),
            enabled: isEnabled,
            onPressed: () {
              _handleForwardNavigation();
            },
          ),
          const SizedBox(width: 8),
          _buildIconButton(
            icon: Icons.refresh,
            tooltip: loc.t('marketplace.reload'),
            enabled: isEnabled,
            onPressed: () {
              _handleReload();
            },
          ),
          const SizedBox(width: 8),
          _buildIconButton(
            icon: Icons.home,
            tooltip: loc.t('marketplace.home'),
            enabled: isEnabled,
            onPressed: () {
              _handleHomeNavigation();
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.08),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      enabled: isEnabled,
                      decoration: InputDecoration(
                        hintText: loc.t('marketplace.search_hint'),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _performSearch,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: isEnabled
                        ? () => _performSearch(_searchController.text)
                        : null,
                    child: Text(loc.t('marketplace.search')),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool enabled = true,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.transparent,
          ),
          child: Icon(icon, size: 20, color: enabled ? null : Colors.grey),
        ),
      ),
    );
  }

  Widget _buildUnsupportedView(bool isDarkMode) {
    final url = _homeUri.toString();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.open_in_browser,
                size: 48,
                color: isDarkMode ? Colors.white54 : Colors.black45,
              ),
              const SizedBox(height: 16),
              Text(
                loc.t('marketplace.unsupported_title'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                loc.t('marketplace.unsupported_body', params: {'url': url}),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.t('marketplace.copy_success'))),
                  );
                },
                icon: const Icon(Icons.copy_all_rounded),
                label: Text(loc.t('marketplace.copy_link')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: _progress > 0 && _progress < 1 ? _progress : null,
    );
  }

  Widget _buildWebView(bool isDarkMode) {
    if (_isWindows) {
      return _buildWindowsWebView(isDarkMode);
    }
    return _buildUnsupportedView(isDarkMode);
  }

  Widget _buildWindowsWebView(bool isDarkMode) {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: _homeUri),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        transparentBackground: true,
        useShouldOverrideUrlLoading: true,
        incognito: false,
        allowsInlineMediaPlayback: true,
        supportZoom: true,
        clearCache: false,
        disableContextMenu: false,
        allowsBackForwardNavigationGestures: true,
        mediaPlaybackRequiresUserGesture: false,
        useOnDownloadStart: true,
        isFraudulentWebsiteWarningEnabled: true,
      ),
      onWebViewCreated: (controller) => _inAppWebViewController = controller,
      shouldOverrideUrlLoading: (controller, action) async {
        return NavigationActionPolicy.ALLOW;
      },
      onLoadStart: (controller, url) {
        if (url != null) {
          setState(() {
            _progress = 0;
            _isLoading = true;
          });
        }
      },
      onLoadStop: (controller, url) async {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _progress = 0;
        });
      },
      onProgressChanged: (controller, progress) {
        if (!mounted) return;
        setState(() {
          _progress = progress / 100;
          _isLoading = progress < 100;
        });
      },
      onDownloadStartRequest: (controller, request) async {
        final webUri = request.url;
        final uri = Uri.parse(webUri.toString());

        final choice = await _showDownloadChoiceDialog(
          context,
          suggestedName: request.suggestedFilename,
          url: webUri.toString(),
        );
        if (choice == _MarketplaceDownloadChoice.cancel || !mounted) return;

        await _handleDownload(
          uri: uri,
          suggestedName: request.suggestedFilename,
          autoInstall: choice == _MarketplaceDownloadChoice.downloadAndInstall,
        );
      },
    );
  }

  Future<void> _loadUri(WebUri uri) async {
    if (_isWindows) {
      await _inAppWebViewController?.loadUrl(urlRequest: URLRequest(url: uri));
    }
  }

  Future<void> _handleBackNavigation() async {
    if (_isWindows) {
      if (await _inAppWebViewController?.canGoBack() ?? false) {
        await _inAppWebViewController?.goBack();
      }
    }
  }

  Future<void> _handleForwardNavigation() async {
    if (_isWindows) {
      if (await _inAppWebViewController?.canGoForward() ?? false) {
        await _inAppWebViewController?.goForward();
      }
    }
  }

  Future<void> _handleReload() async {
    if (_isWindows) {
      await _inAppWebViewController?.reload();
    }
  }

  Future<void> _handleHomeNavigation() async {
    await _loadUri(_homeUri);
  }

  void _performSearch(String query) {
    if (!_isWebViewSupported) {
      return;
    }
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _loadUri(_homeUri);
      return;
    }

    final searchUri = WebUri(
      'https://gamebanana.com/search?_type=Mods&game=19567&query=${Uri.encodeComponent(trimmed)}',
    );
    _loadUri(searchUri);
  }

  Future<_MarketplaceDownloadChoice> _showDownloadChoiceDialog(
    BuildContext context, {
    required String url,
    String? suggestedName,
  }) async {
    final filename = suggestedName ?? path.basename(Uri.parse(url).path);
    return await showDialog<_MarketplaceDownloadChoice>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(loc.t('marketplace.download_title')),
              content: Text(
                loc.t(
                  'marketplace.download_message',
                  params: {
                    'filename': filename.isEmpty
                        ? loc.t('marketplace.unknown_file')
                        : filename,
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, _MarketplaceDownloadChoice.cancel),
                  child: Text(loc.t('marketplace.download_cancel')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _MarketplaceDownloadChoice.downloadOnly,
                  ),
                  child: Text(loc.t('marketplace.download_only')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _MarketplaceDownloadChoice.downloadAndInstall,
                  ),
                  child: Text(loc.t('marketplace.download_install')),
                ),
              ],
            );
          },
        ) ??
        _MarketplaceDownloadChoice.cancel;
  }

  Future<void> _handleDownload({
    required Uri uri,
    String? suggestedName,
    required bool autoInstall,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final sanitizedFilename = _sanitizeFilename(
      suggestedName?.isNotEmpty == true
          ? suggestedName!
          : path.basename(uri.path),
      fallback:
          'mod_${DateTime.now().millisecondsSinceEpoch}${path.extension(uri.path)}',
    );

    final progressNotifier = ValueNotifier<double?>(0);
    final progressDialog = _showProgressDialog(progressNotifier);
    var dialogClosed = false;

    try {
      final downloadedFile = await _downloadToTemporaryFile(
        uri: uri,
        filename: sanitizedFilename,
        progressNotifier: progressNotifier,
      );

      if (!dialogClosed && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogClosed = true;
      }

      await progressDialog;

      if (!mounted) return;

      if (!autoInstall) {
        final savedFile = await _moveToDownloads(
          downloadedFile,
          sanitizedFilename,
        );
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              loc.t('marketplace.download_saved', params: {'path': savedFile}),
            ),
          ),
        );
        return;
      }

      final installResult = await _installArchive(downloadedFile);
      if (!mounted) return;

      installResult.when(
        success: (mods, message) {
          final importedMods = mods.join(', ');
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                loc.t(
                  'marketplace.install_success',
                  params: {
                    'mods': importedMods.isEmpty
                        ? loc.t('marketplace.install_success_default')
                        : importedMods,
                  },
                ),
              ),
            ),
          );
          if (message != null && message.isNotEmpty) {
            scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
          }
        },
        warning: (message) {
          scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
        },
        error: (message) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              backgroundColor: Theme.of(context).colorScheme.error,
              content: Text(message),
            ),
          );
        },
      );
    } catch (e) {
      if (!dialogClosed && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogClosed = true;
      }
      await progressDialog;
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            loc.t('marketplace.download_failed', params: {'message': '$e'}),
          ),
        ),
      );
    } finally {
      if (!dialogClosed && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        await progressDialog;
      }
      progressNotifier.dispose();
    }
  }

  Future<File> _downloadToTemporaryFile({
    required Uri uri,
    required String filename,
    required ValueNotifier<double?> progressNotifier,
  }) async {
    final tempDir = await Directory.systemTemp.createTemp(
      'zzz_marketplace_download_',
    );
    final targetFile = File(path.join(tempDir.path, filename));

    final request = http.Request('GET', uri);
    final response = await request.send();

    if (response.statusCode >= 400) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final sink = targetFile.openWrite();
    final total = response.contentLength;
    int received = 0;

    await response.stream.listen((chunk) {
      received += chunk.length;
      sink.add(chunk);
      if (total != null && total > 0) {
        progressNotifier.value = min(received / total, 1);
      } else {
        progressNotifier.value = null;
      }
    }).asFuture();

    await sink.close();
    progressNotifier.value = 1;

    return targetFile;
  }

  Future<String> _moveToDownloads(File file, String filename) async {
    final downloadsDir = Directory(
      path.join(PathHelper.getAppDataPath(), 'downloads'),
    );
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    final targetPath = path.join(downloadsDir.path, filename);
    await file.copy(targetPath);
    await file.parent.delete(recursive: true);
    return targetPath;
  }

  Future<_InstallResult> _installArchive(File archiveFile) async {
    final config = await ApiService.getConfig();
    final modsPath = config['mods_path'] ?? '';

    if (modsPath.isEmpty) {
      return _InstallResult.error(loc.t('marketplace.install_missing_path'));
    }

    final tempExtractDir = await Directory.systemTemp.createTemp(
      'zzz_marketplace_extract_',
    );

    try {
      final extension = path.extension(archiveFile.path).toLowerCase();
      String? extractionError;
      bool isExtracted = false;

      if (extension == '.zip') {
        isExtracted = await _extractZip(archiveFile, tempExtractDir);
      } else if (extension == '.rar' || extension == '.7z') {
        final result = await _extractWith7Zip(archiveFile, tempExtractDir);
        extractionError = result.error;
        isExtracted = result.success;
      }

      if (!isExtracted) {
        return _InstallResult.error(
          extractionError ?? loc.t('marketplace.install_unsupported'),
        );
      }

      final directoriesToImport = await _prepareDirectoriesForImport(
        tempExtractDir,
        archiveFile,
      );

      if (directoriesToImport.isEmpty) {
        return _InstallResult.warning(loc.t('marketplace.install_empty'));
      }

      final ModManagerService modManager =
          await ApiService.getModManagerService();
      final (importedMods, autoTags) = await modManager.importMods(
        directoriesToImport,
      );

      if (importedMods.isEmpty) {
        return _InstallResult.warning(loc.t('marketplace.install_duplicate'));
      }

      final tagSummary = autoTags.entries
          .map((entry) => '${entry.key} → ${entry.value}')
          .join(', ');

      final message = tagSummary.isNotEmpty
          ? loc.t('marketplace.install_tags', params: {'tags': tagSummary})
          : null;

      return _InstallResult.success(importedMods, message: message);
    } finally {
      if (await tempExtractDir.exists()) {
        await tempExtractDir.delete(recursive: true);
      }
      if (await archiveFile.exists()) {
        await archiveFile.parent.delete(recursive: true);
      }
    }
  }

  Future<List<String>> _prepareDirectoriesForImport(
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

  Future<bool> _extractZip(File archiveFile, Directory destination) async {
    try {
      final bytes = await archiveFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes, verify: true);

      for (final file in archive) {
        final sanitizedPath = _sanitizeArchivePath(destination.path, file.name);
        if (sanitizedPath == null) {
          continue;
        }

        if (file.isFile) {
          final outFile = File(sanitizedPath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          final dir = Directory(sanitizedPath);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<_ArchiveExtractionResult> _extractWith7Zip(
    File archiveFile,
    Directory destination,
  ) async {
    final sevenZipPath = await _locate7Zip();
    if (sevenZipPath == null) {
      return _ArchiveExtractionResult(
        false,
        loc.t('marketplace.install_7zip_missing'),
      );
    }

    final result = await Process.run(sevenZipPath, [
      'x',
      archiveFile.path,
      '-o${destination.path}',
      '-y',
    ]);

    if (result.exitCode != 0) {
      final errorOutput = result.stderr.toString().trim();
      return _ArchiveExtractionResult(
        false,
        errorOutput.isNotEmpty
            ? errorOutput
            : loc.t('marketplace.install_extract_failed'),
      );
    }

    return const _ArchiveExtractionResult(true);
  }

  Future<String?> _locate7Zip() async {
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
          // Ignore failures and continue searching.
        }
      }
    }

    return null;
  }

  String? _sanitizeArchivePath(String base, String relativePath) {
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

  Future<void> _showProgressDialog(ValueNotifier<double?> progressNotifier) {
    final completer = Completer<void>();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ValueListenableBuilder<double?>(
          valueListenable: progressNotifier,
          builder: (context, value, _) {
            return AlertDialog(
              title: Text(loc.t('marketplace.downloading')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value != null)
                    LinearProgressIndicator(value: value)
                  else
                    const LinearProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    value != null
                        ? '${(value * 100).clamp(0, 100).toStringAsFixed(0)}%'
                        : loc.t('marketplace.download_progress_unknown'),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) => completer.complete());
    return completer.future;
  }

  String _sanitizeFilename(String input, {required String fallback}) {
    final sanitized = input.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final trimmed = sanitized.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }
    return trimmed;
  }
}

class _InstallResult {
  final List<String> mods;
  final String? message;
  final String? errorMessage;

  const _InstallResult._({required this.mods, this.message, this.errorMessage});

  factory _InstallResult.success(List<String> mods, {String? message}) =>
      _InstallResult._(mods: mods, message: message);

  factory _InstallResult.warning(String message) =>
      _InstallResult._(mods: const [], message: message);

  factory _InstallResult.error(String message) =>
      _InstallResult._(mods: const [], errorMessage: message);

  void when({
    required void Function(List<String> mods, String? message) success,
    required void Function(String message) warning,
    required void Function(String message) error,
  }) {
    if (errorMessage != null) {
      error(errorMessage!);
      return;
    }

    if (mods.isNotEmpty) {
      success(mods, message);
      return;
    }

    if (message != null) {
      warning(message!);
    }
  }
}

class _ArchiveExtractionResult {
  final bool success;
  final String? error;

  const _ArchiveExtractionResult(this.success, [this.error]);
}
