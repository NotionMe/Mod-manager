# Changelog

## [Unreleased]

### Added
- **Автоматичне тегування модів** - система автоматично визначає персонажів за назвою папки моду
  - Автоматичне тегування при імпорті нових модів
  - Кнопка "Визначити теги для всіх модів" в налаштуваннях
  - Підтримка розпізнавання 38 персонажів
  - Детальна документація в `AUTO_TAGGING.md`

### Fixed
- **Виправлено анімацію перемикача Single/Multi** - синій повзунок більше не виходить за межі кнопки
  - Додано `ClipRRect` для обрізання анімованих елементів
  - Покращено плавність анімації
  
- **Виправлено краш при закритті додатку**
  - Додано `WindowListener` для коректної обробки закриття вікна
  - Швидке завершення процесу без очікування очищення OpenGL контексту
  - Виправлено помилки `eglMakeCurrent failed` та `Couldn't find current GLX or EGL context`

### Changed
- **Перенесено кнопку авто-тегування в налаштування**
  - Раніше кнопка була в головному екрані поруч з F10
  - Тепер кнопка в налаштуваннях у власній секції "Автоматичне тегування"
  - Покращено UX та логічну організацію функцій

### Improved
- Оптимізовано продуктивність закриття додатку
- Покращено UI секції автотегування в налаштуваннях
- Додано детальні інструкції та приклади використання

---

## Функціонал автотегування

### Як це працює

**Автоматично при імпорті:**
- Коли ви імпортуєте моди (drag & drop або Ctrl+V), система автоматично аналізує назви папок
- Якщо в назві є ім'я персонажа, тег встановлюється автоматично

**Для існуючих модів:**
1. Відкрийте Settings (⚙️)
2. Знайдіть секцію "Автоматичне тегування"
3. Натисніть "Визначити теги для всіх модів"
4. Система проаналізує всі моди без тегів

### Приклади

✅ **Назви, які спрацюють:**
- `Ellen_Summer_Skin` → Ellen
- `miyabi-kimono-outfit` → Miyabi
- `Burnice_FireFighter_v2` → Burnice
- `Jane_Doe_Casual` → Jane

❌ **Назви, які НЕ спрацюють:**
- `Cool_Skin_123` (немає імені персонажа)
- `Mod_Pack_Final` (немає імені персонажа)

### Підтримувані персонажі

Система розпізнає 38 персонажів: Anby, Anton, Astra, Belle, Ben, Billy, Burnice, Caesar, Corin, Ellen, Evelyn, Grace, Harumasa, Hugo, Jane, Jufufu, Koleda, Lighter, Lucy, Lycaon, Miyabi, Nekomata, Nicole, Orphie, Panyinhu, Piper, Pulchra, Qingyi, Rina, Seth, Soldier 0 Anby, Soldier 11, Soukaku, Trigger, Vivian, Wise, Yanagi, Yixuan, Zhu Yuan.

---

## Технічні деталі

### API Changes

```dart
// Новий метод в ApiService
Future<Map<String, String>> autoTagAllMods()

// Новий метод в ModManagerService  
Future<Map<String, String>> autoTagAllMods()
```

### Config Service

Теги зберігаються в:
- `SharedPreferences` (`mod_character_tags`)
- `config.json` (`mod_character_tags`)

### Performance

- Швидке завершення процесу при закритті (< 100ms)
- Автотегування працює асинхронно без блокування UI
- Оптимізована анімація Single/Multi перемикача
