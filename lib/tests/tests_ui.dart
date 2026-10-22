import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'tests_catalog.dart';
import 'custom_tests_models.dart';
import 'psqi_scoring.dart';
import 'tests_models.dart';
import 'tests_storage.dart';

String _psqiComponentLabel(BuildContext context, int index) {
  switch (index) {
    case 0:
      return locText(
        context,
        ru: 'Субъективное качество сна',
        en: 'Subjective sleep quality',
        fr: 'Qualité subjective du sommeil',
        de: 'Subjektive Schlafqualität',
        pt: 'Qualidade subjetiva do sono',
      );
    case 1:
      return locText(
        context,
        ru: 'Засыпание (латентность)',
        en: 'Sleep latency',
        fr: 'Latence du sommeil',
        de: 'Schlaflatenz',
        pt: 'Latência do sono',
      );
    case 2:
      return locText(
        context,
        ru: 'Длительность сна',
        en: 'Sleep duration',
        fr: 'Durée du sommeil',
        de: 'Schlafdauer',
        pt: 'Duração do sono',
      );
    case 3:
      return locText(
        context,
        ru: 'Привычная эффективность сна',
        en: 'Habitual sleep efficiency',
        fr: 'Efficacité habituelle du sommeil',
        de: 'Gewöhnliche Schlafeffizienz',
        pt: 'Eficiência habitual do sono',
      );
    case 4:
      return locText(
        context,
        ru: 'Нарушения сна',
        en: 'Sleep disturbances',
        fr: 'Perturbations du sommeil',
        de: 'Schlafstörungen',
        pt: 'Distúrbios do sono',
      );
    case 5:
      return locText(
        context,
        ru: 'Приём снотворного / седативных',
        en: 'Use of sleep medication',
        fr: 'Usage de somnifères',
        de: 'Einnahme von Schlafmitteln',
        pt: 'Uso de medicamentos para dormir',
      );
    default:
      return locText(
        context,
        ru: 'Дневная дисфункция',
        en: 'Daytime dysfunction',
        fr: 'Dysfonctionnement diurne',
        de: 'Tagtägliche Beeinträchtigung',
        pt: 'Disfunção diurna',
      );
  }
}

class TestsScreen extends StatelessWidget {
  const TestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primary;
    return FutureBuilder<List<CustomTestDefinition>>(
      future: CustomTestsLoader.loadAll(),
      builder: (context, snapshot) {
        final custom = snapshot.data ?? const <CustomTestDefinition>[];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (snapshot.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  locText(
                    context,
                    ru: 'Не удалось загрузить пользовательские тесты. Проверьте файл assets/tests/custom/tests.json и что assets/tests/ добавлен в pubspec.yaml. Ошибка: ${snapshot.error}',
                    en: 'Failed to load custom tests. Check assets/tests/custom/tests.json and that assets/tests/ is listed in pubspec.yaml. Error: ${snapshot.error}',
                    fr: 'Impossible de charger les tests personnalisés. Vérifiez assets/tests/custom/tests.json et que assets/tests/ est listé dans pubspec.yaml. Erreur : ${snapshot.error}',
                    de: 'Benutzerdefinierte Tests konnten nicht geladen werden. Prüfen Sie assets/tests/custom/tests.json und dass assets/tests/ in pubspec.yaml eingetragen ist. Fehler: ${snapshot.error}',
                    pt: 'Falha ao carregar testes personalizados. Verifique assets/tests/custom/tests.json e se assets/tests/ está listado no pubspec.yaml. Erro: ${snapshot.error}',
                  ),
                  style: TextStyle(color: scheme.error, height: 1.35),
                ),
              ),

            for (final category in TestsCatalog.categories) ...[
              Text(
                category.$2.resolve(context),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
              const SizedBox(height: 8),
              ...custom.where((e) => e.category == category.$1).map((t) => _CustomTestCard(test: t)),
              ...TestsCatalog.availableTests
                  .where((e) => e.category == category.$1)
                  .map((test) => _TestCard(test: test)),
              ...TestsCatalog.pendingTests
                  .where((e) => e.category == category.$1)
                  .map((test) => _PendingTestCard(test: test)),
              const SizedBox(height: 18),
            ],
          ],
        );
      },
    );
  }
}

class _CustomTestCard extends StatelessWidget {
  final CustomTestDefinition test;

  const _CustomTestCard({required this.test});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test.title.resolve(context),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        test.subtitle.resolve(context),
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: locText(
                    context,
                    ru: 'Прошлые результаты',
                    en: 'Past results',
                    fr: 'Résultats passés',
                    de: 'Frühere Ergebnisse',
                    pt: 'Resultados anteriores',
                  ),
                  icon: const Icon(Icons.history),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CustomTestHistoryScreen(test: test),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              test.description.resolve(context),
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.3),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CustomTestRunScreen(test: test),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  locText(
                    context,
                    ru: 'Пройти',
                    en: 'Start',
                    fr: 'Commencer',
                    de: 'Starten',
                    pt: 'Iniciar',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  final TestDefinition test;

  const _TestCard({required this.test});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test.title.resolve(context),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        test.subtitle.resolve(context),
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: locText(
                    context,
                    ru: 'Прошлые результаты',
                    en: 'Past results',
                    fr: 'Résultats passés',
                    de: 'Frühere Ergebnisse',
                    pt: 'Resultados anteriores',
                  ),
                  icon: const Icon(Icons.history),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TestHistoryScreen(test: test),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              test.description.resolve(context),
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.3),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TestRunScreen(test: test),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  locText(
                    context,
                    ru: 'Пройти',
                    en: 'Start',
                    fr: 'Commencer',
                    de: 'Starten',
                    pt: 'Iniciar',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingTestCard extends StatelessWidget {
  final UnavailableTest test;

  const _PendingTestCard({required this.test});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(test.title.resolve(context)),
        subtitle: Text(
          test.note.resolve(context),
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        trailing: Icon(Icons.lock_outline, color: scheme.outline),
      ),
    );
  }
}

class TestRunScreen extends StatefulWidget {
  final TestDefinition test;

  const TestRunScreen({super.key, required this.test});

  @override
  State<TestRunScreen> createState() => _TestRunScreenState();
}

class CustomTestRunScreen extends StatefulWidget {
  final CustomTestDefinition test;

  const CustomTestRunScreen({super.key, required this.test});

  @override
  State<CustomTestRunScreen> createState() => _CustomTestRunScreenState();
}

class _CustomTestRunScreenState extends State<CustomTestRunScreen> {
  /// Selected option index per question (not raw score — several options may share the same score, e.g. SHAPS).
  late final List<int?> _selectedOptionIndex =
      List<int?>.filled(widget.test.questions.length, null);

  Future<void> _submit() async {
    if (_selectedOptionIndex.any((e) => e == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            locText(
              context,
              ru: 'Ответьте на все вопросы теста.',
              en: 'Please answer all questions.',
              fr: 'Veuillez répondre à toutes les questions.',
              de: 'Bitte beantworten Sie alle Fragen.',
              pt: 'Responda todas as perguntas.',
            ),
          ),
        ),
      );
      return;
    }
    final answers = List<int>.generate(
      widget.test.questions.length,
      (i) => widget.test.questions[i].options[_selectedOptionIndex[i]!].score,
    );
    final completedAt = DateTime.now();
    await TestHistoryStorage.append(
      SavedTestResult(
        testId: widget.test.id,
        completedAt: completedAt,
        answers: answers,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => CustomTestResultScreen(
          test: widget.test,
          completedAt: completedAt,
          answers: answers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.test.title.resolve(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.test.instructions != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.test.instructions!.resolve(context),
                  style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          for (var i = 0; i < widget.test.questions.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}. ${widget.test.questions[i].text.resolve(context)}',
                      style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
                    ),
                    const SizedBox(height: 10),
                    ...widget.test.questions[i].options.asMap().entries.map((entry) {
                      final j = entry.key;
                      final option = entry.value;
                      return RadioListTile<int>(
                        value: j,
                        groupValue: _selectedOptionIndex[i],
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(option.label.resolve(context)),
                        onChanged: (value) => setState(() => _selectedOptionIndex[i] = value),
                      );
                    }),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _submit,
            child: Text(
              locText(
                context,
                ru: 'Завершить тест',
                en: 'Finish test',
                fr: 'Terminer le test',
                de: 'Test beenden',
                pt: 'Concluir teste',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomTestResultScreen extends StatelessWidget {
  final CustomTestDefinition test;
  final DateTime completedAt;
  final List<int> answers;

  const CustomTestResultScreen({
    super.key,
    required this.test,
    required this.completedAt,
    required this.answers,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locale = localeCode(context);
    final isAsrs = test.id == 'asrs';
    final scoreForBands = test.scoreForBands(answers);
    final band = test.bandFor(scoreForBands);
    final psqiComps =
        test.scoring == 'psqi' && answers.length >= 18 ? PsqiScoring.componentScores(answers) : null;
    final subscaleScores = <String, int>{
      for (final s in test.subscales) s.id: test.scoreSubscale(s, answers),
    };
    final partAScore = subscaleScores['part_a'];
    final partBScore = subscaleScores['part_b'];
    final asrsPositive = partAScore != null && partAScore >= 4;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          locText(
            context,
            ru: 'Результат',
            en: 'Result',
            fr: 'Résultat',
            de: 'Ergebnis',
            pt: 'Resultado',
          ),
        ),
        actions: [
          IconButton(
            tooltip: locText(
              context,
              ru: 'История теста',
              en: 'Test history',
              fr: 'Historique du test',
              de: 'Testverlauf',
              pt: 'Histórico do teste',
            ),
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CustomTestHistoryScreen(test: test),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(test.title.resolve(context), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat.yMMMd(locale).add_Hm().format(completedAt),
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    locText(
                      context,
                      ru:
                          'Ниже — смысл ваших ответов словами, а не только подсчёты. Это не диагноз; при сомнениях обсудите с врачом или психологом.',
                      en:
                          'Below is what your answers suggest in words—not just counting. This is not a diagnosis; talk with a clinician or therapist if unsure.',
                      fr:
                          'Ci-dessous, ce que vos réponses suggèrent avec des mots, pas seulement des calculs. Ce n’est pas un diagnostic ; parlez-en à un professionnel si besoin.',
                      de:
                          'Unten steht, was Ihre Antworten in Worten bedeuten—nicht nur Zahlen. Keine Diagnose; bei Unsicherheit mit Fachperson sprechen.',
                      pt:
                          'Abaixo, o que suas respostas sugerem em palavras, não só números. Não é diagnóstico; converse com um profissional se tiver dúvidas.',
                    ),
                    style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  if (test.resultSubscalesOnly && test.subscales.isNotEmpty)
                    Text(
                      locText(
                        context,
                        ru: 'Ниже — разбивка по областям',
                        en: 'Breakdown by area below',
                        fr: 'Répartition par domaine ci‑dessous',
                        de: 'Aufschlüsselung nach Bereichen unten',
                        pt: 'Detalhamento por área abaixo',
                      ),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: scheme.primary),
                    ),
                  if (band != null) ...[
                    const SizedBox(height: 10),
                    Text(band.title.resolve(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (band.description != null) ...[
                      const SizedBox(height: 6),
                      Text(band.description!.resolve(context), style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35)),
                    ],
                  ],
                  if (isAsrs && partAScore != null && partBScore != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      locText(
                        context,
                        ru: 'Ваши баллы',
                        en: 'Your scores',
                        fr: 'Vos scores',
                        de: 'Ihre Werte',
                        pt: 'Seus escores',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      locText(
                        context,
                        ru: 'Часть A: $partAScore из 6, часть B: $partBScore из 12, всего: ${partAScore + partBScore} из 18.',
                        en: 'Part A: $partAScore of 6, Part B: $partBScore of 12, total: ${partAScore + partBScore} of 18.',
                        fr: 'Partie A : $partAScore sur 6, partie B : $partBScore sur 12, total : ${partAScore + partBScore} sur 18.',
                        de: 'Teil A: $partAScore von 6, Teil B: $partBScore von 12, gesamt: ${partAScore + partBScore} von 18.',
                        pt: 'Parte A: $partAScore de 6, parte B: $partBScore de 12, total: ${partAScore + partBScore} de 18.',
                      ),
                      style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      locText(
                        context,
                        ru: asrsPositive
                            ? 'Интерпретация: по части A скрининг положительный (4 и более). Это повод обсудить симптомы со специалистом.'
                            : 'Интерпретация: по части A скрининг не достигает порога (менее 4). Если жалобы мешают в жизни, всё равно стоит обсудить их со специалистом.',
                        en: asrsPositive
                            ? 'Interpretation: Part A reaches a positive screening threshold (4+). Discuss symptoms with a specialist.'
                            : 'Interpretation: Part A is below the screening threshold (<4). If symptoms affect daily life, discuss them with a specialist anyway.',
                        fr: asrsPositive
                            ? 'Interprétation : la partie A atteint le seuil de dépistage positif (4+). Discutez-en avec un spécialiste.'
                            : 'Interprétation : la partie A reste sous le seuil de dépistage (<4). Si les symptômes vous gênent, parlez-en quand même à un spécialiste.',
                        de: asrsPositive
                            ? 'Interpretation: Teil A erreicht den positiven Screening-Schwellenwert (4+). Symptome mit einer Fachperson besprechen.'
                            : 'Interpretation: Teil A liegt unter dem Screening-Schwellenwert (<4). Bei belastenden Symptomen dennoch mit einer Fachperson sprechen.',
                        pt: asrsPositive
                            ? 'Interpretação: a parte A atinge limiar de triagem positivo (4+). Vale discutir os sintomas com um especialista.'
                            : 'Interpretação: a parte A fica abaixo do limiar de triagem (<4). Se os sintomas impactam sua vida, ainda assim converse com um especialista.',
                      ),
                      style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
                    ),
                  ],
                  if (test.subscales.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      locText(
                        context,
                        ru: 'Отдельные темы',
                        en: 'Areas covered',
                        fr: 'Domaines couverts',
                        de: 'Einzelne Themenbereiche',
                        pt: 'Áreas abordadas',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    for (final s in test.subscales)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          isAsrs
                              ? '${s.label.resolve(context)} — ${subscaleScores[s.id] ?? 0}${s.maxScore != null ? ' / ${s.maxScore}' : ''}'
                              : s.label.resolve(context),
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ),
                  ],
                  if (psqiComps != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      locText(
                        context,
                        ru: 'Компоненты сна',
                        en: 'Sleep components',
                        fr: 'Composantes du sommeil',
                        de: 'Schlafkomponenten',
                        pt: 'Componentes do sono',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < psqiComps.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          _psqiComponentLabel(context, i),
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ),
                  ],
                  if (test.resultNote != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      test.resultNote!.resolve(context),
                      style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: Text(
              locText(
                context,
                ru: 'К списку тестов',
                en: 'Back to tests',
                fr: 'Retour aux tests',
                de: 'Zurück zu den Tests',
                pt: 'Voltar aos testes',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomTestHistoryScreen extends StatelessWidget {
  final CustomTestDefinition test;

  const CustomTestHistoryScreen({super.key, required this.test});

  double _yForTrend(List<int> answers) {
    if (test.resultSubscalesOnly && test.subscales.isNotEmpty) {
      var sum = 0.0;
      for (final s in test.subscales) {
        sum += test.scoreSubscale(s, answers);
      }
      return sum / test.subscales.length;
    }
    if (test.scoring != null && test.scoring!.isNotEmpty) {
      return test.scoreTotal(answers).toDouble();
    }
    return answers.fold<double>(0, (a, b) => a + b);
  }

  String _listSubtitle(BuildContext context, List<int> _) {
    return locText(
      context,
      ru: 'Нажмите, чтобы открыть',
      en: 'Tap to view',
      fr: 'Appuyez pour ouvrir',
      de: 'Tippen zum Anzeigen',
      pt: 'Toque para ver',
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = localeCode(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          locText(
            context,
            ru: 'Прошлые результаты',
            en: 'Past results',
            fr: 'Résultats passés',
            de: 'Frühere Ergebnisse',
            pt: 'Resultados anteriores',
          ),
        ),
      ),
      body: FutureBuilder<List<SavedTestResult>>(
        future: TestHistoryStorage.loadForTest(test.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return Center(
              child: Text(
                locText(
                  context,
                  ru: 'Пока нет результатов для этого теста.',
                  en: 'No results yet for this test.',
                  fr: 'Pas encore de résultats pour ce test.',
                  de: 'Für diesen Test gibt es noch keine Ergebnisse.',
                  pt: 'Ainda não há resultados para este teste.',
                ),
                style: const TextStyle(height: 1.3),
              ),
            );
          }

          final spots = <FlSpot>[];
          for (var i = 0; i < items.length; i++) {
            final total = _yForTrend(items[i].answers);
            spots.add(FlSpot(i.toDouble(), total));
          }
          final maxY = spots.map((e) => e.y).fold<double>(0, (a, b) => a > b ? a : b);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locText(
                          context,
                          ru: 'Динамика результатов',
                          en: 'Results over time',
                          fr: 'Évolution des résultats',
                          de: 'Ergebnisverlauf',
                          pt: 'Evolução dos resultados',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: (spots.length - 1).toDouble(),
                            minY: 0,
                            maxY: (maxY <= 0 ? 5 : maxY * 1.15),
                            gridData: FlGridData(
                              show: true,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: scheme.outline.withOpacity(0.2),
                                strokeWidth: 1,
                              ),
                              drawVerticalLine: false,
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(color: scheme.outline.withOpacity(0.35)),
                            ),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  interval: spots.length > 1 ? 1 : 1,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx < 0 || idx >= items.length) return const SizedBox.shrink();
                                    final dt = items[idx].completedAt;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        DateFormat.Md(locale).format(dt),
                                        style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                curveSmoothness: 0.25,
                                barWidth: 3,
                                color: scheme.primary,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(show: true, color: scheme.primary.withOpacity(0.10)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final r in items.reversed)
                Card(
                  child: ListTile(
                    title: Text(DateFormat.yMMMd(locale).add_Hm().format(r.completedAt)),
                    subtitle: Text(
                      _listSubtitle(context, r.answers),
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CustomTestResultScreen(
                            test: test,
                            completedAt: r.completedAt,
                            answers: r.answers,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TestRunScreenState extends State<TestRunScreen> {
  late final List<int?> _answers =
      List<int?>.filled(widget.test.questions.length, null);

  String get _disclaimer => locText(
        context,
        ru:
            'Этот тест не является постановкой диагноза и носит ознакомительный характер. При проблемах или сомнениях лучше обратитесь к специалисту.',
        en:
            'This test is not a diagnosis and is provided for informational purposes only. If you have concerns, please contact a professional.',
        fr:
            'Ce test ne pose pas de diagnostic et a uniquement une valeur informative. En cas de doute, consultez un spécialiste.',
        de:
            'Dieser Test stellt keine Diagnose dar und dient nur zur Orientierung. Bei Problemen oder Unsicherheiten wenden Sie sich bitte an eine Fachperson.',
        pt:
            'Este teste não é um diagnóstico e tem caráter apenas informativo. Em caso de dúvidas, procure um profissional.',
      );

  Future<void> _submit() async {
    if (_answers.any((e) => e == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            locText(
              context,
              ru: 'Ответьте на все вопросы теста.',
              en: 'Please answer all questions.',
              fr: 'Veuillez répondre à toutes les questions.',
              de: 'Bitte beantworten Sie alle Fragen.',
              pt: 'Responda todas as perguntas.',
            ),
          ),
        ),
      );
      return;
    }

    final answers = _answers.cast<int>();
    final completedAt = DateTime.now();
    await TestHistoryStorage.append(
      SavedTestResult(
        testId: widget.test.id,
        completedAt: completedAt,
        answers: answers,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => TestResultScreen(
          test: widget.test,
          completedAt: completedAt,
          answers: answers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.test.title.resolve(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: scheme.primaryContainer.withOpacity(0.55),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.test.subtitle.resolve(context),
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _disclaimer,
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < widget.test.questions.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}. ${widget.test.questions[i].text.resolve(context)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...widget.test.questions[i].options.map((option) {
                      return RadioListTile<int>(
                        value: option.score,
                        groupValue: _answers[i],
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(option.label.resolve(context)),
                        onChanged: (value) {
                          setState(() => _answers[i] = value);
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _submit,
            child: Text(
              locText(
                context,
                ru: 'Завершить тест',
                en: 'Finish test',
                fr: 'Terminer le test',
                de: 'Test beenden',
                pt: 'Concluir teste',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TestResultScreen extends StatelessWidget {
  final TestDefinition test;
  final DateTime completedAt;
  final List<int> answers;

  const TestResultScreen({
    super.key,
    required this.test,
    required this.completedAt,
    required this.answers,
  });

  @override
  Widget build(BuildContext context) {
    final eval = TestsCatalog.evaluate(context, test, answers);
    final scheme = Theme.of(context).colorScheme;
    final locale = localeCode(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          locText(
            context,
            ru: 'Результат',
            en: 'Result',
            fr: 'Résultat',
            de: 'Ergebnis',
            pt: 'Resultado',
          ),
        ),
        actions: [
          IconButton(
            tooltip: locText(
              context,
              ru: 'История теста',
              en: 'Test history',
              fr: 'Historique du test',
              de: 'Testverlauf',
              pt: 'Histórico do teste',
            ),
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TestHistoryScreen(test: test),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.title.resolve(context),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat.yMMMd(locale).add_Hm().format(completedAt),
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    locText(
                      context,
                      ru:
                          'По вашим ответам получилась такая общая картина (это скрининг, не заключение врача):',
                      en:
                          'Here is the overall picture from your answers (a screen, not a doctor’s verdict):',
                      fr:
                          'Voici l’image d’ensemble selon vos réponses (dépistage, pas un avis médical) :',
                      de:
                          'So sieht das Gesamtbild aus Ihren Antworten aus (Screening, kein ärztliches Urteil):',
                      pt:
                          'Esta é a visão geral a partir das suas respostas (triagem, não parecer médico):',
                    ),
                    style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    eval.levelTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(eval.summary, style: const TextStyle(height: 1.35)),
                ],
              ),
            ),
          ),
          if (eval.metrics.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locText(
                        context,
                        ru: 'По каждой линии — словесное описание уровня',
                        en: 'Each line: a word picture of where you land',
                        fr: 'Chaque ligne : une description en mots',
                        de: 'Jede Zeile: eine Beschreibung in Worten',
                        pt: 'Cada linha: uma descrição em palavras',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...eval.metrics.map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              m.level,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (eval.recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locText(
                        context,
                        ru: 'Что это может значить',
                        en: 'What this may mean',
                        fr: 'Ce que cela peut signifier',
                        de: 'Was das bedeuten kann',
                        pt: 'O que isso pode significar',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...eval.recommendations.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('• $line'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TestHistoryScreen extends StatelessWidget {
  final TestDefinition test;

  const TestHistoryScreen({super.key, required this.test});

  @override
  Widget build(BuildContext context) {
    final locale = localeCode(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          locText(
            context,
            ru: 'Прошлые результаты',
            en: 'Past results',
            fr: 'Résultats passés',
            de: 'Frühere Ergebnisse',
            pt: 'Resultados anteriores',
          ),
        ),
      ),
      body: FutureBuilder<List<SavedTestResult>>(
        future: TestHistoryStorage.loadForTest(test.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return Center(
              child: Text(
                locText(
                  context,
                  ru: 'Пока нет результатов для этого теста.',
                  en: 'No results yet for this test.',
                  fr: 'Pas encore de résultats pour ce test.',
                  de: 'Für diesen Test gibt es noch keine Ergebnisse.',
                  pt: 'Ainda não há resultados para este teste.',
                ),
                style: const TextStyle(height: 1.3),
              ),
            );
          }

          final spots = <FlSpot>[];
          for (var i = 0; i < items.length; i++) {
            spots.add(FlSpot(i.toDouble(), TestsCatalog.primaryScore(test, items[i].answers)));
          }
          final maxY = spots.map((e) => e.y).fold<double>(0, (a, b) => a > b ? a : b);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locText(
                          context,
                          ru: 'Динамика результатов',
                          en: 'Results over time',
                          fr: 'Évolution des résultats',
                          de: 'Ergebnisverlauf',
                          pt: 'Evolução dos resultados',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: (spots.length - 1).toDouble(),
                            minY: 0,
                            maxY: (maxY <= 0 ? 5 : maxY * 1.15),
                            gridData: FlGridData(
                              show: true,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: scheme.outline.withOpacity(0.2),
                                strokeWidth: 1,
                              ),
                              drawVerticalLine: false,
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(color: scheme.outline.withOpacity(0.35)),
                            ),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  interval: spots.length > 1 ? 1 : 1,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx < 0 || idx >= items.length) return const SizedBox.shrink();
                                    final dt = items[idx].completedAt;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        DateFormat.Md(locale).format(dt),
                                        style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: scheme.primary,
                                barWidth: 3,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                                    radius: 4,
                                    color: scheme.primary,
                                    strokeWidth: 2,
                                    strokeColor: scheme.surface,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: scheme.primary.withOpacity(0.08),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...items.reversed.map((r) {
                final eval = TestsCatalog.evaluate(context, test, r.answers);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(eval.levelTitle),
                    subtitle: Text(
                      DateFormat.yMMMd(locale).add_Hm().format(r.completedAt),
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
