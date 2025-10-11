/// Character data model for better organization
class CharacterData {
  final String id;
  final String displayName;
  final String assetName;

  const CharacterData({
    required this.id,
    required this.displayName,
    required this.assetName,
  });
}

/// List of all available characters in Zenless Zone Zero
/// IDs are normalized for consistency, asset names match actual file names
const List<CharacterData> zzzCharactersData = [
  CharacterData(id: 'alice', displayName: 'Alice', assetName: 'alice'),
  CharacterData(id: 'anby', displayName: 'Anby', assetName: 'anby'),
  CharacterData(id: 'anton', displayName: 'Anton', assetName: 'anton'),
  CharacterData(id: 'astra', displayName: 'Astra', assetName: 'astra'),
  CharacterData(id: 'belle', displayName: 'Belle', assetName: 'belle'),
  CharacterData(id: 'ben', displayName: 'Ben', assetName: 'ben'),
  CharacterData(
    id: 'billy',
    displayName: 'Billy',
    assetName: 'billy_herinkton',
  ),
  CharacterData(id: 'burnice', displayName: 'Burnice', assetName: 'burnice'),
  CharacterData(id: 'caesar', displayName: 'Caesar', assetName: 'caesar'),
  CharacterData(id: 'corin', displayName: 'Corin', assetName: 'corin'),
  CharacterData(id: 'ellen', displayName: 'Ellen', assetName: 'ellen'),
  CharacterData(id: 'evelyn', displayName: 'Evelyn', assetName: 'evelyn'),
  CharacterData(id: 'grace', displayName: 'Grace', assetName: 'grace'),
  CharacterData(id: 'harumasa', displayName: 'Harumasa', assetName: 'harumasa'),
  CharacterData(id: 'hugo', displayName: 'Hugo', assetName: 'hugo'),
  CharacterData(id: 'jane', displayName: 'Jane', assetName: 'jane'),
  CharacterData(id: 'jufufu', displayName: 'Jufufu', assetName: 'jufufu'),
  CharacterData(id: 'koleda', displayName: 'Koleda', assetName: 'koleda'),
  CharacterData(id: 'lighter', displayName: 'Lighter', assetName: 'lighter'),
  CharacterData(id: 'lucy', displayName: 'Lucy', assetName: 'lucy'),
  CharacterData(id: 'lycaon', displayName: 'Von Lycaon', assetName: 'lycaon'),
  CharacterData(id: 'miyabi', displayName: 'Miyabi', assetName: 'miyabi'),
  CharacterData(id: 'nekomata', displayName: 'Nekomata', assetName: 'nekomata'),
  CharacterData(id: 'nicole', displayName: 'Nicole', assetName: 'nicole'),
  CharacterData(id: 'orphie', displayName: 'Orphie', assetName: 'orphie'),
  CharacterData(id: 'panyinhu', displayName: 'Panyinhu', assetName: 'panyinhu'),
  CharacterData(id: 'piper', displayName: 'Piper', assetName: 'piper'),
  CharacterData(id: 'pulchra', displayName: 'Pulchra', assetName: 'pulchra'),
  CharacterData(id: 'quinqiy', displayName: 'Qingyi', assetName: 'quinqiy'),
  CharacterData(id: 'rina', displayName: 'Rina', assetName: 'rina'),
  CharacterData(id: 'seed', displayName: 'Seed', assetName: 'seed'),
  CharacterData(id: 'seth', displayName: 'Seth', assetName: 'seth'),
  CharacterData(
    id: 'solder0anby',
    displayName: 'Soldier 0 Anby',
    assetName: 'solder0anby',
  ),
  CharacterData(
    id: 'solder11',
    displayName: 'Soldier 11',
    assetName: 'solder11',
  ),
  CharacterData(id: 'soukaku', displayName: 'Soukaku', assetName: 'soukaku'),
  CharacterData(id: 'trigger', displayName: 'Trigger', assetName: 'trigger'),
  CharacterData(id: 'vivian', displayName: 'Vivian', assetName: 'vivian'),
  CharacterData(id: 'wise', displayName: 'Wise', assetName: 'wise'),
  CharacterData(id: 'yanagi', displayName: 'Yanagi', assetName: 'yanagi'),
  CharacterData(id: 'yixuan', displayName: 'Yixuan', assetName: 'yixuan'),
  CharacterData(id: 'yuzuha', displayName: 'Yuzuha', assetName: 'yuzuha'),
  CharacterData(id: 'zhuyuan', displayName: 'Zhu Yuan', assetName: 'zhuyuan'),
];

/// Legacy list for backward compatibility
@deprecated
const List<String> zzzCharacters = [
  'alice',
  'anby',
  'anton',
  'astra',
  'belle',
  'ben',
  'billy',
  'burnice',
  'caesar',
  'corin',
  'ellen',
  'evelyn',
  'grace',
  'harumasa',
  'hugo',
  'jane',
  'jufufu',
  'koleda',
  'lighter',
  'lucy',
  'lycaon',
  'miyabi',
  'nekomata',
  'nicole',
  'orphie',
  'panyinhu',
  'piper',
  'pulchra',
  'quinqiy',
  'rina',
  'seed',
  'seth',
  'solder0anby',
  'solder11',
  'soukaku',
  'trigger',
  'vivian',
  'wise',
  'yanagi',
  'yixuan',
  'yuzuha',
  'zhuyuan',
];

/// Get display name for a character by ID
String getCharacterDisplayName(String id) {
  final character = zzzCharactersData.firstWhere(
    (char) => char.id == id.toLowerCase(),
    orElse: () => CharacterData(id: id, displayName: id, assetName: id),
  );
  return character.displayName;
}

/// Get asset path for a character by ID
String getCharacterAssetName(String id) {
  final character = zzzCharactersData.firstWhere(
    (char) => char.id == id.toLowerCase(),
    orElse: () => CharacterData(id: id, displayName: id, assetName: id),
  );
  return character.assetName;
}
