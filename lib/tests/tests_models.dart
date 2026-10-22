import 'package:flutter/material.dart';

enum TestCategoryId {
  depression,
  anxiety,
  stress,
  bipolar,
  ocd,
  addictions,
  personality,
  wellbeing,
  sleep,
}

enum TestKind {
  phq2,
  phq9,
  gad7,
  audit,
  ftnd,
  who5,
  dass21,
  rses,
  pcl5,
  swls,
}

String localeCode(BuildContext context) =>
    Localizations.localeOf(context).languageCode;

String locText(
  BuildContext context, {
  required String ru,
  required String en,
  String? fr,
  String? de,
  String? pt,
}) {
  switch (localeCode(context)) {
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

class TLoc {
  final String ru;
  final String en;
  final String? fr;
  final String? de;
  final String? pt;

  const TLoc({
    required this.ru,
    required this.en,
    this.fr,
    this.de,
    this.pt,
  });

  String resolve(BuildContext context) => locText(
        context,
        ru: ru,
        en: en,
        fr: fr,
        de: de,
        pt: pt,
      );
}

class TestOption {
  final TLoc label;
  final int score;

  const TestOption({required this.label, required this.score});
}

class TestQuestion {
  final String id;
  final TLoc text;
  final List<TestOption> options;

  const TestQuestion({
    required this.id,
    required this.text,
    required this.options,
  });
}

class TestDefinition {
  final String id;
  final TestKind kind;
  final TestCategoryId category;
  final TLoc title;
  final TLoc subtitle;
  final TLoc description;
  final List<TestQuestion> questions;

  const TestDefinition({
    required this.id,
    required this.kind,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.questions,
  });
}

class UnavailableTest {
  final TestCategoryId category;
  final TLoc title;
  final TLoc note;

  const UnavailableTest({
    required this.category,
    required this.title,
    required this.note,
  });
}

class ResultMetric {
  final String label;
  final String value;
  final String level;

  const ResultMetric({
    required this.label,
    required this.value,
    required this.level,
  });
}

class TestEvaluation {
  final String scoreText;
  final String levelTitle;
  final String summary;
  final List<String> recommendations;
  final List<ResultMetric> metrics;

  const TestEvaluation({
    required this.scoreText,
    required this.levelTitle,
    required this.summary,
    this.recommendations = const [],
    this.metrics = const [],
  });
}

class SavedTestResult {
  final String testId;
  final DateTime completedAt;
  final List<int> answers;

  const SavedTestResult({
    required this.testId,
    required this.completedAt,
    required this.answers,
  });

  Map<String, dynamic> toJson() => {
        'testId': testId,
        'completedAt': completedAt.toIso8601String(),
        'answers': answers,
      };

  factory SavedTestResult.fromJson(Map<String, dynamic> json) {
    return SavedTestResult(
      testId: json['testId'].toString(),
      completedAt: DateTime.parse(json['completedAt'].toString()),
      answers: List<int>.from(json['answers'] as List<dynamic>),
    );
  }
}
