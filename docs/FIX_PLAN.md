# План исправлений Mubeen Quran Pure

Документ составлен по результатам полного аудита от 31.08.2026.
Проверено на Flutter 3.44.9 / Dart 3.12.2, SDK: `C:\Users\abdulla\Desktop\robt\sdk\flutter`.

Каждая задача содержит: файл и строки, суть проблемы, готовое решение, способ
проверки. Задачи упорядочены так, что их можно выполнять сверху вниз без
конфликтов между правками.

---

## Как работать с планом

### Команды проверки

```powershell
$FLUTTER = "C:\Users\abdulla\Desktop\robt\sdk\flutter\bin\flutter.bat"
$DART    = "C:\Users\abdulla\Desktop\robt\sdk\flutter\bin\dart.bat"

& $FLUTTER analyze --no-pub
& $FLUTTER test --no-pub --concurrency=1
& $DART format lib test tool
```

Важно: `flutter test` без `--concurrency=1` падает с `Out of memory` в Dart VM.
Это ограничение машины (свободно ~2 ГБ из 15,4 ГБ), а не дефект проекта.
Всегда запускайте тесты с этим флагом.

### Порядок выполнения

| Этап | Задачи | Смысл этапа |
|---|---|---|
| Этап 1 | 1–4 | Блокеры релиза. Правки мелкие, эффект немедленный |
| Этап 2 | 5–7 | Функциональные дефекты, видимые пользователю |
| Этап 3 | 8–11 | Установка БД, старт, память, версионирование |
| Этап 4 | 12–21 | Качество, доступность, тесты, инфраструктура |
| Этап 5 | 22–29 | Гигиена репозитория и мелочи |

### Статус

Отмечайте выполненное прямо в этом файле, меняя `[ ]` на `[x]`.

---

## Сводная таблица

| № | Задача | Файл | Приоритет |
|---|---|---|---|
| 1 | Потеря закладок на iOS | `lib/controllers/app_controller.dart` | Блокер |
| 2 | Wakelock не отключается | `lib/screens/reader_screen.dart` | Блокер |
| 3 | Релиз подписан debug-ключом | `android/app/build.gradle.kts` | Блокер |
| 4 | Нет лицензий и атрибуции | новые файлы | Блокер |
| 5 | Поиск по арабскому не работает | `lib/data/quran_repository.dart` + `tool/` | Высокий |
| 6 | Мусхаф перезапрашивает БД | `lib/screens/reader_screen.dart` | Высокий |
| 7 | Переход по странице ломает суру | `lib/screens/navigation_screen.dart` | Высокий |
| 8 | Пик памяти ~90 МБ | `lib/data/quran_repository.dart` | Высокий |
| 9 | Блокирующий старт без прогресса | `lib/main.dart`, `lib/app.dart` | Высокий |
| 10 | 45 МБ в бэкапе iCloud | `lib/data/quran_repository.dart` | Высокий |
| 11 | Нет проверки версии контента | `lib/data/quran_repository.dart` | Средний |
| 12 | Контраст ниже WCAG AA | `lib/theme/app_theme.dart` | Средний |
| 13 | Автопрокрутка врёт и дёргается | `lib/screens/reader_screen.dart` | Средний |
| 14 | Фильтр глаз не покрывает шторки | `lib/app.dart` | Средний |
| 15 | Хаптика в слое состояния | `lib/controllers/app_controller.dart` | Средний |
| 16 | Пробелы в тестах | `test/` | Средний |
| 17 | Форматирование не применено | 9 файлов | Средний |
| 18 | Слабый анализатор | `analysis_options.yaml` | Средний |
| 19 | Конфликт ориентаций | `lib/main.dart`, `ios/Runner/Info.plist` | Средний |
| 20 | Гейт не проверяет глоссы | `tool/build_quran_db.py` | Средний |
| 21 | Ошибки глотаются молча | `lib/controllers/app_controller.dart` | Средний |
| 22 | Мусор в репозитории | корень, `android/` | Низкий |
| 23 | Нет CI | `.github/workflows/` | Низкий |
| 24 | Лишняя загрузка переводов | `lib/data/quran_repository.dart` | Низкий |
| 25 | `close()` не вызывается | `lib/app.dart` | Низкий |
| 26 | Поиск сур по транслитерации | `tool/build_quran_db.py` | Низкий |
| 27 | Нет верхней границы аята | `lib/controllers/app_controller.dart` | Низкий |
| 28 | 286 `SelectableText` в скролле | `lib/screens/reader_screen.dart` | Низкий |
| 29 | Нет `PrivacyInfo.xcprivacy` | `ios/Runner/` | Низкий |

---

# Этап 1. Блокеры релиза

## [x] 1. Закладки молча теряются на iOS, macOS и Windows

**Файл:** `lib/controllers/app_controller.dart`, строка 342, метод `_readBookmarks`

**Проблема**

```dart
static Set<int> _readBookmarks(Object? savedValue) {
  if (savedValue is! List<String>) {   // <-- строка 342
    return <int>{};
  }
  ...
}
```

Проверка требует именно `List<String>`. Разные платформы отдают разные типы:

| Платформа | Что возвращает | Проходит проверку |
|---|---|---|
| Android | `List<String>` — плагин делает `jsonDecode(...).cast<String>()` | да |
| iOS / macOS | `List<Object?>` — pigeon декодирует `Map<Object?,Object?>.cast<String,Object>()`, значения не перетипизируются | **нет** |
| Windows / Linux | `List<Object?>` по той же причине | **нет** |

Источник для Android: `shared_preferences_android-2.4.28/lib/src/shared_preferences_android.dart:96-101`.
Источник для iOS: `shared_preferences_foundation-2.5.7/lib/src/messages.g.dart`, метод `getAll`.

На всех платформах кроме Android каждая закладка пользователя стирается при
запуске приложения. Молча, без ошибки.

**Подтверждено экспериментально.** Временный тест дал:
`List<String>['42']` → `{42}` (ок), `List<Object?>['42']` → `{}` (баг).

**Решение**

```dart
static Set<int> _readBookmarks(Object? savedValue) {
  if (savedValue is! List) {
    return <int>{};
  }

  return savedValue
      .whereType<String>()
      .map(int.tryParse)
      .whereType<int>()
      .where((int id) => id > 0)
      .toSet();
}
```

Ключевое: `is! List` вместо `is! List<String>`, затем `whereType<String>()`
отфильтрует нестроковые элементы уже внутри списка.

**Почему существующий тест не поймал баг**

`test/controllers/app_controller_test.dart:161` использует литерал
`<String>['invalid', '-5', '42']`, то есть заведомо `List<String>` — путь
Android. Нужно добавить кейс с `<Object?>`.

**Тест для добавления** в `test/controllers/app_controller_test.dart`:

```dart
test('bookmarks survive a platform-decoded List<Object?>', () async {
  // Android отдаёт List<String>
  SharedPreferences.setMockInitialValues(<String, Object>{
    'bookmarked_ayah_ids': <String>['42'],
  });
  final AppController androidLike = AppController();
  await androidLike.initialize();
  expect(androidLike.bookmarkedAyahIds, equals(<int>{42}));

  // iOS, macOS и Windows отдают List<Object?>
  SharedPreferences.setMockInitialValues(<String, Object>{
    'bookmarked_ayah_ids': <Object?>['42'],
  });
  final AppController iosLike = AppController();
  await iosLike.initialize();
  expect(iosLike.bookmarkedAyahIds, equals(<int>{42}));
});
```

**Проверка:** `& $FLUTTER test --no-pub --concurrency=1` — новый тест зелёный.

---

## [x] 2. Wakelock не отключается никогда

**Файлы:** `lib/screens/reader_screen.dart:27-39`, `lib/screens/quran_home_screen.dart:59`

**Проблема**

```dart
// reader_screen.dart
@override
void initState() {
  super.initState();
  WakelockPlus.enable();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

@override
void dispose() {
  WakelockPlus.disable();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  super.dispose();
}
```

`ReaderScreen` лежит внутри `IndexedStack` (`quran_home_screen.dart:59`).
`IndexedStack` сохраняет состояние всех ветвей и не уничтожает неактивные.
Значит `dispose()` вызывается только при закрытии приложения.

Следствия:
- экран не гаснет всё время работы приложения, в том числе на вкладках
  «Навигация», «Поиск» и «Настройки»;
- иммерсивный режим (скрытые системные панели) применяется ко всем четырём
  вкладкам, хотя задуман только для чтения;
- при уходе приложения в фон wakelock остаётся включённым.

Это прямой расход батареи, что особенно неуместно для приложения, которое
позиционируется как аккуратное и минималистичное.

**Решение**

Wakelock должен зависеть от двух условий: читалка активна И приложение на
переднем плане. Убираем управление из `initState`/`dispose` читалки и переносим
в `QuranHomeScreen`, который знает про активную вкладку.

В `lib/screens/quran_home_screen.dart` заменить `_QuranHomeScreenState`:

```dart
class _QuranHomeScreenState extends State<QuranHomeScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ReaderScreenState> _readerKey =
      GlobalKey<ReaderScreenState>();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncScreenPresentation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _syncScreenPresentation();
  }

  /// Экран держится включённым только когда открыта читалка
  /// и приложение находится на переднем плане.
  void _syncScreenPresentation() {
    final bool readerVisible = _selectedIndex == 0;
    final bool foreground =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    final bool keepAwake = readerVisible && foreground;

    WakelockPlus.toggle(enable: keepAwake);
    SystemChrome.setEnabledSystemUIMode(
      keepAwake ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  void _selectTab(int index) {
    if (_selectedIndex == index) {
      return;
    }
    setState(() => _selectedIndex = index);
    _syncScreenPresentation();
  }

  void _openLocation(ReaderLocation location, {ReaderMode? mode}) {
    _selectTab(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readerKey.currentState?.openLocation(location, mode: mode);
    });
  }
  // build() ниже: onDestinationSelected: _selectTab
}
```

Не забыть импорт `package:wakelock_plus/wakelock_plus.dart` и
`package:flutter/services.dart` в `quran_home_screen.dart`.

В `lib/screens/reader_screen.dart` удалить блоки `initState` (строки 27-32) и
`dispose` (строки 34-39) вместе с импортом `wakelock_plus`, если он больше
нигде не нужен в файле.

Важно: `_openLocation` раньше делал `setState(() => _selectedIndex = 0)`
безусловно. Новый `_selectTab` выходит рано, если вкладка уже активна — это
корректно, потому что `addPostFrameCallback` всё равно вызывается.

**Проверка**

1. `& $FLUTTER analyze --no-pub` — чисто.
2. Ручная проверка на устройстве: открыть настройки, оставить телефон — экран
   должен погаснуть по системному таймауту. Вернуться на чтение — не гаснет.

---

## [x] 3. Релиз больше не подписывается отладочным ключом

**Файл:** `android/app/build.gradle.kts`

Исправлено: `android/key.properties` подключается только при наличии файла и
требует `storeFile`, `storePassword`, `keyAlias` и `keyPassword`. Если файла нет,
release-вариант остаётся неподписанным; fallback на debug-ключ отсутствует.
Неподписанная сборка допустима только для локальной проверки и не должна
распространяться.

OWNER TODO: создать и безопасно хранить release/upload-ключ вне репозитория,
заполнить `android/key.properties` в защищённой среде сборки и проверить
отпечаток сертификата итогового артефакта. Потеря ключа или паролей может лишить
возможности выпускать обновления.

**Проверка:** выполнить `:app:signingReport` без `key.properties` и убедиться,
что у release нет конфигурации подписи; затем повторить в защищённой среде с
ключом и убедиться, что сертификат не является `Android Debug`.

---

## [x] 4. Нет лицензий и атрибуции контента

**Проблема**

В репозитории нет ни одного файла LICENSE. Проверено поиском по всему дереву.

Шрифт. Разбор таблицы `name` файла `assets/fonts/AmiriQuran-Regular.ttf` дал:

```
nameID  0 = Copyright 2010-2022 The Amiri Project Authors (https://github.com/aliftype/amiri)
nameID  1 = Amiri Quran
nameID  5 = Version 1.003
nameID  8 = Alif Type
nameID 13 = This Font Software is licensed under the SIL Open Font License, Version 1.1
nameID 14 = https://openfontlicense.org
OS/2 fsType = 0 (встраивание разрешено)
```

SIL OFL 1.1 разрешает встраивание в приложение, но **требует** поставлять текст
лицензии вместе со шрифтом. Сейчас требование не выполнено.

Контент. Нет указания источников и правового основания для:
- перевода Э. Кулиева (6236 записей);
- перевода Абу Аделя (6236 записей);
- тафсира ас-Саади (6236 записей);
- пословного разбора (77 432 записи).

`docs/TECH_SPEC.md:64-68` подробно оговаривает отложенные аудиоправа, но о
правах на уже вшитый контент не говорит ничего. Для приложения, продающего
себя честностью и отсутствием мусора, это заметный пробел. Магазины приложений
проверяют религиозный контент внимательнее обычного.

**Решение**

Шаг 1. Скачать текст OFL 1.1 и положить рядом со шрифтом как
`assets/fonts/OFL.txt`. Официальный текст: <https://openfontlicense.org>.

Шаг 2. Создать `LICENSE` в корне для кода самого приложения (выбрать лицензию
по своему усмотрению).

Шаг 3. Создать `docs/CONTENT_LICENSES.md` со структурой:

```markdown
# Источники и лицензии контента

## Шрифт

| Ресурс | Amiri Quran 1.003 |
|---|---|
| Автор | The Amiri Project Authors, Alif Type |
| Лицензия | SIL Open Font License 1.1 |
| Текст лицензии | `assets/fonts/OFL.txt` |
| Источник | https://github.com/aliftype/amiri |

## Арабский текст Корана

| Редакция | Уthmani |
|---|---|
| Источник | <заполнить> |
| Основание | <заполнить> |

## Переводы смыслов

| Перевод | Автор | Источник | Основание использования |
|---|---|---|---|
| kuliev | Эльмир Кулиев | <заполнить> | <заполнить> |
| abu_adel | Абу Адель | <заполнить> | <заполнить> |

## Тафсир

| Тафсир | Автор | Источник | Основание |
|---|---|---|---|
| tafsir_saadi | Абд ар-Рахман ас-Саади | <заполнить> | <заполнить> |

## Пословный разбор

| Данные | Источник | Основание |
|---|---|---|
| quran_wbw | <заполнить> | <заполнить> |
```

Шаг 4. Добавить в приложение экран «О программе» с этой атрибуцией. Логичное
место — низ `SettingsScreen`, рядом с карточкой обещания приватности
(`lib/screens/settings_screen.dart:142-161`). Flutter умеет показывать
лицензии зависимостей через `LicensePage`; собственную атрибуцию контента нужно
добавить вручную через `LicenseRegistry.addLicense`.

Шаг 5. Дополнить `docs/TECH_SPEC.md` разделом о правах на встроенный контент,
по аналогии с существующим разделом `Deferred Systems`.

**Проверка:** файлы на месте, экран атрибуции открывается из настроек, в
`docs/CONTENT_LICENSES.md` не осталось `<заполнить>`.

---

# Этап 2. Функциональные дефекты

## [x] 5. Поиск по арабскому с огласовками и хамзой не находит ничего

**Файлы:** `lib/data/quran_repository.dart:600-612` (`_buildFtsPrefixQuery`),
`tool/build_quran_db.py:34-51` (`normalize_arabic`)

**Проблема**

Функция `normalize_arabic` существует только в скрипте сборки и применяется к
индексируемому тексту. Запрос пользователя уходит в FTS как есть:

```dart
String? _buildFtsPrefixQuery(String query) {
  final Iterable<String> tokens = RegExp(r'[\p{L}\p{M}\p{N}]+', unicode: true)
      .allMatches(query).map((RegExpMatch match) => match.group(0)!);
  final List<String> prefixTerms = tokens
      .map((String token) => '"${token.replaceAll('"', '""')}"*')
      .toList(growable: false);
  ...
}
```

Токенизатор `unicode61 remove_diacritics 2` снимает часть диакритики, но не
знает про алиф-васлу и формы хамзы. Замеры на реальной БД:

| Что вводит пользователь | Найдено сейчас |
|---|---|
| `الرحمن` (без огласовок) | 46 |
| `ٱلرحمن` (алиф-васла, как в мусхафе) | **0** |
| `الرَّحمَـٰن` (с огласовками) | **0** |
| `إبراهيم` (с хамзой) | **0** |
| `ابراهيم` (без хамзы) | 1 — и это только название суры |
| `أنعمت` | **0** |

Подсказка в интерфейсе (`lib/screens/search_screen.dart:248`) прямо обещает
«арабский текст с огласовками или без них». Обещание не выполняется.

Есть и вторая, более глубокая причина. `normalize_arabic` **удаляет** U+0670
(надстрочный алиф) вместо замены на обычный алиф:

```python
ARABIC_MARKS = re.compile(r"[\u0610-\u061a\u064b-\u065f\u0670\u06d6-\u06ed]")
                                                   ^^^^^^ удаляется
```

Результат: `ٱلْعَـٰلَمِينَ` нормализуется в `العلمين`, а не в `العالمين`.
Пользователь, набирающий современное написание, не найдёт ничего. Замеры
показали, что U+0670 встречается в **4367 аятах из 6236** — затронуто 70 %
корпуса.

| Современное написание | Найдено сейчас | Написание в нормализованной колонке | Найдено |
|---|---|---|---|
| `العالمين` | **0** | `العلمين` | 61 |
| `ابراهيم` | **0** | `ابرهيم` | 51 |
| `السماوات` | **0** | `السموت` | 183 |

**Решение делится на две части.** Первая не требует пересборки БД, вторая
требует.

### Часть 5a. Нормализация запроса в Dart (без пересборки БД)

Портировать нормализацию в Dart и искать по обеим колонкам. Создать
`lib/data/arabic_normalizer.dart`:

```dart
/// Нормализация арабского текста для поиска.
///
/// Логика повторяет `normalize_arabic` из `tool/build_quran_db.py`.
/// При изменении правил обязательно менять обе реализации и пересобирать
/// поисковый индекс, иначе запрос и индекс разойдутся.
library;

/// Диакритика и коранические знаки, удаляемые при нормализации.
final RegExp _arabicMarks = RegExp(
  r'[\u0610-\u061a\u064b-\u065f\u06d6-\u06ed]',
);

/// Приведение вариантов алифа, хамзы и алифа-максуры к базовой форме.
const Map<String, String> _letterFolding = <String, String>{
  '\u0623': '\u0627', // алиф с хамзой сверху
  '\u0625': '\u0627', // алиф с хамзой снизу
  '\u0622': '\u0627', // алиф с маддой
  '\u0671': '\u0627', // алиф с васлой
  '\u0649': '\u064a', // алиф максура
  '\u0624': '\u0648', // вав с хамзой
  '\u0626': '\u064a', // йа с хамзой
  '\u0640': '', // татвиль
};

/// Нормализация без надстрочного алифа: он удаляется.
/// Соответствует колонке `normalized` в текущем поисковом индексе.
String normalizeArabic(String value) => _normalize(value, daggerAlef: '');

/// Нормализация с надстрочным алифом, приведённым к обычному алифу.
/// Соответствует колонке `normalized_alef`, появляющейся в задаче 5b.
String normalizeArabicWithAlef(String value) =>
    _normalize(value, daggerAlef: '\u0627');

String _normalize(String value, {required String daggerAlef}) {
  final StringBuffer buffer = StringBuffer();
  for (final int rune in value.runes) {
    final String character = String.fromCharCode(rune);
    if (character == '\u0670') {
      buffer.write(daggerAlef);
      continue;
    }
    if (_arabicMarks.hasMatch(character)) {
      continue;
    }
    buffer.write(_letterFolding[character] ?? character);
  }
  return buffer.toString().trim().split(RegExp(r'\s+')).join(' ');
}
```

В `lib/data/quran_repository.dart` заменить `_buildFtsPrefixQuery`:

```dart
String? _buildFtsPrefixQuery(String query) {
  final List<String> tokens = RegExp(r'[\p{L}\p{M}\p{N}]+', unicode: true)
      .allMatches(query)
      .map((RegExpMatch match) => match.group(0)!)
      .toList(growable: false);
  if (tokens.isEmpty) {
    return null;
  }

  final List<String> clauses = <String>[];
  for (final String token in tokens) {
    final String raw = _escapeFtsToken(token);
    final String normalized = _escapeFtsToken(normalizeArabic(token));
    // Исходная форма ищется в колонке text, нормализованная в normalized.
    clauses.add('({text} : $raw* OR {normalized} : $normalized*)');
  }
  return clauses.join(' AND ');
}

String _escapeFtsToken(String token) => '"${token.replaceAll('"', '""')}"';
```

Проверено на реальной БД, поиск по колонке `normalized` нормализованным
запросом:

| Ввод | Было | Стало |
|---|---|---|
| `ٱلرحمن` | 0 | **46** |
| `الرَّحمَـٰن` | 0 | **46** |
| `إبراهيم` | 0 | **1** |
| `أنعمت` | 0 | **7** |
| `Милость` (русский) | работал | **561**, не сломался |
| `Корова` (название суры) | работал | **9**, не сломался |

### Часть 5b. Третья колонка индекса (требует пересборки БД)

Чтобы работало и современное написание, нужна колонка, где U+0670 заменён на
алиф. Read-only БД миграцией не изменить, поэтому ассет придётся пересобрать.

**Предупреждение.** Пересборка требует исходную базу `source.db.gz`, которой в
репозитории нет. `README.md:27` называет вшитый ассет уже готовым. Без исходной
БД задачу 5b выполнить нельзя — сначала найдите или восстановите источник.

В `tool/build_quran_db.py` изменить `normalize_arabic`, добавив параметр, и
дописать колонку в схему FTS:

```python
ARABIC_MARKS = re.compile(r"[\u0610-\u061a\u064b-\u065f\u06d6-\u06ed]")
DAGGER_ALEF = "\u0670"

def normalize_arabic(value: str, *, dagger_alef: str = "") -> str:
    value = unicodedata.normalize("NFKD", value)
    value = value.replace(DAGGER_ALEF, dagger_alef)
    value = ARABIC_MARKS.sub("", value)
    value = value.translate(str.maketrans({
        "أ": "ا", "إ": "ا", "آ": "ا", "ٱ": "ا",
        "ى": "ي", "ؤ": "و", "ئ": "ي", "ـ": "",
    }))
    return " ".join(value.split())
```

В `build_search` добавить `normalized_alef` в объявление FTS5 и заполнять её
через `normalize_arabic(text, dagger_alef="ا")`. В `validate` ожидаемое
количество строк FTS не меняется (18 822), меняется только число колонок.

Замер на прототипе в памяти с тремя колонками:

| Ввод | Найдено аятов |
|---|---|
| `العالمين` (современное) | **61** |
| `العلمين` (как в мусхафе) | **61** |
| `السماوات` | **180** |
| `السموت` | **180** |
| `إبراهيم` | **40** |
| `ٱلرحمن` | **45** |

Оба варианта написания дают одинаковый результат — это и есть цель.

**Тесты для добавления** в новый файл `test/data/arabic_normalizer_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mubeen_quran_pure/data/arabic_normalizer.dart';

void main() {
  group('normalizeArabic', () {
    test('снимает огласовки и коранические знаки', () {
      expect(normalizeArabic('ٱلرَّحْمَـٰنِ'), equals('الرحمن'));
    });

    test('приводит формы хамзы к алифу', () {
      expect(normalizeArabic('إبراهيم'), equals('ابراهيم'));
      expect(normalizeArabic('أَنْعَمْتَ'), equals('انعمت'));
    });

    test('не портит русский текст', () {
      expect(normalizeArabic('Милость'), equals('Милость'));
    });

    test('сжимает пробелы', () {
      expect(normalizeArabic('  الحمد   لله '), equals('الحمد لله'));
    });
  });

  group('normalizeArabicWithAlef', () {
    test('надстрочный алиф становится обычным', () {
      expect(normalizeArabicWithAlef('ٱلْعَـٰلَمِينَ'), equals('العالمين'));
      expect(normalizeArabic('ٱلْعَـٰلَمِينَ'), equals('العلمين'));
    });
  });
}
```

**Проверка**

1. `& $FLUTTER test --no-pub --concurrency=1` — тесты нормализатора зелёные.
2. Вручную в приложении: ввести `ٱلرحمن`, затем `الرحمن` — результаты
   непустые в обоих случаях.
3. Убедиться, что русский поиск и ссылки вида `2:255` не сломались.

---

## [x] 6. Мусхаф-страницы перезапрашивают базу на каждую перерисовку

**Файл:** `lib/screens/reader_screen.dart:483-501`, класс `_MushafPage`

**Проблема**

```dart
class _MushafPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QuranAyah>>(
      future: repository.getAyahsForPage(page),   // <-- строка 497
      ...
```

`Future` создаётся прямо в `build()` у `StatelessWidget`. Цепочка такая:
любое изменение настроек дёргает `notifyListeners()` в `AppController`,
`ListenableBuilder` в `app.dart:22` перестраивает всё дерево, `_MushafPage`
получает новый `Future`, `FutureBuilder` сбрасывается в состояние без данных и
показывает `CircularProgressIndicator`.

Практически это выглядит так: пользователь тянет слайдер размера арабского
шрифта в настройках, а страница мусхафа мигает спиннером десятки раз в секунду,
каждый раз делая запрос к SQLite.

**Решение**

Превратить `_MushafPage` в `StatefulWidget` и кешировать `Future`, обновляя его
только при смене номера страницы:

```dart
class _MushafPage extends StatefulWidget {
  const _MushafPage({
    required this.page,
    required this.controller,
    required this.repository,
  });

  final int page;
  final AppController controller;
  final QuranRepository repository;

  @override
  State<_MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<_MushafPage> {
  late Future<List<QuranAyah>> _ayahs = _load();

  Future<List<QuranAyah>> _load() =>
      widget.repository.getAyahsForPage(widget.page);

  @override
  void didUpdateWidget(covariant _MushafPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Перезапрос только при смене страницы, а не при смене темы или шрифта.
    if (oldWidget.page != widget.page) {
      _ayahs = _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QuranAyah>>(
      future: _ayahs,
      builder: (BuildContext context, AsyncSnapshot<List<QuranAyah>> snapshot) {
        // остальное тело без изменений
      },
    );
  }
}
```

Заодно стоит обработать `snapshot.hasError`: сейчас при ошибке чтения страницы
`FutureBuilder` навсегда останется со спиннером, потому что проверяется только
`!snapshot.hasData` (строка 499).

**Проверка**

1. `& $FLUTTER analyze --no-pub` — чисто.
2. Вручную: открыть режим страниц, зайти в настройки, подвигать слайдер шрифта,
   вернуться — страница не мигает, размер шрифта применился.

---

## [x] 7. Переход по номеру страницы сбрасывает суру на первую

**Файл:** `lib/screens/navigation_screen.dart:77-87`

**Проблема**

```dart
_NumberGrid(
  count: 604,
  prefix: 'Страница',
  compact: true,
  onTap: (int value) async {
    widget.onOpenLocation(
      ReaderLocation(surahId: 1, ayahNumber: 1, page: value),
      //             ^^^^^^^^^^^^^^^^^^^^^^^^ жёсткие единицы
      mode: ReaderMode.mushaf,
    );
  },
),
```

`surahId: 1, ayahNumber: 1` подставлены заглушкой. Пока пользователь листает
страницы, это незаметно. Но `MushafReader` вызывает `onLocationChanged`
(`reader_screen.dart:120-123`), а `ReaderScreen` хранит `_surahId` и
`_targetAyah` для переключения режимов. При переходе с открытой страницы в
вертикальное чтение пользователь оказывается в суре аль-Фатиха, а не там, где
читал.

Кроме того, вызов `controller.saveLocation` (`reader_screen.dart:429`) сохранит
в постоянную память связку «страница 400, сура 1, аят 1», что бессмысленно.

В репозитории есть `getPageForSurah` (`quran_repository.dart:129`), но обратной
функции нет.

**Решение**

Шаг 1. Добавить в `lib/data/quran_repository.dart` метод, возвращающий первый
аят страницы. Логика уже есть в `_getFirstLocation`, нужна только обёртка:

```dart
Future<ReaderLocation> getFirstLocationForPage(int page) async {
  final Database database = _db;
  _requirePositive(page, 'page');
  return _getFirstLocation(database: database, column: 'page', value: page);
}
```

Шаг 2. В `lib/screens/navigation_screen.dart` использовать её:

```dart
onTap: (int value) async {
  final ReaderLocation location =
      await widget.repository.getFirstLocationForPage(value);
  widget.onOpenLocation(location, mode: ReaderMode.mushaf);
},
```

`_getFirstLocation` уже сортирует по `surah_id, number_in_surah, id` и
возвращает колонку `page`, так что `ReaderLocation` будет заполнен полностью и
согласованно.

**Тест для добавления** в `test/data/quran_repository_test.dart`, в
существующую группу негативных проверок:

```dart
expect(() => repository.getFirstLocationForPage(1), throwsStateError);
expect(
  () => repository.getFirstLocationForPage(0),
  throwsA(isA<StateError>()),
);
```

Второй кейс: `_db` бросает `StateError` раньше, чем `_requirePositive`
успевает бросить `RangeError`, потому что геттер вызывается первой строкой.
Это соответствует поведению остальных методов.

**Проверка**

1. `& $FLUTTER test --no-pub --concurrency=1`.
2. Вручную: навигация → «Страницы» → страница 300 → переключить режим на
   вертикальное чтение. Должна открыться сура, реально находящаяся на 300-й
   странице, а не аль-Фатиха.

---

# Этап 3. Установка базы, старт, память

Задачи 8–11 удобно делать одним рефакторингом `QuranRepository`, потому что все
четыре касаются метода `_openDatabase` и его окружения.

## [x] 8. Пиковое потребление памяти при первой установке около 90 МБ

**Файл:** `lib/data/quran_repository.dart:396-430` (`_installDatabase`),
551-555 (`_decodeGzip`)

**Проблема**

```dart
Uint8List _decodeGzip(Uint8List compressedBytes) {
  return Uint8List.fromList(
    GZipDecoder().decodeBytes(compressedBytes, verify: true),
  );
}
```

`decodeBytes` возвращает `List<int>` — распакованная база это 44,9 МБ
(измерено). `Uint8List.fromList` делает полную копию, то есть ещё 44,9 МБ.
Плюс 11 МБ сжатого ассета, загруженного через `rootBundle.load`. Всё живёт в
памяти одновременно, и всё это происходит **до** `runApp` (см. `main.dart:20`).

Итого пик около 90 МБ на старте, до появления первого кадра. На бюджетных
устройствах это риск падения по нехватке памяти ровно в момент первого запуска,
то есть при первом знакомстве пользователя с приложением.

**Решение**

Писать распакованные данные в файл потоком, не собирая в памяти. Заменить
`_installDatabase` и `_decodeGzip`:

```dart
Future<void> _installDatabase(File destination) async {
  final File temporary = File('${destination.path}.tmp');
  if (await temporary.exists()) {
    await temporary.delete();
  }

  try {
    final ByteData assetData = await rootBundle.load(_databaseAsset);
    final Uint8List compressedBytes = assetData.buffer.asUint8List(
      assetData.offsetInBytes,
      assetData.lengthInBytes,
    );

    final IOSink sink = temporary.openWrite();
    try {
      // Поток из GZipCodec отдаёт данные чанками, поэтому распакованная база
      // целиком в памяти не оказывается.
      await sink.addStream(
        Stream<List<int>>.value(compressedBytes).transform(gzip.decoder),
      );
      await sink.flush();
    } finally {
      await sink.close();
    }

    if (!await _hasSqliteHeader(temporary)) {
      throw const FormatException(
        'The decompressed Quran asset is not a SQLite database.',
      );
    }

    if (await destination.exists()) {
      await destination.delete();
    }
    await temporary.rename(destination.path);
  } finally {
    if (await temporary.exists()) {
      await temporary.delete();
    }
  }
}
```

Что меняется:

- `gzip.decoder` из `dart:io` вместо `GZipDecoder` из пакета `archive` — работает
  потоком;
- проверка заголовка SQLite переносится с байтов в памяти на уже записанный
  файл, для чего используется существующая функция `_hasSqliteHeader`;
- функции `_decodeGzip` и `_bytesHaveSqliteHeader` (если больше не нужна)
  удаляются вместе с вызовом `compute`.

После удаления `_decodeGzip` проверьте, нужен ли пакет `archive` где-то ещё.
Если нет — уберите его из `pubspec.yaml:12`. Это единственное место его
использования во всём проекте.

Пик памяти после правки: около 11 МБ сжатого ассета плюс буфер потока, вместо
90 МБ.

**Проверка**

1. `& $FLUTTER analyze --no-pub`.
2. Удалить приложение с устройства, установить заново, убедиться, что первый
   запуск проходит и содержимое читается.
3. Если доступен DevTools, посмотреть график памяти на первом запуске.

---

## [x] 9. Приложение блокирует старт на распаковке и не даёт повторить попытку

**Файлы:** `lib/main.dart:8-33`, `lib/app.dart:29-44`, `lib/app.dart:46-86`

**Проблема первая — блокирующий старт.**

```dart
final AppController controller = AppController();
final QuranRepository repository = QuranRepository();
Object? startupError;
try {
  await Future.wait(<Future<void>>[
    controller.initialize(),
    repository.open(),
  ]);
} on Object catch (error) {
  startupError = error;
}

runApp(...);
```

`runApp` вызывается только после того, как 45 МБ распакованы и записаны на
диск. Пользователь при первом запуске видит нативный splash несколько секунд без
какой-либо индикации прогресса. Выглядит как зависание.

**Проблема вторая — тупик при ошибке.**

`StartupErrorScreen` (`app.dart:46`) показывает текст ошибки и предложение
перезапустить приложение. Кнопки повтора нет. Если ошибка была временной
(например, не хватило места на диске, пользователь его освободил), выйти из
этого состояния можно только переустановкой приложения.

**Проблема третья — утечка внутренних путей.**

`app.dart:75` выводит `error.toString()` прямо в интерфейс. Для файловых
исключений это включает полный путь в песочнице приложения. Пользователю это
ничего не даёт, а лишние детали внутреннего устройства показывать не стоит.

**Решение**

Шаг 1. Отдать управление стартом в UI. Упростить `lib/main.dart`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    MubeenQuranApp(
      controller: AppController(),
      repository: QuranRepository(),
    ),
  );
}
```

Шаг 2. В `lib/app.dart` сделать `MubeenQuranApp` состоятельным: он сам
запускает инициализацию, показывает заставку с индикатором, а при ошибке — экран
с кнопкой «Повторить», которая перезапускает `Future`.

Набросок:

```dart
class MubeenQuranApp extends StatefulWidget {
  const MubeenQuranApp({
    super.key,
    required this.controller,
    required this.repository,
  });

  final AppController controller;
  final QuranRepository repository;

  @override
  State<MubeenQuranApp> createState() => _MubeenQuranAppState();
}

class _MubeenQuranAppState extends State<MubeenQuranApp> {
  late Future<void> _startup = _start();

  Future<void> _start() => Future.wait<void>(<Future<void>>[
        widget.controller.initialize(),
        widget.repository.open(),
      ]);

  void _retry() => setState(() => _startup = _start());

  @override
  void dispose() {
    widget.repository.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          title: 'Mubeen Quran Pure',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(widget.controller.themeStyle),
          home: FutureBuilder<void>(
            future: _startup,
            builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
              if (snapshot.hasError) {
                return StartupErrorScreen(
                  error: snapshot.error!,
                  onRetry: _retry,
                );
              }
              if (snapshot.connectionState != ConnectionState.done) {
                return const StartupProgressScreen();
              }
              return QuranHomeScreen(
                controller: widget.controller,
                repository: widget.repository,
              );
            },
          ),
        );
      },
    );
  }
}
```

Шаг 3. Добавить `StartupProgressScreen` — простую заставку в стиле приложения с
`CircularProgressIndicator` и подписью вида «Подготовка Корана». Первый запуск
занимает секунды, поэтому текст должен объяснять, что происходит однократная
подготовка.

Шаг 4. В `StartupErrorScreen` добавить обязательный параметр `onRetry` и кнопку.
Технические детали ошибки скрыть за раскрывающимся блоком (`ExpansionTile`) с
заголовком «Подробности», чтобы они были доступны для диагностики, но не лезли в
глаза и не пугали.

**Внимание.** Правка задевает существующий тест `test/widget_test.dart`, который
конструирует `MubeenQuranApp` с параметром `startupError`. После рефакторинга
этого параметра не будет. Тест нужно переписать: либо тестировать
`StartupErrorScreen` напрямую как отдельный виджет, либо подменять репозиторий
на падающий. Первый вариант проще и честнее по смыслу.

Заодно этот рефакторинг закрывает задачу 25: `repository.close()` начинает
вызываться в `dispose`.

**Проверка**

1. `& $FLUTTER test --no-pub --concurrency=1` — переписанный тест зелёный.
2. Удалить приложение, установить, запустить: видна заставка с индикатором, а не
   застывший splash.
3. Проверить экран ошибки: например, временно указать несуществующее имя ассета
   в `_databaseAsset`, убедиться, что кнопка «Повторить» появляется и работает,
   затем вернуть значение.

---

## [x] 10. Сорок пять мегабайт уходят в резервную копию iCloud

**Файл:** `lib/data/quran_repository.dart:371-375`

**Проблема**

```dart
final Directory supportDirectory = await getApplicationSupportDirectory();
```

На iOS это `Library/Application Support`, который по умолчанию попадает в
резервную копию iCloud и iTunes. В бэкап пользователя уезжают 45 МБ данных,
которые в любой момент восстанавливаются из ассета приложения. Это расход
чужой квоты iCloud и замедление резервного копирования без всякой пользы.

Apple прямо рекомендует исключать из бэкапа воспроизводимые данные.

**Решение**

Вариант A, предпочтительный: пометить файл флагом исключения из бэкапа. Dart
такого API не имеет, потребуется platform channel в
`ios/Runner/AppDelegate.swift` с вызовом
`URL.setResourceValue(true, forKey: .isExcludedFromBackupKey)`. Способ надёжный:
файл остаётся в Application Support, но не бэкапится.

Вариант B, простой: класть базу в каталог кешей.

```dart
Future<Directory> _databaseDirectory() async {
  if (Platform.isIOS || Platform.isMacOS) {
    // Библиотечные кеши не попадают в резервные копии, а база в любой момент
    // восстанавливается из ассета приложения.
    return getApplicationCacheDirectory();
  }
  return getApplicationSupportDirectory();
}
```

`getApplicationCacheDirectory` есть в `path_provider` 2.1.6, который уже
подключён. Осторожно: система вправе очистить кеш при нехватке места. Для
приложения это не страшно, потому что `_openDatabase` проверяет заголовок
SQLite (`quran_repository.dart:378`) и переустанавливает базу при необходимости.
Но пользователь на медленном устройстве может неожиданно получить повторную
распаковку. С учётом задачи 9 у него хотя бы будет видна заставка с прогрессом.

Рекомендация: начать с варианта B как быстрого и безопасного, а вариант A
сделать позже, если повторные распаковки окажутся заметны на практике.

Настройки и закладки лежат в `SharedPreferences` и в бэкап попадают — так и
должно быть, это пользовательские данные.

**Проверка**

Собрать под iOS, установить, проверить размер приложения в разделе бэкапа
настроек устройства: 45 МБ базы не должны в нём фигурировать.

---

## [x] 11. Версия контента нигде не проверяется

**Файл:** `lib/data/quran_repository.dart:13`, 370-394

**Проблема**

```dart
const String _databaseFileName = 'quran_pure_v2.db';
```

Версия зашита в имя файла. В самой базе есть и `PRAGMA user_version = 2`, и
таблица `content_metadata` со `schema_version = 2` (проверено на ассете), но
приложение их никогда не читает — `_openDatabase` выполняет только
`PRAGMA schema_version` (строка 388), и то лишь как проверку живости соединения.

Последствия:

- если контент обновится без переименования файла, пользователи с уже
  установленной базой останутся на старой версии навсегда, потому что
  `_hasSqliteHeader` вернёт `true` и переустановки не будет;
- старые файлы `quran_pure_v1.db` не удаляются и занимают место;
- рассинхронизация между кодом и схемой обнаружится не сразу, а случайной
  ошибкой SQL в рантайме.

**Решение**

Добавить константу ожидаемой версии и проверять её при открытии:

```dart
/// Версия схемы контента, с которой умеет работать этот код.
/// Значение обязано совпадать с `PRAGMA user_version` в собранном ассете
/// (см. `tool/build_quran_db.py`, строка с `PRAGMA user_version`).
const int _expectedContentVersion = 2;

Future<void> _openDatabase() async {
  final Directory directory = await _databaseDirectory();
  final String databasePath = path.join(directory.path, _databaseFileName);
  final File databaseFile = File(databasePath);

  if (!await _hasSqliteHeader(databaseFile)) {
    await _installDatabase(databaseFile);
  }

  Database database = await _open(databasePath);
  if (await _contentVersion(database) != _expectedContentVersion) {
    // Установленная база устарела: переустанавливаем из ассета.
    await database.close();
    await _installDatabase(databaseFile);
    database = await _open(databasePath);
    if (await _contentVersion(database) != _expectedContentVersion) {
      await database.close();
      throw StateError(
        'Quran content version mismatch: expected $_expectedContentVersion.',
      );
    }
  }
  _database = database;
}

Future<int> _contentVersion(Database database) async {
  final List<Map<String, Object?>> rows =
      await database.rawQuery('PRAGMA user_version');
  final Object? value = rows.single.values.first;
  return value is int ? value : -1;
}
```

Метод `_open` — это вынесенный из старого `_openDatabase` вызов `openDatabase`
вместе с проверочным `PRAGMA schema_version`.

Дополнительно стоит подчистить устаревшие файлы: при успешной установке пройти
по каталогу и удалить `quran_pure_v*.db`, кроме актуального.

**Тест.** Проверка версии требует настоящей базы, поэтому её удобно закрыть в
рамках задачи 16 (интеграционные тесты репозитория), а не отдельно.

**Проверка:** `& $FLUTTER analyze --no-pub`, затем ручной запуск на устройстве
с удалённым приложением.

<!--PART5-->


