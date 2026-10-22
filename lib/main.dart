import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:fl_chart/fl_chart.dart';
import 'widgets/animated_cat.dart';
import 'services/notification_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'export/export_service.dart';
import 'tests/tests_feature.dart';
import 'tests/tests_catalog.dart';
import 'tests/tests_models.dart';
import 'tests/tests_storage.dart';
import 'tests/custom_tests_models.dart';

/// Папка для фото заметок в [getApplicationDocumentsDirectory] — не сбрасывается при очистке кэша Android.
const String _kDiaryPhotosSubdir = 'emotion_diary_photos';

Future<Directory> _diaryPhotosDirectory() async {
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(base.path, _kDiaryPhotosSubdir));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

/// Копирует файл из временного пути после [ImagePicker] в постоянное хранилище приложения.
Future<File> _persistPickedPhoto(XFile xFile) async {
  final photosDir = await _diaryPhotosDirectory();
  final srcPath = xFile.path;
  final ext = p.extension(srcPath);
  final safeExt = (ext.isNotEmpty && ext.length <= 8) ? ext : '.jpg';
  final name =
      'img_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(0x7fffffff)}$safeExt';
  final dest = File(p.join(photosDir.path, name));
  await File(srcPath).copy(dest.path);
  return dest;
}

Future<void> _deletePersistedDiaryPhotoIfOwned(File file) async {
  try {
    final base = await getApplicationDocumentsDirectory();
    final root = p.normalize(p.join(base.path, _kDiaryPhotosSubdir));
    if (!p.isWithin(root, p.normalize(file.path))) return;
    if (await file.exists()) await file.delete();
  } catch (_) {}
}

class EmotionSources {
  // Stable keys for storage and logic (do not translate).
  static const String friends = 'friends';
  static const String communication = 'communication';
  static const String hobby = 'hobby';
  static const String work = 'work';
  static const String nature = 'nature';
  static const String rest = 'rest';
  static const String family = 'family';
  static const String romanticInterest = 'romantic_interest';
  static const String other = 'other';

  static const List<String> keys = <String>[
    friends,
    communication,
    hobby,
    work,
    nature,
    rest,
    family,
    romanticInterest,
    other,
  ];

  // Backward compatibility with old saved Russian values.
  static const Map<String, String> _legacyRuToKey = {
    'Друзья': friends,
    'Общение': communication,
    'Хобби': hobby,
    'Работа': work,
    'Природа': nature,
    'Отдых': rest,
    'Семья': family,
    'Любовный интерес': romanticInterest,
    'Другое': other,
  };

  static const Map<String, Color> colorsByKey = {
    friends: Color.fromARGB(255, 121, 17, 52),
    communication: Colors.blue,
    hobby: Colors.green,
    work: Colors.orange,
    nature: Color.fromARGB(255, 7, 84, 48),
    rest: Colors.purple,
    family: Colors.red,
    romanticInterest: Color(0xFF009688),
    other: Color.fromARGB(255, 19, 1, 96),
  };

  static String normalizeKey(String stored) {
    if (colorsByKey.containsKey(stored)) return stored;
    return _legacyRuToKey[stored] ?? other;
  }

  static String label(BuildContext context, String storedOrKey) {
    final l10n = AppLocalizations.of(context);
    switch (normalizeKey(storedOrKey)) {
      case friends:
        return l10n.sourceFriends;
      case communication:
        return l10n.sourceCommunication;
      case hobby:
        return l10n.sourceHobby;
      case work:
        return l10n.sourceWork;
      case nature:
        return l10n.sourceNature;
      case rest:
        return l10n.sourceRest;
      case family:
        return l10n.sourceFamily;
      case romanticInterest:
        return l10n.sourceRomanticInterest;
      default:
        return l10n.sourceOther;
    }
  }
}

enum EmotionDiaryKind { positive, negative }

extension EmotionDiaryKindX on EmotionDiaryKind {
  String get storageValue => switch (this) {
    EmotionDiaryKind.positive => 'positive',
    EmotionDiaryKind.negative => 'negative',
  };

  static EmotionDiaryKind fromStorage(String? value) {
    return value == 'negative' ? EmotionDiaryKind.negative : EmotionDiaryKind.positive;
  }
}

// Модель для записи
class EmotionEntry {
  final DateTime date;
  final EmotionDiaryKind kind;
  final String source;
  final String note;
  /// Время фактического создания записи (для отображения в дневнике).
  /// Не влияет на выбранную дату (calendar day) в поле [date].
  final DateTime? createdAt;
  final List<String>? imagePaths;
  final String? emotion;
  final int? emotionColorValue;
  final int? sourceColorValue;

  EmotionEntry({
    required this.date,
    required this.source,
    required this.note,
    this.kind = EmotionDiaryKind.positive,
    this.createdAt,
    this.imagePaths,
    this.emotion,
    this.emotionColorValue,
    this.sourceColorValue,
  });

  bool get isNegative => kind == EmotionDiaryKind.negative;
  bool get isPositive => !isNegative;

  String get statisticKey {
    if (isNegative) {
      final label = emotion?.trim();
      if (label != null && label.isNotEmpty) return label;
      return source.trim();
    }
    final pos = emotion?.trim();
    if (pos != null && pos.isNotEmpty) return pos;
    return EmotionSources.normalizeKey(source);
  }

  String primaryLabel(BuildContext context) {
    if (isNegative) {
      final label = emotion?.trim();
      return (label == null || label.isEmpty) ? source : label;
    }
    final pos = emotion?.trim();
    if (pos != null && pos.isNotEmpty) return pos;
    return EmotionSources.label(context, source);
  }

  String? secondaryLabel(BuildContext context) {
    if (isNegative) {
      final label = source.trim();
      return label.isEmpty ? null : label;
    }
    return null;
  }

  Color primaryColor(BuildContext context) {
    if (isNegative) {
      return Color(emotionColorValue ?? Colors.red.value);
    }
    if (emotionColorValue != null) {
      return Color(emotionColorValue!);
    }
    return EmotionSources.colorsByKey[EmotionSources.normalizeKey(source)] ??
        Theme.of(context).colorScheme.primary;
  }

  Color secondaryColor(BuildContext context) {
    if (isNegative) {
      if (source.trim().isEmpty) {
        return primaryColor(context);
      }
      return Color(sourceColorValue ?? Colors.orange.value);
    }
    return primaryColor(context);
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'kind': kind.storageValue,
    'source': source,
    'note': note,
    'createdAt': createdAt?.toIso8601String(),
    'imagePaths': imagePaths,
    'emotion': emotion,
    'emotionColorValue': emotionColorValue,
    'sourceColorValue': sourceColorValue,
  };

  factory EmotionEntry.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('date') || !json.containsKey('source') || !json.containsKey('note')) {
      throw const FormatException('Invalid entry format');
    }

    List<String>? paths;
    if (json['imagePaths'] != null) {
      paths = List<String>.from(json['imagePaths']);
    } else if (json['imagePath'] != null) {
      // Для обратной совместимости со старым форматом
      paths = [json['imagePath'].toString()];
    }

    final kind = EmotionDiaryKindX.fromStorage(json['kind']?.toString());
    final rawSource = json['source'].toString();
    final emotionStr = json['emotion']?.toString().trim();
    final hasCatalogPositive =
        kind == EmotionDiaryKind.positive && emotionStr != null && emotionStr.isNotEmpty;
    DateTime? createdAt;
    final rawCreated = json['createdAt']?.toString().trim();
    if (rawCreated != null && rawCreated.isNotEmpty) {
      try {
        createdAt = DateTime.parse(rawCreated);
      } catch (_) {
        createdAt = null;
      }
    }
    return EmotionEntry(
      date: DateTime.parse(json['date']),
      kind: kind,
      source: kind == EmotionDiaryKind.positive
          ? (hasCatalogPositive ? '' : EmotionSources.normalizeKey(rawSource))
          : rawSource,
      note: json['note'].toString(),
      createdAt: createdAt,
      imagePaths: paths,
      emotion: json['emotion']?.toString(),
      emotionColorValue: json['emotionColorValue'] as int?,
      sourceColorValue: json['sourceColorValue'] as int?,
    );
  }

  EmotionEntry copyWith({
    DateTime? date,
    EmotionDiaryKind? kind,
    String? source,
    String? note,
    DateTime? createdAt,
    List<String>? imagePaths,
    String? emotion,
    int? emotionColorValue,
    int? sourceColorValue,
  }) {
    return EmotionEntry(
      date: date ?? this.date,
      kind: kind ?? this.kind,
      source: source ?? this.source,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      imagePaths: imagePaths ?? this.imagePaths,
      emotion: emotion ?? this.emotion,
      emotionColorValue: emotionColorValue ?? this.emotionColorValue,
      sourceColorValue: sourceColorValue ?? this.sourceColorValue,
    );
  }

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is EmotionEntry &&
    runtimeType == other.runtimeType &&
    date == other.date &&
    kind == other.kind &&
    source == other.source &&
    note == other.note &&
    createdAt == other.createdAt &&
    emotion == other.emotion &&
    emotionColorValue == other.emotionColorValue &&
    sourceColorValue == other.sourceColorValue &&
    listEquals(imagePaths, other.imagePaths);

  @override
  int get hashCode =>
    date.hashCode ^
    kind.hashCode ^
    source.hashCode ^
    note.hashCode ^
    (createdAt?.hashCode ?? 0) ^
    (emotion?.hashCode ?? 0) ^
    (emotionColorValue ?? 0) ^
    (sourceColorValue ?? 0) ^
    (imagePaths?.hashCode ?? 0);
}

class ThemeProvider {
  static const String _themeKey = 'selected_theme';
  static final StreamController<String> themeStreamController = StreamController<String>.broadcast();
  static final StreamController<String> diaryTitleStreamController = StreamController<String>.broadcast();
  
  static final Map<String, ThemeData> themes = {
    'Фиолетовый': ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
      primarySwatch: Colors.deepPurple,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
    ),
    'Пастельный фиолетовый': ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFB39DDB), brightness: Brightness.light),
      primarySwatch: Colors.deepPurple,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFB39DDB),
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFB39DDB),
          foregroundColor: Colors.white,
        ),
      ),
    ),
    'Синий': ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    ),
    'Пастельный синий': ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF90CAF9), brightness: Brightness.light),
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF90CAF9),
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF90CAF9),
          foregroundColor: Colors.white,
        ),
      ),
    ),
    'Зеленый': ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.light),
      primarySwatch: Colors.green,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    ),
    'Пастельный зеленый': ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFA5D6A7), brightness: Brightness.light),
      primarySwatch: Colors.green,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFA5D6A7),
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFA5D6A7),
          foregroundColor: Colors.white,
        ),
      ),
    ),
    'Красный': ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.red, brightness: Brightness.light),
      primarySwatch: Colors.red,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
      ),
    ),
    'Пастельный красный': ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFEF9A9A), brightness: Brightness.light),
      primarySwatch: Colors.red,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFEF9A9A),
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFEF9A9A),
          foregroundColor: Colors.white,
        ),
      ),
    ),
    'Оранжевый': ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange, brightness: Brightness.light),
      primarySwatch: Colors.orange,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
      ),
    ),
    'Пастельный оранжевый': ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFFFCC80), brightness: Brightness.light),
      primarySwatch: Colors.orange,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFCC80),
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFFFCC80),
          foregroundColor: Colors.white,
        ),
      ),
    ),
    'Бирюзовый': ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.light),
      primarySwatch: Colors.teal,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
    ),
    'Пастельный бирюзовый': ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF80CBC4), brightness: Brightness.light),
      primarySwatch: Colors.teal,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF80CBC4),
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF80CBC4),
          foregroundColor: Colors.white,
        ),
      ),
    ),
    'Темная': ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
    ),
  };

  static final Map<String, Color> themeColors = {
    'Фиолетовый': Colors.deepPurple,
    'Пастельный фиолетовый': Color(0xFFB39DDB),
    'Синий': Colors.blue,
    'Пастельный синий': Color(0xFF90CAF9),
    'Зеленый': Colors.green,
    'Пастельный зеленый': Color(0xFFA5D6A7),
    'Красный': Colors.red,
    'Пастельный красный': Color(0xFFEF9A9A),
    'Оранжевый': Colors.orange,
    'Пастельный оранжевый': Color(0xFFFFCC80),
    'Бирюзовый': Colors.teal,
    'Пастельный бирюзовый': Color(0xFF80CBC4),
    'Темная': Color(0xFF121212),
  };

  /// Акцент для навигации, ползунков и т.п. = [ColorScheme.primary] активной темы.
  static Color accentForScheme(ColorScheme scheme) => scheme.primary;

  /// Подсветка пунктов выпадающих меню (справка и др.) и интерактивные оттенки — от активной темы, не фиксированный фиолетовый.
  static ThemeData withPopupAndMenuTheming(ThemeData base) {
    final ColorScheme cs = base.colorScheme;
    final Color accent = cs.primary;
    return base.copyWith(
      focusColor: accent.withOpacity(0.12),
      hoverColor: accent.withOpacity(0.10),
      highlightColor: accent.withOpacity(0.08),
      splashColor: accent.withOpacity(0.14),
      popupMenuTheme: PopupMenuThemeData(
        color: cs.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shadowColor: cs.shadow,
        elevation: 3,
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return cs.onSurface.withOpacity(0.38);
            }
            return cs.onSurface;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return accent.withOpacity(0.18);
            }
            if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
              return accent.withOpacity(0.10);
            }
            return null;
          }),
        ),
      ),
    );
  }

  static String displayName(BuildContext context, String themeKey) {
    final l10n = AppLocalizations.of(context);
    switch (themeKey) {
      case 'Фиолетовый':
        return l10n.themePurple;
      case 'Пастельный фиолетовый':
        return l10n.themePurplePastel;
      case 'Синий':
        return l10n.themeBlue;
      case 'Пастельный синий':
        return l10n.themeBluePastel;
      case 'Зеленый':
        return l10n.themeGreen;
      case 'Пастельный зеленый':
        return l10n.themeGreenPastel;
      case 'Красный':
        return l10n.themeRed;
      case 'Пастельный красный':
        return l10n.themeRedPastel;
      case 'Оранжевый':
        return l10n.themeOrange;
      case 'Пастельный оранжевый':
        return l10n.themeOrangePastel;
      case 'Бирюзовый':
        return l10n.themeTeal;
      case 'Пастельный бирюзовый':
        return l10n.themeTealPastel;
      case 'Темная':
        return l10n.themeDark;
      default:
        return themeKey;
    }
  }
  
  static Future<void> saveTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeName);
    themeStreamController.add(themeName); // Отправляем новую тему в поток
  }

  /// До первого выбора в настройках: светлая система → «Фиолетовый», тёмная → «Темная».
  static String themeNameMatchingPlatform() {
    return PlatformDispatcher.instance.platformBrightness == Brightness.dark
        ? 'Темная'
        : 'Фиолетовый';
  }

  static Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeKey);
    if (saved != null && saved.isNotEmpty) {
      return saved;
    }
    final initial = themeNameMatchingPlatform();
    await prefs.setString(_themeKey, initial);
    return initial;
  }
}

enum WelcomeImagesMode { landscapes, cats }

class WelcomeImagesSettings {
  static const String _prefsKey = 'welcome_images_modes_v2';
  static const String _legacyPrefsKey = 'welcome_images_mode';
  static const String _catsPrefix = 'assets/images/';
  static const String _landscapesPrefix = 'assets/fon/';
  static final StreamController<Set<WelcomeImagesMode>> streamController =
      StreamController<Set<WelcomeImagesMode>>.broadcast();

  static const Set<String> _excludedFromCats = {
    'assets/images/app_icon.png',
    'assets/images/app_icon_foreground.png',
    'assets/images/splash.png',
  };

  static bool _isRasterImageKey(String key) {
    final k = key.toLowerCase();
    return k.endsWith('.png') ||
        k.endsWith('.jpg') ||
        k.endsWith('.jpeg') ||
        k.endsWith('.webp') ||
        k.endsWith('.gif');
  }

  static Future<List<String>> _listFromManifest(String folderPrefix) async {
    final manifestRaw = await rootBundle.loadString('AssetManifest.json');
    final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
    return manifest.keys
        .where((k) => k.startsWith(folderPrefix))
        .where(_isRasterImageKey)
        .where((k) => folderPrefix != _catsPrefix || !_excludedFromCats.contains(k))
        .toList()
      ..sort();
  }

  static Future<List<String>> assetPoolForSelection(Set<WelcomeImagesMode> modes) async {
    final selected = modes.isEmpty ? {WelcomeImagesMode.landscapes} : modes;
    final out = <String>[];
    if (selected.contains(WelcomeImagesMode.landscapes)) {
      out.addAll(await _listFromManifest(_landscapesPrefix));
    }
    if (selected.contains(WelcomeImagesMode.cats)) {
      out.addAll(await _listFromManifest(_catsPrefix));
    }
    return out.toSet().toList()..sort();
  }

  static Future<Set<WelcomeImagesMode>> getModes() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey);
    if (list != null && list.isNotEmpty) {
      final parsed = <WelcomeImagesMode>{};
      for (final raw in list) {
        switch (raw) {
          case 'landscapes':
            parsed.add(WelcomeImagesMode.landscapes);
          case 'cats':
            parsed.add(WelcomeImagesMode.cats);
        }
      }
      if (parsed.isNotEmpty) return parsed;
    }
    // Backward compatibility with old single-value setting.
    final legacy = prefs.getString(_legacyPrefsKey);
    return switch (legacy) {
      'cats' => {WelcomeImagesMode.cats},
      'landscapes' => {WelcomeImagesMode.landscapes},
      _ => {WelcomeImagesMode.landscapes},
    };
  }

  static Future<void> saveModes(Set<WelcomeImagesMode> modes) async {
    final safe = modes.isEmpty ? {WelcomeImagesMode.landscapes} : modes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, safe.map((e) => e.name).toList());
    await prefs.remove(_legacyPrefsKey);
    streamController.add(Set<WelcomeImagesMode>.from(safe));
  }
}

// Провайдер для хранения записей
class EmotionProvider {
  static const String _entriesKey = 'emotion_entries';
  
  static Future<void> addEntry(EmotionEntry entry) async {
    final entries = await getEntries();
    entries.add(entry);
    await _saveEntries(entries);
  }

  static Future<void> deleteEntry(EmotionEntry entry) async {
    final entries = await getEntries();
    entries.removeWhere((e) => 
      e.date == entry.date && 
      e.kind == entry.kind &&
      e.source == entry.source && 
      e.note == entry.note && 
      e.createdAt == entry.createdAt &&
      e.emotion == entry.emotion &&
      e.emotionColorValue == entry.emotionColorValue &&
      e.sourceColorValue == entry.sourceColorValue &&
      listEquals(e.imagePaths, entry.imagePaths)
    );
    await _saveEntries(entries);
  }

  static Future<List<EmotionEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final String? entriesJson = prefs.getString(_entriesKey);
    if (entriesJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(entriesJson);
    return decoded.map((item) => EmotionEntry.fromJson(item)).toList();
  }

  static Future<void> _saveEntries(List<EmotionEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_entriesKey, entriesJson);
  }

  static Future<Map<String, int>> getStatistics(StatsPeriod period) async {
    final entries = await getEntries();
    final now = DateTime.now();
    final filteredEntries = entries.where((entry) {
      switch (period) {
        case StatsPeriod.week:
          return entry.date.isAfter(now.subtract(const Duration(days: 7)));
        case StatsPeriod.month:
          return entry.date.isAfter(now.subtract(const Duration(days: 30)));
        default:
          return true;
      }
    }).toList();

    final positiveEntries = filteredEntries.where((e) => e.isPositive).toList();
    final Map<String, int> stats = {};
    for (var sourceKey in EmotionSources.keys) {
      stats[sourceKey] = positiveEntries.where((e) => EmotionSources.normalizeKey(e.source) == sourceKey).length;
    }
    return stats;
  }

  static Future<List<EmotionEntry>> getEntriesForPeriod(
    StatsPeriod period, {
    Set<EmotionDiaryKind>? kinds,
  }) async {
    final entries = await getEntries();
    final now = DateTime.now();
    return entries.where((entry) {
      final inPeriod = switch (period) {
        StatsPeriod.week => entry.date.isAfter(now.subtract(const Duration(days: 7))),
        StatsPeriod.month => entry.date.isAfter(now.subtract(const Duration(days: 30))),
        StatsPeriod.allTime => true,
      };
      final kindOk = kinds == null || kinds.contains(entry.kind);
      return inPeriod && kindOk;
    }).toList();
  }

  static Future<String?> getDominantEmotionForDate(DateTime date) async {
    final entries = await getEntries();
    final dayEntries = entries.where((entry) => 
      entry.isPositive &&
      entry.date.year == date.year &&
      entry.date.month == date.month &&
      entry.date.day == date.day
    ).toList();

    if (dayEntries.isEmpty) return null;

    final Map<String, int> emotionCounts = {};
    for (var entry in dayEntries) {
      final key = entry.statisticKey;
      emotionCounts[key] = (emotionCounts[key] ?? 0) + 1;
    }

    return emotionCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}

/// Пользовательская негативная «эмоция» для справочника и выпадающего списка.
class CatalogNegativeEmotion {
  final String id;
  final String name;
  final int colorValue;

  const CatalogNegativeEmotion({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
      };

  factory CatalogNegativeEmotion.fromJson(Map<String, dynamic> json) {
    return CatalogNegativeEmotion(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: json['colorValue'] as int,
    );
  }
}

class NegativeEmotionCatalog {
  static const String _prefsKey = 'negative_emotion_catalog_v1';

  static Future<List<CatalogNegativeEmotion>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) {
      await save(<CatalogNegativeEmotion>[]);
      return [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    var list = decoded
        .map((e) => CatalogNegativeEmotion.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    // Убираем старые предустановленные эмоции (id def_*).
    final cleaned = list.where((e) => !e.id.startsWith('def_')).toList();
    if (cleaned.length != list.length) {
      await save(cleaned);
      list = cleaned;
    }
    return list;
  }

  static Future<void> save(List<CatalogNegativeEmotion> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  static Future<void> add(CatalogNegativeEmotion e) async {
    final list = await load();
    list.add(e);
    await save(list);
  }

  static Future<void> removeById(String id) async {
    final list = await load();
    list.removeWhere((x) => x.id == id);
    await save(list);
  }
}

/// Каталог положительных эмоций (название + цвет), отдельное хранилище от негативных.
class CatalogPositiveEmotion {
  final String id;
  final String name;
  final int colorValue;

  const CatalogPositiveEmotion({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
      };

  factory CatalogPositiveEmotion.fromJson(Map<String, dynamic> json) {
    return CatalogPositiveEmotion(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: json['colorValue'] as int,
    );
  }
}

class PositiveEmotionCatalog {
  static const String _prefsKey = 'positive_emotion_catalog_v1';

  static Future<List<CatalogPositiveEmotion>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) {
      await save(<CatalogPositiveEmotion>[]);
      return [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => CatalogPositiveEmotion.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> save(List<CatalogPositiveEmotion> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  static Future<void> add(CatalogPositiveEmotion e) async {
    final list = await load();
    list.add(e);
    await save(list);
  }

  static Future<void> removeById(String id) async {
    final list = await load();
    list.removeWhere((x) => x.id == id);
    await save(list);
  }
}

class MoodEntry {
  final DateTime date;
  final int mood;

  MoodEntry({
    required this.date,
    required this.mood,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'mood': mood,
  };

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      date: DateTime.parse(json['date']),
      mood: json['mood'] as int,
    );
  }
}

class MoodProvider {
  static const String _moodsKey = 'mood_entries';
  
  static Future<void> saveMood(DateTime date, int mood) async {
    final moods = await getMoods();
    
    // Удаляем старое настроение за этот день, если оно есть
    moods.removeWhere((entry) => 
      entry.date.year == date.year &&
      entry.date.month == date.month &&
      entry.date.day == date.day
    );
    
    // Добавляем новое настроение
    moods.add(MoodEntry(date: date, mood: mood));
    await _saveMoods(moods);
  }

  static Future<List<MoodEntry>> getMoods() async {
    final prefs = await SharedPreferences.getInstance();
    final String? moodsJson = prefs.getString(_moodsKey);
    if (moodsJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(moodsJson);
    return decoded.map((item) => MoodEntry.fromJson(item)).toList();
  }

  static Future<MoodEntry?> getMoodForDate(DateTime date) async {
    final moods = await getMoods();
    return moods.firstWhere(
      (entry) => 
        entry.date.year == date.year &&
        entry.date.month == date.month &&
        entry.date.day == date.day,
      orElse: () => MoodEntry(date: date, mood: 0),
    );
  }

  static Future<void> _saveMoods(List<MoodEntry> moods) async {
    final prefs = await SharedPreferences.getInstance();
    final moodsJson = jsonEncode(moods.map((e) => e.toJson()).toList());
    await prefs.setString(_moodsKey, moodsJson);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Init date symbols for the supported locales (to avoid hardcoding RU only).
  await initializeDateFormatting('ru_RU', null);
  await initializeDateFormatting('en_US', null);
  await initializeDateFormatting('fr_FR', null);
  await initializeDateFormatting('de_DE', null);
  await initializeDateFormatting('pt_PT', null);
  await NotificationService.ensureInitialized();
  // Фиксируем ориентацию в портретном режиме
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const MyApp());
}

String calendarLocaleTag(BuildContext context) {
  final code = Localizations.localeOf(context).languageCode;
  switch (code) {
    case 'ru':
      return 'ru_RU';
    case 'en':
      return 'en_US';
    case 'fr':
      return 'fr_FR';
    case 'de':
      return 'de_DE';
    case 'pt':
      return 'pt_PT';
    default:
      return 'en_US';
  }
}

String _exportText(
  BuildContext context, {
  required String ru,
  required String en,
  String? fr,
  String? de,
  String? pt,
}) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'en':
      return en;
    case 'fr':
      return fr ?? en;
    case 'de':
      return de ?? en;
    case 'pt':
      return pt ?? en;
    default:
      return ru;
  }
}

enum AppLanguage {
  system,
  ru,
  en,
  fr,
  de,
  pt,
}

class LocaleProvider {
  static const String _localeKey = 'app_locale'; // system|ru|en

  static Future<AppLanguage> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localeKey) ?? 'system';
    switch (raw) {
      case 'ru':
        return AppLanguage.ru;
      case 'en':
        return AppLanguage.en;
      case 'fr':
        return AppLanguage.fr;
      case 'de':
        return AppLanguage.de;
      case 'pt':
        return AppLanguage.pt;
      default:
        return AppLanguage.system;
    }
  }

  static Future<void> saveLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (language) {
      AppLanguage.system => 'system',
      AppLanguage.ru => 'ru',
      AppLanguage.en => 'en',
      AppLanguage.fr => 'fr',
      AppLanguage.de => 'de',
      AppLanguage.pt => 'pt',
    };
    await prefs.setString(_localeKey, value);
  }
}

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static const supportedLocales = <Locale>[
    Locale('ru'),
    Locale('en'),
    Locale('fr'),
    Locale('de'),
    Locale('pt'),
  ];

  static AppLocalizations of(BuildContext context) {
    final result = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(result != null, 'No AppLocalizations found in context');
    return result!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _strings = {
    'ru': {
      'appTitle': 'КПТ дневник',
      'navAdd': 'Добавить',
      'navHistory': 'Дневник',
      'navTests': 'Тесты',
      'navStats': 'Статистика',
      'navSettings': 'Настройки',
      'welcome': 'Добро пожаловать!',
      'welcomeDialogTitle': 'Добро пожаловать в «Дневник КПТ»!',
      'welcomeDialogBody1': 'Ваш инструмент для осознанной жизни\nЭтот дневник — ваш персональный помощник в изучении внутреннего мира. В отличие от обычных заметок, «Дневник КПТ» предлагает комплексный подход: фиксируйте не только радостные моменты, но и прорабатывайте сложные, негативные эмоции. Интегрированные тесты помогут вам объективно оценивать свое состояние в динамике, превращая субъективные ощущения в понятные данные.',
      'welcomeDialogBody2': 'Научный подход и практика\nМетодика приложения опирается на принципы когнитивно-поведенческой терапии (КПТ) — одного из самых эффективных направлений современной психологии. Дневник можно использовать как инструмент для самопомощи, так и в качестве дополнения к терапии. Ваш психолог сможет точнее анализировать отчеты, что сделает сессии более продуктивными и ускорит ваш прогресс.',
      'welcomeDialogBenefitsTitle': 'Работа с дневником поможет вам:',
      'welcomeDialogBullet1': 'Осознать свои реакции: научитесь видеть связь между мыслями, эмоциями и поведением.',
      'welcomeDialogBullet2': 'Проработать негатив: эффективно справляться с тревожными или угнетающими мыслями, используя проверенные техники.',
      'welcomeDialogBullet3': 'Ценить хорошее: развивать «насмотренность» на позитивные события и укреплять психологическую устойчивость.',
      'welcomeDialogBullet4': 'Отслеживать динамику: проходить профессиональные тесты и видеть реальные изменения в своем состоянии.',
      'welcomeDialogBullet5': 'Стать опорой для самого себя: освоить базовые навыки саморегуляции, которые останутся с вами навсегда.',
      'welcomeDialogFooter': 'Начните путь к глубокому пониманию себя и эмоциональному балансу уже сегодня!',
      'ok': 'Понятно',
      'addEntryButton': 'Добавить запись',
      'newEntryTitle': 'Новая запись',
      'save': 'Сохранить',
      'saveErrorPrefix': 'Ошибка при сохранении: ',
      'emotionSourceLabel': 'Источник эмоций',
      'noteLabel': 'Заметка',
      'noteHint': 'Опишите свои эмоции...',
      'noteValidationRequired': 'Пожалуйста, введите заметку',
      'addPhoto': 'Добавить фото',
      'addMorePhotos': 'Добавить еще фото',
      'deleteEntryTitle': 'Удалить запись?',
      'deleteEntryConfirm1': 'Вы уверены, что хотите удалить эту запись?',
      'cancel': 'Отмена',
      'delete': 'Удалить',
      'confirmTitle': 'Подтверждение',
      'deleteEntryConfirm2': 'Это действие нельзя отменить. Вы действительно хотите удалить запись?',
      'deleteYes': 'Да, удалить',
      'selectMood': 'Выберите настроение',
      'deleteMood': 'Удалить настроение',
      'moodVeryBad': 'Очень плохое',
      'moodBad': 'Плохое',
      'moodNeutral': 'Нейтральное',
      'moodGood': 'Хорошее',
      'moodGreat': 'Отличное',
      'moodNotSelected': 'Не выбрано',
      'historyTitle': 'Дневник',
      'noEntriesForSelectedDate': 'Нет записей на выбранную дату',
      'noDataToDisplay': 'Нет данных для отображения',
      'editEntryTitle': 'Редактировать запись',
      'entryDateLabel': 'Дата записи',
      'photosLabel': 'Фотографии',
      'securityQuestion': 'Уточняющий вопрос',
      'enterQuestionHint': 'Введите вопрос',
      'notInstalled': 'Не установлен',
      'start': 'Начать',
      'pinSetupTitle': 'Установка PIN-кода',
      'forgotPin': 'Забыли PIN-код?',
      'pinPromptEnter': 'Введите PIN-код',
      'pinPromptNew': 'Введите новый PIN-код',
      'pinPromptConfirm': 'Подтвердите PIN-код',
      'recoverySetupTitle': 'Настройка восстановления доступа',
      'recoveryTitle': 'Восстановление доступа',
      'confirm': 'Подтвердить',
      'backToPin': 'Вернуться к PIN-коду',
      'invalidPin': 'Неверный PIN-код',
      'invalidRecoveryWord': 'Неверное кодовое слово',
      'pinMismatch': 'PIN-коды не совпадают',
      'fillAllFields': 'Пожалуйста, заполните все поля',
      'categoryEntries': 'Записи',
      'categoryMood': 'Настроение',
      'periodAllTime': 'Все время',
      'periodMonth': 'Месяц',
      'periodWeek': 'Неделя',
      'periodAllTimeFor': 'все время',
      'periodMonthFor': 'месяц',
      'periodWeekFor': 'неделю',
      'chartLine': 'Линейная',
      'chartPie': 'Круговая',
      'chartByDay': 'Статистика по дням',
      'distributionLabel': 'Распределение',
      'distributionSubjectMood': 'настроения',
      'distributionSubjectEmotions': 'эмоций',
      'distributionForPeriod': 'за',
      'countLabel': 'Количество',
      'legendLabel': 'Легенда',
      'diaryDefaultTitle': 'Мой дневник',
      'chooseDay': 'Выберите день',
      'sourceFriends': 'Друзья',
      'sourceCommunication': 'Общение',
      'sourceHobby': 'Хобби',
      'sourceWork': 'Работа',
      'sourceNature': 'Природа',
      'sourceRest': 'Отдых',
      'sourceFamily': 'Семья',
      'sourceRomanticInterest': 'Любовный интерес',
      'sourceOther': 'Другое',
      'themePurple': 'Фиолетовый',
      'themePurplePastel': 'Пастельный фиолетовый',
      'themeBlue': 'Синий',
      'themeBluePastel': 'Пастельный синий',
      'themeGreen': 'Зеленый',
      'themeGreenPastel': 'Пастельный зеленый',
      'themeRed': 'Красный',
      'themeRedPastel': 'Пастельный красный',
      'themeOrange': 'Оранжевый',
      'themeOrangePastel': 'Пастельный оранжевый',
      'themeTeal': 'Бирюзовый',
      'themeTealPastel': 'Пастельный бирюзовый',
      'themePink': 'Розовый',
      'themeDark': 'Темная',
      'emotionFriends': 'друзья',
      'emotionCommunication': 'общение',
      'emotionHobby': 'хобби',
      'emotionWork': 'работа',
      'emotionNature': 'природа',
      'emotionRest': 'отдых',
      'emotionUnexpectedEvents': 'неожиданные события',
      'emotionLove': 'любовь',
      'emotionCreativity': 'творчество',
      'emotionAchievements': 'достижения',
      'emotionRomanticInterest': 'любовный интерес',
      'noteEditorTitle': 'Редактировать запись',
      'noteEditorEntryTitleLabel': 'Заголовок',
      'noteEditorEmotionsLabel': 'Эмоции',
      'noteEditorContentLabel': 'Содержание',
      'settingsTitle': 'Настройки приложения',
      'settingsThemeSection': 'Цветовая тема',
      'settingsWelcomeImagesSection': 'Приветственные картинки',
      'welcomeImagesLandscapes': 'Пейзажи',
      'welcomeImagesCats': 'Коты',
      'settingsNotificationsSection': 'Уведомления',
      'settingsNotificationsEnabled': 'Ежедневное напоминание',
      'settingsNotificationsTime': 'Время',
      'settingsNotificationsTitle': 'Заголовок уведомления',
      'settingsNotificationsBody': 'Текст уведомления',
      'settingsNotificationsBodyHint': 'Например: Пора записать приятные моменты дня',
      'settingsNotificationsTest': 'Тестовое уведомление',
      'settingsLanguageSection': 'Язык',
      'languageSystem': 'Системный',
      'languageRussian': 'Русский',
      'languageEnglish': 'English',
      'languageFrench': 'Français',
      'languageGerman': 'Deutsch',
      'languagePortuguese': 'Português',
      'pinTitle': 'PIN-код',
      'pinEnabled': 'Включен',
      'pinDisabled': 'Выключен',
      'changePin': 'Изменить PIN-код',
      'recoveryWord': 'Кодовое слово',
      'enterWordHint': 'Введите слово',
      'notSet': 'Не установлено',
    },
    'en': {
      'appTitle': 'CBT Diary',
      'navAdd': 'Add',
      'navHistory': 'Diary',
      'navTests': 'Tests',
      'navStats': 'Stats',
      'navSettings': 'Settings',
      'welcome': 'Welcome!',
      'welcomeDialogTitle': 'Welcome to the Positive Emotions Diary!',
      'welcomeDialogBody1': 'This diary is designed to help you track and cultivate positive emotions in your life. By writing down joyful moments, pleasant impressions, and positive thoughts, you will learn to notice and appreciate the good in each day. This can help you develop a more positive mindset and create a happier, more fulfilling life.',
      'welcomeDialogBody2': 'The diary is based on principles of cognitive behavioral therapy (CBT) and can be used independently or together with a psychologist. Many professionals recommend keeping such a diary as part of the therapeutic process to better track progress and discuss results during sessions.',
      'welcomeDialogBenefitsTitle': 'Keeping a diary can help you:',
      'welcomeDialogBullet1': 'Notice and appreciate joyful moments in everyday life.',
      'welcomeDialogBullet2': 'Develop a positive mindset and an optimistic outlook.',
      'welcomeDialogBullet3': 'Create and maintain a good mood.',
      'welcomeDialogBullet4': 'Work more effectively with a psychologist by tracking your progress.',
      'welcomeDialogBullet5': 'Apply CBT techniques to develop positive thinking.',
      'welcomeDialogFooter': 'Start your journey to a happier life today!',
      'ok': 'OK',
      'addEntryButton': 'Add entry',
      'newEntryTitle': 'New entry',
      'save': 'Save',
      'saveErrorPrefix': 'Save failed: ',
      'emotionSourceLabel': 'Emotion source',
      'noteLabel': 'Note',
      'noteHint': 'Describe your emotions...',
      'noteValidationRequired': 'Please enter a note',
      'addPhoto': 'Add photo',
      'addMorePhotos': 'Add more photos',
      'deleteEntryTitle': 'Delete entry?',
      'deleteEntryConfirm1': 'Are you sure you want to delete this entry?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'confirmTitle': 'Confirmation',
      'deleteEntryConfirm2': 'This action cannot be undone. Do you really want to delete the entry?',
      'deleteYes': 'Yes, delete',
      'selectMood': 'Select mood',
      'deleteMood': 'Remove mood',
      'moodVeryBad': 'Very bad',
      'moodBad': 'Bad',
      'moodNeutral': 'Neutral',
      'moodGood': 'Good',
      'moodGreat': 'Great',
      'moodNotSelected': 'Not selected',
      'historyTitle': 'Diary',
      'noEntriesForSelectedDate': 'No entries for the selected date',
      'noDataToDisplay': 'No data to display',
      'editEntryTitle': 'Edit entry',
      'entryDateLabel': 'Entry date',
      'photosLabel': 'Photos',
      'securityQuestion': 'Security question',
      'enterQuestionHint': 'Enter a question',
      'notInstalled': 'Not set',
      'start': 'Start',
      'pinSetupTitle': 'Set up PIN code',
      'forgotPin': 'Forgot PIN?',
      'pinPromptEnter': 'Enter PIN code',
      'pinPromptNew': 'Enter a new PIN code',
      'pinPromptConfirm': 'Confirm PIN code',
      'recoverySetupTitle': 'Set up account recovery',
      'recoveryTitle': 'Account recovery',
      'confirm': 'Confirm',
      'backToPin': 'Back to PIN',
      'invalidPin': 'Invalid PIN code',
      'invalidRecoveryWord': 'Invalid recovery word',
      'pinMismatch': 'PIN codes do not match',
      'fillAllFields': 'Please fill in all fields',
      'categoryEntries': 'Entries',
      'categoryMood': 'Mood',
      'periodAllTime': 'All time',
      'periodMonth': 'Month',
      'periodWeek': 'Week',
      'periodAllTimeFor': 'all time',
      'periodMonthFor': 'a month',
      'periodWeekFor': 'a week',
      'chartLine': 'Line',
      'chartPie': 'Pie',
      'chartByDay': 'Daily stats',
      'distributionLabel': 'Distribution',
      'distributionSubjectMood': 'mood',
      'distributionSubjectEmotions': 'emotions',
      'distributionForPeriod': 'for',
      'countLabel': 'Count',
      'legendLabel': 'Legend',
      'diaryDefaultTitle': 'My diary',
      'chooseDay': 'Select a day',
      'sourceFriends': 'Friends',
      'sourceCommunication': 'Communication',
      'sourceHobby': 'Hobby',
      'sourceWork': 'Work',
      'sourceNature': 'Nature',
      'sourceRest': 'Rest',
      'sourceFamily': 'Family',
      'sourceRomanticInterest': 'Romantic interest',
      'sourceOther': 'Other',
      'themePurple': 'Purple',
      'themePurplePastel': 'Pastel purple',
      'themeBlue': 'Blue',
      'themeBluePastel': 'Pastel blue',
      'themeGreen': 'Green',
      'themeGreenPastel': 'Pastel green',
      'themeRed': 'Red',
      'themeRedPastel': 'Pastel red',
      'themeOrange': 'Orange',
      'themeOrangePastel': 'Pastel orange',
      'themeTeal': 'Teal',
      'themeTealPastel': 'Pastel teal',
      'themePink': 'Pink',
      'themeDark': 'Dark',
      'emotionFriends': 'friends',
      'emotionCommunication': 'communication',
      'emotionHobby': 'hobby',
      'emotionWork': 'work',
      'emotionNature': 'nature',
      'emotionRest': 'rest',
      'emotionUnexpectedEvents': 'unexpected events',
      'emotionLove': 'love',
      'emotionCreativity': 'creativity',
      'emotionAchievements': 'achievements',
      'emotionRomanticInterest': 'romantic interest',
      'noteEditorTitle': 'Edit entry',
      'noteEditorEntryTitleLabel': 'Title',
      'noteEditorEmotionsLabel': 'Emotions',
      'noteEditorContentLabel': 'Content',
      'settingsTitle': 'App settings',
      'settingsThemeSection': 'Color theme',
      'settingsWelcomeImagesSection': 'Welcome images',
      'welcomeImagesLandscapes': 'Landscapes',
      'welcomeImagesCats': 'Cats',
      'settingsNotificationsSection': 'Notifications',
      'settingsNotificationsEnabled': 'Daily reminder',
      'settingsNotificationsTime': 'Time',
      'settingsNotificationsTitle': 'Notification title',
      'settingsNotificationsBody': 'Notification text',
      'settingsNotificationsBodyHint': 'Example: Time to write today’s good moments',
      'settingsNotificationsTest': 'Test notification',
      'settingsLanguageSection': 'Language',
      'languageSystem': 'System',
      'languageRussian': 'Russian',
      'languageEnglish': 'English',
      'languageFrench': 'French',
      'languageGerman': 'German',
      'languagePortuguese': 'Portuguese',
      'pinTitle': 'PIN code',
      'pinEnabled': 'Enabled',
      'pinDisabled': 'Disabled',
      'changePin': 'Change PIN code',
      'recoveryWord': 'Recovery word',
      'enterWordHint': 'Enter a word',
      'notSet': 'Not set',
    },
    'fr': {
      'appTitle': 'Journal TCC',
      'navAdd': 'Ajouter',
      'navHistory': 'Journal',
      'navTests': 'Tests',
      'navStats': 'Statistiques',
      'navSettings': 'Paramètres',
      'welcome': 'Bienvenue !',
      'welcomeDialogTitle': "Bienvenue dans le journal des émotions positives !",
      'welcomeDialogBody1': "Ce journal est conçu pour vous aider à suivre et à développer des émotions positives dans votre vie. En notant vos moments de joie, vos impressions agréables et vos pensées positives, vous apprendrez à mieux remarquer et apprécier le positif au quotidien. Cela peut vous aider à développer un état d'esprit plus positif et à créer une vie plus heureuse et plus épanouie.",
      'welcomeDialogBody2': "Ce journal s'appuie sur les principes de la thérapie cognitivo-comportementale (TCC) et peut être utilisé seul ou avec un psychologue. De nombreux professionnels recommandent de tenir un tel journal dans le cadre d'un processus thérapeutique afin de mieux suivre les progrès et d'en discuter lors des séances.",
      'welcomeDialogBenefitsTitle': 'Tenir un journal peut vous aider à :',
      'welcomeDialogBullet1': 'Remarquer et apprécier les moments de joie au quotidien.',
      'welcomeDialogBullet2': 'Développer une pensée positive et une vision optimiste.',
      'welcomeDialogBullet3': 'Créer et maintenir une bonne humeur.',
      'welcomeDialogBullet4': 'Travailler plus efficacement avec un psychologue en suivant vos progrès.',
      'welcomeDialogBullet5': 'Appliquer des techniques de TCC pour développer une pensée positive.',
      'welcomeDialogFooter': 'Commencez dès aujourd’hui votre chemin vers une vie plus heureuse !',
      'ok': "D'accord",
      'addEntryButton': 'Ajouter une entrée',
      'newEntryTitle': 'Nouvelle entrée',
      'save': 'Enregistrer',
      'saveErrorPrefix': "Échec de l'enregistrement : ",
      'emotionSourceLabel': "Source d'émotion",
      'noteLabel': 'Note',
      'noteHint': 'Décrivez vos émotions...',
      'noteValidationRequired': 'Veuillez saisir une note',
      'addPhoto': 'Ajouter une photo',
      'addMorePhotos': 'Ajouter plus de photos',
      'deleteEntryTitle': "Supprimer l'entrée ?",
      'deleteEntryConfirm1': 'Voulez-vous vraiment supprimer cette entrée ?',
      'cancel': 'Annuler',
      'delete': 'Supprimer',
      'confirmTitle': 'Confirmation',
      'deleteEntryConfirm2': "Cette action est irréversible. Voulez-vous vraiment supprimer l'entrée ?",
      'deleteYes': 'Oui, supprimer',
      'selectMood': "Choisir l'humeur",
      'deleteMood': "Supprimer l'humeur",
      'moodVeryBad': 'Très mauvais',
      'moodBad': 'Mauvais',
      'moodNeutral': 'Neutre',
      'moodGood': 'Bon',
      'moodGreat': 'Excellent',
      'moodNotSelected': 'Non sélectionné',
      'historyTitle': 'Journal',
      'noEntriesForSelectedDate': 'Aucune entrée pour la date sélectionnée',
      'noDataToDisplay': 'Aucune donnée à afficher',
      'editEntryTitle': "Modifier l'entrée",
      'entryDateLabel': "Date de l'entrée",
      'photosLabel': 'Photos',
      'securityQuestion': 'Question de sécurité',
      'enterQuestionHint': 'Saisissez une question',
      'notInstalled': 'Non défini',
      'start': 'Commencer',
      'pinSetupTitle': 'Configurer le code PIN',
      'forgotPin': 'PIN oublié ?',
      'pinPromptEnter': 'Saisissez le code PIN',
      'pinPromptNew': 'Saisissez un nouveau code PIN',
      'pinPromptConfirm': 'Confirmez le code PIN',
      'recoverySetupTitle': "Configurer la récupération d'accès",
      'recoveryTitle': "Récupération d'accès",
      'confirm': 'Confirmer',
      'backToPin': 'Retour au PIN',
      'invalidPin': 'Code PIN incorrect',
      'invalidRecoveryWord': 'Mot de récupération incorrect',
      'pinMismatch': 'Les codes PIN ne correspondent pas',
      'fillAllFields': 'Veuillez remplir tous les champs',
      'categoryEntries': 'Entrées',
      'categoryMood': 'Humeur',
      'periodAllTime': 'Tout le temps',
      'periodMonth': 'Mois',
      'periodWeek': 'Semaine',
      'periodAllTimeFor': 'tout le temps',
      'periodMonthFor': 'un mois',
      'periodWeekFor': 'une semaine',
      'chartLine': 'Linéaire',
      'chartPie': 'Camembert',
      'chartByDay': 'Stats quotidiennes',
      'distributionLabel': 'Répartition',
      'distributionSubjectMood': "de l'humeur",
      'distributionSubjectEmotions': 'des émotions',
      'distributionForPeriod': 'pour',
      'countLabel': 'Nombre',
      'legendLabel': 'Légende',
      'diaryDefaultTitle': 'Mon journal',
      'chooseDay': 'Choisissez un jour',
      'sourceFriends': 'Amis',
      'sourceCommunication': 'Communication',
      'sourceHobby': 'Loisir',
      'sourceWork': 'Travail',
      'sourceNature': 'Nature',
      'sourceRest': 'Repos',
      'sourceFamily': 'Famille',
      'sourceRomanticInterest': 'Intérêt romantique',
      'sourceOther': 'Autre',
      'themePurple': 'Violet',
      'themePurplePastel': 'Violet pastel',
      'themeBlue': 'Bleu',
      'themeBluePastel': 'Bleu pastel',
      'themeGreen': 'Vert',
      'themeGreenPastel': 'Vert pastel',
      'themeRed': 'Rouge',
      'themeRedPastel': 'Rouge pastel',
      'themeOrange': 'Orange',
      'themeOrangePastel': 'Orange pastel',
      'themeTeal': 'Sarcelle',
      'themeTealPastel': 'Sarcelle pastel',
      'themePink': 'Rose',
      'themeDark': 'Sombre',
      'emotionFriends': 'amis',
      'emotionCommunication': 'communication',
      'emotionHobby': 'loisir',
      'emotionWork': 'travail',
      'emotionNature': 'nature',
      'emotionRest': 'repos',
      'emotionUnexpectedEvents': 'événements inattendus',
      'emotionLove': 'amour',
      'emotionCreativity': 'créativité',
      'emotionAchievements': 'réalisations',
      'emotionRomanticInterest': 'intérêt romantique',
      'noteEditorTitle': "Modifier l'entrée",
      'noteEditorEntryTitleLabel': 'Titre',
      'noteEditorEmotionsLabel': 'Émotions',
      'noteEditorContentLabel': 'Contenu',
      'settingsTitle': "Paramètres de l'application",
      'settingsThemeSection': 'Thème de couleur',
      'settingsWelcomeImagesSection': 'Images d’accueil',
      'welcomeImagesLandscapes': 'Paysages',
      'welcomeImagesCats': 'Chats',
      'settingsNotificationsSection': 'Notifications',
      'settingsNotificationsEnabled': 'Rappel quotidien',
      'settingsNotificationsTime': 'Heure',
      'settingsNotificationsTitle': 'Titre de la notification',
      'settingsNotificationsBody': 'Texte de la notification',
      'settingsNotificationsBodyHint': 'Ex. : Il est temps d’écrire les bons moments du jour',
      'settingsNotificationsTest': 'Notification test',
      'settingsLanguageSection': 'Langue',
      'languageSystem': 'Système',
      'languageRussian': 'Russe',
      'languageEnglish': 'Anglais',
      'languageFrench': 'Français',
      'languageGerman': 'Allemand',
      'languagePortuguese': 'Portugais',
      'pinTitle': 'Code PIN',
      'pinEnabled': 'Activé',
      'pinDisabled': 'Désactivé',
      'changePin': 'Modifier le code PIN',
      'recoveryWord': 'Mot de récupération',
      'enterWordHint': 'Entrez un mot',
      'notSet': 'Non défini',
    },
    'de': {
      'appTitle': 'KVT-Tagebuch',
      'navAdd': 'Hinzufügen',
      'navHistory': 'Tagebuch',
      'navTests': 'Tests',
      'navStats': 'Statistik',
      'navSettings': 'Einstellungen',
      'welcome': 'Willkommen!',
      'welcomeDialogTitle': 'Willkommen im Tagebuch positiver Emotionen!',
      'welcomeDialogBody1': 'Dieses Tagebuch hilft dir dabei, positive Emotionen in deinem Leben zu beobachten und zu stärken. Wenn du freudige Momente, angenehme Eindrücke und positive Gedanken festhältst, lernst du, das Gute im Alltag besser wahrzunehmen und zu schätzen. Das kann dir helfen, eine positivere Haltung zu entwickeln und ein glücklicheres, erfüllteres Leben zu gestalten.',
      'welcomeDialogBody2': 'Das Tagebuch basiert auf Prinzipien der kognitiven Verhaltenstherapie (KVT) und kann sowohl allein als auch gemeinsam mit einer Psychologin oder einem Psychologen genutzt werden. Viele Fachleute empfehlen ein solches Tagebuch als Teil des therapeutischen Prozesses, um Fortschritte besser zu verfolgen und Ergebnisse in Sitzungen zu besprechen.',
      'welcomeDialogBenefitsTitle': 'Ein Tagebuch kann dir helfen:',
      'welcomeDialogBullet1': 'Freudige Momente im Alltag wahrzunehmen und zu schätzen.',
      'welcomeDialogBullet2': 'Positives Denken und eine optimistische Sicht zu entwickeln.',
      'welcomeDialogBullet3': 'Gute Stimmung aufzubauen und zu erhalten.',
      'welcomeDialogBullet4': 'Effektiver mit einer Psychologin oder einem Psychologen zu arbeiten, indem du deinen Fortschritt verfolgst.',
      'welcomeDialogBullet5': 'KVT-Techniken anzuwenden, um positives Denken zu fördern.',
      'welcomeDialogFooter': 'Starte deine Reise zu einem glücklicheren Leben noch heute!',
      'ok': 'OK',
      'addEntryButton': 'Eintrag hinzufügen',
      'newEntryTitle': 'Neuer Eintrag',
      'save': 'Speichern',
      'saveErrorPrefix': 'Speichern fehlgeschlagen: ',
      'emotionSourceLabel': 'Emotionsquelle',
      'noteLabel': 'Notiz',
      'noteHint': 'Beschreibe deine Emotionen...',
      'noteValidationRequired': 'Bitte gib eine Notiz ein',
      'addPhoto': 'Foto hinzufügen',
      'addMorePhotos': 'Weitere Fotos hinzufügen',
      'deleteEntryTitle': 'Eintrag löschen?',
      'deleteEntryConfirm1': 'Möchtest du diesen Eintrag wirklich löschen?',
      'cancel': 'Abbrechen',
      'delete': 'Löschen',
      'confirmTitle': 'Bestätigung',
      'deleteEntryConfirm2': 'Diese Aktion kann nicht rückgängig gemacht werden. Möchtest du den Eintrag wirklich löschen?',
      'deleteYes': 'Ja, löschen',
      'selectMood': 'Stimmung auswählen',
      'deleteMood': 'Stimmung entfernen',
      'moodVeryBad': 'Sehr schlecht',
      'moodBad': 'Schlecht',
      'moodNeutral': 'Neutral',
      'moodGood': 'Gut',
      'moodGreat': 'Sehr gut',
      'moodNotSelected': 'Nicht ausgewählt',
      'historyTitle': 'Tagebuch',
      'noEntriesForSelectedDate': 'Keine Einträge für das ausgewählte Datum',
      'noDataToDisplay': 'Keine Daten zum Anzeigen',
      'editEntryTitle': 'Eintrag bearbeiten',
      'entryDateLabel': 'Datum des Eintrags',
      'photosLabel': 'Fotos',
      'securityQuestion': 'Sicherheitsfrage',
      'enterQuestionHint': 'Frage eingeben',
      'notInstalled': 'Nicht festgelegt',
      'start': 'Starten',
      'pinSetupTitle': 'PIN-Code einrichten',
      'forgotPin': 'PIN vergessen?',
      'pinPromptEnter': 'PIN-Code eingeben',
      'pinPromptNew': 'Neuen PIN-Code eingeben',
      'pinPromptConfirm': 'PIN-Code bestätigen',
      'recoverySetupTitle': 'Wiederherstellung einrichten',
      'recoveryTitle': 'Wiederherstellung',
      'confirm': 'Bestätigen',
      'backToPin': 'Zurück zum PIN',
      'invalidPin': 'Ungültiger PIN-Code',
      'invalidRecoveryWord': 'Ungültiges Wiederherstellungswort',
      'pinMismatch': 'PIN-Codes stimmen nicht überein',
      'fillAllFields': 'Bitte alle Felder ausfüllen',
      'categoryEntries': 'Einträge',
      'categoryMood': 'Stimmung',
      'periodAllTime': 'Gesamt',
      'periodMonth': 'Monat',
      'periodWeek': 'Woche',
      'periodAllTimeFor': 'insgesamt',
      'periodMonthFor': 'einen Monat',
      'periodWeekFor': 'eine Woche',
      'chartLine': 'Linie',
      'chartPie': 'Kreis',
      'chartByDay': 'Tagesstatistik',
      'distributionLabel': 'Verteilung',
      'distributionSubjectMood': 'der Stimmung',
      'distributionSubjectEmotions': 'der Emotionen',
      'distributionForPeriod': 'für',
      'countLabel': 'Anzahl',
      'legendLabel': 'Legende',
      'diaryDefaultTitle': 'Mein Tagebuch',
      'chooseDay': 'Wähle einen Tag aus',
      'sourceFriends': 'Freunde',
      'sourceCommunication': 'Kommunikation',
      'sourceHobby': 'Hobby',
      'sourceWork': 'Arbeit',
      'sourceNature': 'Natur',
      'sourceRest': 'Erholung',
      'sourceFamily': 'Familie',
      'sourceRomanticInterest': 'Romantisches Interesse',
      'sourceOther': 'Sonstiges',
      'themePurple': 'Violett',
      'themePurplePastel': 'Pastellviolett',
      'themeBlue': 'Blau',
      'themeBluePastel': 'Pastellblau',
      'themeGreen': 'Grün',
      'themeGreenPastel': 'Pastellgrün',
      'themeRed': 'Rot',
      'themeRedPastel': 'Pastellrot',
      'themeOrange': 'Orange',
      'themeOrangePastel': 'Pastellorange',
      'themeTeal': 'Türkis',
      'themeTealPastel': 'Pastelltürkis',
      'themePink': 'Rosa',
      'themeDark': 'Dunkel',
      'emotionFriends': 'freunde',
      'emotionCommunication': 'kommunikation',
      'emotionHobby': 'hobby',
      'emotionWork': 'arbeit',
      'emotionNature': 'natur',
      'emotionRest': 'erholung',
      'emotionUnexpectedEvents': 'unerwartete ereignisse',
      'emotionLove': 'liebe',
      'emotionCreativity': 'kreativität',
      'emotionAchievements': 'erfolge',
      'emotionRomanticInterest': 'romantisches interesse',
      'noteEditorTitle': 'Eintrag bearbeiten',
      'noteEditorEntryTitleLabel': 'Titel',
      'noteEditorEmotionsLabel': 'Emotionen',
      'noteEditorContentLabel': 'Inhalt',
      'settingsTitle': 'App-Einstellungen',
      'settingsThemeSection': 'Farbthema',
      'settingsWelcomeImagesSection': 'Willkommensbilder',
      'welcomeImagesLandscapes': 'Landschaften',
      'welcomeImagesCats': 'Katzen',
      'settingsNotificationsSection': 'Benachrichtigungen',
      'settingsNotificationsEnabled': 'Tägliche Erinnerung',
      'settingsNotificationsTime': 'Uhrzeit',
      'settingsNotificationsTitle': 'Benachrichtigungstitel',
      'settingsNotificationsBody': 'Benachrichtigungstext',
      'settingsNotificationsBodyHint': 'Beispiel: Zeit, die schönen Momente des Tages aufzuschreiben',
      'settingsNotificationsTest': 'Testbenachrichtigung',
      'settingsLanguageSection': 'Sprache',
      'languageSystem': 'System',
      'languageRussian': 'Russisch',
      'languageEnglish': 'Englisch',
      'languageFrench': 'Französisch',
      'languageGerman': 'Deutsch',
      'languagePortuguese': 'Portugiesisch',
      'pinTitle': 'PIN-Code',
      'pinEnabled': 'Aktiviert',
      'pinDisabled': 'Deaktiviert',
      'changePin': 'PIN-Code ändern',
      'recoveryWord': 'Wiederherstellungswort',
      'enterWordHint': 'Wort eingeben',
      'notSet': 'Nicht festgelegt',
    },
    'pt': {
      'appTitle': 'Diário TCC',
      'navAdd': 'Adicionar',
      'navHistory': 'Diário',
      'navTests': 'Testes',
      'navStats': 'Estatísticas',
      'navSettings': 'Configurações',
      'welcome': 'Bem-vindo!',
      'welcomeDialogTitle': 'Bem-vindo ao Diário de Emoções Positivas!',
      'welcomeDialogBody1': 'Este diário foi criado para ajudar você a acompanhar e desenvolver emoções positivas na sua vida. Ao registrar momentos de alegria, impressões agradáveis e pensamentos positivos, você vai aprender a perceber e valorizar o que há de bom em cada dia. Isso pode ajudar a construir uma mentalidade mais positiva e uma vida mais feliz e plena.',
      'welcomeDialogBody2': 'O diário é baseado em princípios da terapia cognitivo-comportamental (TCC) e pode ser usado tanto de forma independente quanto com um psicólogo. Muitos profissionais recomendam manter um diário como parte do processo terapêutico para acompanhar melhor o progresso e discutir os resultados nas sessões.',
      'welcomeDialogBenefitsTitle': 'Manter um diário pode ajudar você a:',
      'welcomeDialogBullet1': 'Perceber e valorizar momentos de alegria no dia a dia.',
      'welcomeDialogBullet2': 'Desenvolver uma mentalidade positiva e uma visão otimista.',
      'welcomeDialogBullet3': 'Criar e manter um bom humor.',
      'welcomeDialogBullet4': 'Trabalhar de forma mais eficaz com um psicólogo ao acompanhar seu progresso.',
      'welcomeDialogBullet5': 'Aplicar técnicas da TCC para desenvolver o pensamento positivo.',
      'welcomeDialogFooter': 'Comece hoje mesmo sua jornada para uma vida mais feliz!',
      'ok': 'OK',
      'addEntryButton': 'Adicionar registro',
      'newEntryTitle': 'Novo registro',
      'save': 'Salvar',
      'saveErrorPrefix': 'Falha ao salvar: ',
      'emotionSourceLabel': 'Fonte da emoção',
      'noteLabel': 'Nota',
      'noteHint': 'Descreva suas emoções...',
      'noteValidationRequired': 'Por favor, digite uma nota',
      'addPhoto': 'Adicionar foto',
      'addMorePhotos': 'Adicionar mais fotos',
      'deleteEntryTitle': 'Excluir registro?',
      'deleteEntryConfirm1': 'Tem certeza de que deseja excluir este registro?',
      'cancel': 'Cancelar',
      'delete': 'Excluir',
      'confirmTitle': 'Confirmação',
      'deleteEntryConfirm2': 'Esta ação não pode ser desfeita. Você realmente deseja excluir o registro?',
      'deleteYes': 'Sim, excluir',
      'selectMood': 'Escolha o humor',
      'deleteMood': 'Remover humor',
      'moodVeryBad': 'Muito ruim',
      'moodBad': 'Ruim',
      'moodNeutral': 'Neutro',
      'moodGood': 'Bom',
      'moodGreat': 'Ótimo',
      'moodNotSelected': 'Não selecionado',
      'historyTitle': 'Diário',
      'noEntriesForSelectedDate': 'Nenhum registro para a data selecionada',
      'noDataToDisplay': 'Sem dados para exibir',
      'editEntryTitle': 'Editar registro',
      'entryDateLabel': 'Data do registro',
      'photosLabel': 'Fotos',
      'securityQuestion': 'Pergunta de segurança',
      'enterQuestionHint': 'Digite uma pergunta',
      'notInstalled': 'Não definido',
      'start': 'Começar',
      'pinSetupTitle': 'Configurar PIN',
      'forgotPin': 'Esqueceu o PIN?',
      'pinPromptEnter': 'Digite o PIN',
      'pinPromptNew': 'Digite um novo PIN',
      'pinPromptConfirm': 'Confirme o PIN',
      'recoverySetupTitle': 'Configurar recuperação de acesso',
      'recoveryTitle': 'Recuperação de acesso',
      'confirm': 'Confirmar',
      'backToPin': 'Voltar ao PIN',
      'invalidPin': 'PIN incorreto',
      'invalidRecoveryWord': 'Palavra de recuperação incorreta',
      'pinMismatch': 'Os PINs não coincidem',
      'fillAllFields': 'Por favor, preencha todos os campos',
      'categoryEntries': 'Registros',
      'categoryMood': 'Humor',
      'periodAllTime': 'Todo o período',
      'periodMonth': 'Mês',
      'periodWeek': 'Semana',
      'periodAllTimeFor': 'todo o período',
      'periodMonthFor': 'um mês',
      'periodWeekFor': 'uma semana',
      'chartLine': 'Linha',
      'chartPie': 'Pizza',
      'chartByDay': 'Estatísticas diárias',
      'distributionLabel': 'Distribuição',
      'distributionSubjectMood': 'do humor',
      'distributionSubjectEmotions': 'das emoções',
      'distributionForPeriod': 'por',
      'countLabel': 'Quantidade',
      'legendLabel': 'Legenda',
      'diaryDefaultTitle': 'Meu diário',
      'chooseDay': 'Selecione um dia',
      'sourceFriends': 'Amigos',
      'sourceCommunication': 'Comunicação',
      'sourceHobby': 'Hobby',
      'sourceWork': 'Trabalho',
      'sourceNature': 'Natureza',
      'sourceRest': 'Descanso',
      'sourceFamily': 'Família',
      'sourceRomanticInterest': 'Interesse romântico',
      'sourceOther': 'Outro',
      'themePurple': 'Roxo',
      'themePurplePastel': 'Roxo pastel',
      'themeBlue': 'Azul',
      'themeBluePastel': 'Azul pastel',
      'themeGreen': 'Verde',
      'themeGreenPastel': 'Verde pastel',
      'themeRed': 'Vermelho',
      'themeRedPastel': 'Vermelho pastel',
      'themeOrange': 'Laranja',
      'themeOrangePastel': 'Laranja pastel',
      'themeTeal': 'Turquesa',
      'themeTealPastel': 'Turquesa pastel',
      'themePink': 'Rosa',
      'themeDark': 'Escuro',
      'emotionFriends': 'amigos',
      'emotionCommunication': 'comunicação',
      'emotionHobby': 'hobby',
      'emotionWork': 'trabalho',
      'emotionNature': 'natureza',
      'emotionRest': 'descanso',
      'emotionUnexpectedEvents': 'eventos inesperados',
      'emotionLove': 'amor',
      'emotionCreativity': 'criatividade',
      'emotionAchievements': 'conquistas',
      'emotionRomanticInterest': 'interesse romântico',
      'noteEditorTitle': 'Editar registro',
      'noteEditorEntryTitleLabel': 'Título',
      'noteEditorEmotionsLabel': 'Emoções',
      'noteEditorContentLabel': 'Conteúdo',
      'settingsTitle': 'Configurações do app',
      'settingsThemeSection': 'Tema de cores',
      'settingsWelcomeImagesSection': 'Imagens de boas-vindas',
      'welcomeImagesLandscapes': 'Paisagens',
      'welcomeImagesCats': 'Gatos',
      'settingsNotificationsSection': 'Notificações',
      'settingsNotificationsEnabled': 'Lembrete diário',
      'settingsNotificationsTime': 'Horário',
      'settingsNotificationsTitle': 'Título da notificação',
      'settingsNotificationsBody': 'Texto da notificação',
      'settingsNotificationsBodyHint': 'Ex.: Hora de registrar os bons momentos do dia',
      'settingsNotificationsTest': 'Notificação de teste',
      'settingsLanguageSection': 'Idioma',
      'languageSystem': 'Sistema',
      'languageRussian': 'Russo',
      'languageEnglish': 'Inglês',
      'languageFrench': 'Francês',
      'languageGerman': 'Alemão',
      'languagePortuguese': 'Português',
      'pinTitle': 'Código PIN',
      'pinEnabled': 'Ativado',
      'pinDisabled': 'Desativado',
      'changePin': 'Alterar código PIN',
      'recoveryWord': 'Palavra de recuperação',
      'enterWordHint': 'Digite uma palavra',
      'notSet': 'Não definido',
    },
  };

  String _t(String key) {
    final lang = _strings.containsKey(locale.languageCode) ? locale.languageCode : 'en';
    return _strings[lang]![key] ?? key;
  }

  String get appTitle => _t('appTitle');
  String get navAdd => _t('navAdd');
  String get navHistory => _t('navHistory');
  String get navTests => _t('navTests');
  String get navStats => _t('navStats');
  String get navSettings => _t('navSettings');
  String get welcome => _t('welcome');
  String get welcomeDialogTitle => _t('welcomeDialogTitle');
  String get welcomeDialogBody1 => _t('welcomeDialogBody1');
  String get welcomeDialogBody2 => _t('welcomeDialogBody2');
  String get welcomeDialogBenefitsTitle => _t('welcomeDialogBenefitsTitle');
  String get welcomeDialogBullet1 => _t('welcomeDialogBullet1');
  String get welcomeDialogBullet2 => _t('welcomeDialogBullet2');
  String get welcomeDialogBullet3 => _t('welcomeDialogBullet3');
  String get welcomeDialogBullet4 => _t('welcomeDialogBullet4');
  String get welcomeDialogBullet5 => _t('welcomeDialogBullet5');
  String get welcomeDialogFooter => _t('welcomeDialogFooter');
  String get ok => _t('ok');
  String get addEntryButton => _t('addEntryButton');
  String get newEntryTitle => _t('newEntryTitle');
  String get save => _t('save');
  String get saveErrorPrefix => _t('saveErrorPrefix');
  String get emotionSourceLabel => _t('emotionSourceLabel');
  String get noteLabel => _t('noteLabel');
  String get noteHint => _t('noteHint');
  String get noteValidationRequired => _t('noteValidationRequired');
  String get addPhoto => _t('addPhoto');
  String get addMorePhotos => _t('addMorePhotos');
  String get deleteEntryTitle => _t('deleteEntryTitle');
  String get deleteEntryConfirm1 => _t('deleteEntryConfirm1');
  String get cancel => _t('cancel');
  String get delete => _t('delete');
  String get confirmTitle => _t('confirmTitle');
  String get deleteEntryConfirm2 => _t('deleteEntryConfirm2');
  String get deleteYes => _t('deleteYes');
  String get selectMood => _t('selectMood');
  String get deleteMood => _t('deleteMood');
  String get moodVeryBad => _t('moodVeryBad');
  String get moodBad => _t('moodBad');
  String get moodNeutral => _t('moodNeutral');
  String get moodGood => _t('moodGood');
  String get moodGreat => _t('moodGreat');
  String get moodNotSelected => _t('moodNotSelected');
  String get historyTitle => _t('historyTitle');
  String get noEntriesForSelectedDate => _t('noEntriesForSelectedDate');
  String get noDataToDisplay => _t('noDataToDisplay');
  String get editEntryTitle => _t('editEntryTitle');
  String get entryDateLabel => _t('entryDateLabel');
  String get photosLabel => _t('photosLabel');
  String get securityQuestion => _t('securityQuestion');
  String get enterQuestionHint => _t('enterQuestionHint');
  String get notInstalled => _t('notInstalled');
  String get start => _t('start');
  String get pinSetupTitle => _t('pinSetupTitle');
  String get forgotPin => _t('forgotPin');
  String get pinPromptEnter => _t('pinPromptEnter');
  String get pinPromptNew => _t('pinPromptNew');
  String get pinPromptConfirm => _t('pinPromptConfirm');
  String get recoverySetupTitle => _t('recoverySetupTitle');
  String get recoveryTitle => _t('recoveryTitle');
  String get confirm => _t('confirm');
  String get backToPin => _t('backToPin');
  String get invalidPin => _t('invalidPin');
  String get invalidRecoveryWord => _t('invalidRecoveryWord');
  String get pinMismatch => _t('pinMismatch');
  String get fillAllFields => _t('fillAllFields');
  String get categoryEntries => _t('categoryEntries');
  String get categoryMood => _t('categoryMood');
  String get periodAllTime => _t('periodAllTime');
  String get periodMonth => _t('periodMonth');
  String get periodWeek => _t('periodWeek');
  String get periodAllTimeFor => _t('periodAllTimeFor');
  String get periodMonthFor => _t('periodMonthFor');
  String get periodWeekFor => _t('periodWeekFor');
  String get chartLine => _t('chartLine');
  String get chartPie => _t('chartPie');
  String get chartByDay => _t('chartByDay');
  String get distributionLabel => _t('distributionLabel');
  String get distributionSubjectMood => _t('distributionSubjectMood');
  String get distributionSubjectEmotions => _t('distributionSubjectEmotions');
  String get distributionForPeriod => _t('distributionForPeriod');
  String get countLabel => _t('countLabel');
  String get legendLabel => _t('legendLabel');
  String get diaryDefaultTitle => _t('diaryDefaultTitle');
  String get chooseDay => _t('chooseDay');
  String get sourceFriends => _t('sourceFriends');
  String get sourceCommunication => _t('sourceCommunication');
  String get sourceHobby => _t('sourceHobby');
  String get sourceWork => _t('sourceWork');
  String get sourceNature => _t('sourceNature');
  String get sourceRest => _t('sourceRest');
  String get sourceFamily => _t('sourceFamily');
  String get sourceRomanticInterest => _t('sourceRomanticInterest');
  String get sourceOther => _t('sourceOther');
  String get themePurple => _t('themePurple');
  String get themePurplePastel => _t('themePurplePastel');
  String get themeBlue => _t('themeBlue');
  String get themeBluePastel => _t('themeBluePastel');
  String get themeGreen => _t('themeGreen');
  String get themeGreenPastel => _t('themeGreenPastel');
  String get themeRed => _t('themeRed');
  String get themeRedPastel => _t('themeRedPastel');
  String get themeOrange => _t('themeOrange');
  String get themeOrangePastel => _t('themeOrangePastel');
  String get themeTeal => _t('themeTeal');
  String get themeTealPastel => _t('themeTealPastel');
  String get themePink => _t('themePink');
  String get themeDark => _t('themeDark');
  String get emotionFriends => _t('emotionFriends');
  String get emotionCommunication => _t('emotionCommunication');
  String get emotionHobby => _t('emotionHobby');
  String get emotionWork => _t('emotionWork');
  String get emotionNature => _t('emotionNature');
  String get emotionRest => _t('emotionRest');
  String get emotionUnexpectedEvents => _t('emotionUnexpectedEvents');
  String get emotionLove => _t('emotionLove');
  String get emotionCreativity => _t('emotionCreativity');
  String get emotionAchievements => _t('emotionAchievements');
  String get emotionRomanticInterest => _t('emotionRomanticInterest');
  String get noteEditorTitle => _t('noteEditorTitle');
  String get noteEditorEntryTitleLabel => _t('noteEditorEntryTitleLabel');
  String get noteEditorEmotionsLabel => _t('noteEditorEmotionsLabel');
  String get noteEditorContentLabel => _t('noteEditorContentLabel');
  String get settingsTitle => _t('settingsTitle');
  String get settingsThemeSection => _t('settingsThemeSection');
  String get settingsWelcomeImagesSection => _t('settingsWelcomeImagesSection');
  String get welcomeImagesLandscapes => _t('welcomeImagesLandscapes');
  String get welcomeImagesCats => _t('welcomeImagesCats');
  String get settingsNotificationsSection => _t('settingsNotificationsSection');
  String get settingsNotificationsEnabled => _t('settingsNotificationsEnabled');
  String get settingsNotificationsTime => _t('settingsNotificationsTime');
  String get settingsNotificationsTitle => _t('settingsNotificationsTitle');
  String get settingsNotificationsBody => _t('settingsNotificationsBody');
  String get settingsNotificationsBodyHint => _t('settingsNotificationsBodyHint');
  String get settingsNotificationsTest => _t('settingsNotificationsTest');
  String get settingsLanguageSection => _t('settingsLanguageSection');
  String get languageSystem => _t('languageSystem');
  String get languageRussian => _t('languageRussian');
  String get languageEnglish => _t('languageEnglish');
  String get languageFrench => _t('languageFrench');
  String get languageGerman => _t('languageGerman');
  String get languagePortuguese => _t('languagePortuguese');
  String get pinTitle => _t('pinTitle');
  String get pinEnabled => _t('pinEnabled');
  String get pinDisabled => _t('pinDisabled');
  String get changePin => _t('changePin');
  String get recoveryWord => _t('recoveryWord');
  String get enterWordHint => _t('enterWordHint');
  String get notSet => _t('notSet');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _currentTheme = ThemeProvider.themeNameMatchingPlatform();
  AppLanguage _language = AppLanguage.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadLanguage();
  }

  Future<void> _loadTheme() async {
    final theme = await ThemeProvider.getTheme();
    setState(() {
      _currentTheme = theme;
    });
  }

  void updateTheme(String themeName) {
    setState(() {
      _currentTheme = themeName;
    });
  }

  Future<void> _loadLanguage() async {
    final lang = await LocaleProvider.getLanguage();
    setState(() {
      _language = lang;
    });
  }

  Future<void> updateLanguage(AppLanguage language) async {
    await LocaleProvider.saveLanguage(language);
    setState(() {
      _language = language;
    });
  }

  Locale? _resolveLocale() {
    switch (_language) {
      case AppLanguage.system:
        return null;
      case AppLanguage.ru:
        return const Locale('ru');
      case AppLanguage.en:
        return const Locale('en');
      case AppLanguage.fr:
        return const Locale('fr');
      case AppLanguage.de:
        return const Locale('de');
      case AppLanguage.pt:
        return const Locale('pt');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: ThemeProvider.withPopupAndMenuTheming(ThemeProvider.themes[_currentTheme]!),
      locale: _resolveLocale(),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: SplashScreen(currentTheme: _currentTheme),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final String currentTheme;
  const SplashScreen({super.key, required this.currentTheme});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;

    if (isFirstLaunch) {
      await prefs.setBool('is_first_launch', false);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const WelcomeScreen(),
          ),
        );
      }
    } else {
      if (mounted) {
        final bool isPinEnabled = prefs.getBool('pin_enabled') ?? false;
        if (isPinEnabled) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PinCodeScreen(isSetup: false),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(currentTheme: widget.currentTheme),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String currentTheme;
  const HomeScreen({super.key, required this.currentTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToMainScreen();
  }

  Future<void> _navigateToMainScreen() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => MainScreen(currentTheme: widget.currentTheme),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AnimatedCat(),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).welcome,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String currentTheme;
  const MainScreen({super.key, required this.currentTheme});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final PageController _pageController;
  bool _pageSwipeEnabled = true;
  late StreamSubscription _themeSubscription;
  late StreamSubscription _diaryTitleSubscription;
  late String _currentTheme;
  String _diaryTitle = '';
  bool _didInitDiaryTitle = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _currentTheme = widget.currentTheme;
    _themeSubscription = ThemeProvider.themeStreamController.stream.listen((newTheme) {
      setState(() {
        _currentTheme = newTheme;
      });
    });
    _diaryTitleSubscription = ThemeProvider.diaryTitleStreamController.stream.listen((newTitle) {
      setState(() {
        _diaryTitle = newTitle;
      });
    });
    _loadDiaryTitle();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitDiaryTitle) {
      _didInitDiaryTitle = true;
      setState(() {
        _diaryTitle = AppLocalizations.of(context).diaryDefaultTitle;
      });
    }
  }

  Future<void> _loadDiaryTitle() async {
    final prefs = await SharedPreferences.getInstance();
    final rawTitle = prefs.getString('diary_title');
    final savedTitle = (rawTitle == null || rawTitle.trim().isEmpty)
        ? AppLocalizations.of(context).diaryDefaultTitle
        : rawTitle;
    setState(() {
      _diaryTitle = savedTitle;
    });
  }

  @override
  void dispose() {
    _themeSubscription.cancel();
    _diaryTitleSubscription.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _showWelcomeMessage() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final accent = Theme.of(dialogContext).colorScheme.primary;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.welcomeDialogTitle,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Text(
                  l10n.welcomeDialogBody1,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.welcomeDialogBody2,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.welcomeDialogBenefitsTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildBulletPoint(l10n.welcomeDialogBullet1, accent),
                _buildBulletPoint(l10n.welcomeDialogBullet2, accent),
                _buildBulletPoint(l10n.welcomeDialogBullet3, accent),
                _buildBulletPoint(l10n.welcomeDialogBullet4, accent),
                _buildBulletPoint(l10n.welcomeDialogBullet5, accent),
                const SizedBox(height: 24),
                Text(
                  l10n.welcomeDialogFooter,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: accent,
                    foregroundColor: Theme.of(dialogContext).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.ok,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBulletPoint(String text, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> get _screens => [
    DiaryScreen(currentTheme: _currentTheme),
    const HistoryScreen(),
    const TestsScreen(),
    StatisticsScreen(
      currentTheme: _currentTheme,
      onPageSwipeEnabled: (enabled) {
        if (!mounted) return;
        if (_pageSwipeEnabled == enabled) return;
        setState(() => _pageSwipeEnabled = enabled);
      },
    ),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = ThemeProvider.accentForScheme(scheme);
    final unselectedNav = Color.lerp(scheme.onSurfaceVariant, accent, 0.35) ?? scheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(
        title: Text(_diaryTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: l10n.welcome,
            onPressed: _showWelcomeMessage,
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: _pageSwipeEnabled
            ? const PageScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _selectedIndex = index);
        },
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: scheme.surface,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: l10n.navAdd,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            label: l10n.navHistory,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note),
            label: l10n.navTests,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: l10n.navStats,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: accent,
        unselectedItemColor: unselectedNav,
        selectedIconTheme: IconThemeData(color: accent),
        unselectedIconTheme: IconThemeData(color: unselectedNav),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        onTap: _onItemTapped,
      ),
    );
  }
}

class DiaryScreen extends StatefulWidget {
  final String currentTheme;
  const DiaryScreen({super.key, required this.currentTheme});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  static const String _fallbackWelcomeAsset = 'assets/images/cat1.png';
  String _currentImage = '';
  List<String> _welcomeImagePaths = [];
  StreamSubscription<Set<WelcomeImagesMode>>? _welcomeImagesSub;
  final TextEditingController _titleController = TextEditingController();
  bool _isEditingTitle = false;
  static const String _diaryTitleKey = 'diary_title';
  bool _didInitDiaryTitle = false;

  @override
  void initState() {
    super.initState();
    _welcomeImagesSub = WelcomeImagesSettings.streamController.stream.listen((_) {
      if (mounted) {
        unawaited(_reloadWelcomeImage());
      }
    });
    unawaited(_reloadWelcomeImage());
    _loadDiaryTitle();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitDiaryTitle) {
      _didInitDiaryTitle = true;
      if (_titleController.text.trim().isEmpty) {
        setState(() {
          _titleController.text = AppLocalizations.of(context).diaryDefaultTitle;
        });
      }
    }
  }

  Future<void> _loadDiaryTitle() async {
    final prefs = await SharedPreferences.getInstance();
    final rawTitle = prefs.getString(_diaryTitleKey);
    final savedTitle = (rawTitle == null || rawTitle.trim().isEmpty)
        ? AppLocalizations.of(context).diaryDefaultTitle
        : rawTitle;
    setState(() {
      _titleController.text = savedTitle;
    });
  }

  Future<void> _saveDiaryTitle(String title) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_diaryTitleKey, title);
    ThemeProvider.diaryTitleStreamController.add(title);
  }

  Future<void> _reloadWelcomeImage() async {
    final modes = await WelcomeImagesSettings.getModes();
    var pool = await WelcomeImagesSettings.assetPoolForSelection(modes);
    if (pool.isEmpty && !modes.contains(WelcomeImagesMode.cats)) {
      pool = await WelcomeImagesSettings.assetPoolForSelection(
        {WelcomeImagesMode.landscapes, WelcomeImagesMode.cats},
      );
    }
    if (pool.isEmpty) {
      pool = [_fallbackWelcomeAsset];
    }
    if (!mounted) return;
    setState(() {
      _welcomeImagePaths = pool;
      _currentImage = pool[Random().nextInt(pool.length)];
    });
  }

  void _selectRandomImage() {
    if (_welcomeImagePaths.isEmpty) {
      unawaited(_reloadWelcomeImage());
      return;
    }
    setState(() {
      _currentImage = _welcomeImagePaths[Random().nextInt(_welcomeImagePaths.length)];
    });
  }

  String _text({
    required String ru,
    required String en,
    required String fr,
    required String de,
    required String pt,
  }) {
    final code = Localizations.localeOf(context).languageCode;
    switch (code) {
      case 'en':
        return en;
      case 'fr':
        return fr;
      case 'de':
        return de;
      case 'pt':
        return pt;
      default:
        return ru;
    }
  }

  @override
  void dispose() {
    _welcomeImagesSub?.cancel();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _titleController,
                  enabled: _isEditingTitle,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: _isEditingTitle ? null : scheme.primary,
                  ),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onFieldSubmitted: (newValue) {
                    _saveDiaryTitle(newValue);
                    setState(() {
                      _isEditingTitle = false;
                    });
                  },
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final side = min(constraints.maxWidth, constraints.maxHeight);
                      return Center(
                        child: GestureDetector(
                          onTap: _selectRandomImage,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              width: side,
                              height: side,
                              child: _currentImage.isEmpty
                                  ? const Center(child: CircularProgressIndicator())
                                  : Image.asset(
                                      _currentImage,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                  onPressed: () async {
                          final entry = await Navigator.push<EmotionEntry>(
                      context,
                      MaterialPageRoute(
                              builder: (context) => const AddEntryScreen(
                                diaryKind: EmotionDiaryKind.positive,
                              ),
                      ),
                    );
                          if (entry != null) {
                            await EmotionProvider.addEntry(entry);
                          }
                    if (context.mounted) {
                      final historyScreen = context.findAncestorStateOfType<_HistoryScreenState>();
                      if (historyScreen != null) {
                        historyScreen._loadEntries();
                      }
                    }
                  },
                        child: Text(_text(
                          ru: 'Добавить положительную запись',
                          en: 'Add positive entry',
                          fr: 'Ajouter une entrée positive',
                          de: 'Positiven Eintrag hinzufügen',
                          pt: 'Adicionar registro positivo',
                        )),
                      ),
                    ),
                    const SizedBox(width: 12),
                Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final entry = await Navigator.push<EmotionEntry>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddEntryScreen(
                                diaryKind: EmotionDiaryKind.negative,
                              ),
                            ),
                          );
                          if (entry != null) {
                            await EmotionProvider.addEntry(entry);
                          }
                          if (context.mounted) {
                            final historyScreen = context.findAncestorStateOfType<_HistoryScreenState>();
                            if (historyScreen != null) {
                              historyScreen._loadEntries();
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.secondaryContainer,
                          foregroundColor: scheme.onSecondaryContainer,
                        ),
                        child: Text(_text(
                          ru: 'Добавить негативную запись',
                          en: 'Add negative entry',
                          fr: 'Ajouter une entrée négative',
                          de: 'Negativen Eintrag hinzufügen',
                          pt: 'Adicionar registro negativo',
                        )),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Icon(_isEditingTitle ? Icons.check : Icons.edit),
                onPressed: () {
                  setState(() {
                    _isEditingTitle = !_isEditingTitle;
                  });
                  if (!_isEditingTitle) {
                    _saveDiaryTitle(_titleController.text);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddEntryScreen extends StatefulWidget {
  final EmotionDiaryKind diaryKind;
  final EmotionEntry? initialEntry;

  const AddEntryScreen({
    super.key,
    this.diaryKind = EmotionDiaryKind.positive,
    this.initialEntry,
  });

  bool get isEditing => initialEntry != null;

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  /// Палитра для каталогов позитивных/негативных эмоций: базовые Material-цвета + оттенки.
  static const List<Color> _catalogEmotionPalette = <Color>[
    // Красный, розовый
    Color(0xFFB71C1C),
    Color(0xFFD32F2F),
    Colors.red,
    Color(0xFFFF5252),
    Color(0xFFFF8A80),
    Color(0xFFC2185B),
    Colors.pink,
    Color(0xFFEC407A),
    Color(0xFFF48FB1),
    Color(0xFFFF80AB),
    // Оранжевый, янтарь, жёлтый
    Color(0xFFE65100),
    Colors.deepOrange,
    Colors.orange,
    Color(0xFFFFB74D),
    Colors.amber,
    Color(0xFFFFEE58),
    Colors.yellow,
    Color(0xFFFFF59D),
    // Зелёный, лайм
    Color(0xFF1B5E20),
    Color(0xFF388E3C),
    Colors.green,
    Color(0xFF81C784),
    Color(0xFFA5D6A7),
    Colors.lightGreen,
    Colors.lime,
    Color(0xFFCDDC39),
    // Бирюзовый, циан
    Color(0xFF006064),
    Color(0xFF00897B),
    Colors.teal,
    Color(0xFF4DB6AC),
    Colors.cyan,
    Color(0xFF4DD0E1),
    Color(0xFFB2EBF2),
    // Синий, индиго
    Color(0xFF0D47A1),
    Color(0xFF1565C0),
    Colors.blue,
    Color(0xFF64B5F6),
    Color(0xFF90CAF9),
    Colors.lightBlue,
    Color(0xFF283593),
    Colors.indigo,
    Color(0xFF7986CB),
    // Фиолетовый
    Color(0xFF4A148C),
    Color(0xFF6A1B9A),
    Colors.deepPurple,
    Colors.purple,
    Color(0xFFBA68C8),
    Color(0xFFE1BEE7),
    // Коричневый, сине-серый, серый
    Color(0xFF3E2723),
    Colors.brown,
    Color(0xFFA1887F),
    Color(0xFF37474F),
    Color(0xFF546E7A),
    Colors.blueGrey,
    Colors.grey,
    Color(0xFFBDBDBD),
    Color(0xFFE0E0E0),
  ];

  final _formKey = GlobalKey<FormState>();
  String _selectedSource = EmotionSources.friends;
  final _noteController = TextEditingController();
  final _negativeMergedController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<File> _images = [];
  List<CatalogNegativeEmotion> _negativeCatalog = [];
  String? _selectedNegativeEmotionId;
  bool _negativeCatalogLoading = false;

  List<CatalogPositiveEmotion> _positiveCatalog = [];
  String? _selectedPositiveEmotionId;
  bool _positiveCatalogLoading = false;

  bool get _isNegative => widget.diaryKind == EmotionDiaryKind.negative;

  /// Редактирование старой позитивной записи без поля `emotion` (только `source`).
  bool get _isLegacyPositiveEdit =>
      widget.isEditing &&
      widget.initialEntry != null &&
      widget.initialEntry!.isPositive &&
      (widget.initialEntry!.emotion == null || widget.initialEntry!.emotion!.trim().isEmpty);

  static String _mergedTextFromNegativeEntry(EmotionEntry e) {
    final s = e.source.trim();
    final n = e.note.trim();
    if (s.isNotEmpty && n.isNotEmpty) return '$s\n$n';
    if (s.isNotEmpty) return s;
    return n;
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialEntry;
    if (initial != null) {
      _selectedDate = initial.date;
      _images = initial.imagePaths?.map((path) => File(path)).toList() ?? [];
      if (initial.isNegative) {
        _negativeMergedController.text = _mergedTextFromNegativeEntry(initial);
      } else {
        _noteController.text = initial.note;
        _selectedSource = EmotionSources.normalizeKey(initial.source);
      }
    }
    if (_isNegative) {
      _loadNegativeCatalog(widget.initialEntry);
    } else {
      _loadPositiveCatalog(widget.initialEntry);
    }
  }

  Future<void> _loadNegativeCatalog(EmotionEntry? initial) async {
    setState(() => _negativeCatalogLoading = true);
    final list = await NegativeEmotionCatalog.load();
    if (!mounted) return;
      setState(() {
      _negativeCatalog = list;
      if (initial != null && initial.isNegative) {
        final name = initial.emotion?.trim() ?? '';
        CatalogNegativeEmotion? match;
        for (final e in list) {
          if (e.name == name) {
            match = e;
            break;
          }
        }
        _selectedNegativeEmotionId = match?.id ?? (list.isNotEmpty ? list.first.id : null);
      } else {
        _selectedNegativeEmotionId = list.isNotEmpty ? list.first.id : null;
      }
      _negativeCatalogLoading = false;
    });
  }

  Future<void> _loadPositiveCatalog(EmotionEntry? initial) async {
    setState(() => _positiveCatalogLoading = true);
    final list = await PositiveEmotionCatalog.load();
    if (!mounted) return;
    setState(() {
      _positiveCatalog = list;
      if (initial != null && initial.isPositive) {
        final name = initial.emotion?.trim() ?? '';
        CatalogPositiveEmotion? match;
        if (name.isNotEmpty) {
          for (final e in list) {
            if (e.name == name) {
              match = e;
              break;
            }
          }
        }
        if (match != null) {
          _selectedPositiveEmotionId = match.id;
        } else if (_isLegacyPositiveEdit) {
          _selectedPositiveEmotionId = null;
        } else {
          _selectedPositiveEmotionId = list.isNotEmpty ? list.first.id : null;
        }
      } else {
        _selectedPositiveEmotionId = list.isNotEmpty ? list.first.id : null;
      }
      _positiveCatalogLoading = false;
    });
  }

  Future<void> _showAddNegativeEmotionDialog() async {
    final controller = TextEditingController();
    Color selectedColor = _catalogEmotionPalette.first;
    void disposeCtrlSoon() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (routeContext) {
        final scheme = Theme.of(routeContext).colorScheme;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final l10nDlg = AppLocalizations.of(dialogCtx);
            return AlertDialog(
              title: Text(_text(
                ru: 'Новая эмоция',
                en: 'New emotion',
                fr: 'Nouvelle émotion',
                de: 'Neue Emotion',
                pt: 'Nova emoção',
              )),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: _text(
                          ru: 'Название эмоции',
                          en: 'Emotion name',
                          fr: 'Nom de l’émotion',
                          de: 'Name der Emotion',
                          pt: 'Nome da emoção',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _text(
                        ru: 'Цвет',
                        en: 'Color',
                        fr: 'Couleur',
                        de: 'Farbe',
                        pt: 'Cor',
                      ),
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _catalogEmotionPalette.map((color) {
                        final isSelected = selectedColor.value == color.value;
                        return InkWell(
                          onTap: () => setDialogState(() => selectedColor = color),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? scheme.onSurface : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: Text(l10nDlg.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;
                    Navigator.of(dialogCtx).pop(true);
                  },
                  child: Text(l10nDlg.save),
                ),
              ],
            );
          },
        );
      },
    );

    final name = controller.text.trim();
    disposeCtrlSoon();

    if (saved != true || name.isEmpty) {
      return;
    }
    final created = CatalogNegativeEmotion(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      colorValue: selectedColor.value,
    );
    await NegativeEmotionCatalog.add(created);
    await _loadNegativeCatalog(null);
    if (!mounted) return;
    setState(() => _selectedNegativeEmotionId = created.id);
  }

  void _onTrashNegativeEmotionTap() {
    final id = _selectedNegativeEmotionId;
    if (id == null || _negativeCatalog.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_text(
            ru: 'Сначала выберите эмоцию или добавьте её через +',
            en: 'Select an emotion first, or add one with +',
            fr: 'Sélectionnez d’abord une émotion ou ajoutez-en une avec +',
            de: 'Wählen Sie zuerst eine Emotion oder fügen Sie eine mit + hinzu',
            pt: 'Selecione uma emoção ou adicione uma com +',
          )),
        ),
      );
      return;
    }
    CatalogNegativeEmotion? target;
    for (final e in _negativeCatalog) {
      if (e.id == id) {
        target = e;
        break;
      }
    }
    if (target == null) return;
    _confirmDeleteNegativeEmotion(target);
  }

  Future<void> _confirmDeleteNegativeEmotion(CatalogNegativeEmotion emotion) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final l10nDlg = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(_text(
            ru: 'Удалить эмоцию?',
            en: 'Delete emotion?',
            fr: 'Supprimer l’émotion ?',
            de: 'Emotion löschen?',
            pt: 'Excluir emoção?',
          )),
          content: Text('«${emotion.name}»'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10nDlg.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                _text(
                  ru: 'Удалить',
                  en: 'Delete',
                  fr: 'Supprimer',
                  de: 'Löschen',
                  pt: 'Excluir',
                ),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true) return;
    await NegativeEmotionCatalog.removeById(emotion.id);
    await _loadNegativeCatalog(null);
  }

  Future<void> _showAddPositiveEmotionDialog() async {
    final controller = TextEditingController();
    Color selectedColor = _catalogEmotionPalette.first;
    void disposeCtrlSoon() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (routeContext) {
        final scheme = Theme.of(routeContext).colorScheme;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final l10nDlg = AppLocalizations.of(dialogCtx);
            return AlertDialog(
              title: Text(_text(
                ru: 'Новая эмоция',
                en: 'New emotion',
                fr: 'Nouvelle émotion',
                de: 'Neue Emotion',
                pt: 'Nova emoção',
              )),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: _text(
                          ru: 'Название эмоции',
                          en: 'Emotion name',
                          fr: 'Nom de l’émotion',
                          de: 'Name der Emotion',
                          pt: 'Nome da emoção',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _text(
                        ru: 'Цвет',
                        en: 'Color',
                        fr: 'Couleur',
                        de: 'Farbe',
                        pt: 'Cor',
                      ),
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _catalogEmotionPalette.map((color) {
                        final isSelected = selectedColor.value == color.value;
                        return InkWell(
                          onTap: () => setDialogState(() => selectedColor = color),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? scheme.onSurface : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: Text(l10nDlg.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;
                    Navigator.of(dialogCtx).pop(true);
                  },
                  child: Text(l10nDlg.save),
                ),
              ],
            );
          },
        );
      },
    );

    final name = controller.text.trim();
    disposeCtrlSoon();

    if (saved != true || name.isEmpty) {
      return;
    }
    final created = CatalogPositiveEmotion(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      colorValue: selectedColor.value,
    );
    await PositiveEmotionCatalog.add(created);
    await _loadPositiveCatalog(null);
    if (!mounted) return;
    setState(() => _selectedPositiveEmotionId = created.id);
  }

  void _onTrashPositiveEmotionTap() {
    final id = _selectedPositiveEmotionId;
    if (id == null || _positiveCatalog.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_text(
            ru: 'Сначала выберите эмоцию или добавьте её через +',
            en: 'Select an emotion first, or add one with +',
            fr: 'Sélectionnez d’abord une émotion ou ajoutez-en une avec +',
            de: 'Wählen Sie zuerst eine Emotion oder fügen Sie eine mit + hinzu',
            pt: 'Selecione uma emoção ou adicione uma com +',
          )),
        ),
      );
      return;
    }
    CatalogPositiveEmotion? target;
    for (final e in _positiveCatalog) {
      if (e.id == id) {
        target = e;
        break;
      }
    }
    if (target == null) return;
    _confirmDeletePositiveEmotion(target);
  }

  Future<void> _confirmDeletePositiveEmotion(CatalogPositiveEmotion emotion) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final l10nDlg = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(_text(
            ru: 'Удалить эмоцию?',
            en: 'Delete emotion?',
            fr: 'Supprimer l’émotion ?',
            de: 'Emotion löschen?',
            pt: 'Excluir emoção?',
          )),
          content: Text('«${emotion.name}»'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10nDlg.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                _text(
                  ru: 'Удалить',
                  en: 'Delete',
                  fr: 'Supprimer',
                  de: 'Löschen',
                  pt: 'Excluir',
                ),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true) return;
    await PositiveEmotionCatalog.removeById(emotion.id);
    await _loadPositiveCatalog(null);
  }

  String _text({
    required String ru,
    required String en,
    required String fr,
    required String de,
    required String pt,
  }) {
    final code = Localizations.localeOf(context).languageCode;
    switch (code) {
      case 'en':
        return en;
      case 'fr':
        return fr;
      case 'de':
        return de;
      case 'pt':
        return pt;
      default:
        return ru;
    }
  }

  String _noteFieldEmotionPrerequisiteMessage() {
    return _text(
      ru: 'Чтобы создать запись, сначала создайте и выберите эмоцию.',
      en: 'To create an entry, first add and select an emotion.',
      fr: 'Pour créer une entrée, créez d’abord une émotion et sélectionnez-la.',
      de: 'Um einen Eintrag zu erstellen, legen Sie zuerst eine Emotion an und wählen Sie sie.',
      pt: 'Para criar um registro, crie e selecione uma emoção primeiro.',
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isEmpty) return;
    final List<File> persisted = [];
    for (final xFile in images) {
      try {
        persisted.add(await _persistPickedPhoto(xFile));
      } catch (e, st) {
        debugPrint('emotion_diary: persist photo failed: $e $st');
      }
    }
    if (persisted.isEmpty) return;
    if (!mounted) return;
    setState(() => _images.addAll(persisted));
  }

  @override
  void dispose() {
    _noteController.dispose();
    _negativeMergedController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (_isNegative && _negativeCatalog.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_text(
              ru: 'Сначала добавьте эмоции через +.',
              en: 'Add emotions with + first.',
              fr: 'Ajoutez d’abord des émotions avec +.',
              de: 'Fügen Sie zuerst Emotionen mit + hinzu.',
              pt: 'Adicione emoções com + primeiro.',
            )),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    if (!_isNegative && _positiveCatalog.isEmpty && !_isLegacyPositiveEdit) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_text(
              ru: 'Сначала добавьте эмоции через +.',
              en: 'Add emotions with + first.',
              fr: 'Ajoutez d’abord des émotions avec +.',
              de: 'Fügen Sie zuerst Emotionen mit + hinzu.',
              pt: 'Adicione emoções com + primeiro.',
            )),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    try {
      final entry = _isNegative
          ? () {
              final id = _selectedNegativeEmotionId;
              if (id == null || _negativeCatalog.isEmpty) {
                throw StateError('negative_emotion_catalog');
              }
              final emotion = _negativeCatalog.firstWhere((e) => e.id == id);
              return EmotionEntry(
          date: _selectedDate,
                kind: EmotionDiaryKind.negative,
                source: '',
                createdAt: widget.isEditing ? widget.initialEntry?.createdAt : DateTime.now(),
                emotion: emotion.name,
                emotionColorValue: emotion.colorValue,
                sourceColorValue: null,
                note: _negativeMergedController.text.trim(),
                imagePaths: _images.map((file) => file.path).toList(),
              );
            }()
          : () {
              final legacyKeep = _isLegacyPositiveEdit &&
                  (_selectedPositiveEmotionId == null || _positiveCatalog.isEmpty);
              if (legacyKeep) {
                return EmotionEntry(
                  date: _selectedDate,
                  kind: EmotionDiaryKind.positive,
          source: _selectedSource,
                  createdAt: widget.isEditing ? widget.initialEntry?.createdAt : DateTime.now(),
          note: _noteController.text.trim(),
          imagePaths: _images.map((file) => file.path).toList(),
        );
              }
              if (_positiveCatalog.isEmpty) {
                throw StateError('positive_emotion_catalog');
              }
              final id = _selectedPositiveEmotionId;
              if (id == null) {
                throw StateError('positive_emotion_catalog');
              }
              final emotion = _positiveCatalog.firstWhere((e) => e.id == id);
              return EmotionEntry(
                date: _selectedDate,
                kind: EmotionDiaryKind.positive,
                source: '',
                createdAt: widget.isEditing ? widget.initialEntry?.createdAt : DateTime.now(),
                emotion: emotion.name,
                emotionColorValue: emotion.colorValue,
                note: _noteController.text.trim(),
                imagePaths: _images.map((file) => file.path).toList(),
              );
            }();
        if (mounted) {
        Navigator.pop(context, entry);
        }
      } catch (e) {
        if (mounted) {
        final l10n = AppLocalizations.of(context);
        final code = e is StateError ? e.message : '';
        final isNegCat = code == 'negative_emotion_catalog';
        final isPosCat = code == 'positive_emotion_catalog';
        final msg = isNegCat || isPosCat
            ? _text(
                ru: 'Выберите эмоцию из списка или добавьте через +.',
                en: 'Pick an emotion from the list or add one with +.',
                fr: 'Choisissez une émotion dans la liste ou ajoutez-en une avec +.',
                de: 'Wählen Sie eine Emotion aus der Liste oder fügen Sie eine mit + hinzu.',
                pt: 'Escolha uma emoção na lista ou adicione com +.',
              )
            : '${l10n.saveErrorPrefix}$e';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
            content: Text(msg),
              backgroundColor: Colors.red,
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primary;
    final title = widget.isEditing ? l10n.editEntryTitle : l10n.newEntryTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Opacity(
                          opacity: 0.14,
                          child: Text(
                            _isNegative ? '🫤' : '😊',
                            style: const TextStyle(fontSize: 132, height: 1),
                          ),
                        ),
                      ),
                    ),
                  ),
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _selectedDate,
                    selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = selectedDay;
                  });
                },
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek: StartingDayOfWeek.monday,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekendStyle: TextStyle(color: Colors.red),
                    ),
                calendarStyle: const CalendarStyle(
                  weekendTextStyle: TextStyle(color: Colors.red),
                ),
                    locale: calendarLocaleTag(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_isNegative) ...[
                if (_negativeCatalogLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _negativeCatalog.isEmpty
                            ? Material(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  onTap: _showAddNegativeEmotionDialog,
                                  borderRadius: BorderRadius.circular(14),
                                  child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: _text(
                                    ru: 'Эмоция',
                                    en: 'Emotion',
                                    fr: 'Émotion',
                                    de: 'Emotion',
                                    pt: 'Emoção',
                                  ),
                                  filled: true,
                                  fillColor: scheme.surfaceContainerHighest,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.55)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.45)),
                                  ),
                                ),
                        child: Text(
                                  _text(
                                    ru: 'Нажмите +, чтобы создать эмоцию.',
                                    en: 'Tap + to create an emotion.',
                                    fr: 'Appuyez sur + pour créer une émotion.',
                                    de: 'Tippen Sie auf +, um eine Emotion zu erstellen.',
                                    pt: 'Toque em + para criar uma emoção.',
                                  ),
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                              ),
                                ),
                              )
                            : DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: _selectedNegativeEmotionId != null &&
                                        _negativeCatalog.any((e) => e.id == _selectedNegativeEmotionId)
                                    ? _selectedNegativeEmotionId
                                    : _negativeCatalog.first.id,
                                decoration: InputDecoration(
                                  labelText: _text(
                                    ru: 'Эмоция',
                                    en: 'Emotion',
                                    fr: 'Émotion',
                                    de: 'Emotion',
                                    pt: 'Emoção',
                                  ),
                                  filled: true,
                                  fillColor: scheme.surfaceContainerHighest,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.55)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.45)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: accent.withOpacity(0.95), width: 2),
                                  ),
                                ),
                                items: _negativeCatalog.map((e) {
                                  return DropdownMenuItem<String>(
                                    value: e.id,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            color: Color(e.colorValue),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Flexible(
                                          child: Text(
                                            e.name,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newId) {
                                  setState(() => _selectedNegativeEmotionId = newId);
                                },
                                validator: (value) {
                                  if (value == null || _negativeCatalog.isEmpty) {
                                    return _text(
                                      ru: 'Выберите эмоцию из списка',
                                      en: 'Pick an emotion from the list',
                                      fr: 'Choisissez une émotion dans la liste',
                                      de: 'Wählen Sie eine Emotion aus der Liste',
                                      pt: 'Escolha uma emoção na lista',
                                    );
                                  }
                                  return null;
                                },
                              ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _onTrashNegativeEmotionTap,
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 52,
                            height: 56,
                            child: Icon(
                              Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _showAddNegativeEmotionDialog,
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 52,
                            height: 56,
                            child: Icon(
                              Icons.add,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_negativeCatalog.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _negativeCatalog.map((emotion) {
                        final isSelected = emotion.id == _selectedNegativeEmotionId;
                        return ChoiceChip(
                          label: Text(emotion.name),
                          selected: isSelected,
                          avatar: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Color(emotion.colorValue),
                              shape: BoxShape.circle,
                            ),
                          ),
                          onSelected: (_) {
                            setState(() => _selectedNegativeEmotionId = emotion.id);
                          },
                        );
                      }).toList(),
                    ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _negativeMergedController,
                  readOnly: _negativeCatalog.isEmpty,
                  decoration: _negativeCatalog.isEmpty
                      ? InputDecoration(
                          label: Text(
                            _noteFieldEmotionPrerequisiteMessage(),
                            style: const TextStyle(color: Colors.orange),
                            maxLines: 4,
                            softWrap: true,
                          ),
                          floatingLabelStyle: const TextStyle(color: Colors.orange),
                          border: const OutlineInputBorder(),
                        )
                      : InputDecoration(
                          labelText: l10n.noteLabel,
                          border: const OutlineInputBorder(),
                          hintText: l10n.noteHint,
                        ),
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  validator: (value) {
                    if (_negativeCatalog.isEmpty) return null;
                    if (value == null || value.isEmpty) {
                      return l10n.noteValidationRequired;
                    }
                    return null;
                  },
                ),
              ] else ...[
                if (_positiveCatalogLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _positiveCatalog.isEmpty && !_isLegacyPositiveEdit
                            ? Material(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  onTap: _showAddPositiveEmotionDialog,
                                  borderRadius: BorderRadius.circular(14),
                                  child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: _text(
                                    ru: 'Эмоция',
                                    en: 'Emotion',
                                    fr: 'Émotion',
                                    de: 'Emotion',
                                    pt: 'Emoção',
                                  ),
                                  filled: true,
                                  fillColor: scheme.surfaceContainerHighest,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.55)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.45)),
                                  ),
                                ),
                                child: Text(
                                  _text(
                                    ru: 'Нажмите +, чтобы создать эмоцию.',
                                    en: 'Tap + to create an emotion.',
                                    fr: 'Appuyez sur + pour créer une émotion.',
                                    de: 'Tippen Sie auf +, um eine Emotion zu erstellen.',
                                    pt: 'Toque em + para criar uma emoção.',
                                  ),
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                              ),
                                ),
                              )
                            : DropdownButtonFormField<String?>(
                                isExpanded: true,
                                value: () {
                                  if (_selectedPositiveEmotionId != null &&
                                      _positiveCatalog.any((e) => e.id == _selectedPositiveEmotionId)) {
                                    return _selectedPositiveEmotionId;
                                  }
                                  if (_isLegacyPositiveEdit) return null;
                                  return _positiveCatalog.isNotEmpty ? _positiveCatalog.first.id : null;
                                }(),
                                decoration: InputDecoration(
                                  labelText: _text(
                                    ru: 'Эмоция',
                                    en: 'Emotion',
                                    fr: 'Émotion',
                                    de: 'Emotion',
                                    pt: 'Emoção',
                                  ),
                                  filled: true,
                                  fillColor: scheme.surfaceContainerHighest,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.55)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.45)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: accent.withOpacity(0.95), width: 2),
                                  ),
                                ),
                                items: [
                                  if (_isLegacyPositiveEdit)
                                    DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text(
                                        _text(
                                          ru: 'Как в записи (старый формат)',
                                          en: 'As saved (legacy format)',
                                          fr: 'Comme enregistré (ancien format)',
                                          de: 'Wie gespeichert (altes Format)',
                                          pt: 'Como salvo (formato antigo)',
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ..._positiveCatalog.map((e) {
                                    return DropdownMenuItem<String?>(
                                      value: e.id,
                    child: Row(
                      children: [
                        Container(
                                            width: 18,
                                            height: 18,
                          decoration: BoxDecoration(
                                              color: Color(e.colorValue),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                                          Flexible(
                                            child: Text(
                                              e.name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                      ],
                    ),
                  );
                                  }),
                                ],
                                onChanged: (String? newId) {
                                  setState(() => _selectedPositiveEmotionId = newId);
                                },
                                validator: (value) {
                                  if (_positiveCatalog.isEmpty) {
                                    if (_isLegacyPositiveEdit) return null;
                                    return _text(
                                      ru: 'Нажмите +, чтобы создать эмоцию.',
                                      en: 'Tap + to create an emotion.',
                                      fr: 'Appuyez sur + pour créer une émotion.',
                                      de: 'Tippen Sie auf +, um eine Emotion zu erstellen.',
                                      pt: 'Toque em + para criar uma emoção.',
                                    );
                                  }
                                  if (!_isLegacyPositiveEdit && value == null) {
                                    return _text(
                                      ru: 'Выберите эмоцию из списка',
                                      en: 'Pick an emotion from the list',
                                      fr: 'Choisissez une émotion dans la liste',
                                      de: 'Wählen Sie eine Emotion aus der Liste',
                                      pt: 'Escolha uma emoção na lista',
                                    );
                                  }
                                  return null;
                                },
                              ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _onTrashPositiveEmotionTap,
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 52,
                            height: 56,
                            child: Icon(
                              Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _showAddPositiveEmotionDialog,
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 52,
                            height: 56,
                            child: Icon(
                              Icons.add,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_positiveCatalog.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _positiveCatalog.map((emotion) {
                        final isSelected = emotion.id == _selectedPositiveEmotionId;
                        return ChoiceChip(
                          label: Text(emotion.name),
                          selected: isSelected,
                          avatar: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Color(emotion.colorValue),
                              shape: BoxShape.circle,
                            ),
                          ),
                          onSelected: (_) {
                            setState(() => _selectedPositiveEmotionId = emotion.id);
                          },
                        );
                      }).toList(),
                    ),
                ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                readOnly: _positiveCatalog.isEmpty && !_isLegacyPositiveEdit,
                decoration: _isLegacyPositiveEdit
                    ? InputDecoration(
                        labelText: l10n.noteLabel,
                        border: const OutlineInputBorder(),
                        hintText: l10n.noteHint,
                      )
                    : (_positiveCatalog.isEmpty
                        ? InputDecoration(
                            label: Text(
                              _noteFieldEmotionPrerequisiteMessage(),
                              style: const TextStyle(color: Colors.orange),
                              maxLines: 4,
                              softWrap: true,
                            ),
                            floatingLabelStyle: const TextStyle(color: Colors.orange),
                            border: const OutlineInputBorder(),
                          )
                        : InputDecoration(
                            labelText: l10n.noteLabel,
                            border: const OutlineInputBorder(),
                            hintText: l10n.noteHint,
                          )),
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                validator: (value) {
                  if (_positiveCatalog.isEmpty && !_isLegacyPositiveEdit) return null;
                  if (value == null || value.isEmpty) {
                    return l10n.noteValidationRequired;
                  }
                  return null;
                },
              ),
              ],
              const SizedBox(height: 16),
              if (_images.isNotEmpty) ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _images[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                final removed = _images[index];
                                setState(() {
                                  _images.removeAt(index);
                                });
                                await _deletePersistedDiaryPhotoIfOwned(removed);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo),
                  label: Text(_images.isEmpty ? l10n.addPhoto : l10n.addMorePhotos),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveEntry,
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum HistoryDiaryFilter { negative, mixed, positive }

/// Круглые значки − / + для фильтра истории (вместо «пальцев»).
class _HistoryFilterGlyph extends StatelessWidget {
  final String symbol;
  final bool active;
  final Color accent;

  const _HistoryFilterGlyph({
    required this.symbol,
    required this.active,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = active ? 1.0 : 0.38;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: accent.withOpacity(opacity),
          width: 2,
        ),
        color: accent.withOpacity(active ? 0.16 : 0.06),
      ),
      child: Text(
        symbol,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: symbol == '+' ? 22 : 20,
          fontWeight: FontWeight.w700,
          height: 1,
          letterSpacing: 0,
          color: accent.withOpacity(opacity),
        ),
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  List<EmotionEntry> _entries = [];
  Map<DateTime, EmotionEntry> _dominantEntries = {};
  Map<DateTime, int> _moods = {};
  MoodEntry? _selectedDateMood;
  HistoryDiaryFilter _historyFilter = HistoryDiaryFilter.mixed;
  bool _showCalendar = false;
  static const String _historyFilterKey = 'history_diary_filter';

  static double _doubleForHistoryFilter(HistoryDiaryFilter f) {
    return switch (f) {
      HistoryDiaryFilter.negative => 0.0,
      HistoryDiaryFilter.mixed => 1.0,
      HistoryDiaryFilter.positive => 2.0,
    };
  }

  static HistoryDiaryFilter _historyFilterForDouble(double d) {
    final i = d.round().clamp(0, 2);
    return switch (i) {
      0 => HistoryDiaryFilter.negative,
      1 => HistoryDiaryFilter.mixed,
      2 => HistoryDiaryFilter.positive,
      _ => HistoryDiaryFilter.mixed,
    };
  }

  late AnimationController _filterSliderController;
  double _filterAnimFrom = 1.0;
  double _filterAnimTo = 1.0;
  bool _filterSliderDragging = false;
  double _filterDragValue = 1.0;

  double get _filterSliderDisplayValue {
    if (_filterSliderDragging) {
      return _filterDragValue.clamp(0.0, 2.0);
    }
    final t = Curves.easeOutCubic.transform(_filterSliderController.value);
    return _filterAnimFrom + (_filterAnimTo - _filterAnimFrom) * t;
  }

  @override
  void initState() {
    super.initState();
    _filterSliderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(() {
        if (mounted) setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _filterAnimFrom = _filterAnimTo;
        }
      });
    _restoreHistoryFilter();
    _loadSelectedDateMood();
  }

  Future<void> _restoreHistoryFilter() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyFilterKey);
    final restored = switch (raw) {
      'negative' => HistoryDiaryFilter.negative,
      'positive' => HistoryDiaryFilter.positive,
      _ => HistoryDiaryFilter.mixed,
    };
    if (!mounted) return;
    final v = _doubleForHistoryFilter(restored);
    setState(() {
      _historyFilter = restored;
      _filterAnimFrom = v;
      _filterAnimTo = v;
    });
    _filterSliderController.value = 1.0;
    await _loadEntries();
  }

  @override
  void dispose() {
    _filterSliderController.dispose();
    super.dispose();
  }

  void _onHistoryFilterSliderStart() {
    _filterSliderController.stop();
    final startVal = _filterSliderDisplayValue;
    setState(() {
      _filterSliderDragging = true;
      _filterDragValue = startVal;
    });
  }

  void _onHistoryFilterSliderChanged(double value) {
    setState(() {
      _filterDragValue = value.clamp(0.0, 2.0);
    });
  }

  void _onHistoryFilterSliderEnd(double released) {
    var v = released.clamp(0.0, 2.0);
    const stops = <double>[0, 1, 2];
    var snapped = stops.first;
    var bestD = 99.0;
    for (final s in stops) {
      final d = (v - s).abs();
      if (d < bestD) {
        bestD = d;
        snapped = s;
      }
    }
    final next = _historyFilterForDouble(snapped);
    setState(() {
      _filterSliderDragging = false;
      _filterAnimFrom = v;
      _filterAnimTo = snapped;
      _historyFilter = next;
    });
    unawaited(_saveHistoryFilter(next));
    unawaited(_loadEntries());
    _filterSliderController.forward(from: 0);
  }

  Future<void> _saveHistoryFilter(HistoryDiaryFilter filter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyFilterKey, filter.name);
  }

  Future<void> _loadSelectedDateMood() async {
    final mood = await MoodProvider.getMoodForDate(_selectedDate);
    setState(() {
      _selectedDateMood = mood;
    });
  }

  String _text({
    required String ru,
    required String en,
    required String fr,
    required String de,
    required String pt,
  }) {
    final code = Localizations.localeOf(context).languageCode;
    switch (code) {
      case 'en':
        return en;
      case 'fr':
        return fr;
      case 'de':
        return de;
      case 'pt':
        return pt;
      default:
        return ru;
    }
  }

  bool _matchesHistoryFilter(EmotionEntry entry) {
    switch (_historyFilter) {
      case HistoryDiaryFilter.positive:
        return entry.isPositive;
      case HistoryDiaryFilter.negative:
        return entry.isNegative;
      case HistoryDiaryFilter.mixed:
        return true;
    }
  }

  Future<void> _loadEntries() async {
    final entries = await EmotionProvider.getEntries();
    final moods = await MoodProvider.getMoods();
    final dominantEntries = <DateTime, EmotionEntry>{};
    final moodMap = <DateTime, int>{};
    
    for (var mood in moods) {
      moodMap[mood.date] = mood.mood;
    }
    
    final filteredEntries = entries.where(_matchesHistoryFilter).toList();
    final startRange = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endRange = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

    for (var day = startRange; day.isBefore(endRange.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
      final dayEntries = filteredEntries.where((entry) =>
        entry.date.year == day.year &&
        entry.date.month == day.month &&
        entry.date.day == day.day
      ).toList();
      if (dayEntries.isNotEmpty) {
        final Map<String, int> counts = {};
        final Map<String, EmotionEntry> sample = {};
        for (final entry in dayEntries) {
          final key = entry.statisticKey;
          counts[key] = (counts[key] ?? 0) + 1;
          sample[key] ??= entry;
        }
        final dominantKey = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
        dominantEntries[day] = sample[dominantKey]!;
      }
    }

    setState(() {
      _entries = filteredEntries.where((entry) => 
        entry.date.year == _selectedDate.year &&
        entry.date.month == _selectedDate.month &&
        entry.date.day == _selectedDate.day
      ).toList();
      _dominantEntries = dominantEntries;
      _moods = moodMap;
    });
  }

  Future<void> _deleteEntry(EmotionEntry entry) async {
    final l10n = AppLocalizations.of(context);
    // Первое подтверждение
    final bool? firstConfirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.deleteEntryTitle),
          content: Text(l10n.deleteEntryConfirm1),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(l10n.delete),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (firstConfirm == true) {
      // Второе подтверждение
      final bool? secondConfirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(l10n.confirmTitle),
            content: Text(l10n.deleteEntryConfirm2),
            actions: <Widget>[
              TextButton(
                child: Text(l10n.cancel),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text(l10n.deleteYes),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (secondConfirm == true) {
        await EmotionProvider.deleteEntry(entry);
        _loadEntries();
      }
    }
  }

  String _formatHistorySelectedDate() {
    final locale = calendarLocaleTag(context);
    return DateFormat.yMMMEd(locale).format(_selectedDate);
  }

  Future<void> _showMoodSelector() async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.selectMood),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(5, (index) {
                final mood = index + 1;
                return ListTile(
                  leading: Text(
                    _getMoodEmoji(mood),
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(_getMoodDescription(mood)),
                  onTap: () => Navigator.of(context).pop(mood),
                );
              }),
              const Divider(),
              ListTile(
                leading: const Text(
                  '❌',
                  style: TextStyle(fontSize: 24),
                ),
                title: Text(l10n.deleteMood),
                onTap: () => Navigator.of(context).pop(0),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      if (result == 0) {
        // Удаляем настроение
        final moods = await MoodProvider.getMoods();
        moods.removeWhere((mood) => 
          mood.date.year == _selectedDate.year &&
          mood.date.month == _selectedDate.month &&
          mood.date.day == _selectedDate.day
        );
        await MoodProvider._saveMoods(moods);
      } else {
        // Сохраняем новое настроение
        await MoodProvider.saveMood(_selectedDate, result);
      }
      await _loadSelectedDateMood();
      await _loadEntries();
    }
  }

  String _getMoodDescription(int mood) {
    final l10n = AppLocalizations.of(context);
    switch (mood) {
      case 1:
        return l10n.moodVeryBad;
      case 2:
        return l10n.moodBad;
      case 3:
        return l10n.moodNeutral;
      case 4:
        return l10n.moodGood;
      case 5:
        return l10n.moodGreat;
      default:
        return l10n.moodNotSelected;
    }
  }

  Future<void> _editEntry(EmotionEntry entry) async {
    final updatedEntry = await Navigator.push<EmotionEntry>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEntryScreen(
          diaryKind: entry.kind,
          initialEntry: entry,
        ),
      ),
    );

    if (updatedEntry != null) {
      await EmotionProvider.deleteEntry(entry);
      await EmotionProvider.addEntry(updatedEntry);
      _loadEntries();
    }
  }

  void _showPhotoViewer(List<String> imagePaths, int initialIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              PageView.builder(
                controller: PageController(initialPage: initialIndex),
                itemCount: imagePaths.length,
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(
                      File(imagePaths[index]),
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              if (imagePaths.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      imagePaths.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == initialIndex ? Colors.white : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = ThemeProvider.accentForScheme(scheme);
    final filterDisplay = _filterSliderDisplayValue;

    final moodBg = (_selectedDateMood != null && _selectedDateMood!.mood > 0)
        ? _getMoodColor(_selectedDateMood!.mood).withOpacity(0.12)
        : scheme.surfaceContainerHighest;

    Widget moodDisplay = Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Material(
                color: scheme.surfaceContainerHighest,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showCalendar = !_showCalendar;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_month_outlined, size: 22, color: accent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatHistorySelectedDate(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                                ),
                  ),
                ),
              ],
            ),
                        const SizedBox(height: 8),
                        Text(
                          _showCalendar
                              ? _text(
                                  ru: 'Выберите день в календаре ниже',
                                  en: 'Choose a day in the calendar below',
                                  fr: 'Choisissez un jour dans le calendrier ci-dessous',
                                  de: 'Wählen Sie unten einen Tag im Kalender',
                                  pt: 'Escolha um dia no calendário abaixo',
                                )
                              : _text(
                                  ru: 'Нажмите, чтобы открыть календарь и выбрать дату',
                                  en: 'Tap to open the calendar and pick a date',
                                  fr: 'Appuyez pour ouvrir le calendrier et choisir une date',
                                  de: 'Tippen, um den Kalender zu öffnen und ein Datum zu wählen',
                                  pt: 'Toque para abrir o calendário e escolher uma data',
                                ),
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: accent.withOpacity(0.22)),
            Expanded(
              child: Material(
                color: moodBg,
                child: InkWell(
                  onTap: () => _showMoodSelector(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                          _selectedDateMood != null && _selectedDateMood!.mood > 0
                              ? _getMoodEmoji(_selectedDateMood!.mood)
                              : '😐',
                          style: const TextStyle(fontSize: 44),
                        ),
                        const SizedBox(height: 6),
                Text(
                          _selectedDateMood != null && _selectedDateMood!.mood > 0
                              ? _getMoodDescription(_selectedDateMood!.mood)
                              : l10n.selectMood,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                    fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _text(
                            ru: 'Нажмите, чтобы выбрать настроение',
                            en: 'Tap to set your mood',
                            fr: 'Appuyez pour choisir votre humeur',
                            de: 'Tippen, um die Stimmung zu wählen',
                            pt: 'Toque para definir o humor',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: scheme.onSurfaceVariant,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                  ),
                ),
              ],
            ),
          ),
        );

    Widget calendarWidget = TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _selectedDate,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDate, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDate = selectedDay;
          _showCalendar = false;
        });
        _loadSelectedDateMood();
        _loadEntries();
      },
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.monday,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      calendarStyle: const CalendarStyle(
        weekendTextStyle: TextStyle(color: Colors.red),
        markerDecoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekendStyle: TextStyle(color: Colors.red),
      ),
      locale: calendarLocaleTag(context),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          final dominantEntry = _dominantEntries[date];
          final mood = _moods[date];
          
          return Stack(
            children: [
              if (dominantEntry != null)
                Positioned(
                  bottom: 1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dominantEntry.primaryColor(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              if (mood != null && mood > 0)
                Positioned(
                  top: 1,
                  child: _buildMoodEmoji(mood),
                ),
            ],
          );
        },
        dowBuilder: (context, day) => null,
      ),
    );

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Transform.translate(
                        offset: const Offset(8, 0),
                        child: _HistoryFilterGlyph(
                          symbol: '\u2212',
                          active: _historyFilter == HistoryDiaryFilter.negative,
                          accent: accent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: scheme.outlineVariant.withOpacity(0.55),
                            inactiveTrackColor: scheme.outlineVariant.withOpacity(0.55),
                            thumbColor: accent,
                            overlayColor: accent.withOpacity(0.18),
                          ),
                          child: Slider(
                            min: 0,
                            max: 2,
                            value: filterDisplay,
                            onChangeStart: (_) => _onHistoryFilterSliderStart(),
                            onChanged: _onHistoryFilterSliderChanged,
                            onChangeEnd: _onHistoryFilterSliderEnd,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Transform.translate(
                        offset: const Offset(-8, 0),
                        child: _HistoryFilterGlyph(
                          symbol: '+',
                          active: _historyFilter == HistoryDiaryFilter.positive,
                          accent: accent,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _text(
                          ru: 'Негативный',
                          en: 'Negative',
                          fr: 'Négatif',
                          de: 'Negativ',
                          pt: 'Negativo',
                        ),
                        style: TextStyle(
                          color: _historyFilter == HistoryDiaryFilter.negative
                              ? accent
                              : scheme.onSurfaceVariant,
                          fontWeight: _historyFilter == HistoryDiaryFilter.negative
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      Text(
                        _text(
                          ru: 'Дневник',
                          en: 'Diary',
                          fr: 'Journal',
                          de: 'Tagebuch',
                          pt: 'Diário',
                        ),
                        style: TextStyle(
                          color: _historyFilter == HistoryDiaryFilter.mixed
                              ? accent
                              : scheme.onSurfaceVariant,
                          fontWeight: _historyFilter == HistoryDiaryFilter.mixed
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      Text(
                        _text(
                          ru: 'Позитивный',
                          en: 'Positive',
                          fr: 'Positif',
                          de: 'Positiv',
                          pt: 'Positivo',
                        ),
                        style: TextStyle(
                          color: _historyFilter == HistoryDiaryFilter.positive
                              ? accent
                              : scheme.onSurfaceVariant,
                          fontWeight: _historyFilter == HistoryDiaryFilter.positive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: moodDisplay,
            ),
            if (_showCalendar) calendarWidget,
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _entries.isEmpty
                ? Center(
                    child: Text(AppLocalizations.of(context).noEntriesForSelectedDate),
                  )
                : Column(
                    children: _entries.map((entry) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          leading: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: entry.primaryColor(context),
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Text(entry.primaryLabel(context)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (entry.secondaryLabel(context) != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: entry.secondaryColor(context),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(entry.secondaryLabel(context)!),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ],
                              if (entry.note.trim().isNotEmpty) Text(entry.note),
                              Builder(
                                builder: (context) {
                                  final dt = entry.createdAt ?? entry.date;
                                  final t = DateFormat.Hm(calendarLocaleTag(context)).format(dt);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      t,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (entry.imagePaths != null && entry.imagePaths!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 4,
                                    mainAxisSpacing: 4,
                                  ),
                                  itemCount: entry.imagePaths!.length,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () => _showPhotoViewer(entry.imagePaths!, index),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.file(
                                          File(entry.imagePaths![index]),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editEntry(entry),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deleteEntry(entry),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodEmoji(int mood) {
    final emoji = _getMoodEmoji(mood);
    final color = _getMoodColor(mood);
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  String _getMoodEmoji(int mood) {
    switch (mood) {
      case 1:
        return '😢';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😊';
      default:
        return '😐';
    }
  }

  Color _getMoodColor(int mood) {
    switch (mood) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.red.shade300;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class StatisticsScreen extends StatefulWidget {
  final String currentTheme;
  final ValueChanged<bool>? onPageSwipeEnabled;
  const StatisticsScreen({
    super.key,
    required this.currentTheme,
    this.onPageSwipeEnabled,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

enum StatisticsDiaryMode {
  negative,
  mixed,
  positive,
  mood,
}

enum StatsPeriod {
  allTime,
  month,
  week,
}

enum ChartType {
  line,
  pie,
  byDay,
}

class StatisticsEntryBucket {
  final String label;
  final Color color;
  final int count;

  const StatisticsEntryBucket({
    required this.label,
    required this.color,
    required this.count,
  });
}

class StatisticsModeSelector extends StatefulWidget {
  final StatisticsDiaryMode value;
  final ValueChanged<StatisticsDiaryMode> onChanged;
  final Color accent;
  final Color inactiveColor;
  final Map<StatisticsDiaryMode, String> labels;
  final ValueChanged<bool>? onPageSwipeEnabled;

  const StatisticsModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.accent,
    required this.inactiveColor,
    required this.labels,
    this.onPageSwipeEnabled,
  });

  @override
  State<StatisticsModeSelector> createState() => _StatisticsModeSelectorState();
}

class _StatisticsModeSelectorState extends State<StatisticsModeSelector> {
  Offset? _dragVisualPoint;
  bool _isDragging = false;

  /// Треугольник позитивный — негативный — настроение; «дневник» — центроид.
  Map<StatisticsDiaryMode, Offset> _points(Size size) {
    const left = 30.0;
    final right = size.width - 30.0;
    final top = 10.0;
    final bottom = size.height - 10.0;
    final moodY = (top + bottom) / 2;
    final positive = Offset(left, top);
    final negative = Offset(left, bottom);
    final mood = Offset(right, moodY);
    final mixed = Offset(
      (positive.dx + negative.dx + mood.dx) / 3,
      (positive.dy + negative.dy + mood.dy) / 3,
    );
    return {
      StatisticsDiaryMode.positive: positive,
      StatisticsDiaryMode.negative: negative,
      StatisticsDiaryMode.mixed: mixed,
      StatisticsDiaryMode.mood: mood,
    };
  }

  static Offset _closestOnSegment(Offset a, Offset b, Offset p) {
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 < 1e-12) return a;
    var t = ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / len2;
    t = t.clamp(0.0, 1.0);
    return Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
  }

  Offset _projectTouchToBranch(Offset f, Size size) {
    final pts = _points(size);
    final positiveP = pts[StatisticsDiaryMode.positive]!;
    final negativeP = pts[StatisticsDiaryMode.negative]!;
    final moodP = pts[StatisticsDiaryMode.mood]!;
    final mixedP = pts[StatisticsDiaryMode.mixed]!;

    const mixedHitRadius = 28.0;
    if ((f - mixedP).distance <= mixedHitRadius) {
      return mixedP;
    }

    final segments = <(Offset, Offset)>[
      (positiveP, negativeP),
      (negativeP, moodP),
      (moodP, positiveP),
      (positiveP, mixedP),
      (negativeP, mixedP),
      (moodP, mixedP),
    ];

    double bestDist = double.infinity;
    Offset best = mixedP;
    for (final seg in segments) {
      final close = _closestOnSegment(seg.$1, seg.$2, f);
      final d = (f - close).distance;
      if (d < bestDist) {
        bestDist = d;
        best = close;
      }
    }
    return best;
  }

  StatisticsDiaryMode _modeFromTouch(Offset f, Size size, StatisticsDiaryMode current) {
    final pts = _points(size);
    final positiveP = pts[StatisticsDiaryMode.positive]!;
    final negativeP = pts[StatisticsDiaryMode.negative]!;
    final moodP = pts[StatisticsDiaryMode.mood]!;
    final mixedP = pts[StatisticsDiaryMode.mixed]!;

    const mixedHitRadius = 28.0;
    if ((f - mixedP).distance <= mixedHitRadius) {
      return StatisticsDiaryMode.mixed;
    }

    final segments = <(Offset, Offset, StatisticsDiaryMode, StatisticsDiaryMode)>[
      (positiveP, negativeP, StatisticsDiaryMode.positive, StatisticsDiaryMode.negative),
      (negativeP, moodP, StatisticsDiaryMode.negative, StatisticsDiaryMode.mood),
      (moodP, positiveP, StatisticsDiaryMode.mood, StatisticsDiaryMode.positive),
      (positiveP, mixedP, StatisticsDiaryMode.positive, StatisticsDiaryMode.mixed),
      (negativeP, mixedP, StatisticsDiaryMode.negative, StatisticsDiaryMode.mixed),
      (moodP, mixedP, StatisticsDiaryMode.mood, StatisticsDiaryMode.mixed),
    ];

    double bestDist = double.infinity;
    StatisticsDiaryMode best = current;
    for (final seg in segments) {
      final close = _closestOnSegment(seg.$1, seg.$2, f);
      final d = (f - close).distance;
      if (d < bestDist) {
        bestDist = d;
        final da = (close - seg.$1).distance;
        final db = (close - seg.$2).distance;
        best = da <= db ? seg.$3 : seg.$4;
      }
    }
    return best;
  }

  void _clearDrag() {
    if ((_dragVisualPoint != null || _isDragging) && mounted) {
      setState(() {
        _dragVisualPoint = null;
        _isDragging = false;
      });
      widget.onPageSwipeEnabled?.call(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const areaTop = 22.0;
        const areaHeight = 138.0;
        final size = Size(width, areaHeight);
        final points = _points(size);

        void handlePosition(Offset localPosition) {
          final adjusted = Offset(
            localPosition.dx.clamp(0.0, width),
            (localPosition.dy - areaTop).clamp(0.0, areaHeight),
          );
          final projected = _projectTouchToBranch(adjusted, size);
          final next = _modeFromTouch(adjusted, size, widget.value);
          setState(() {
            _dragVisualPoint = projected;
            _isDragging = true;
          });
          widget.onPageSwipeEnabled?.call(false);
          if (next != widget.value) widget.onChanged(next);
        }

        TextStyle labelStyle(StatisticsDiaryMode mode) => TextStyle(
              color: widget.value == mode ? widget.accent : widget.inactiveColor,
              fontWeight: widget.value == mode ? FontWeight.bold : FontWeight.w500,
              fontSize: 11.5,
              height: 1.15,
            );

        final p = points[StatisticsDiaryMode.positive]!;
        final m = points[StatisticsDiaryMode.mood]!;
        final c = points[StatisticsDiaryMode.mixed]!;
        final activePoint = _dragVisualPoint ?? points[widget.value]!;
        final mainRadius = _isDragging ? 15.0 : 14.0;
        final haloRadius = _isDragging ? 20.0 : 16.0;
        const bottomLabelBand = 52.0;

        return SizedBox(
          height: areaTop + areaHeight + bottomLabelBand,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (details) => handlePosition(details.localPosition),
            onPanUpdate: (details) => handlePosition(details.localPosition),
            onPanEnd: (_) => _clearDrag(),
            onPanCancel: _clearDrag,
            onTapDown: (details) => handlePosition(details.localPosition),
            onTapUp: (_) => _clearDrag(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: areaTop,
                  height: areaHeight,
                  child: CustomPaint(
                    painter: _StatisticsModeSelectorPainter(
                      points: points,
                      selectedMode: widget.value,
                      accent: widget.accent,
                      inactiveColor: widget.inactiveColor,
                    ),
                  ),
                ),
                ...points.entries.map((entry) {
                  final point = entry.value;
                  const r = 10.0;
                  return Positioned(
                    left: point.dx - r,
                    top: areaTop + point.dy - r,
                    child: Container(
                      width: r * 2,
                      height: r * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: widget.inactiveColor,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }),
                AnimatedPositioned(
                  duration: Duration(milliseconds: _isDragging ? 220 : 320),
                  curve: Curves.easeOutCubic,
                  left: activePoint.dx - haloRadius,
                  top: areaTop + activePoint.dy - haloRadius,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: _isDragging ? 260 : 340),
                    curve: Curves.easeOutCubic,
                    width: haloRadius * 2,
                    height: haloRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.accent.withOpacity(_isDragging ? 0.12 : 0.08),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accent.withOpacity(_isDragging ? 0.20 : 0.10),
                          blurRadius: _isDragging ? 18 : 10,
                          spreadRadius: _isDragging ? 2 : 0,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: _dragVisualPoint == null
                      ? const Duration(milliseconds: 220)
                      : const Duration(milliseconds: 90),
                  curve: Curves.easeOutCubic,
                  left: activePoint.dx - mainRadius,
                  top: areaTop + activePoint.dy - mainRadius,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: _isDragging ? 120 : 180),
                    curve: Curves.easeOutCubic,
                    width: mainRadius * 2,
                    height: mainRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.accent,
                      border: Border.all(color: widget.accent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accent.withOpacity(_isDragging ? 0.34 : 0.24),
                          blurRadius: _isDragging ? 16 : 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 2,
                  top: (areaTop + p.dy - 48).clamp(0.0, areaTop - 6),
                  width: (width * 0.52).clamp(120.0, width - 8),
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.labels[StatisticsDiaryMode.positive] ?? '',
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      style: labelStyle(StatisticsDiaryMode.positive),
                    ),
                  ),
                ),
                Positioned(
                  top: areaTop + areaHeight + 6,
                  left: 6,
                  width: width * 0.42,
                  child: Text(
                    widget.labels[StatisticsDiaryMode.negative] ?? '',
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle(StatisticsDiaryMode.negative),
                  ),
                ),
                Positioned(
                  left: (c.dx - 58).clamp(0.0, width - 116),
                  top: areaTop + c.dy + 14,
                  width: 116,
                  child: Text(
                    widget.labels[StatisticsDiaryMode.mixed] ?? '',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle(StatisticsDiaryMode.mixed),
                  ),
                ),
                Positioned(
                  right: 2,
                  top: (areaTop + m.dy - 30).clamp(areaTop + 2, areaTop + areaHeight - 36),
                  width: (width - m.dx + 8).clamp(88.0, width * 0.42),
                  child: Text(
                    widget.labels[StatisticsDiaryMode.mood] ?? '',
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle(StatisticsDiaryMode.mood),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatisticsModeSelectorPainter extends CustomPainter {
  final Map<StatisticsDiaryMode, Offset> points;
  final StatisticsDiaryMode selectedMode;
  final Color accent;
  final Color inactiveColor;

  const _StatisticsModeSelectorPainter({
    required this.points,
    required this.selectedMode,
    required this.accent,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final inactivePaint = Paint()
      ..color = inactiveColor.withOpacity(0.38)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final spokePaint = Paint()
      ..color = inactiveColor.withOpacity(0.22)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = accent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final positive = points[StatisticsDiaryMode.positive]!;
    final negative = points[StatisticsDiaryMode.negative]!;
    final mixed = points[StatisticsDiaryMode.mixed]!;
    final mood = points[StatisticsDiaryMode.mood]!;

    final negativeMoodExtraPaint = Paint()
      ..color = inactiveColor.withOpacity(0.22)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Периметр треугольника: путь между тремя режимами.
    canvas.drawLine(positive, negative, inactivePaint);
    canvas.drawLine(mood, positive, inactivePaint);
    // Дополнительная «грань» негативный — настроение (контур + усиленная подложка).
    canvas.drawLine(negative, mood, negativeMoodExtraPaint);
    canvas.drawLine(negative, mood, inactivePaint);

    // Линии к центру «общий дневник».
    canvas.drawLine(positive, mixed, spokePaint);
    canvas.drawLine(negative, mixed, spokePaint);
    canvas.drawLine(mood, mixed, spokePaint);

    void drawActiveEdge(Offset a, Offset b) {
      canvas.drawLine(a, b, activePaint);
    }

    switch (selectedMode) {
      case StatisticsDiaryMode.positive:
        drawActiveEdge(positive, negative);
        drawActiveEdge(positive, mood);
        drawActiveEdge(positive, mixed);
        break;
      case StatisticsDiaryMode.negative:
        drawActiveEdge(positive, negative);
        drawActiveEdge(negative, mood);
        drawActiveEdge(negative, mixed);
        break;
      case StatisticsDiaryMode.mood:
        drawActiveEdge(negative, mood);
        drawActiveEdge(mood, positive);
        drawActiveEdge(mood, mixed);
        break;
      case StatisticsDiaryMode.mixed:
        drawActiveEdge(positive, mixed);
        drawActiveEdge(negative, mixed);
        drawActiveEdge(mood, mixed);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _StatisticsModeSelectorPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedMode != selectedMode ||
        oldDelegate.accent != accent ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatsPeriod _selectedPeriod = StatsPeriod.allTime;
  List<StatisticsEntryBucket> _statistics = [];
  Map<DateTime, int> _moodStatistics = {};
  ChartType _selectedChartType = ChartType.pie;
  StatisticsDiaryMode _statsMode = StatisticsDiaryMode.mixed;
  static const String _statsModeKey = 'statistics_mode';
  static const String _statsPeriodKey = 'statistics_period';
  static const String _statsChartTypeByModeKey = 'statistics_chart_type_by_mode';
  final Map<StatisticsDiaryMode, ChartType> _chartTypesByMode = {
    StatisticsDiaryMode.negative: ChartType.pie,
    StatisticsDiaryMode.mixed: ChartType.pie,
    StatisticsDiaryMode.positive: ChartType.pie,
    StatisticsDiaryMode.mood: ChartType.byDay,
  };

  final List<StatsPeriod> _periods = const [
    StatsPeriod.allTime,
    StatsPeriod.month,
    StatsPeriod.week,
  ];

  List<ChartType> get _availableChartTypes {
    if (_statsMode == StatisticsDiaryMode.mood) {
      return const [ChartType.line, ChartType.pie, ChartType.byDay];
    } else {
      return const [ChartType.line, ChartType.pie];
    }
  }

  @override
  void initState() {
    super.initState();
    _restoreStatisticsUiState();
  }

  ChartType _defaultChartTypeForMode(StatisticsDiaryMode mode) {
    return mode == StatisticsDiaryMode.mood ? ChartType.byDay : ChartType.pie;
  }

  StatisticsDiaryMode _parseStatsMode(String? raw) {
    return switch (raw) {
      'negative' => StatisticsDiaryMode.negative,
      'positive' => StatisticsDiaryMode.positive,
      'mood' => StatisticsDiaryMode.mood,
      _ => StatisticsDiaryMode.mixed,
    };
  }

  StatsPeriod _parseStatsPeriod(String? raw) {
    return switch (raw) {
      'week' => StatsPeriod.week,
      'month' => StatsPeriod.month,
      _ => StatsPeriod.allTime,
    };
  }

  ChartType _parseChartType(String? raw) {
    return switch (raw) {
      'line' => ChartType.line,
      'byDay' => ChartType.byDay,
      _ => ChartType.pie,
    };
  }

  Future<void> _restoreStatisticsUiState() async {
    final prefs = await SharedPreferences.getInstance();
    final restoredMode = _parseStatsMode(prefs.getString(_statsModeKey));
    final restoredPeriod = _parseStatsPeriod(prefs.getString(_statsPeriodKey));
    final restoredCharts = Map<StatisticsDiaryMode, ChartType>.from(_chartTypesByMode);
    final rawChartMap = prefs.getString(_statsChartTypeByModeKey);
    if (rawChartMap != null && rawChartMap.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawChartMap);
        if (decoded is Map<String, dynamic>) {
          for (final mode in StatisticsDiaryMode.values) {
            final chartRaw = decoded[mode.name]?.toString();
            if (chartRaw != null) {
              restoredCharts[mode] = _parseChartType(chartRaw);
            }
          }
        }
      } catch (_) {}
    }
    var restoredSelectedChart =
        restoredCharts[restoredMode] ?? _defaultChartTypeForMode(restoredMode);
    final restoredAvailable = restoredMode == StatisticsDiaryMode.mood
        ? const [ChartType.line, ChartType.pie, ChartType.byDay]
        : const [ChartType.line, ChartType.pie];
    if (!restoredAvailable.contains(restoredSelectedChart)) {
      restoredSelectedChart = _defaultChartTypeForMode(restoredMode);
      restoredCharts[restoredMode] = restoredSelectedChart;
    }
    if (!mounted) return;
    setState(() {
      _statsMode = restoredMode;
      _selectedPeriod = restoredPeriod;
      _chartTypesByMode
        ..clear()
        ..addAll(restoredCharts);
      _selectedChartType = restoredSelectedChart;
    });
    await _loadStatistics();
  }

  Future<void> _saveStatisticsUiState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statsModeKey, _statsMode.name);
    await prefs.setString(_statsPeriodKey, _selectedPeriod.name);
    final map = <String, String>{};
    for (final entry in _chartTypesByMode.entries) {
      map[entry.key.name] = entry.value.name;
    }
    await prefs.setString(_statsChartTypeByModeKey, jsonEncode(map));
  }

  Future<void> _loadStatistics() async {
    if (_statsMode == StatisticsDiaryMode.mood) {
      await _loadMoodStatistics();
    } else {
      final entries = await EmotionProvider.getEntriesForPeriod(
        _selectedPeriod,
        kinds: switch (_statsMode) {
          StatisticsDiaryMode.positive => {EmotionDiaryKind.positive},
          StatisticsDiaryMode.negative => {EmotionDiaryKind.negative},
          StatisticsDiaryMode.mixed => null,
          StatisticsDiaryMode.mood => null,
        },
      );
      final Map<String, StatisticsEntryBucket> grouped = {};
      for (final entry in entries) {
        final key = entry.statisticKey;
        final existing = grouped[key];
        grouped[key] = StatisticsEntryBucket(
          label: entry.primaryLabel(context),
          color: entry.primaryColor(context),
          count: (existing?.count ?? 0) + 1,
        );
      }
      setState(() {
        _statistics = grouped.values.toList()
          ..sort((a, b) => b.count.compareTo(a.count));
        if (!_availableChartTypes.contains(_selectedChartType)) {
          final fallback = _defaultChartTypeForMode(_statsMode);
          _selectedChartType = fallback;
          _chartTypesByMode[_statsMode] = fallback;
        }
      });
    }
  }

  Future<void> _loadMoodStatistics() async {
    final moods = await MoodProvider.getMoods();
    final now = DateTime.now();
    final filteredMoods = moods.where((mood) {
      switch (_selectedPeriod) {
        case StatsPeriod.week:
          return mood.date.isAfter(now.subtract(const Duration(days: 7)));
        case StatsPeriod.month:
          return mood.date.isAfter(now.subtract(const Duration(days: 30)));
        default:
          return true;
      }
    }).toList();

    setState(() {
      _moodStatistics = Map.fromEntries(
        filteredMoods.map((mood) => MapEntry(mood.date, mood.mood))
      );
    });
  }

  void _onCategoryChanged(StatisticsDiaryMode mode) {
    var selectedForMode = _chartTypesByMode[mode] ?? _defaultChartTypeForMode(mode);
    final nextAvailable = mode == StatisticsDiaryMode.mood
        ? const [ChartType.line, ChartType.pie, ChartType.byDay]
        : const [ChartType.line, ChartType.pie];
    if (!nextAvailable.contains(selectedForMode)) {
      selectedForMode = _defaultChartTypeForMode(mode);
      _chartTypesByMode[mode] = selectedForMode;
    }
    setState(() {
      _statsMode = mode;
      _selectedChartType = selectedForMode;
    });
    _saveStatisticsUiState();
    _loadStatistics();
  }

  String _text({
    required String ru,
    required String en,
    required String fr,
    required String de,
    required String pt,
  }) {
    final code = Localizations.localeOf(context).languageCode;
    switch (code) {
      case 'en':
        return en;
      case 'fr':
        return fr;
      case 'de':
        return de;
      case 'pt':
        return pt;
      default:
        return ru;
    }
  }

  String _periodLabel(StatsPeriod period, AppLocalizations l10n) {
    switch (period) {
      case StatsPeriod.allTime:
        return l10n.periodAllTime;
      case StatsPeriod.month:
        return l10n.periodMonth;
      case StatsPeriod.week:
        return l10n.periodWeek;
    }
  }

  String _periodLabelForTitle(StatsPeriod period, AppLocalizations l10n) {
    switch (period) {
      case StatsPeriod.allTime:
        return l10n.periodAllTimeFor;
      case StatsPeriod.month:
        return l10n.periodMonthFor;
      case StatsPeriod.week:
        return l10n.periodWeekFor;
    }
  }

  String _chartTypeLabel(ChartType type, AppLocalizations l10n) {
    switch (type) {
      case ChartType.line:
        return l10n.chartLine;
      case ChartType.pie:
        return l10n.chartPie;
      case ChartType.byDay:
        return l10n.chartByDay;
    }
  }

  /// Заголовок над круговой диаграммой — внутри области графика, чтобы диаграмма не наезжала на текст.
  Widget _distributionHeading(AppLocalizations l10n) {
    final w = MediaQuery.sizeOf(context).width;
    final fs = w < 320 ? 13.0 : (w < 380 ? 15.0 : 17.0);
    final subject = _statsMode == StatisticsDiaryMode.mood
        ? l10n.distributionSubjectMood
        : l10n.distributionSubjectEmotions;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: Text(
        '${l10n.distributionLabel} $subject ${l10n.distributionForPeriod} ${_periodLabelForTitle(_selectedPeriod, l10n)}',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fs,
          fontWeight: FontWeight.bold,
          height: 1.25,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = ThemeProvider.accentForScheme(scheme);
    final inactiveIcon = Color.lerp(scheme.onSurface, accent, 0.35) ?? scheme.onSurface;
    final l10n = AppLocalizations.of(context);

    Widget modernDropdown<T>({
      required T value,
      required List<DropdownMenuItem<T>> items,
      required ValueChanged<T?> onChanged,
    }) {
      final w = MediaQuery.sizeOf(context).width;
      final fs = w < 340 ? 12.5 : (w < 380 ? 13.5 : 14.5);
      return DropdownButtonHideUnderline(
        child: DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          menuMaxHeight: 360,
          iconEnabledColor: scheme.onSurfaceVariant,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: scheme.surfaceContainerHighest,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.55)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accent.withOpacity(0.9), width: 2),
            ),
          ),
          style: TextStyle(color: scheme.onSurface, fontSize: fs, fontWeight: FontWeight.w600),
          items: items,
          onChanged: onChanged,
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          StatisticsModeSelector(
            value: _statsMode,
            onChanged: _onCategoryChanged,
            accent: accent,
            inactiveColor: inactiveIcon,
            onPageSwipeEnabled: widget.onPageSwipeEnabled,
            labels: {
              StatisticsDiaryMode.negative: _text(
                ru: 'Негативный дневник',
                en: 'Negative diary',
                fr: 'Journal négatif',
                de: 'Negatives Tagebuch',
                pt: 'Diário negativo',
              ),
              StatisticsDiaryMode.mixed: _text(
                ru: 'Дневник',
                en: 'Diary',
                fr: 'Journal',
                de: 'Tagebuch',
                pt: 'Diário',
              ),
              StatisticsDiaryMode.positive: _text(
                ru: 'Позитивный дневник',
                en: 'Positive diary',
                fr: 'Journal positif',
                de: 'Positives Tagebuch',
                pt: 'Diário positivo',
              ),
              StatisticsDiaryMode.mood: l10n.categoryMood,
            },
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: modernDropdown<StatsPeriod>(
                  value: _selectedPeriod,
                  items: _periods.map((period) {
                    return DropdownMenuItem<StatsPeriod>(
                      value: period,
                      child: Text(
                        _periodLabel(period, l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (StatsPeriod? newValue) {
                    if (newValue == null) return;
                    setState(() => _selectedPeriod = newValue);
                    _saveStatisticsUiState();
                    _loadStatistics();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: modernDropdown<ChartType>(
                  value: _selectedChartType,
                  items: _availableChartTypes.map((type) {
                    return DropdownMenuItem<ChartType>(
                      value: type,
                      child: Text(
                        _chartTypeLabel(type, l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (ChartType? newValue) {
                    if (newValue == null) return;
                    setState(() {
                      _selectedChartType = newValue;
                      _chartTypesByMode[_statsMode] = newValue;
                    });
                    _saveStatisticsUiState();
                  },
                ),
              ),
            ],
            ),
            const SizedBox(height: 16),
          Expanded(
            child: _statsMode == StatisticsDiaryMode.mood
              ? (_selectedChartType == ChartType.line
                  ? _buildMoodLinearChart() 
                  : _selectedChartType == ChartType.pie
                    ? _buildMoodPieChart()
                    : _buildMoodTrendChart())
              : (_selectedChartType == ChartType.line
                  ? _buildLinearChart() 
                  : _buildPieChart()),
          ),
        ],
      ),
    );
  }

  /// В [fl_chart] `PieChartSectionData.radius` — толщина сегмента, а внешний
  /// радиус бублика = [centerSpaceRadius] + [sectionThickness].
  /// Соотношение 0.42/1.0 (дыра/кольцо) — как в прежней визуальной задумке, но
  /// так, чтобы (дыра+кольцо) * 2 умещались в [minSide].
  (double sectionThickness, double centerHole, double titleFontSize) _pieDonutLayout(double minSide) {
    if (minSide <= 0 || !minSide.isFinite) {
      return (10.0, 4.0, 9.0);
    }
    const double holeToThickness = 0.42;
    const double sum = 1.0 + holeToThickness; // 1.42
    // Запас под подписи процентов, которые рисуются снаружи кольца
    const double halfSideInset = 0.80;
    final maxOuter = (minSide * 0.5) * halfSideInset;
    var sectionThickness = maxOuter / sum;
    var centerHole = sectionThickness * holeToThickness;
    if (sectionThickness < 4.0) {
      sectionThickness = 4.0;
      centerHole = sectionThickness * holeToThickness;
    }
    final upper = (minSide * 0.5) * 0.88;
    if (centerHole + sectionThickness > upper) {
      sectionThickness = upper / sum;
      centerHole = sectionThickness * holeToThickness;
    }
    final titleSize = (sectionThickness * 0.19).clamp(7.0, 15.0);
    return (sectionThickness, centerHole, titleSize);
  }

  Widget _buildPieChart() {
    final l10n = AppLocalizations.of(context);
    final total = _statistics.fold<int>(0, (sum, item) => sum + item.count);
    if (total == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _distributionHeading(l10n),
          Expanded(
            child: Center(child: Text(l10n.noDataToDisplay)),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, outer) {
        // Только легенда прокручивается; круг всегда целиком в своей области.
        final legendHeight = (outer.maxHeight * 0.28).clamp(110.0, 190.0);
    return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
            _distributionHeading(l10n),
        Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final minSide = min(constraints.maxWidth, constraints.maxHeight);
                        final (sectionThick, centerHole, sliceTitleSize) = _pieDonutLayout(minSide);
                        return Center(
                          child: PieChart(
                            PieChartData(
                              sections: _statistics.map((item) {
                                final count = item.count;
                                final percentage = count / total;
                                return PieChartSectionData(
                                  color: item.color,
                                  value: count.toDouble(),
                                  title: count > 0 ? '${(percentage * 100).toStringAsFixed(1)}%' : '',
                                  titlePositionPercentageOffset: 0.55,
                                  radius: sectionThick,
                                  titleStyle: TextStyle(
                                    fontSize: sliceTitleSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                              sectionsSpace: 2,
                              centerSpaceRadius: centerHole,
                              startDegreeOffset: -90,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    height: legendHeight,
                    child: SingleChildScrollView(
                      child: Column(
                        children: _statistics.map((item) {
                          final count = item.count;
                          final percentage = count / total;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: item.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Text(
                                  '${count} (${(percentage * 100).toStringAsFixed(1)}%)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLinearChart() {
    return ListView(
      children: _statistics.map((item) {
        final total = _statistics.fold<int>(0, (sum, current) => sum + current.count);
        final percentage = total > 0 ? item.count / total : 0.0;
        return _buildStatCard(
          item.label,
          percentage,
          item.color,
          item.count,
        );
      }).toList(),
    );
  }

  Widget _buildMoodPieChart() {
    final l10n = AppLocalizations.of(context);
    final total = _moodStatistics.length;
    if (total == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _distributionHeading(l10n),
          Expanded(
            child: Center(child: Text(l10n.noDataToDisplay)),
          ),
        ],
      );
    }

    final Map<int, int> moodCounts = {};
    for (var mood in _moodStatistics.values) {
      moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
    }

    return LayoutBuilder(
      builder: (context, outer) {
        final legendHeight = (outer.maxHeight * 0.28).clamp(110.0, 190.0);
    return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
            _distributionHeading(l10n),
        Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final minSide = min(constraints.maxWidth, constraints.maxHeight);
                        final (sectionThick, centerHole, sliceTitleSize) = _pieDonutLayout(minSide);
                        return Center(
                          child: PieChart(
                            PieChartData(
                              sections: List.generate(5, (index) {
                                final mood = index + 1;
                                final count = moodCounts[mood] ?? 0;
                                final percentage = count / total;
                                return PieChartSectionData(
                                  color: _getMoodColor(mood),
                                  value: count.toDouble(),
                                  title: count > 0 ? '${(percentage * 100).toStringAsFixed(1)}%' : '',
                                  titlePositionPercentageOffset: 0.55,
                                  radius: sectionThick,
                                  titleStyle: TextStyle(
                                    fontSize: sliceTitleSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }),
                              sectionsSpace: 2,
                              centerSpaceRadius: centerHole,
                              startDegreeOffset: -90,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    height: legendHeight,
                    child: SingleChildScrollView(
                      child: Column(
                        children: List.generate(5, (index) {
                          final mood = index + 1;
                          final count = moodCounts[mood] ?? 0;
                          final percentage = count / total;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Text(
                                  _getMoodEmoji(mood),
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _getMoodDescription(mood),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Text(
                                  '${count} (${(percentage * 100).toStringAsFixed(1)}%)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMoodLinearChart() {
    final total = _moodStatistics.length;
    if (total == 0) {
      return Center(
        child: Text(AppLocalizations.of(context).noDataToDisplay),
      );
    }

    final Map<int, int> moodCounts = {};
    for (var mood in _moodStatistics.values) {
      moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
    }

    return ListView(
      children: List.generate(5, (index) {
        final mood = index + 1;
        final count = moodCounts[mood] ?? 0;
        final percentage = count / total;
        return _buildMoodStatCard(mood, percentage, count);
      }),
    );
  }

  Widget _buildMoodStatCard(int mood, double percentage, int count) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _getMoodEmoji(mood),
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 10),
                Text(
                  _getMoodDescription(mood),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_getMoodColor(mood)),
            ),
            const SizedBox(height: 8),
            Text(
              '${AppLocalizations.of(context).countLabel}: $count (${(percentage * 100).toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  String _getMoodEmoji(int mood) {
    switch (mood) {
      case 1: return '😢';
      case 2: return '😕';
      case 3: return '😐';
      case 4: return '🙂';
      case 5: return '😊';
      default: return '😐';
    }
  }

  String _getMoodDescription(int mood) {
    final l10n = AppLocalizations.of(context);
    switch (mood) {
      case 1: return l10n.moodVeryBad;
      case 2: return l10n.moodBad;
      case 3: return l10n.moodNeutral;
      case 4: return l10n.moodGood;
      case 5: return l10n.moodGreat;
      default: return l10n.moodNotSelected;
    }
  }

  Color _getMoodColor(int mood) {
    switch (mood) {
      case 1: return Colors.red;
      case 2: return Colors.red.shade300;
      case 3: return Colors.yellow;
      case 4: return Colors.lightGreen;
      case 5: return Colors.green;
      default: return Colors.grey;
    }
  }

  Widget _buildMoodTrendChart() {
    if (_moodStatistics.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context).noDataToDisplay),
      );
    }

    // Сортируем даты
    final sortedDates = _moodStatistics.keys.toList()..sort();
    if (sortedDates.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context).noDataToDisplay),
      );
    }

    // Создаем точки для графика
    final spots = List.generate(sortedDates.length, (index) {
      final date = sortedDates[index];
      final mood = _moodStatistics[date]!;
      return FlSpot(index.toDouble(), mood.toDouble());
    });

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // В тёмной теме primary иногда сливается с фоном — делаем линию ярче и толще.
    final lineColor = isDark
        ? Color.lerp(scheme.primary, scheme.onSurface, 0.45) ?? scheme.primary
        : scheme.primary;
    final lineWidth = isDark ? 4.5 : 3.0;
    final dotStroke = scheme.surface;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: scheme.outline.withOpacity(isDark ? 0.35 : 0.25),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: scheme.outline.withOpacity(isDark ? 0.28 : 0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: (sortedDates.length / 5).ceil().toDouble(),
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= sortedDates.length) return const Text('');
                        final date = sortedDates[value.toInt()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: TextStyle(
                              fontSize: 10,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value < 1 || value > 5) return const Text('');
                        return Text(
                          _getMoodEmoji(value.toInt()),
                          style: TextStyle(fontSize: 12, color: scheme.onSurface),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: scheme.outline.withOpacity(isDark ? 0.6 : 0.45)),
                ),
                minX: 0,
                maxX: (sortedDates.length - 1).toDouble(),
                minY: 1,
                maxY: 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: lineColor,
                    barWidth: lineWidth,
                    isStrokeCapRound: true,
                    shadow: isDark
                        ? Shadow(
                            color: lineColor.withOpacity(0.55),
                            blurRadius: 10,
                            offset: const Offset(0, 1),
                          )
                        : const Shadow(color: Colors.transparent),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: isDark ? 5 : 4,
                          color: _getMoodColor(spot.y.toInt()),
                          strokeWidth: isDark ? 2.5 : 2,
                          strokeColor: dotStroke,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withOpacity(isDark ? 0.18 : 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppLocalizations.of(context).legendLabel}:',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: List.generate(5, (index) {
                  final mood = index + 1;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getMoodEmoji(mood),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getMoodDescription(mood),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String source, double percentage, Color color, int count) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  source,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            const SizedBox(height: 8),
            Text(
              '${AppLocalizations.of(context).countLabel}: $count (${(percentage * 100).toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ExportRangePreset {
  week,
  twoWeeks,
  month,
  all,
  custom,
}

enum _ExportTarget {
  appFolder,
  customFolder,
  share,
}

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  _ExportRangePreset _rangePreset = _ExportRangePreset.week;
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _includePositiveDiary = false;
  bool _includeNegativeDiary = false;
  bool _includeMoodCalendar = false;
  bool _loadingData = true;
  bool _exporting = false;
  List<CustomTestDefinition> _customTests = const <CustomTestDefinition>[];
  List<SavedTestResult> _allTestResults = const <SavedTestResult>[];
  final Map<TestKind, bool> _selectedBuiltInTests = <TestKind, bool>{};
  final Map<String, bool> _selectedCustomTests = <String, bool>{};

  @override
  void initState() {
    super.initState();
    for (final test in TestsCatalog.availableTests) {
      _selectedBuiltInTests[test.kind] = false;
    }
    _loadExportData();
  }

  Future<void> _loadExportData() async {
    try {
      final loaded = await Future.wait<Object>([
        CustomTestsLoader.loadAll(),
        TestHistoryStorage.loadAll(),
      ]);
      final custom = loaded[0] as List<CustomTestDefinition>;
      final results = loaded[1] as List<SavedTestResult>;
      if (!mounted) return;
      setState(() {
        _customTests = custom;
        _allTestResults = results;
        for (final test in custom) {
          _selectedCustomTests[test.id] = false;
        }
        _loadingData = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _customTests = const <CustomTestDefinition>[];
        _allTestResults = const <SavedTestResult>[];
        _loadingData = false;
      });
    }
  }

  bool get _hasAnySelection {
    return _includePositiveDiary ||
        _includeNegativeDiary ||
        _includeMoodCalendar ||
        _selectedBuiltInTests.values.any((v) => v) ||
        _selectedCustomTests.values.any((v) => v);
  }

  DateTimeRange? _effectiveRangeOrNull() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_rangePreset) {
      case _ExportRangePreset.week:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: DateTime(today.year, today.month, today.day, 23, 59, 59),
        );
      case _ExportRangePreset.twoWeeks:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 13)),
          end: DateTime(today.year, today.month, today.day, 23, 59, 59),
        );
      case _ExportRangePreset.month:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: DateTime(today.year, today.month, today.day, 23, 59, 59),
        );
      case _ExportRangePreset.all:
        return null;
      case _ExportRangePreset.custom:
        if (_customStart == null || _customEnd == null) return null;
        final start = DateTime(_customStart!.year, _customStart!.month, _customStart!.day);
        final end = DateTime(_customEnd!.year, _customEnd!.month, _customEnd!.day, 23, 59, 59);
        return start.isAfter(end) ? DateTimeRange(start: end, end: start) : DateTimeRange(start: start, end: end);
    }
  }

  String _presetLabel(_ExportRangePreset preset) {
    switch (preset) {
      case _ExportRangePreset.week:
        return _exportText(
          context,
          ru: 'За последнюю неделю',
          en: 'Last week',
          fr: 'Dernière semaine',
          de: 'Letzte Woche',
          pt: 'Última semana',
        );
      case _ExportRangePreset.twoWeeks:
        return _exportText(
          context,
          ru: 'За последние 2 недели',
          en: 'Last 2 weeks',
          fr: '2 dernières semaines',
          de: 'Letzte 2 Wochen',
          pt: 'Últimas 2 semanas',
        );
      case _ExportRangePreset.month:
        return _exportText(
          context,
          ru: 'За последний месяц',
          en: 'Last month',
          fr: 'Dernier mois',
          de: 'Letzter Monat',
          pt: 'Último mês',
        );
      case _ExportRangePreset.all:
        return _exportText(
          context,
          ru: 'Полностью',
          en: 'All time',
          fr: 'Tout',
          de: 'Gesamter период',
          pt: 'Tudo',
        );
      case _ExportRangePreset.custom:
        return _exportText(
          context,
          ru: 'Выставить даты вручную',
          en: 'Custom dates',
          fr: 'Choisir les dates',
          de: 'Zeitraum manuell',
          pt: 'Escolher datas',
        );
    }
  }

  String _formatRangeLabel(DateTimeRange? range) {
    if (range == null) {
      return _exportText(
        context,
        ru: 'Период: полностью',
        en: 'Period: all time',
        fr: 'Période : complète',
        de: 'Zeitraum: vollständig',
        pt: 'Período: completo',
      );
    }
    final locale = calendarLocaleTag(context);
    final start = DateFormat.yMMMd(locale).format(range.start);
    final end = DateFormat.yMMMd(locale).format(range.end);
    return _exportText(
      context,
      ru: 'Период: $start - $end',
      en: 'Period: $start - $end',
      fr: 'Période : $start - $end',
      de: 'Zeitraum: $start - $end',
      pt: 'Período: $start - $end',
    );
  }

  Future<void> _pickBoundary({required bool start}) async {
    final current = start ? _customStart : _customEnd;
    final fallback = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? fallback,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: Locale(Localizations.localeOf(context).languageCode),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _customStart = picked;
      } else {
        _customEnd = picked;
      }
    });
  }

  bool _inDateRange(DateTime date, DateTimeRange? range) {
    if (range == null) return true;
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(DateTime(range.start.year, range.start.month, range.start.day)) &&
        !day.isAfter(DateTime(range.end.year, range.end.month, range.end.day));
  }

  bool _inDateTimeRange(DateTime dateTime, DateTimeRange? range) {
    if (range == null) return true;
    return !dateTime.isBefore(range.start) && !dateTime.isAfter(range.end);
  }

  String _moodEmoji(int mood) {
    switch (mood) {
      case 1:
        return '😞';
      case 2:
        return '🙁';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      default:
        return '😄';
    }
  }

  String _moodLabel(int mood) {
    switch (mood) {
      case 1:
        return _exportText(context, ru: 'Очень тяжело', en: 'Very low', fr: 'Très bas', de: 'Sehr niedrig', pt: 'Muito baixo');
      case 2:
        return _exportText(context, ru: 'Ниже обычного', en: 'Below usual', fr: 'Sous l’habitude', de: 'Unter dem Üblichen', pt: 'Abaixo do habitual');
      case 3:
        return _exportText(context, ru: 'Нейтрально', en: 'Neutral', fr: 'Neutre', de: 'Neutral', pt: 'Neutro');
      case 4:
        return _exportText(context, ru: 'Неплохо', en: 'Fairly good', fr: 'Plutôt bon', de: 'Ganz gut', pt: 'Bem razoável');
      default:
        return _exportText(context, ru: 'Очень хорошо', en: 'Very good', fr: 'Très bon', de: 'Sehr gut', pt: 'Muito bom');
    }
  }

  double _customTrendValue(CustomTestDefinition test, List<int> answers) {
    if (test.resultSubscalesOnly && test.subscales.isNotEmpty) {
      var sum = 0.0;
      for (final s in test.subscales) {
        sum += test.scoreSubscale(s, answers);
      }
      return sum / test.subscales.length;
    }
    return test.scoreTotal(answers).toDouble();
  }

  int _runCountForTest(String testId) {
    final range = _effectiveRangeOrNull();
    return _allTestResults
        .where((r) => r.testId == testId && _inDateTimeRange(r.completedAt, range))
        .length;
  }

  Future<PdfExportDocumentData> _buildExportDocument() async {
    final range = _effectiveRangeOrNull();
    final locale = calendarLocaleTag(context);
    final entries = await EmotionProvider.getEntries();
    final moods = await MoodProvider.getMoods();
    final allResults = _allTestResults;
    final sections = <PdfExportSection>[];

    if (_includePositiveDiary) {
      sections.add(_buildDiarySection(
        title: _exportText(context, ru: 'Позитивный дневник', en: 'Positive diary', fr: 'Journal positif', de: 'Positives Tagebuch', pt: 'Diário positivo'),
        intro: _exportText(context, ru: 'В отчёт включены записи позитивного дневника за выбранный период.', en: 'This section includes positive diary entries for the selected period.', fr: 'Cette partie contient les entrées positives de la période choisie.', de: 'Dieser Teil enthält positive Tagebucheinträge für den gewählten Zeitraum.', pt: 'Esta seção inclui registros positivos do período selecionado.'),
        filtered: entries.where((e) => e.isPositive && _inDateRange(e.date, range)).toList()
          ..sort((a, b) => b.date.compareTo(a.date)),
      ));
    }

    if (_includeNegativeDiary) {
      sections.add(_buildDiarySection(
        title: _exportText(context, ru: 'Негативный дневник', en: 'Negative diary', fr: 'Journal négatif', de: 'Negatives Tagebuch', pt: 'Diário negativo'),
        intro: _exportText(context, ru: 'В отчёт включены записи негативного дневника за выбранный период.', en: 'This section includes negative diary entries for the selected period.', fr: 'Cette partie contient les entrées négatives de la période choisie.', de: 'Dieser Teil enthält negative Tagebucheinträge für den gewählten Zeitraum.', pt: 'Esta seção inclui registros negativos do período selecionado.'),
        filtered: entries.where((e) => e.isNegative && _inDateRange(e.date, range)).toList()
          ..sort((a, b) => b.date.compareTo(a.date)),
      ));
    }

    if (_includeMoodCalendar) {
      final filteredMoods = moods.where((m) => m.mood > 0 && _inDateRange(m.date, range)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      final points = filteredMoods
          .map(
            (m) => PdfExportPoint(
              label: DateFormat.Md(locale).format(m.date),
              value: m.mood.toDouble(),
            ),
          )
          .toList();
      final average = filteredMoods.isEmpty
          ? 0
          : filteredMoods.fold<int>(0, (sum, e) => sum + e.mood) / filteredMoods.length;
      final moodIntro = filteredMoods.isEmpty
          ? _exportText(context, ru: 'В выбранный период нет отметок настроения.', en: 'There are no mood marks in the selected period.', fr: 'Aucune donnée d’humeur sur cette période.', de: 'Für diesen Zeitraum gibt es keine Stimmungsdaten.', pt: 'Não há registros de humor nesse período.')
          : average >= 4
              ? _exportText(context, ru: 'По выбранному периоду настроение чаще держалось в устойчиво положительной зоне.', en: 'Across the selected period, mood stayed mostly on the positive side.', fr: 'Sur la période choisie, l’humeur est restée le plus souvent du côté positif.', de: 'Im gewählten Zeitraum lag die Stimmung meist eher im positiven Bereich.', pt: 'No período selecionado, o humor ficou mais vezes em uma zona positiva.')
              : average >= 3
                  ? _exportText(context, ru: 'По выбранному периоду настроение выглядело смешанным или нейтральным.', en: 'Across the selected period, mood looked mixed or neutral overall.', fr: 'Sur la période choisie, l’humeur paraît plutôt mixte ou neutre.', de: 'Im gewählten Zeitraum wirkte die Stimmung eher gemischt oder neutral.', pt: 'No período selecionado, o humor pareceu mais misto ou neutro.')
                  : _exportText(context, ru: 'По выбранному периоду настроение чаще смещалось в тяжёлую зону.', en: 'Across the selected period, mood leaned more often toward the low side.', fr: 'Sur la période choisie, l’humeur a davantage penché vers le bas.', de: 'Im gewählten Zeitraum verschob sich die Stimmung häufiger in den belasteten Bereich.', pt: 'No período selecionado, o humor ficou mais vezes em uma zona difícil.');
      sections.add(
        PdfExportSection(
          title: _exportText(context, ru: 'Календарь настроений', en: 'Mood calendar', fr: 'Calendrier de l’humeur', de: 'Stimmungskalender', pt: 'Calendário de humor'),
          intro: moodIntro,
          chartTitle: filteredMoods.isEmpty
              ? null
              : _exportText(context, ru: 'Динамика настроения', en: 'Mood trend', fr: 'Évolution de l’humeur', de: 'Stimmungsverlauf', pt: 'Evolução do humor'),
          chartKind: filteredMoods.isEmpty ? null : PdfExportChartKind.line,
          chartPoints: points,
          entries: filteredMoods
              .reversed
              .map(
                (m) => PdfExportEntry(
                  title: DateFormat.yMMMd(locale).format(m.date),
                  subtitle: '${_moodEmoji(m.mood)} ${_moodLabel(m.mood)}',
                ),
              )
              .toList(),
          emptyMessage: _exportText(context, ru: 'За этот период нет сохранённых отметок настроения.', en: 'There are no saved mood marks in this period.', fr: 'Aucune humeur enregistrée pour cette période.', de: 'Für diesen Zeitraum gibt es keine gespeicherten Stimmungsdaten.', pt: 'Não há registros de humor nesse período.'),
        ),
      );
    }

    for (final test in TestsCatalog.availableTests.where((t) => _selectedBuiltInTests[t.kind] == true)) {
      final filtered = allResults.where((r) => r.testId == test.id && _inDateTimeRange(r.completedAt, range)).toList()
        ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
      final chartPoints = filtered
          .map(
            (r) => PdfExportPoint(
              label: DateFormat.Md(locale).format(r.completedAt),
              value: TestsCatalog.primaryScore(test, r.answers),
            ),
          )
          .toList();
      sections.add(
        PdfExportSection(
          title: test.title.resolve(context),
          intro: test.description.resolve(context),
          chartTitle: filtered.isEmpty
              ? null
              : _exportText(context, ru: 'Динамика по прохождениям', en: 'History over time', fr: 'Historique dans le temps', de: 'Verlauf über die Zeit', pt: 'Histórico ao longo do tempo'),
          chartKind: filtered.length > 1 ? PdfExportChartKind.verticalBars : null,
          chartPoints: chartPoints,
          entries: filtered.reversed.map((r) => _builtInTestEntry(test, r, locale)).toList(),
          emptyMessage: _exportText(context, ru: 'По выбранному периоду для этого теста нет сохранённых прохождений.', en: 'There are no saved runs for this test in the selected period.', fr: 'Aucun résultat enregistré pour ce test sur la période choisie.', de: 'Für diesen Zeitraum gibt es zu diesem Test keine gespeicherten Durchläufe.', pt: 'Não há resultados salvos deste teste no período selecionado.'),
        ),
      );
    }

    for (final test in _customTests.where((t) => _selectedCustomTests[t.id] == true)) {
      final filtered = allResults.where((r) => r.testId == test.id && _inDateTimeRange(r.completedAt, range)).toList()
        ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
      final chartPoints = filtered
          .map(
            (r) => PdfExportPoint(
              label: DateFormat.Md(locale).format(r.completedAt),
              value: _customTrendValue(test, r.answers),
            ),
          )
          .toList();
      sections.add(
        PdfExportSection(
          title: test.title.resolve(context),
          intro: test.description.resolve(context),
          chartTitle: filtered.length > 1
              ? _exportText(context, ru: 'Динамика по прохождениям', en: 'History over time', fr: 'Historique dans le temps', de: 'Verlauf über die Zeit', pt: 'Histórico ao longo do tempo')
              : null,
          chartKind: filtered.length > 1 ? PdfExportChartKind.verticalBars : null,
          chartPoints: chartPoints,
          entries: filtered.reversed.map((r) => _customTestEntry(test, r, locale)).toList(),
          emptyMessage: _exportText(context, ru: 'По выбранному периоду для этого теста нет сохранённых прохождений.', en: 'There are no saved runs for this test in the selected period.', fr: 'Aucun résultat enregistré pour ce test sur la période choisie.', de: 'Für diesen Zeitraum gibt es zu diesem Test keine gespeicherten Durchläufe.', pt: 'Não há resultados salvos deste teste no período selecionado.'),
        ),
      );
    }

    String? diaryIconSvg;
    try {
      diaryIconSvg = await rootBundle.loadString('assets/images/pdf_diary_icon.svg');
    } catch (_) {
      diaryIconSvg = null;
    }
    Uint8List? iconBytes;
    if (diaryIconSvg == null) {
      try {
        iconBytes = (await rootBundle.load('assets/images/app_icon.png')).buffer.asUint8List();
      } catch (_) {
        iconBytes = null;
      }
    }
    return PdfExportDocumentData(
      appName: AppLocalizations.of(context).appTitle,
      appIconSvg: diaryIconSvg,
      appIconBytes: iconBytes,
      title: _exportText(context, ru: 'Выгрузка данных', en: 'Data export', fr: 'Export des données', de: 'Datenexport', pt: 'Exportação de dados'),
      subtitle: _exportText(
        context,
        ru: 'PDF-файл собран из выбранных разделов приложения: дневник, настроение и результаты тестов.',
        en: 'This PDF is compiled from the selected app sections: diary, mood, and test results.',
        fr: 'Ce PDF regroupe les sections choisies : journal, humeur et résultats de tests.',
        de: 'Dieses PDF bündelt die gewählten Bereiche: Tagebuch, Stimmung und Testergebnisse.',
        pt: 'Este PDF reúne as seções escolhidas: diário, humor e resultados de testes.',
      ),
      generatedAtLabel: _exportText(
        context,
        ru: 'Собрано: ${DateFormat.yMMMd(locale).add_Hm().format(DateTime.now())}',
        en: 'Generated: ${DateFormat.yMMMd(locale).add_Hm().format(DateTime.now())}',
        fr: 'Généré : ${DateFormat.yMMMd(locale).add_Hm().format(DateTime.now())}',
        de: 'Erstellt: ${DateFormat.yMMMd(locale).add_Hm().format(DateTime.now())}',
        pt: 'Gerado em: ${DateFormat.yMMMd(locale).add_Hm().format(DateTime.now())}',
      ),
      rangeLabel: _formatRangeLabel(range),
      sections: sections,
    );
  }

  PdfExportSection _buildDiarySection({
    required String title,
    required String intro,
    required List<EmotionEntry> filtered,
  }) {
    if (filtered.isEmpty) {
      return PdfExportSection(
        title: title,
        intro: intro,
        emptyMessage: _exportText(
          context,
          ru: 'За выбранный период в этом разделе нет записей.',
          en: 'There are no entries in this section for the selected period.',
          fr: 'Aucune entrée dans cette section pour la période choisie.',
          de: 'Für diesen Zeitraum gibt es in diesem Bereich keine Einträge.',
          pt: 'Não há registros nesta seção no período selecionado.',
        ),
      );
    }

    final counts = <String, int>{};
    for (final entry in filtered) {
      final label = entry.primaryLabel(context);
      counts[label] = (counts[label] ?? 0) + 1;
    }
    final points = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final locale = calendarLocaleTag(context);
    return PdfExportSection(
      title: title,
      intro: intro,
      chartTitle: _exportText(context, ru: 'Распределение тем и эмоций', en: 'Distribution of themes and emotions', fr: 'Répartition des thèmes et émotions', de: 'Verteilung von Themen und Emotionen', pt: 'Distribuição de temas e emoções'),
      chartKind: PdfExportChartKind.pie,
      chartPoints: points
          .map((e) => PdfExportPoint(label: e.key, value: e.value.toDouble(), note: 'x${e.value}'))
          .toList(),
      entries: filtered
          .map(
            (entry) => PdfExportEntry(
              title: DateFormat.yMMMd(locale).add_Hm().format(entry.createdAt ?? entry.date),
              subtitle: entry.primaryLabel(context),
              lines: [
                if ((entry.secondaryLabel(context) ?? '').trim().isNotEmpty)
                  '${_exportText(context, ru: 'Дополнительная тема', en: 'Secondary theme', fr: 'Thème supplémentaire', de: 'Zusatzthema', pt: 'Tema adicional')}: ${entry.secondaryLabel(context)!}',
                if (entry.note.trim().isNotEmpty) entry.note.trim(),
                if ((entry.imagePaths?.isNotEmpty ?? false))
                  _exportText(
                    context,
                    ru: 'К записи прикреплены изображения.',
                    en: 'Images are attached to this entry.',
                    fr: 'Des images sont jointes à cette entrée.',
                    de: 'An diesen Eintrag sind Bilder angehängt.',
                    pt: 'Há imagens anexadas a este registro.',
                  ),
              ],
            ),
          )
          .toList(),
    );
  }

  PdfExportEntry _builtInTestEntry(TestDefinition test, SavedTestResult result, String locale) {
    final eval = TestsCatalog.evaluate(context, test, result.answers);
    return PdfExportEntry(
      title: DateFormat.yMMMd(locale).add_Hm().format(result.completedAt),
      subtitle: eval.levelTitle,
      lines: [
        if (eval.scoreText.trim().isNotEmpty)
          '${_exportText(context, ru: 'Баллы', en: 'Score', fr: 'Score', de: 'Punktzahl', pt: 'Pontuação')}: ${eval.scoreText}',
        eval.summary,
        ...eval.metrics.map((m) => '${m.label}: ${m.level}'),
        ...eval.recommendations,
      ],
    );
  }

  PdfExportEntry _customTestEntry(CustomTestDefinition test, SavedTestResult result, String locale) {
    final scoreForBands = test.scoreForBands(result.answers);
    final band = test.bandFor(scoreForBands);
    return PdfExportEntry(
      title: DateFormat.yMMMd(locale).add_Hm().format(result.completedAt),
      subtitle: band?.title.resolve(context) ??
          (test.resultSubscalesOnly
              ? _exportText(context, ru: 'Разбивка по областям', en: 'Breakdown by area', fr: 'Répartition par domaine', de: 'Aufschlüsselung nach Bereichen', pt: 'Detalhamento por área')
              : _exportText(context, ru: 'Результат сохранён', en: 'Result saved', fr: 'Résultat enregistré', de: 'Ergebnis gespeichert', pt: 'Resultado salvo')),
      lines: [
        if (band?.description != null) band!.description!.resolve(context),
        if (test.resultNote != null) test.resultNote!.resolve(context),
        if (test.subscales.isNotEmpty)
          '${_exportText(context, ru: 'Темы', en: 'Areas', fr: 'Domaines', de: 'Bereiche', pt: 'Áreas')}: ${test.subscales.map((s) => s.label.resolve(context)).join(', ')}',
      ],
    );
  }

  Future<Directory> _defaultExportDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'exports'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _fileName() {
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    return 'emotion_export_$stamp.pdf';
  }

  Future<void> _runExport(_ExportTarget target) async {
    if (!_hasAnySelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _exportText(
              context,
              ru: 'Сначала выберите хотя бы один раздел для выгрузки.',
              en: 'Select at least one section to export first.',
              fr: 'Choisissez d’abord au moins une section à exporter.',
              de: 'Wählen Sie zuerst mindestens einen Bereich für den Export.',
              pt: 'Escolha primeiro pelo menos uma seção para exportar.',
            ),
          ),
        ),
      );
      return;
    }
    if (_rangePreset == _ExportRangePreset.custom && (_customStart == null || _customEnd == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _exportText(
              context,
              ru: 'Для ручного периода выберите обе даты.',
              en: 'For a custom period, choose both dates.',
              fr: 'Pour une période manuelle, choisissez les deux dates.',
              de: 'Für einen manuellen Zeitraum beide Daten wählen.',
              pt: 'Para um período manual, escolha as duas datas.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _exporting = true);
    try {
      final data = await _buildExportDocument();
      final bytes = await PdfExportService.buildReport(data);
      Directory destinationDir;
      switch (target) {
        case _ExportTarget.appFolder:
        case _ExportTarget.share:
          destinationDir = await _defaultExportDir();
          break;
        case _ExportTarget.customFolder:
          final picked = await FilePicker.getDirectoryPath();
          if (picked == null || picked.trim().isEmpty) {
            if (mounted) setState(() => _exporting = false);
            return;
          }
          destinationDir = Directory(picked);
          break;
      }

      final file = File(p.join(destinationDir.path, _fileName()));
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      if (target == _ExportTarget.share) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: _exportText(
              context,
              ru: 'Выгрузка данных из приложения',
              en: 'App data export',
              fr: 'Export des données de l’application',
              de: 'Datenexport aus der App',
              pt: 'Exportação de dados do aplicativo',
            ),
            text: _exportText(
              context,
              ru: 'PDF-файл с выбранными данными из приложения.',
              en: 'PDF file with the selected app data.',
              fr: 'Fichier PDF avec les données sélectionnées de l’application.',
              de: 'PDF-Datei mit den ausgewählten App-Daten.',
              pt: 'Arquivo PDF com os dados selecionados do aplicativo.',
            ),
          ),
        );
        if (!mounted) return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            target == _ExportTarget.share
                ? _exportText(
                    context,
                    ru: 'Файл подготовлен и передан в меню отправки.',
                    en: 'The file was prepared and sent to the share sheet.',
                    fr: 'Le fichier a été préparé et envoyé au menu de partage.',
                    de: 'Die Datei wurde erstellt und zum Teilen bereitgestellt.',
                    pt: 'O arquivo foi preparado e enviado para o menu de compartilhamento.',
                  )
                : _exportText(
                    context,
                    ru: 'PDF сохранён: ${file.path}',
                    en: 'PDF saved: ${file.path}',
                    fr: 'PDF enregistré : ${file.path}',
                    de: 'PDF gespeichert: ${file.path}',
                    pt: 'PDF salvo em: ${file.path}',
                  ),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _exportText(
              context,
              ru: 'Не удалось собрать PDF: $e',
              en: 'Could not build the PDF: $e',
              fr: 'Impossible de générer le PDF : $e',
              de: 'PDF konnte nicht erstellt werden: $e',
              pt: 'Não foi possível gerar o PDF: $e',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  int get _selectedTestCount {
    return _selectedBuiltInTests.values.where((v) => v).length +
        _selectedCustomTests.values.where((v) => v).length;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locale = calendarLocaleTag(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _exportText(
            context,
            ru: 'Выгрузка данных',
            en: 'Data export',
            fr: 'Export des données',
            de: 'Datenexport',
            pt: 'Exportação de dados',
          ),
        ),
      ),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  _exportText(
                    context,
                    ru: 'Выберите период, разделы и тесты, которые нужно включить в PDF.',
                    en: 'Choose the period, sections, and tests to include in the PDF.',
                    fr: 'Choisissez la période, les sections et les tests à inclure dans le PDF.',
                    de: 'Zeitraum, Bereiche und Tests für das PDF auswählen.',
                    pt: 'Escolha o período, as seções e os testes a incluir no PDF.',
                  ),
                  style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
                ),
                const SizedBox(height: 16),
                Text(
                  _exportText(context, ru: 'Период', en: 'Period', fr: 'Période', de: 'Zeitraum', pt: 'Período'),
                  style: TextStyle(fontWeight: FontWeight.bold, color: scheme.primary),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      for (final preset in _ExportRangePreset.values)
                        RadioListTile<_ExportRangePreset>(
                          value: preset,
                          groupValue: _rangePreset,
                          title: Text(_presetLabel(preset)),
                          onChanged: (value) => setState(() => _rangePreset = value!),
                        ),
                      if (_rangePreset == _ExportRangePreset.custom) ...[
                        const Divider(height: 1),
                        ListTile(
                          title: Text(_exportText(context, ru: 'Дата начала', en: 'Start date', fr: 'Date de début', de: 'Startdatum', pt: 'Data inicial')),
                          subtitle: Text(_customStart == null ? _exportText(context, ru: 'Не выбрана', en: 'Not selected', fr: 'Non choisie', de: 'Nicht gewählt', pt: 'Não escolhida') : DateFormat.yMMMd(locale).format(_customStart!)),
                          trailing: const Icon(Icons.date_range_outlined),
                          onTap: () => _pickBoundary(start: true),
                        ),
                        ListTile(
                          title: Text(_exportText(context, ru: 'Дата конца', en: 'End date', fr: 'Date de fin', de: 'Enddatum', pt: 'Data final')),
                          subtitle: Text(_customEnd == null ? _exportText(context, ru: 'Не выбрана', en: 'Not selected', fr: 'Non choisie', de: 'Nicht gewählt', pt: 'Não escolhida') : DateFormat.yMMMd(locale).format(_customEnd!)),
                          trailing: const Icon(Icons.event_available_outlined),
                          onTap: () => _pickBoundary(start: false),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _exportText(context, ru: 'Что включить', en: 'What to include', fr: 'À inclure', de: 'Was einschließen', pt: 'O que incluir'),
                  style: TextStyle(fontWeight: FontWeight.bold, color: scheme.primary),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      CheckboxListTile(
                        value: _includePositiveDiary,
                        title: Text(_exportText(context, ru: 'Позитивный дневник', en: 'Positive diary', fr: 'Journal positif', de: 'Positives Tagebuch', pt: 'Diário positivo')),
                        onChanged: (v) => setState(() => _includePositiveDiary = v ?? false),
                      ),
                      CheckboxListTile(
                        value: _includeNegativeDiary,
                        title: Text(_exportText(context, ru: 'Негативный дневник', en: 'Negative diary', fr: 'Journal négatif', de: 'Negatives Tagebuch', pt: 'Diário negativo')),
                        onChanged: (v) => setState(() => _includeNegativeDiary = v ?? false),
                      ),
                      CheckboxListTile(
                        value: _includeMoodCalendar,
                        title: Text(_exportText(context, ru: 'Календарь настроений', en: 'Mood calendar', fr: 'Calendrier de l’humeur', de: 'Stimmungskalender', pt: 'Calendário de humor')),
                        onChanged: (v) => setState(() => _includeMoodCalendar = v ?? false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ExpansionTile(
                    title: Text(
                      _exportText(
                        context,
                        ru: 'Тесты',
                        en: 'Tests',
                        fr: 'Tests',
                        de: 'Tests',
                        pt: 'Testes',
                      ),
                    ),
                    subtitle: Text(
                      _selectedTestCount == 0
                          ? _exportText(context, ru: 'Ничего не выбрано', en: 'Nothing selected', fr: 'Rien de sélectionné', de: 'Nichts ausgewählt', pt: 'Nada selecionado')
                          : _exportText(
                              context,
                              ru: 'Выбрано: $_selectedTestCount',
                              en: 'Selected: $_selectedTestCount',
                              fr: 'Sélectionnés : $_selectedTestCount',
                              de: 'Ausgewählt: $_selectedTestCount',
                              pt: 'Selecionados: $_selectedTestCount',
                            ),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    for (final key in _selectedBuiltInTests.keys) {
                                      _selectedBuiltInTests[key] = true;
                                    }
                                    for (final key in _selectedCustomTests.keys) {
                                      _selectedCustomTests[key] = true;
                                    }
                                  });
                                },
                                child: Text(_exportText(context, ru: 'Выбрать все', en: 'Select all', fr: 'Tout sélectionner', de: 'Alle auswählen', pt: 'Selecionar tudo')),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    for (final key in _selectedBuiltInTests.keys) {
                                      _selectedBuiltInTests[key] = false;
                                    }
                                    for (final key in _selectedCustomTests.keys) {
                                      _selectedCustomTests[key] = false;
                                    }
                                  });
                                },
                                child: Text(_exportText(context, ru: 'Снять все', en: 'Clear all', fr: 'Tout retirer', de: 'Alle abwählen', pt: 'Limpar tudo')),
                              ),
                            ],
                          ),
                        ),
                      ),
                      for (final test in TestsCatalog.availableTests)
                        CheckboxListTile(
                          value: _selectedBuiltInTests[test.kind] ?? false,
                          title: Text(test.title.resolve(context)),
                          subtitle: Text(
                            '${test.subtitle.resolve(context)}\n${_exportText(context, ru: 'Прохождений за период', en: 'Runs in range', fr: 'Passages sur la période', de: 'Durchläufe im Zeitraum', pt: 'Realizações no período')}: ${_runCountForTest(test.id)}',
                          ),
                          isThreeLine: true,
                          onChanged: (v) => setState(() => _selectedBuiltInTests[test.kind] = v ?? false),
                        ),
                      for (final test in _customTests)
                        CheckboxListTile(
                          value: _selectedCustomTests[test.id] ?? false,
                          title: Text(test.title.resolve(context)),
                          subtitle: Text(
                            '${test.subtitle.resolve(context)}\n${_exportText(context, ru: 'Прохождений за период', en: 'Runs in range', fr: 'Passages sur la période', de: 'Durchläufe im Zeitraum', pt: 'Realizações no período')}: ${_runCountForTest(test.id)}',
                          ),
                          isThreeLine: true,
                          onChanged: (v) => setState(() => _selectedCustomTests[test.id] = v ?? false),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: _exporting ? null : () => _runExport(_ExportTarget.appFolder),
                child: Text(_exporting
                    ? _exportText(context, ru: 'Подготовка PDF...', en: 'Preparing PDF...', fr: 'Préparation du PDF...', de: 'PDF wird erstellt...', pt: 'Preparando PDF...')
                    : _exportText(context, ru: 'Выгрузить', en: 'Export', fr: 'Exporter', de: 'Exportieren', pt: 'Exportar')),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _exporting ? null : () => _runExport(_ExportTarget.customFolder),
                child: Text(_exportText(context, ru: 'Выгрузить в', en: 'Export to...', fr: 'Exporter vers...', de: 'Exportieren nach...', pt: 'Exportar para...')),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: _exporting ? null : () => _runExport(_ExportTarget.share),
                child: Text(_exportText(context, ru: 'Выгрузить и отослать', en: 'Export and share', fr: 'Exporter et envoyer', de: 'Exportieren und teilen', pt: 'Exportar e compartilhar')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTheme = 'Фиолетовый';
  late final StreamSubscription<String> _themeSubscription;
  Set<WelcomeImagesMode> _welcomeImagesModes = {WelcomeImagesMode.landscapes};
  bool _isPinEnabled = false;
  AppLanguage _selectedLanguage = AppLanguage.system;
  final TextEditingController _recoveryWordController = TextEditingController();
  final TextEditingController _securityQuestionController = TextEditingController();
  bool _isEditingRecoveryWord = false;
  bool _isEditingSecurityQuestion = false;
  // v2: список ежедневных напоминаний
  static const String _notifV2Key = 'notifications_daily_v2';
  static const int _maxDailyReminders = 6;
  List<_DailyReminderDraft> _dailyReminders = <_DailyReminderDraft>[];
  bool _didInitNotificationDefaults = false;

  // legacy keys (v1)
  static const String _notifEnabledKey = 'notifications_enabled';
  static const String _notifHourKey = 'notifications_hour';
  static const String _notifMinuteKey = 'notifications_minute';
  static const String _notifTitleKey = 'notifications_title';
  static const String _notifBodyKey = 'notifications_body';

  @override
  void initState() {
    super.initState();
    _themeSubscription = ThemeProvider.themeStreamController.stream.listen((themeName) {
      if (mounted) {
        setState(() => _selectedTheme = themeName);
      }
    });
    _loadTheme();
    _loadWelcomeImagesModes();
    _loadPinStatus();
    _loadRecoveryInfo();
    _loadLanguage();
    _loadNotificationSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitNotificationDefaults) return;
    _didInitNotificationDefaults = true;
    final l10n = AppLocalizations.of(context);
    if (_dailyReminders.isEmpty) {
      _dailyReminders = [
        _DailyReminderDraft(
          enabled: false,
          time: const TimeOfDay(hour: 20, minute: 0),
          title: TextEditingController(text: l10n.appTitle),
          body: TextEditingController(text: l10n.settingsNotificationsBodyHint),
        ),
      ];
    } else {
      for (final r in _dailyReminders) {
        if (r.title.text.trim().isEmpty) r.title.text = l10n.appTitle;
        if (r.body.text.trim().isEmpty) r.body.text = l10n.settingsNotificationsBodyHint;
      }
    }
  }

  @override
  void dispose() {
    _themeSubscription.cancel();
    _recoveryWordController.dispose();
    _securityQuestionController.dispose();
    for (final r in _dailyReminders) {
      r.title.dispose();
      r.body.dispose();
    }
    super.dispose();
  }

  Future<void> _loadRecoveryInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final recoveryWord = prefs.getString('recovery_word') ?? '';
    final securityQuestion = prefs.getString('security_question') ?? '';
    setState(() {
      _recoveryWordController.text = recoveryWord;
      _securityQuestionController.text = securityQuestion;
    });
  }

  Future<void> _saveRecoveryWord() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('recovery_word', _recoveryWordController.text);
    setState(() {
      _isEditingRecoveryWord = false;
    });
  }

  Future<void> _saveSecurityQuestion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('security_question', _securityQuestionController.text);
    setState(() {
      _isEditingSecurityQuestion = false;
    });
  }

  Future<void> _loadTheme() async {
    final theme = await ThemeProvider.getTheme();
    setState(() {
      _selectedTheme = theme;
    });
  }

  Future<void> _loadWelcomeImagesModes() async {
    final modes = await WelcomeImagesSettings.getModes();
    if (mounted) {
      setState(() => _welcomeImagesModes = modes);
    }
  }

  String _welcomeModeLabel(WelcomeImagesMode mode, AppLocalizations l10n) {
    switch (mode) {
      case WelcomeImagesMode.landscapes:
        return l10n.welcomeImagesLandscapes;
      case WelcomeImagesMode.cats:
        return l10n.welcomeImagesCats;
    }
  }

  String _welcomeModesSummary(AppLocalizations l10n) {
    if (_welcomeImagesModes.isEmpty) return l10n.welcomeImagesLandscapes;
    final labels = _welcomeImagesModes
        .map((mode) => _welcomeModeLabel(mode, l10n))
        .toList()
      ..sort();
    return labels.join(', ');
  }

  Future<void> _toggleWelcomeMode(WelcomeImagesMode mode, bool enabled) async {
    final next = Set<WelcomeImagesMode>.from(_welcomeImagesModes);
    if (enabled) {
      next.add(mode);
    } else {
      next.remove(mode);
      if (next.isEmpty) {
        next.add(mode);
      }
    }
    setState(() => _welcomeImagesModes = next);
    await WelcomeImagesSettings.saveModes(next);
  }

  Future<void> _loadLanguage() async {
    final lang = await LocaleProvider.getLanguage();
    setState(() {
      _selectedLanguage = lang;
    });
  }

  Future<void> _setLanguage(AppLanguage language) async {
    setState(() {
      _selectedLanguage = language;
    });
    if (mounted) {
      await (context.findAncestorStateOfType<_MyAppState>())?.updateLanguage(language);
    }
  }

  Future<void> _loadPinStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPinEnabled = prefs.getBool('pin_enabled') ?? false;
    });
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final rawV2 = prefs.getString(_notifV2Key);
    if (rawV2 != null && rawV2.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawV2) as List<dynamic>;
        final list = <_DailyReminderDraft>[];
        for (final item in decoded) {
          final m = Map<String, dynamic>.from(item as Map);
          list.add(_DailyReminderDraft(
            enabled: (m['enabled'] as bool?) ?? false,
            time: TimeOfDay(
              hour: (m['hour'] as int?) ?? 20,
              minute: (m['minute'] as int?) ?? 0,
            ),
            title: TextEditingController(text: (m['title'] as String?) ?? ''),
            body: TextEditingController(text: (m['body'] as String?) ?? ''),
          ));
        }
        setState(() => _dailyReminders = list.isEmpty ? <_DailyReminderDraft>[] : list);
        return;
      } catch (_) {}
    }

    // migrate legacy single reminder -> v2 list
    final enabled = prefs.getBool(_notifEnabledKey) ?? false;
    final hour = prefs.getInt(_notifHourKey) ?? 20;
    final minute = prefs.getInt(_notifMinuteKey) ?? 0;
    final title = prefs.getString(_notifTitleKey) ?? '';
    final body = prefs.getString(_notifBodyKey) ?? '';
    setState(() {
      _dailyReminders = [
        _DailyReminderDraft(
          enabled: enabled,
          time: TimeOfDay(hour: hour, minute: minute),
          title: TextEditingController(text: title),
          body: TextEditingController(text: body),
        ),
      ];
    });
    await _saveNotificationSettingsV2();
  }

  Future<void> _saveNotificationSettingsV2() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _dailyReminders.map((r) {
      return {
        'enabled': r.enabled,
        'hour': r.time.hour,
        'minute': r.time.minute,
        'title': r.title.text.trim(),
        'body': r.body.text.trim(),
      };
    }).toList();
    await prefs.setString(_notifV2Key, jsonEncode(list));
  }

  Future<void> _applyNotificationSchedule() async {
    await _saveNotificationSettingsV2();
    final enabledAny = _dailyReminders.any((r) => r.enabled);
    await NotificationService.cancelDailyRemindersV2(count: _maxDailyReminders);
    if (!enabledAny) return;
    await NotificationService.requestPermissionIfNeeded();
    final l10n = AppLocalizations.of(context);
    for (var i = 0; i < _dailyReminders.length; i++) {
      final r = _dailyReminders[i];
      if (!r.enabled) continue;
      final title = r.title.text.trim().isEmpty ? l10n.appTitle : r.title.text.trim();
      final body = r.body.text.trim().isEmpty ? l10n.settingsNotificationsBodyHint : r.body.text.trim();
      await NotificationService.scheduleDailyReminderV2(
        index: i,
        hour: r.time.hour,
        minute: r.time.minute,
        title: title,
        body: body,
      );
    }
  }

  Future<void> _pickNotificationTime(int index) async {
    final current = _dailyReminders[index].time;
    final initial = DateTime(2020, 1, 1, current.hour, current.minute);
    DateTime temp = initial;
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final accent = ThemeProvider.accentForScheme(scheme);
        return SafeArea(
          top: false,
          child: SizedBox(
            height: 320,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(AppLocalizations.of(context).cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(temp),
                        child: Text(
                          AppLocalizations.of(context).save,
                          style: TextStyle(color: accent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness: Theme.of(context).brightness,
                      primaryColor: accent,
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: initial,
                      use24hFormat: true,
                      onDateTimeChanged: (value) {
                        temp = value;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || picked == null) return;
    setState(() {
      _dailyReminders[index] = _dailyReminders[index].copyWith(
        time: TimeOfDay(hour: picked.hour, minute: picked.minute),
      );
    });
    await _applyNotificationSchedule();
  }

  void _addDailyReminder() {
    if (_dailyReminders.length >= _maxDailyReminders) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _dailyReminders = [
        ..._dailyReminders,
        _DailyReminderDraft(
          enabled: false,
          time: const TimeOfDay(hour: 20, minute: 0),
          title: TextEditingController(text: l10n.appTitle),
          body: TextEditingController(text: l10n.settingsNotificationsBodyHint),
        ),
      ];
    });
    _applyNotificationSchedule();
  }

  Future<void> _removeDailyReminder(int index) async {
    if (index < 0 || index >= _dailyReminders.length) return;
    if (_dailyReminders.length <= 1) return;
    final removed = _dailyReminders[index];
    setState(() {
      _dailyReminders = [
        ..._dailyReminders..removeAt(index),
      ];
    });
    removed.title.dispose();
    removed.body.dispose();
    await _applyNotificationSchedule();
  }

  Future<void> _togglePin(bool value) async {
    if (value) {
      // Включаем PIN-код
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PinCodeScreen(isSetup: true),
        ),
      );
    } else {
      // Отключаем PIN-код
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pin_enabled', false);
      setState(() {
        _isPinEnabled = false;
      });
    }
  }

  Future<void> _changePin() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PinCodeScreen(isSetup: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = ThemeProvider.accentForScheme(scheme);
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          l10n.settingsTitle,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.settingsThemeSection,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedTheme,
          decoration: InputDecoration(
            filled: true,
            fillColor: scheme.surfaceContainerHighest,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.55)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.45)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accent.withOpacity(0.95), width: 2),
            ),
          ),
          items: ThemeProvider.themeColors.keys.map((String theme) {
            return DropdownMenuItem<String>(
              value: theme,
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: ThemeProvider.themeColors[theme],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(ThemeProvider.displayName(context, theme)),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) async {
            if (newValue != null) {
              setState(() {
                _selectedTheme = newValue;
              });
              await ThemeProvider.saveTheme(newValue);
              if (mounted) {
                final appState = context.findAncestorStateOfType<_MyAppState>();
                appState?.updateTheme(newValue);
              }
            }
          },
        ),
        const SizedBox(height: 24),
        Text(
          l10n.settingsWelcomeImagesSection,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant.withOpacity(0.45)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              leading: Icon(Icons.image_outlined, color: accent),
              title: Text(l10n.settingsWelcomeImagesSection),
              subtitle: Text(
                _welcomeModesSummary(l10n),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              children: [
                CheckboxListTile(
                  value: _welcomeImagesModes.contains(WelcomeImagesMode.landscapes),
                  title: Text(l10n.welcomeImagesLandscapes),
                  secondary: const Icon(Icons.landscape_outlined),
                  onChanged: (value) {
                    if (value == null) return;
                    _toggleWelcomeMode(WelcomeImagesMode.landscapes, value);
                  },
                ),
                CheckboxListTile(
                  value: _welcomeImagesModes.contains(WelcomeImagesMode.cats),
                  title: Text(l10n.welcomeImagesCats),
                  secondary: const Icon(Icons.pets_outlined),
                  onChanged: (value) {
                    if (value == null) return;
                    _toggleWelcomeMode(WelcomeImagesMode.cats, value);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.settingsNotificationsSection,
          style: TextStyle(fontWeight: FontWeight.bold, color: accent),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                ...List.generate(_dailyReminders.length, (i) {
                  final r = _dailyReminders[i];
                  final timeText =
                      '${r.time.hour.toString().padLeft(2, '0')}:${r.time.minute.toString().padLeft(2, '0')}';
                  return Padding(
                    padding: EdgeInsets.only(bottom: i == _dailyReminders.length - 1 ? 0 : 16),
                    child: Column(
                      children: [
                        SwitchTheme(
                          data: SwitchThemeData(
                            thumbColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.disabled)) {
                                return scheme.onSurface.withOpacity(0.38);
                              }
                              if (states.contains(WidgetState.selected)) return accent;
                              return scheme.outline;
                            }),
                            trackColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.disabled)) {
                                return scheme.onSurface.withOpacity(0.12);
                              }
                              if (states.contains(WidgetState.selected)) {
                                return accent.withOpacity(0.45);
                              }
                              return scheme.surfaceContainerHighest;
                            }),
                          ),
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.settingsNotificationsEnabled,
                                    style: TextStyle(
                                      color: r.enabled ? accent : scheme.onSurface.withOpacity(0.72),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (i > 0 && _dailyReminders.length > 1)
                                  IconButton(
                                    tooltip: l10n.delete,
                                    onPressed: () => _removeDailyReminder(i),
                                    icon: Icon(Icons.delete_outline, color: scheme.error),
                                  ),
                              ],
                            ),
                            value: r.enabled,
                            onChanged: (value) async {
                              setState(() {
                                _dailyReminders[i] = _dailyReminders[i].copyWith(enabled: value);
                              });
                              await _applyNotificationSchedule();
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            l10n.settingsNotificationsTime,
                            style: TextStyle(
                              color: Color.lerp(scheme.onSurface, accent, r.enabled ? 0.25 : 0.12),
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(r.enabled ? 0.14 : 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: accent.withOpacity(r.enabled ? 0.95 : 0.35),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              timeText,
                              style: TextStyle(
                                color: accent.withOpacity(r.enabled ? 1.0 : 0.55),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          onTap: r.enabled ? () => _pickNotificationTime(i) : null,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: r.title,
                          enabled: r.enabled,
                          decoration: InputDecoration(
                            labelText: l10n.settingsNotificationsTitle,
                            labelStyle: TextStyle(
                              color: r.enabled ? accent.withOpacity(0.95) : scheme.onSurfaceVariant,
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: scheme.outline.withOpacity(0.55)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: scheme.outline.withOpacity(0.55)),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: scheme.outline.withOpacity(0.28)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: accent, width: 2),
                            ),
                          ),
                          onChanged: (_) => _applyNotificationSchedule(),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: r.body,
                          enabled: r.enabled,
                          minLines: 2,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: l10n.settingsNotificationsBody,
                            hintText: l10n.settingsNotificationsBodyHint,
                            labelStyle: TextStyle(
                              color: r.enabled ? accent.withOpacity(0.95) : scheme.onSurfaceVariant,
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: scheme.outline.withOpacity(0.55)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: scheme.outline.withOpacity(0.55)),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: scheme.outline.withOpacity(0.28)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: accent, width: 2),
                            ),
                          ),
                          onChanged: (_) => _applyNotificationSchedule(),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            style: TextButton.styleFrom(foregroundColor: accent),
                            onPressed: r.enabled
                                ? () async {
                                    await NotificationService.requestPermissionIfNeeded();
                                    final title = r.title.text.trim().isEmpty ? l10n.appTitle : r.title.text.trim();
                                    final body = r.body.text.trim().isEmpty
                                        ? l10n.settingsNotificationsBodyHint
                                        : r.body.text.trim();
                                    await NotificationService.showNow(title: title, body: body);
                                  }
                                : null,
                            child: Text(l10n.settingsNotificationsTest),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton.filledTonal(
                    onPressed: _dailyReminders.length < _maxDailyReminders ? _addDailyReminder : null,
                    icon: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _exportText(
            context,
            ru: 'Выгрузка данных',
            en: 'Data export',
            fr: 'Export des données',
            de: 'Datenexport',
            pt: 'Exportação de dados',
          ),
          style: TextStyle(fontWeight: FontWeight.bold, color: accent),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Icon(Icons.picture_as_pdf_outlined, color: accent),
            title: Text(
              _exportText(
                context,
                ru: 'Собрать PDF-отчёт по дневнику, настроению и тестам',
                en: 'Build a PDF report for diary, mood, and tests',
                fr: 'Créer un rapport PDF pour le journal, l’humeur et les tests',
                de: 'PDF-Bericht für Tagebuch, Stimmung und Tests erstellen',
                pt: 'Gerar relatório PDF do diário, humor e testes',
              ),
            ),
            subtitle: Text(
              _exportText(
                context,
                ru: 'Выберите период, нужные разделы и способ сохранения или отправки.',
                en: 'Choose a time range, sections, and how to save or share the file.',
                fr: 'Choisissez la période, les sections et la façon d’enregistrer ou partager le fichier.',
                de: 'Zeitraum, Bereiche und Speicher- oder Freigabeart auswählen.',
                pt: 'Escolha o período, as seções e como salvar ou compartilhar o arquivo.',
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DataExportScreen(),
                ),
              );
            },
          ),
        ),
        const Divider(),
        Text(
          l10n.settingsLanguageSection,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<AppLanguage>(
          value: _selectedLanguage,
          decoration: InputDecoration(
            filled: true,
            fillColor: scheme.surfaceContainerHighest,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.55)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.45)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accent.withOpacity(0.95), width: 2),
            ),
          ),
          items: <DropdownMenuItem<AppLanguage>>[
            DropdownMenuItem(
              value: AppLanguage.system,
              child: Text(l10n.languageSystem),
            ),
            DropdownMenuItem(
              value: AppLanguage.ru,
              child: Text(l10n.languageRussian),
            ),
            DropdownMenuItem(
              value: AppLanguage.en,
              child: Text(l10n.languageEnglish),
            ),
            DropdownMenuItem(
              value: AppLanguage.fr,
              child: Text(l10n.languageFrench),
            ),
            DropdownMenuItem(
              value: AppLanguage.de,
              child: Text(l10n.languageGerman),
            ),
            DropdownMenuItem(
              value: AppLanguage.pt,
              child: Text(l10n.languagePortuguese),
            ),
          ],
          onChanged: (newValue) async {
            if (newValue == null) return;
            await _setLanguage(newValue);
          },
        ),
        const Divider(),
        SwitchListTile(
          title: Text(
            l10n.pinTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(_isPinEnabled ? l10n.pinEnabled : l10n.pinDisabled),
          value: _isPinEnabled,
          onChanged: _togglePin,
        ),
        if (_isPinEnabled) ...[
          ListTile(
            title: Text(
              l10n.changePin,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.edit),
            onTap: _changePin,
          ),
          const Divider(),
          ListTile(
            title: Text(
              l10n.recoveryWord,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: _isEditingRecoveryWord
                ? TextField(
                    controller: _recoveryWordController,
                    decoration: InputDecoration(
                      hintText: l10n.enterWordHint,
                      border: const OutlineInputBorder(),
                    ),
                  )
                : Text(_recoveryWordController.text.isEmpty
                    ? l10n.notSet
                    : '••••••••'),
            trailing: _isEditingRecoveryWord
                ? IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _saveRecoveryWord,
                  )
                : IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      setState(() {
                        _isEditingRecoveryWord = true;
                      });
                    },
                  ),
          ),
          ListTile(
            title: Text(
              l10n.securityQuestion,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: _isEditingSecurityQuestion
                ? TextField(
                    controller: _securityQuestionController,
                    decoration: InputDecoration(
                      hintText: l10n.enterQuestionHint,
                      border: const OutlineInputBorder(),
                    ),
                  )
                : Text(_securityQuestionController.text.isEmpty
                    ? l10n.notInstalled
                    : _securityQuestionController.text),
            trailing: _isEditingSecurityQuestion
                ? IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _saveSecurityQuestion,
                  )
                : IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      setState(() {
                        _isEditingSecurityQuestion = true;
                      });
                    },
                  ),
          ),
        ],
      ],
    );
  }
}

class _DailyReminderDraft {
  final bool enabled;
  final TimeOfDay time;
  final TextEditingController title;
  final TextEditingController body;

  const _DailyReminderDraft({
    required this.enabled,
    required this.time,
    required this.title,
    required this.body,
  });

  _DailyReminderDraft copyWith({
    bool? enabled,
    TimeOfDay? time,
  }) {
    return _DailyReminderDraft(
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
      title: title,
      body: body,
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accent.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  l10n.welcomeDialogTitle,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Text(
                  l10n.welcomeDialogBody1,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.welcomeDialogBody2,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.welcomeDialogBenefitsTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildBulletPoint(l10n.welcomeDialogBullet1, accent),
                _buildBulletPoint(l10n.welcomeDialogBullet2, accent),
                _buildBulletPoint(l10n.welcomeDialogBullet3, accent),
                _buildBulletPoint(l10n.welcomeDialogBullet4, accent),
                _buildBulletPoint(l10n.welcomeDialogBullet5, accent),
                const SizedBox(height: 24),
                Text(
                  l10n.welcomeDialogFooter,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(currentTheme: 'Фиолетовый'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.start,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PinCodeScreen extends StatefulWidget {
  final bool isSetup;
  const PinCodeScreen({super.key, required this.isSetup});

  @override
  State<PinCodeScreen> createState() => _PinCodeScreenState();
}

class _PinCodeScreenState extends State<PinCodeScreen> {
  final List<String> _pin = [];
  String _confirmPin = '';
  bool _isConfirming = false;
  String _errorMessage = '';
  bool _isRecoveryMode = false;
  final TextEditingController _recoveryWordController = TextEditingController();
  final TextEditingController _securityQuestionController = TextEditingController();
  bool _isSettingUpRecovery = false;

  @override
  void dispose() {
    _recoveryWordController.dispose();
    _securityQuestionController.dispose();
    super.dispose();
  }

  Future<void> _checkPin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('pin_code') ?? '';
    
    if (_pin.join() == savedPin) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(currentTheme: 'Фиолетовый'),
          ),
        );
      }
    } else {
      setState(() {
        _errorMessage = AppLocalizations.of(context).invalidPin;
        _pin.clear();
      });
    }
  }

  Future<void> _checkRecoveryWord() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRecoveryWord = prefs.getString('recovery_word') ?? '';
    
    if (_recoveryWordController.text.toLowerCase() == savedRecoveryWord.toLowerCase()) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(currentTheme: 'Фиолетовый'),
          ),
        );
      }
    } else {
      setState(() {
        _errorMessage = AppLocalizations.of(context).invalidRecoveryWord;
        _recoveryWordController.clear();
      });
    }
  }

  Future<void> _savePin() async {
    if (_pin.length == 4) {
      if (!_isConfirming) {
        setState(() {
          _confirmPin = _pin.join();
          _pin.clear();
          _isConfirming = true;
          _errorMessage = '';
        });
      } else {
        if (_pin.join() == _confirmPin) {
          setState(() {
            _isSettingUpRecovery = true;
            _errorMessage = '';
          });
        } else {
          setState(() {
            _errorMessage = AppLocalizations.of(context).pinMismatch;
            _pin.clear();
            _isConfirming = false;
          });
        }
      }
    }
  }

  Future<void> _saveRecoveryInfo() async {
    if (_recoveryWordController.text.isEmpty || _securityQuestionController.text.isEmpty) {
      setState(() {
        _errorMessage = AppLocalizations.of(context).fillAllFields;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pin_code', _confirmPin);
    await prefs.setString('recovery_word', _recoveryWordController.text);
    await prefs.setString('security_question', _securityQuestionController.text);
    await prefs.setBool('pin_enabled', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(currentTheme: 'Фиолетовый'),
        ),
      );
    }
  }

  void _onNumberPressed(String number) {
    if (_pin.length < 4) {
      setState(() {
        _pin.add(number);
        _errorMessage = '';
      });
      if (_pin.length == 4) {
        if (widget.isSetup) {
          _savePin();
        } else {
          _checkPin();
        }
      }
    }
  }

  void _onDeletePressed() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin.removeLast();
        _errorMessage = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: widget.isSetup ? AppBar(
        title: Text(l10n.pinSetupTitle),
      ) : null,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isRecoveryMode && !_isSettingUpRecovery) ...[
              Text(
                widget.isSetup
                    ? (_isConfirming ? l10n.pinPromptConfirm : l10n.pinPromptNew)
                    : l10n.pinPromptEnter,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.all(8),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _pin.length ? Theme.of(context).primaryColor : Colors.grey.shade300,
                    ),
                  );
                }),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              if (!widget.isSetup)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isRecoveryMode = true;
                      _errorMessage = '';
                    });
                  },
                  child: Text(l10n.forgotPin),
                ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    if (index == 9) {
                      return const SizedBox.shrink();
                    } else if (index == 10) {
                      return _buildNumberButton('0');
                    } else if (index == 11) {
                      return IconButton(
                        onPressed: _onDeletePressed,
                        icon: const Icon(Icons.backspace),
                      );
                    } else {
                      return _buildNumberButton((index + 1).toString());
                    }
                  },
                ),
              ),
            ] else if (_isSettingUpRecovery) ...[
              Text(
                l10n.recoverySetupTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _recoveryWordController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.recoveryWord,
                        hintText: l10n.enterWordHint,
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _securityQuestionController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.securityQuestion,
                        hintText: l10n.enterQuestionHint,
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveRecoveryInfo,
                child: Text(l10n.save),
              ),
            ] else ...[
              Text(
                l10n.recoveryTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: TextField(
                  controller: _recoveryWordController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: l10n.enterWordHint,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkRecoveryWord,
                child: Text(l10n.confirm),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isRecoveryMode = false;
                    _errorMessage = '';
                    _recoveryWordController.clear();
                  });
                },
                child: Text(l10n.backToPin),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return ElevatedButton(
      onPressed: () => _onNumberPressed(number),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        number,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
