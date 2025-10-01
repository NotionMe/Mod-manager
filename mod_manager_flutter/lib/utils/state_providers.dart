import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character_info.dart';
import '../services/api_service.dart';
import '../services/mod_manager_service.dart';

// API Service Provider
final modManagerServiceProvider = FutureProvider<ModManagerService>((ref) async {
  return await ApiService.getModManagerService();
});

// Zoom scale provider
final zoomScaleProvider = StateProvider<double>((ref) => 1.0);

// Tab index provider
final tabIndexProvider = StateProvider<int>((ref) => 0);

// Characters list
final charactersProvider = StateProvider<List<CharacterInfo>>((ref) => []);

// Selected character index
final selectedCharacterIndexProvider = StateProvider<int>((ref) => 0);

// Current mods list (all mods)
final modsProvider = StateProvider<List<ModInfo>>((ref) => []);

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtered characters based on search - optimized with select
final filteredCharactersProvider = Provider<List<CharacterInfo>>((ref) {
  final characters = ref.watch(charactersProvider);
  final query = ref.watch(searchQueryProvider);

  if (query.isEmpty) {
    return characters;
  }

  final lowerQuery = query.toLowerCase();
  return characters.where((character) {
    return character.name.toLowerCase().contains(lowerQuery) ||
        character.id.toLowerCase().contains(lowerQuery);
  }).toList();
});

// Skins for selected character - optimized
final currentCharacterSkinsProvider = Provider<List<ModInfo>>((ref) {
  final characters = ref.watch(charactersProvider);
  final selectedIndex = ref.watch(selectedCharacterIndexProvider);

  if (characters.isEmpty || selectedIndex < 0 || selectedIndex >= characters.length) {
    return const [];
  }

  return characters[selectedIndex].skins;
}); // Theme mode provider (dark/light)
final isDarkModeProvider = StateProvider<bool>((ref) => true);

// Settings providers
final modsPathProvider = StateProvider<String>((ref) => '');
final autoRefreshProvider = StateProvider<bool>((ref) => false);

// View mode: grid or carousel
final isGridViewProvider = StateProvider<bool>((ref) => true);

// Activation mode: single (один скін) або multi (кілька скінів)
enum ActivationMode { single, multi }

final activationModeProvider = StateProvider<ActivationMode>((ref) => ActivationMode.single);

// Sidebar collapsed state
final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);

// Auto F10 reload toggle (green = enabled, red = disabled)
final autoF10ReloadProvider = StateProvider<bool>((ref) => false);
