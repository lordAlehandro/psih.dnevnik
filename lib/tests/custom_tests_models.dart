import 'dart:convert';

import 'package:flutter/services.dart';

import 'psqi_scoring.dart';
import 'tests_models.dart';

class CustomTestBand {
  final int minInclusive;
  final int maxInclusive;
  final TLoc title;
  final TLoc? description;

  const CustomTestBand({
    required this.minInclusive,
    required this.maxInclusive,
    required this.title,
    this.description,
  });

  factory CustomTestBand.fromJson(Map<String, dynamic> json) {
    return CustomTestBand(
      minInclusive: (json['minInclusive'] as num).toInt(),
      maxInclusive: (json['maxInclusive'] as num).toInt(),
      title: _tlocFromJson(json['title']),
      description: json['description'] == null
          ? null
          : _tlocFromJson(Map<String, dynamic>.from(json['description'] as Map)),
    );
  }
}

class CustomTestSubscale {
  final String id;
  final TLoc label;
  final List<int> itemIndices; // 0-based
  final int? maxScore;

  const CustomTestSubscale({
    required this.id,
    required this.label,
    required this.itemIndices,
    this.maxScore,
  });

  factory CustomTestSubscale.fromJson(Map<String, dynamic> json) {
    final idRaw = _stringOrNull(json['id']);
    return CustomTestSubscale(
      id: (idRaw != null && idRaw.isNotEmpty) ? idRaw : 'subscale',
      label: _tlocFromJson(json['label']),
      itemIndices: (json['itemIndices'] as List<dynamic>).map((e) => (e as num).toInt()).toList(),
      maxScore: (json['maxScore'] as num?)?.toInt(),
    );
  }
}

class CustomTestDefinition {
  final String id;
  final TestCategoryId category;
  final TLoc title;
  final TLoc subtitle;
  final TLoc description;
  final TLoc? instructions;
  final List<TestQuestion> questions;
  final List<CustomTestBand> bands;
  final List<CustomTestSubscale> subscales;
  final int? maxScore;
  final String? bandsBasis; // "raw" (default) or "percent"
  /// When true, the result screen omits the headline total (use when only subscales are interpretable).
  final bool resultSubscalesOnly;
  final TLoc? resultNote;
  /// Non-null selects special scoring (e.g. `"psqi"` — not a plain sum of option scores).
  final String? scoring;

  const CustomTestDefinition({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.questions,
    required this.bands,
    required this.subscales,
    this.instructions,
    this.maxScore,
    this.bandsBasis,
    this.resultSubscalesOnly = false,
    this.resultNote,
    this.scoring,
  });

  int scoreTotal(List<int> answers) {
    switch (scoring) {
      case 'psqi':
        return PsqiScoring.globalScore(answers);
      default:
        return answers.fold<int>(0, (a, b) => a + b);
    }
  }

  int scoreForBands(List<int> answers) {
    final raw = scoreTotal(answers);
    if (bandsBasis == 'percent' && maxScore != null && maxScore! > 0) {
      return ((raw / maxScore!) * 100).round();
    }
    return raw;
  }

  int scoreSubscale(CustomTestSubscale s, List<int> answers) {
    var sum = 0;
    for (final idx in s.itemIndices) {
      if (idx < 0 || idx >= answers.length) continue;
      sum += answers[idx];
    }
    return sum;
  }

  CustomTestBand? bandFor(int scoreForBands) {
    for (final b in bands) {
      if (scoreForBands >= b.minInclusive && scoreForBands <= b.maxInclusive) return b;
    }
    return null;
  }

  factory CustomTestDefinition.fromJson(Map<String, dynamic> json) {
    final qList = json['questions'] as List<dynamic>;
    final questions = <TestQuestion>[];
    for (var i = 0; i < qList.length; i++) {
      final q = Map<String, dynamic>.from(qList[i] as Map);
      final qid = _stringOrNull(q['id']);
      questions.add(
        TestQuestion(
          id: (qid != null && qid.isNotEmpty) ? qid : 'q$i',
          text: _tlocFromJson(q['text']),
          options: (q['options'] as List<dynamic>)
              .map((o) => Map<String, dynamic>.from(o as Map))
              .map(
                (o) => TestOption(
                  label: _tlocFromJson(o['label']),
                  score: (o['score'] as num).toInt(),
                ),
              )
              .toList(),
        ),
      );
    }

    final defId = _stringOrNull(json['id']);
    return CustomTestDefinition(
      id: (defId != null && defId.isNotEmpty) ? defId : 'custom_test',
      category: _testCategoryFromJson(json['category']),
      title: _tlocFromJson(json['title']),
      subtitle: _tlocFromJson(json['subtitle']),
      description: _tlocFromJson(json['description']),
      instructions: json['instructions'] == null
          ? null
          : _tlocFromJson(Map<String, dynamic>.from(json['instructions'] as Map)),
      questions: questions,
      bands: (json['bands'] as List<dynamic>)
          .map((e) => CustomTestBand.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      subscales: (json['subscales'] as List<dynamic>? ?? const [])
          .map((e) => CustomTestSubscale.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      maxScore: (json['maxScore'] as num?)?.toInt(),
      bandsBasis: json['bandsBasis'] as String?,
      resultSubscalesOnly: json['resultSubscalesOnly'] == true,
      resultNote: json['resultNote'] == null
          ? null
          : _tlocFromJson(Map<String, dynamic>.from(json['resultNote'] as Map)),
      scoring: _stringOrNull(json['scoring']),
    );
  }
}

String? _stringOrNull(dynamic v) => v is String ? v : null;

TestCategoryId _testCategoryFromJson(dynamic v) {
  final s = _stringOrNull(v);
  if (s == null || s.isEmpty) return TestCategoryId.depression;
  try {
    return TestCategoryId.values.byName(s);
  } catch (_) {
    return TestCategoryId.depression;
  }
}

TLoc _tlocFromJson(Object? raw) {
  final json = Map<String, dynamic>.from(raw as Map);
  final ru = _stringOrNull(json['ru']) ?? '';
  final en = _stringOrNull(json['en']) ?? '';
  final fill = ru.isNotEmpty ? ru : en;
  return TLoc(
    ru: ru.isNotEmpty ? ru : fill,
    en: en.isNotEmpty ? en : fill,
    fr: _stringOrNull(json['fr']),
    de: _stringOrNull(json['de']),
    pt: _stringOrNull(json['pt']),
  );
}

class CustomTestsLoader {
  static Future<List<CustomTestDefinition>> loadAll() async {
    final manifestRaw = await rootBundle.loadString('AssetManifest.json');
    final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;

    final customAssets = manifest.keys
        .where((k) => k.startsWith('assets/tests/custom/'))
        .where((k) => k.toLowerCase().endsWith('.json'))
        .toList()
      ..sort();

    final out = <CustomTestDefinition>[];
    for (final path in customAssets) {
      final raw = await rootBundle.loadString(path);
      if (raw.trim().isEmpty) continue;

      final decoded = jsonDecode(raw);
      if (decoded is List) {
        out.addAll(
          decoded
              .map((e) => CustomTestDefinition.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList(),
        );
      } else if (decoded is Map) {
        out.add(CustomTestDefinition.fromJson(Map<String, dynamic>.from(decoded)));
      }
    }
    return out;
  }
}

