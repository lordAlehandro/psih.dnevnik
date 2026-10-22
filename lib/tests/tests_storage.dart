import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'tests_models.dart';

class TestHistoryStorage {
  static const String key = 'tests_results_v1';

  static Future<List<SavedTestResult>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return <SavedTestResult>[];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => SavedTestResult.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<List<SavedTestResult>> loadForTest(String testId) async {
    final all = await loadAll();
    return all.where((e) => e.testId == testId).toList()
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
  }

  static Future<void> append(SavedTestResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();
    all.add(result);
    await prefs.setString(key, jsonEncode(all.map((e) => e.toJson()).toList()));
  }
}
