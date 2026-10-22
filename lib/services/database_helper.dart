import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/diary_entry.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static const String _entriesKey = 'diary_entries';

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'emotion_diary.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        emotionType TEXT NOT NULL,
        imagePath TEXT
      )
    ''');
  }

  Future<int> insertEntry(DiaryEntry entry) async {
    if (entry.id == 0) {
      final entries = await getEntries();
      final newId = entries.isEmpty ? 1 : entries.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
      final newEntry = DiaryEntry(
        id: newId,
        date: entry.date,
        title: entry.title,
        content: entry.content,
        emotionTypes: entry.emotionTypes,
        imagePath: entry.imagePath,
      );
      await _saveEntries([...entries, newEntry]);
      return newId;
    }
    return 0;
  }

  Future<int> updateEntry(DiaryEntry entry) async {
    final entries = await getEntries();
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      entries[index] = entry;
      await _saveEntries(entries);
      return 1;
    }
    return 0;
  }

  Future<int> deleteEntry(int id) async {
    final entries = await getEntries();
    final filteredEntries = entries.where((e) => e.id != id).toList();
    await _saveEntries(filteredEntries);
    return 1;
  }

  Future<List<DiaryEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getStringList(_entriesKey) ?? [];
    return entriesJson
        .map((json) => DiaryEntry.fromMap(jsonDecode(json)))
        .toList();
  }

  Future<DiaryEntry?> getEntry(int id) async {
    final entries = await getEntries();
    return entries.firstWhere((entry) => entry.id == id);
  }

  Future<void> _saveEntries(List<DiaryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = entries
        .map((entry) => jsonEncode(entry.toMap()))
        .toList();
    await prefs.setStringList(_entriesKey, entriesJson);
  }
} 