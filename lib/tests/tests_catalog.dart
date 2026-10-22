import 'package:flutter/material.dart';

import 'tests_models.dart';

const optNeverToAlways4 = <TestOption>[
  TestOption(label: TLoc(ru: 'Совсем нет', en: 'Not at all', fr: 'Pas du tout', de: 'Überhaupt nicht', pt: 'De modo nenhum'), score: 0),
  TestOption(label: TLoc(ru: 'Несколько дней', en: 'Several days', fr: 'Plusieurs jours', de: 'An mehreren Tagen', pt: 'Vários dias'), score: 1),
  TestOption(label: TLoc(ru: 'Более половины дней', en: 'More than half the days', fr: 'Plus de la moitié des jours', de: 'An mehr als der Hälfte der Tage', pt: 'Mais da metade dos dias'), score: 2),
  TestOption(label: TLoc(ru: 'Почти каждый день', en: 'Nearly every day', fr: 'Presque tous les jours', de: 'Beinahe jeden Tag', pt: 'Quase todos os dias'), score: 3),
];

const optDass = <TestOption>[
  TestOption(label: TLoc(ru: 'Совсем не относилось ко мне', en: 'Did not apply to me at all', fr: 'Ne me correspondait pas du tout', de: 'Traf überhaupt nicht auf mich zu', pt: 'Não se aplicou a mim de forma alguma'), score: 0),
  TestOption(label: TLoc(ru: 'Относилось ко мне в некоторой степени', en: 'Applied to me to some degree', fr: 'S’appliquait à moi dans une certaine mesure', de: 'Traf in gewissem Maß auf mich zu', pt: 'Aplicou-se a mim em algum grau'), score: 1),
  TestOption(label: TLoc(ru: 'Относилось ко мне в значительной степени', en: 'Applied to me to a considerable degree', fr: 'S’appliquait à moi de manière considérable', de: 'Traf in erheblichem Maß auf mich zu', pt: 'Aplicou-se a mim de forma considerável'), score: 2),
  TestOption(label: TLoc(ru: 'Очень сильно относилось ко мне', en: 'Applied to me very much or most of the time', fr: 'S’appliquait fortement à moi ou la plupart du temps', de: 'Traf sehr stark oder die meiste Zeit auf mich zu', pt: 'Aplicou-se a mim muito ou na maior parte do tempo'), score: 3),
];

const optWho5 = <TestOption>[
  TestOption(label: TLoc(ru: 'Ни разу', en: 'At no time', fr: 'À aucun moment', de: 'Zu keinem Zeitpunkt', pt: 'Em nenhum momento'), score: 0),
  TestOption(label: TLoc(ru: 'Иногда', en: 'Some of the time', fr: 'Une partie du temps', de: 'Manchmal', pt: 'Em parte do tempo'), score: 1),
  TestOption(label: TLoc(ru: 'Меньше половины времени', en: 'Less than half the time', fr: 'Moins de la moitié du temps', de: 'Weniger als die Hälfte der Zeit', pt: 'Menos da metade do tempo'), score: 2),
  TestOption(label: TLoc(ru: 'Больше половины времени', en: 'More than half the time', fr: 'Plus de la moitié du temps', de: 'Mehr als die Hälfte der Zeit', pt: 'Mais da metade do tempo'), score: 3),
  TestOption(label: TLoc(ru: 'Большую часть времени', en: 'Most of the time', fr: 'La plupart du temps', de: 'Die meiste Zeit', pt: 'Na maior parte do tempo'), score: 4),
  TestOption(label: TLoc(ru: 'Всё время', en: 'All of the time', fr: 'Tout le temps', de: 'Die ganze Zeit', pt: 'Todo o tempo'), score: 5),
];

const optAgreePositive = <TestOption>[
  TestOption(label: TLoc(ru: 'Полностью согласен', en: 'Strongly agree', fr: 'Tout à fait d’accord', de: 'Stimme voll zu', pt: 'Concordo totalmente'), score: 3),
  TestOption(label: TLoc(ru: 'Скорее согласен', en: 'Agree', fr: 'D’accord', de: 'Stimme zu', pt: 'Concordo'), score: 2),
  TestOption(label: TLoc(ru: 'Скорее не согласен', en: 'Disagree', fr: 'Pas d’accord', de: 'Stimme eher nicht zu', pt: 'Discordo'), score: 1),
  TestOption(label: TLoc(ru: 'Полностью не согласен', en: 'Strongly disagree', fr: 'Pas du tout d’accord', de: 'Stimme überhaupt nicht zu', pt: 'Discordo totalmente'), score: 0),
];

const optAgreeNegative = <TestOption>[
  TestOption(label: TLoc(ru: 'Полностью согласен', en: 'Strongly agree', fr: 'Tout à fait d’accord', de: 'Stimme voll zu', pt: 'Concordo totalmente'), score: 0),
  TestOption(label: TLoc(ru: 'Скорее согласен', en: 'Agree', fr: 'D’accord', de: 'Stimme zu', pt: 'Concordo'), score: 1),
  TestOption(label: TLoc(ru: 'Скорее не согласен', en: 'Disagree', fr: 'Pas d’accord', de: 'Stimme eher nicht zu', pt: 'Discordo'), score: 2),
  TestOption(label: TLoc(ru: 'Полностью не согласен', en: 'Strongly disagree', fr: 'Pas du tout d’accord', de: 'Stimme überhaupt nicht zu', pt: 'Discordo totalmente'), score: 3),
];

const optPcl5 = <TestOption>[
  TestOption(label: TLoc(ru: 'Совсем нет', en: 'Not at all', fr: 'Pas du tout', de: 'Überhaupt nicht', pt: 'De modo nenhum'), score: 0),
  TestOption(label: TLoc(ru: 'Немного', en: 'A little bit', fr: 'Un peu', de: 'Ein wenig', pt: 'Um pouco'), score: 1),
  TestOption(label: TLoc(ru: 'Умеренно', en: 'Moderately', fr: 'Modérément', de: 'Mäßig', pt: 'Moderadamente'), score: 2),
  TestOption(label: TLoc(ru: 'Сильно', en: 'Quite a bit', fr: 'Beaucoup', de: 'Ziemlich stark', pt: 'Bastante'), score: 3),
  TestOption(label: TLoc(ru: 'Крайне сильно', en: 'Extremely', fr: 'Extrêmement', de: 'Extrem', pt: 'Extremamente'), score: 4),
];

const optSwls = <TestOption>[
  TestOption(label: TLoc(ru: 'Совершенно не согласен', en: 'Strongly disagree', fr: 'Tout à fait en désaccord', de: 'Stimme überhaupt nicht zu', pt: 'Discordo totalmente'), score: 1),
  TestOption(label: TLoc(ru: 'Не согласен', en: 'Disagree', fr: 'En désaccord', de: 'Stimme nicht zu', pt: 'Discordo'), score: 2),
  TestOption(label: TLoc(ru: 'Скорее не согласен', en: 'Slightly disagree', fr: 'Plutôt en désaccord', de: 'Stimme eher nicht zu', pt: 'Discordo um pouco'), score: 3),
  TestOption(label: TLoc(ru: 'Ни согласен, ни не согласен', en: 'Neither agree nor disagree', fr: 'Ni d’accord ni en désaccord', de: 'Weder noch', pt: 'Nem concordo nem discordo'), score: 4),
  TestOption(label: TLoc(ru: 'Скорее согласен', en: 'Slightly agree', fr: 'Plutôt d’accord', de: 'Stimme eher zu', pt: 'Concordo um pouco'), score: 5),
  TestOption(label: TLoc(ru: 'Согласен', en: 'Agree', fr: 'D’accord', de: 'Stimme zu', pt: 'Concordo'), score: 6),
  TestOption(label: TLoc(ru: 'Полностью согласен', en: 'Strongly agree', fr: 'Tout à fait d’accord', de: 'Stimme voll zu', pt: 'Concordo totalmente'), score: 7),
];

class TestsCatalog {
  static const List<(TestCategoryId, TLoc)> categories = [
    (TestCategoryId.depression, TLoc(ru: '1. Депрессия и общее состояние', en: '1. Depression and general state', fr: '1. Dépression et état général', de: '1. Depression und allgemeiner Zustand', pt: '1. Depressão e estado geral')),
    (TestCategoryId.anxiety, TLoc(ru: '2. Тревога и паника', en: '2. Anxiety and panic', fr: '2. Anxiété et panique', de: '2. Angst und Panik', pt: '2. Ansiedade e pânico')),
    (TestCategoryId.stress, TLoc(ru: '3. Стресс и травма', en: '3. Stress and trauma', fr: '3. Stress et traumatisme', de: '3. Stress und Trauma', pt: '3. Estresse e trauma')),
    (TestCategoryId.bipolar, TLoc(ru: '4. Биполярное расстройство и мания', en: '4. Bipolar disorder and mania', fr: '4. Trouble bipolaire et manie', de: '4. Bipolare Störung und Manie', pt: '4. Transtorno bipolar e mania')),
    (TestCategoryId.ocd, TLoc(ru: '5. Обсессивно-компульсивное расстройство', en: '5. Obsessive-compulsive disorder', fr: '5. Trouble obsessionnel-compulsif', de: '5. Zwangsstörung', pt: '5. Transtorno obsessivo-compulsivo')),
    (TestCategoryId.addictions, TLoc(ru: '6. Пищевое поведение и зависимости', en: '6. Eating behavior and addictions', fr: '6. Comportement alimentaire et dépendances', de: '6. Essverhalten und Abhängigkeiten', pt: '6. Comportamento alimentar e dependências')),
    (TestCategoryId.personality, TLoc(ru: '7. Самооценка и личность', en: '7. Self-esteem and personality', fr: '7. Estime de soi et personnalité', de: '7. Selbstwert und Persönlichkeit', pt: '7. Autoestima e personalidade')),
    (TestCategoryId.wellbeing, TLoc(ru: '8. Благополучие и позитивные эмоции', en: '8. Wellbeing and positive emotions', fr: '8. Bien-être et émotions positives', de: '8. Wohlbefinden und positive Emotionen', pt: '8. Bem-estar e emoções positivas')),
    (TestCategoryId.sleep, TLoc(ru: '9. Сон и отношения', en: '9. Sleep and relationships', fr: '9. Sommeil et relations', de: '9. Schlaf und Beziehungen', pt: '9. Sono e relacionamentos')),
  ];

  static final List<TestDefinition> availableTests = [
    _phq2(),
    _phq9(),
    _gad7(),
    _dass21(),
    _pcl5(),
    _audit(),
    _ftnd(),
    _rses(),
    _who5(),
    _swls(),
  ];

  static final List<UnavailableTest> pendingTests = [];

  static double primaryScore(TestDefinition test, List<int> answers) {
    switch (test.kind) {
      case TestKind.phq2:
      case TestKind.phq9:
      case TestKind.gad7:
      case TestKind.audit:
      case TestKind.ftnd:
      case TestKind.rses:
      case TestKind.pcl5:
      case TestKind.swls:
        return answers.fold<double>(0, (a, b) => a + b);
      case TestKind.who5:
        return answers.fold<double>(0, (a, b) => a + b) * 4;
      case TestKind.dass21:
        return answers.fold<double>(0, (a, b) => a + b) * 2;
    }
  }

  static TestEvaluation evaluate(BuildContext context, TestDefinition test, List<int> answers) {
    switch (test.kind) {
      case TestKind.phq2:
        final score = answers.fold<int>(0, (a, b) => a + b);
        return TestEvaluation(
          scoreText: '$score / 6',
          levelTitle: score >= 3
              ? locText(context, ru: 'Положительный скрининг', en: 'Positive screen', fr: 'Dépistage positif', de: 'Positives Screening', pt: 'Triagem positiva')
              : locText(context, ru: 'Низкий риск', en: 'Low risk', fr: 'Faible risque', de: 'Niedriges Risiko', pt: 'Baixo risco'),
          summary: score >= 3
              ? locText(context, ru: 'Короткий скрининг показывает заметные симптомы сниженного настроения или потери интереса.', en: 'The brief screen suggests noticeable low mood or loss of interest.', fr: 'Le dépistage bref suggère des symptômes notables d’humeur dépressive ou de perte d’intérêt.', de: 'Das Kurzscreening weist auf spürbare Niedergeschlagenheit oder Interessenverlust hin.', pt: 'A triagem breve sugere sintomas perceptíveis de humor deprimido ou perda de interesse.')
              : locText(context, ru: 'По короткому скринингу выраженные депрессивные симптомы не выявлены.', en: 'The brief screen does not suggest pronounced depressive symptoms.', fr: 'Le dépistage bref ne suggère pas de symptômes dépressifs marqués.', de: 'Das Kurzscreening weist nicht auf ausgeprägte depressive Symptome hin.', pt: 'A triagem breve não sugere sintomas depressivos marcantes.'),
          recommendations: [
            if (score >= 3)
              locText(context, ru: 'Полезно пройти более полный тест, например PHQ-9.', en: 'It may be useful to complete PHQ-9 for a fuller screen.', fr: 'Il peut être utile de passer un test plus complet comme le PHQ-9.', de: 'Es kann hilfreich sein, einen umfassenderen Test wie den PHQ-9 auszufüllen.', pt: 'Pode ser útil fazer um teste mais completo, como o PHQ-9.'),
          ],
        );
      case TestKind.phq9:
        final score = answers.fold<int>(0, (a, b) => a + b);
        final level = score <= 4
            ? locText(context, ru: 'Минимальные симптомы', en: 'Minimal symptoms', fr: 'Symptômes minimes', de: 'Minimale Symptome', pt: 'Sintomas mínimos')
            : score <= 9
                ? locText(context, ru: 'Лёгкие симптомы', en: 'Mild symptoms', fr: 'Symptômes légers', de: 'Leichte Symptome', pt: 'Sintomas leves')
                : score <= 14
                    ? locText(context, ru: 'Умеренные симптомы', en: 'Moderate symptoms', fr: 'Symptômes modérés', de: 'Mäßige Symptome', pt: 'Sintomas moderados')
                    : score <= 19
                        ? locText(context, ru: 'Выраженные симптомы', en: 'Moderately severe symptoms', fr: 'Symptômes modérément sévères', de: 'Deutlich ausgeprägte Symptome', pt: 'Sintomas moderadamente graves')
                        : locText(context, ru: 'Тяжёлые симптомы', en: 'Severe symptoms', fr: 'Symptômes sévères', de: 'Schwere Symptome', pt: 'Sintomas graves');
        return TestEvaluation(
          scoreText: '$score / 27',
          levelTitle: level,
          summary: locText(context, ru: 'PHQ-9 отражает выраженность депрессивных симптомов за последние 2 недели.', en: 'PHQ-9 reflects depressive symptom severity over the last 2 weeks.', fr: 'Le PHQ-9 reflète l’intensité des symptômes dépressifs au cours des 2 dernières semaines.', de: 'Der PHQ-9 zeigt die Ausprägung depressiver Symptome in den letzten 2 Wochen.', pt: 'O PHQ-9 reflete a intensidade dos sintomas depressivos nas últimas 2 semanas.'),
          recommendations: [
            locText(context, ru: 'Это скрининг, а не диагноз.', en: 'This is a screening tool, not a diagnosis.', fr: 'Il s’agit d’un dépistage, pas d’un diagnostic.', de: 'Dies ist ein Screening, keine Diagnose.', pt: 'Isto é uma triagem, não um diagnóstico.'),
            if (score >= 10) locText(context, ru: 'При заметных или сильных симптомах по этой шкале полезно обсудить состояние со специалистом.', en: 'If symptoms on this scale look moderate or strong, discussing with a professional is recommended.', fr: 'Si les symptômes sur cette échelle semblent modérés ou marqués, parler à un professionnel est utile.', de: 'Wirken die Symptome auf dieser Skala mittel bis stark, lohnt ein Gespräch mit einer Fachperson.', pt: 'Se os sintomas nesta escala parecem moderados ou fortes, conversar com um profissional é recomendável.'),
            if (answers[8] > 0) locText(context, ru: 'Положительный ответ на вопрос о самоповреждении требует срочного внимания и обращения за помощью.', en: 'A positive self-harm item deserves urgent professional attention.', fr: 'Une réponse positive à la question sur l’automutilation nécessite une attention urgente et une aide professionnelle.', de: 'Eine positive Antwort auf die Frage zu Selbstverletzung erfordert dringende fachliche Hilfe.', pt: 'Uma resposta positiva sobre autoagressão exige atenção urgente e ajuda profissional.'),
          ],
        );
      case TestKind.gad7:
        final score = answers.fold<int>(0, (a, b) => a + b);
        final level = score < 5
            ? locText(context, ru: 'Минимальная тревога', en: 'Minimal anxiety', fr: 'Anxiété minimale', de: 'Minimale Angst', pt: 'Ansiedade mínima')
            : score < 10
                ? locText(context, ru: 'Лёгкая тревога', en: 'Mild anxiety', fr: 'Anxiété légère', de: 'Leichte Angst', pt: 'Ansiedade leve')
                : score < 15
                    ? locText(context, ru: 'Умеренная тревога', en: 'Moderate anxiety', fr: 'Anxiété modérée', de: 'Mäßige Angst', pt: 'Ansiedade moderada')
                    : locText(context, ru: 'Выраженная тревога', en: 'Severe anxiety', fr: 'Anxiété sévère', de: 'Starke Angst', pt: 'Ansiedade grave');
        return TestEvaluation(
          scoreText: '$score / 21',
          levelTitle: level,
          summary: locText(context, ru: 'GAD-7 помогает оценить выраженность генерализованной тревоги.', en: 'GAD-7 helps assess generalized anxiety severity.', fr: 'Le GAD-7 aide à évaluer l’intensité de l’anxiété généralisée.', de: 'Der GAD-7 hilft, die Stärke generalisierter Angst einzuschätzen.', pt: 'O GAD-7 ajuda a avaliar a intensidade da ansiedade generalizada.'),
          recommendations: [
            if (score >= 10) locText(context, ru: 'При выраженной тревоге по этой шкале полезна более подробная беседа со специалистом.', en: 'If anxiety looks strong on this scale, a fuller talk with a professional is often helpful.', fr: 'Si l’anxiété paraît marquée sur cette échelle, un échange plus approfondi avec un professionnel aide souvent.', de: 'Wirkt die Angst auf dieser Skala ausgeprägt, ist ein ausführlicheres Gespräch mit Fachpersonal oft hilfreich.', pt: 'Se a ansiedade parece forte nesta escala, uma conversa mais aprofundada com um profissional costuma ajudar.'),
          ],
        );
      case TestKind.audit:
        final score = answers.fold<int>(0, (a, b) => a + b);
        final level = score < 8
            ? locText(context, ru: 'Низкий риск', en: 'Low risk', fr: 'Faible risque', de: 'Niedriges Risiko', pt: 'Baixo risco')
            : score < 16
                ? locText(context, ru: 'Рискованное употребление', en: 'Risky use', fr: 'Usage à risque', de: 'Risikoreicher Konsum', pt: 'Uso de risco')
                : score < 20
                    ? locText(context, ru: 'Вредное употребление', en: 'Harmful use', fr: 'Usage nocif', de: 'Schädlicher Konsum', pt: 'Uso nocivo')
                    : locText(context, ru: 'Высокий риск зависимости', en: 'Possible dependence', fr: 'Risque élevé de dépendance', de: 'Hohes Abhängigkeitsrisiko', pt: 'Alto risco de dependência');
        return TestEvaluation(
          scoreText: '$score / 40',
          levelTitle: level,
          summary: locText(context, ru: 'AUDIT помогает оценить риск проблемного употребления алкоголя.', en: 'AUDIT helps estimate the risk of problematic alcohol use.', fr: 'AUDIT aide à estimer le risque d’usage problématique de l’alcool.', de: 'AUDIT hilft, das Risiko eines problematischen Alkoholkonsums einzuschätzen.', pt: 'O AUDIT ajuda a estimar o risco de uso problemático de álcool.'),
        );
      case TestKind.ftnd:
        final score = answers.fold<int>(0, (a, b) => a + b);
        final level = score <= 2
            ? locText(context, ru: 'Очень низкая зависимость', en: 'Very low dependence', fr: 'Dépendance très faible', de: 'Sehr geringe Abhängigkeit', pt: 'Dependência muito baixa')
            : score <= 4
                ? locText(context, ru: 'Низкая зависимость', en: 'Low dependence', fr: 'Faible dépendance', de: 'Geringe Abhängigkeit', pt: 'Baixa dependência')
                : score == 5
                    ? locText(context, ru: 'Умеренная зависимость', en: 'Moderate dependence', fr: 'Dépendance modérée', de: 'Mäßige Abhängigkeit', pt: 'Dependência moderada')
                    : score <= 7
                        ? locText(context, ru: 'Высокая зависимость', en: 'High dependence', fr: 'Forte dépendance', de: 'Hohe Abhängigkeit', pt: 'Alta dependência')
                        : locText(context, ru: 'Очень высокая зависимость', en: 'Very high dependence', fr: 'Très forte dépendance', de: 'Sehr hohe Abhängigkeit', pt: 'Dependência muito alta');
        return TestEvaluation(
          scoreText: '$score / 10',
          levelTitle: level,
          summary: locText(context, ru: 'FTND оценивает выраженность никотиновой зависимости.', en: 'FTND estimates the degree of nicotine dependence.', fr: 'Le FTND estime le niveau de dépendance à la nicotine.', de: 'Der FTND schätzt den Grad der Nikotinabhängigkeit ein.', pt: 'O FTND estima o grau de dependência de nicotina.'),
          recommendations: [
            if (score >= 5) locText(context, ru: 'Если зависимость от сигарет ощущается средней или сильной, полезно обсудить отказ от курения со специалистом.', en: 'If cigarette dependence feels moderate or strong, discussing quitting with a professional may help.', fr: 'Si la dépendance à la cigarette semble modérée ou forte, discuter de l’arrêt avec un professionnel peut aider.', de: 'Wirkt die Zigarettenabhängigkeit mittel bis stark, kann ein Gespräch über das Aufhören mit Fachpersonal helfen.', pt: 'Se a dependência de cigarros parece moderada ou forte, discutir a cessação com um profissional pode ajudar.'),
          ],
        );
      case TestKind.who5:
        final raw = answers.fold<int>(0, (a, b) => a + b);
        final score = raw * 4;
        final level = score <= 28
            ? locText(context, ru: 'Очень низкое благополучие', en: 'Very low wellbeing', fr: 'Bien-être très faible', de: 'Sehr geringes Wohlbefinden', pt: 'Bem-estar muito baixo')
            : score <= 50
                ? locText(context, ru: 'Сниженное благополучие', en: 'Reduced wellbeing', fr: 'Bien-être réduit', de: 'Verringertes Wohlbefinden', pt: 'Bem-estar reduzido')
                : score <= 75
                    ? locText(context, ru: 'Удовлетворительное благополучие', en: 'Moderate wellbeing', fr: 'Bien-être satisfaisant', de: 'Ordentliches Wohlbefinden', pt: 'Bem-estar satisfatório')
                    : locText(context, ru: 'Высокое благополучие', en: 'High wellbeing', fr: 'Bien-être élevé', de: 'Hohes Wohlbefinden', pt: 'Bem-estar elevado');
        return TestEvaluation(
          scoreText: '$score / 100',
          levelTitle: level,
          summary: locText(context, ru: 'Чем выше результат, тем лучше субъективное психологическое благополучие.', en: 'The higher the score, the better the perceived mental wellbeing.', fr: 'Plus le score est élevé, meilleur est le bien-être psychologique subjectif.', de: 'Je höher der Wert, desto besser das subjektive psychische Wohlbefinden.', pt: 'Quanto maior a pontuação, melhor o bem-estar psicológico subjetivo.'),
          recommendations: [
            if (score <= 50) locText(context, ru: 'Если вы чувствуете, что благополучие низкое, можно отдельно обсудить это со специалистом.', en: 'If you feel your wellbeing is low, you can discuss it with a professional.', fr: 'Si vous sentez que votre bien-être est bas, vous pouvez en parler à un professionnel.', de: 'Wenn Sie Ihr Wohlbefinden als niedrig erleben, können Sie das mit einer Fachperson besprechen.', pt: 'Se sente que o bem-estar está baixo, pode conversar com um profissional.'),
          ],
        );
      case TestKind.rses:
        final score = answers.fold<int>(0, (a, b) => a + b);
        final level = score < 15
            ? locText(context, ru: 'Низкая самооценка', en: 'Low self-esteem', fr: 'Faible estime de soi', de: 'Niedriges Selbstwertgefühl', pt: 'Baixa autoestima')
            : score <= 25
                ? locText(context, ru: 'Средняя / устойчивая самооценка', en: 'Average / stable self-esteem', fr: 'Estime de soi moyenne / stable', de: 'Durchschnittliches / stabiles Selbstwertgefühl', pt: 'Autoestima média / estável')
                : locText(context, ru: 'Высокая самооценка', en: 'High self-esteem', fr: 'Estime de soi élevée', de: 'Hohes Selbstwertgefühl', pt: 'Alta autoestima');
        return TestEvaluation(
          scoreText: '$score / 30',
          levelTitle: level,
          summary: locText(context, ru: 'Шкала Розенберга оценивает общее отношение к себе.', en: 'The Rosenberg scale measures general self-regard.', fr: 'L’échelle de Rosenberg mesure l’attitude générale envers soi-même.', de: 'Die Rosenberg-Skala erfasst die allgemeine Haltung sich selbst gegenüber.', pt: 'A escala de Rosenberg mede a atitude geral em relação a si mesmo(a).'),
        );
      case TestKind.dass21:
        final depression = (answers[2] + answers[4] + answers[9] + answers[12] + answers[15] + answers[16] + answers[20]) * 2;
        final anxiety = (answers[1] + answers[3] + answers[6] + answers[8] + answers[14] + answers[18] + answers[19]) * 2;
        final stress = (answers[0] + answers[5] + answers[7] + answers[10] + answers[11] + answers[13] + answers[17]) * 2;
        final dLabel = locText(context, ru: 'депрессии', en: 'depression', fr: 'dépression', de: 'Depression', pt: 'depressão');
        final aLabel = locText(context, ru: 'тревоги', en: 'anxiety', fr: 'anxiété', de: 'Angst', pt: 'ansiedade');
        final sLabel = locText(context, ru: 'стресса', en: 'stress', fr: 'stress', de: 'Stress', pt: 'estresse');
        final triple = <(int, String)>[
          (depression, dLabel),
          (anxiety, aLabel),
          (stress, sLabel),
        ]..sort((x, y) => y.$1.compareTo(x.$1));
        final emphasis = triple[0].$1 == triple[1].$1 && triple[1].$1 == triple[2].$1
            ? locText(
                context,
                ru: 'По трём линиям нагрузка сейчас выглядит примерно одинаковой — смотрите описание у каждой темы ниже.',
                en: 'The three areas look similarly loaded right now—see each topic below.',
                fr: 'Les trois domaines semblent à charge comparable — voir chaque thème ci-dessous.',
                de: 'Die drei Bereiche wirken ähnlich belastet—siehe jedes Thema unten.',
                pt: 'As três áreas parecem com carga parecida—veja cada tema abaixo.',
              )
            : triple[0].$1 > triple[1].$1
                ? locText(
                    context,
                    ru: 'Сильнее всего по ответам выделяется тема ${triple[0].$2}; остальные две — в блоках ниже.',
                    en: 'Your answers highlight ${triple[0].$2} most; the other two areas are below.',
                    fr: 'Vos réponses mettent surtout en avant ${triple[0].$2}; les deux autres domaines sont en dessous.',
                    de: 'Ihre Antworten betonen vor allem ${triple[0].$2}; die anderen beiden Bereiche stehen unten.',
                    pt: 'Suas respostas destacam mais ${triple[0].$2}; as outras duas áreas estão abaixo.',
                  )
                : locText(
                    context,
                    ru: 'Несколько тем выглядят близко по силе — полезно прочитать все три описания ниже.',
                    en: 'Several themes look similarly strong—read all three descriptions below.',
                    fr: 'Plusieurs thèmes semblent proches en intensité — lisez les trois descriptions ci-dessous.',
                    de: 'Mehrere Themen wirken ähnlich stark—lesen Sie alle drei Beschreibungen unten.',
                    pt: 'Vários temas parecem parecidos em intensidade — leia as três descrições abaixo.',
                  );
        return TestEvaluation(
          scoreText: '',
          levelTitle: locText(
            context,
            ru: 'Три линии: депрессия, тревога и стресс',
            en: 'Three areas: depression, anxiety, and stress',
            fr: 'Trois domaines : dépression, anxiété et stress',
            de: 'Drei Bereiche: Depression, Angst und Stress',
            pt: 'Três áreas: depressão, ansiedade e estresse',
          ),
          summary: '${locText(context, ru: 'DASS-21 разделяет переживания на три темы. ', en: 'DASS-21 looks at three separate themes. ', fr: 'Le DASS-21 sépare les difficultés en trois thèmes. ', de: 'Das DASS-21 teilt Belastungen in drei Themen. ', pt: 'O DASS-21 separa as dificuldades em três temas. ')}$emphasis',
          metrics: [
            ResultMetric(label: locText(context, ru: 'Депрессия', en: 'Depression', fr: 'Dépression', de: 'Depression', pt: 'Depressão'), value: '', level: _dassLevel(context, depression, 'depression')),
            ResultMetric(label: locText(context, ru: 'Тревога', en: 'Anxiety', fr: 'Anxiété', de: 'Angst', pt: 'Ansiedade'), value: '', level: _dassLevel(context, anxiety, 'anxiety')),
            ResultMetric(label: locText(context, ru: 'Стресс', en: 'Stress', fr: 'Stress', de: 'Stress', pt: 'Estresse'), value: '', level: _dassLevel(context, stress, 'stress')),
          ],
        );
      case TestKind.pcl5:
        final score = answers.fold<int>(0, (a, b) => a + b);
        final level = score >= 33
            ? locText(context, ru: 'Высокая вероятность клинически значимых симптомов ПТСР', en: 'Probable clinically significant PTSD symptoms', fr: 'Probabilité élevée de symptômes cliniquement significatifs de TSPT', de: 'Hohe Wahrscheinlichkeit klinisch bedeutsamer PTBS-Symptome', pt: 'Alta probabilidade de sintomas clinicamente significativos de TEPT')
            : score >= 20
                ? locText(context, ru: 'Заметные симптомы травматического стресса', en: 'Noticeable traumatic stress symptoms', fr: 'Symptômes notables de stress traumatique', de: 'Deutliche traumatische Stresssymptome', pt: 'Sintomas perceptíveis de estresse traumático')
                : locText(context, ru: 'Низкий уровень симптомов', en: 'Lower symptom level', fr: 'Faible niveau de symptômes', de: 'Niedriges Symptomniveau', pt: 'Baixo nível de sintomas');
        return TestEvaluation(
          scoreText: '$score / 80',
          levelTitle: level,
          summary: locText(context, ru: 'PCL-5 оценивает выраженность симптомов посттравматического стресса за последний месяц.', en: 'PCL-5 assesses post-traumatic stress symptoms over the past month.', fr: 'Le PCL-5 évalue l’intensité des symptômes de stress post-traumatique au cours du dernier mois.', de: 'Der PCL-5 erfasst die Ausprägung posttraumatischer Stresssymptome im letzten Monat.', pt: 'O PCL-5 avalia a intensidade dos sintomas de estresse pós-traumático no último mês.'),
          recommendations: [
            if (score >= 31) locText(context, ru: 'Если переживания после травмы сильно мешают жизни, имеет смысл обсудить это со специалистом.', en: 'If trauma-related distress strongly affects daily life, talking with a professional makes sense.', fr: 'Si la détresse liée au trauma gêne fortement la vie quotidienne, parler à un professionnel est pertinent.', de: 'Wenn traumabedingte Belastung den Alltag stark beeinträchtigt, ist ein Gespräch mit Fachpersonal sinnvoll.', pt: 'Se o sofrimento pós-trauma atrapalha muito o dia a dia, faz sentido conversar com um profissional.'),
          ],
        );
      case TestKind.swls:
        final score = answers.fold<int>(0, (a, b) => a + b);
        final level = score <= 9
            ? locText(context, ru: 'Крайне низкая удовлетворённость', en: 'Extremely dissatisfied', fr: 'Extrêmement insatisfait(e)', de: 'Extrem unzufrieden', pt: 'Extremamente insatisfeito(a)')
            : score <= 14
                ? locText(context, ru: 'Низкая удовлетворённость', en: 'Dissatisfied', fr: 'Insatisfait(e)', de: 'Unzufrieden', pt: 'Insatisfeito(a)')
                : score <= 19
                    ? locText(context, ru: 'Слегка ниже среднего', en: 'Slightly below average', fr: 'Légèrement en dessous de la moyenne', de: 'Leicht unterdurchschnittlich', pt: 'Um pouco abaixo da média')
                    : score <= 25
                        ? locText(context, ru: 'Средняя удовлетворённость', en: 'Average satisfaction', fr: 'Satisfaction moyenne', de: 'Durchschnittliche Zufriedenheit', pt: 'Satisfação média')
                        : score <= 30
                            ? locText(context, ru: 'Высокая удовлетворённость', en: 'Satisfied', fr: 'Satisfait(e)', de: 'Zufrieden', pt: 'Satisfeito(a)')
                            : locText(context, ru: 'Очень высокая удовлетворённость', en: 'Highly satisfied', fr: 'Très satisfait(e)', de: 'Sehr zufrieden', pt: 'Muito satisfeito(a)');
        return TestEvaluation(
          scoreText: '$score / 35',
          levelTitle: level,
          summary: locText(context, ru: 'SWLS показывает, насколько вы в целом довольны своей жизнью.', en: 'SWLS reflects how satisfied you are with your life overall.', fr: 'Le SWLS montre à quel point vous êtes globalement satisfait(e) de votre vie.', de: 'Die SWLS zeigt, wie zufrieden Sie insgesamt mit Ihrem Leben sind.', pt: 'A SWLS mostra o quanto você está satisfeito(a) com sua vida em geral.'),
        );
    }
  }

  static String _dassLevel(BuildContext context, int score, String type) {
    switch (type) {
      case 'depression':
        if (score <= 9) {
          return locText(
            context,
            ru: 'По этой линии нет сильных признаков депрессии — ближе к обычному фону переживаний.',
            en: 'On this line, depression-type strain looks low—closer to your usual baseline.',
            fr: 'Sur cette ligne, la charge « dépression » semble faible, proche de votre habitude.',
            de: 'Auf dieser Linie wirkt depressionsähnliche Belastung gering—näher an Ihrer üblichen Basis.',
            pt: 'Nesta linha, a carga ligada à depressão parece baixa—perto do seu habitual.',
          );
        }
        if (score <= 13) {
          return locText(
            context,
            ru: 'Лёгкая выраженность переживаний в сторону депрессии. Имеет смысл присмотреться, если это мешает сну, работе или отношениям.',
            en: 'Mild depression-related strain. Notice if it starts affecting sleep, work, or relationships.',
            fr: 'Charge légère côté dépression. Restez attentif(ve) si cela perturbe sommeil, travail ou relations.',
            de: 'Leichte depressionsnahe Belastung. Achten Sie darauf, ob Schlaf, Arbeit oder Beziehungen leiden.',
            pt: 'Carga leve ligada à depressão. Observe se começa a afetar sono, trabalho ou relacionamentos.',
          );
        }
        if (score <= 20) {
          return locText(
            context,
            ru: 'Умеренно выраженные депрессивные переживания. Полезно поговорить с близким человеком или специалистом.',
            en: 'Moderate depression-related strain. Talking with someone you trust or a professional is often helpful.',
            fr: 'Charge modérée côté dépression. Parler à une personne de confiance ou à un professionnel aide souvent.',
            de: 'Mäßige depressionsnahe Belastung. Ein Gespräch mit Vertrauensperson oder Fachperson hilft oft.',
            pt: 'Carga moderada ligada à depressão. Conversar com alguém de confiança ou um profissional costuma ajudar.',
          );
        }
        if (score <= 27) {
          return locText(
            context,
            ru: 'Сильная нагрузка по депрессивной линии. Разумно обратиться за профессиональной поддержкой.',
            en: 'Strong depression-related strain. Seeking professional support is a sensible step.',
            fr: 'Forte charge côté dépression. Consulter un professionnel est une démarche raisonnable.',
            de: 'Starke depressionsnahe Belastung. Professionelle Unterstützung ist ein sinnvoller Schritt.',
            pt: 'Carga forte ligada à depressão. Buscar apoio profissional é um passo sensato.',
          );
        }
        return locText(
          context,
          ru: 'Очень высокая нагрузка. Важно не оставаться с этим в одиночку и обратиться за помощью как можно скорее.',
          en: 'Very heavy strain. Please don’t face this alone—reach out for help as soon as you can.',
          fr: 'Charge très lourde. Ne restez pas seul(e) : cherchez de l’aide au plus vite.',
          de: 'Sehr hohe Belastung. Bitte bleiben Sie nicht allein—holen Sie möglichst bald Hilfe.',
          pt: 'Carga muito pesada. Não fique sozinho(a)—busque ajuda o quanto antes.',
        );
      case 'anxiety':
        if (score <= 7) {
          return locText(
            context,
            ru: 'По этой линии тревожные переживания сейчас в спокойной зоне — без сильной нагрузки.',
            en: 'On this line, anxiety-type strain looks calm—not heavily loaded right now.',
            fr: 'Sur cette ligne, l’anxiété semble calme, sans forte charge pour l’instant.',
            de: 'Auf dieser Linie wirkt ängstliche Belastung ruhig—derzeit nicht stark.',
            pt: 'Nesta linha, a ansiedade parece calma—sem carga forte no momento.',
          );
        }
        if (score <= 9) {
          return locText(
            context,
            ru: 'Лёгкая тревожность. Полезно замечать триггеры и отдых, если напряжение нарастает.',
            en: 'Mild anxiety strain. Notice triggers and rest if tension builds.',
            fr: 'Anxiété légère. Repérez les déclencheurs et reposez-vous si la tension monte.',
            de: 'Leichte Angstbelastung. Achten Sie auf Auslöser und Pausen, wenn die Spannung steigt.',
            pt: 'Ansiedade leve. Observe gatilhos e descanse se a tensão aumentar.',
          );
        }
        if (score <= 14) {
          return locText(
            context,
            ru: 'Умеренная тревожная нагрузка. Имеет смысл обсудить переживания с близким человеком или специалистом.',
            en: 'Moderate anxiety strain. Discussing how you feel with someone close or a clinician often helps.',
            fr: 'Charge d’anxiété modérée. Parler de ce que vous vivez à un proche ou un soignant aide souvent.',
            de: 'Mäßige Angstbelastung. Über das Erlebte mit Nahestehenden oder Fachperson zu sprechen hilft oft.',
            pt: 'Carga moderada de ansiedade. Falar do que sente com alguém próximo ou profissional costuma ajudar.',
          );
        }
        if (score <= 19) {
          return locText(
            context,
            ru: 'Сильная тревога по ответам на эту шкалу. Рекомендуется профессиональная оценка.',
            en: 'Strong anxiety on this scale. A professional assessment is recommended.',
            fr: 'Anxiété marquée sur cette échelle. Une évaluation professionnelle est recommandée.',
            de: 'Ausgeprägte Angst auf dieser Skala. Eine fachliche Abklärung wird empfohlen.',
            pt: 'Ansiedade forte nesta escala. Avaliação profissional recomendada.',
          );
        }
        return locText(
          context,
          ru: 'Очень высокая тревожная нагрузка. Обратитесь за срочной поддержкой к специалисту или кризисной службе, если есть страх за себя.',
          en: 'Very heavy anxiety strain. Seek urgent support from a clinician or crisis service if you fear for your safety.',
          fr: 'Anxiété très lourde. En cas de crainte pour votre sécurité, contactez un soignant ou un service d’urgence psychologique.',
          de: 'Sehr hohe Angstbelastung. Bei Sorge um Ihre Sicherheit wenden Sie sich dringend an Fachhilfe oder Krisendienst.',
          pt: 'Carga muito pesada de ansiedade. Se teme pela sua segurança, busque apoio urgente ou serviço de crise.',
        );
      default:
        if (score <= 14) {
          return locText(
            context,
            ru: 'Стресс по этой линии в обычном диапазоне — без сильной перегрузки.',
            en: 'Stress on this line is in a typical range—not heavily overloaded.',
            fr: 'Le stress sur cette ligne reste dans une plage habituelle, sans forte surcharge.',
            de: 'Stress auf dieser Linie liegt im üblichen Bereich—nicht stark überlastet.',
            pt: 'O estresse nesta linha está numa faixa habitual—sem sobrecarga forte.',
          );
        }
        if (score <= 18) {
          return locText(
            context,
            ru: 'Лёгкое повышение стресса. Помогают режим сна, паузы и разговор о нагрузке с близкими.',
            en: 'Mildly elevated stress. Sleep, breaks, and talking about load with trusted people usually help.',
            fr: 'Stress un peu élevé. Sommeil, pauses et discussion avec des proches aident en général.',
            de: 'Leicht erhöhter Stress. Schlaf, Pausen und Gespräche mit Vertrauenspersonen helfen meist.',
            pt: 'Estresse um pouco elevado. Sono, pausas e conversar com pessoas de confiança costumam ajudar.',
          );
        }
        if (score <= 25) {
          return locText(
            context,
            ru: 'Умеренно высокий стресс. Имеет смысл снизить нагрузку где возможно и обсудить самочувствие со специалистом.',
            en: 'Moderately high stress. Easing load where you can and talking with a professional makes sense.',
            fr: 'Stress modérément élevé. Réduire la charge quand c’est possible et en parler à un professionnel est pertinent.',
            de: 'Mäßig hoher Stress. Belastung wo möglich senken und mit Fachperson sprechen ist sinnvoll.',
            pt: 'Estresse moderadamente alto. Reduzir a carga quando der e falar com um profissional faz sentido.',
          );
        }
        if (score <= 33) {
          return locText(
            context,
            ru: 'Сильный стресс: вы на пределе ресурсов. Важна поддержка и, при необходимости, обращение к врачу или психологу.',
            en: 'Strong stress—you may be near your limits. Support matters; consider seeing a doctor or therapist.',
            fr: 'Stress fort : vous êtes peut-être au bout des ressources. Le soutien compte ; consultez si besoin.',
            de: 'Starker Stress—Sie könnten am Limit sein. Unterstützung zählt; bei Bedarf Arzt oder Therapeut.',
            pt: 'Estresse forte—você pode estar no limite. Apoio importa; considere médico ou terapeuta.',
          );
        }
        return locText(
          context,
          ru: 'Очень высокий стресс. Не откладывайте разговор со специалистом и о помощи близким, если стало тяжело справляться одному.',
          en: 'Very high stress. Don’t postpone talking with a professional and asking loved ones for help if coping alone feels hard.',
          fr: 'Stress très élevé. Ne repoussez pas un rendez-vous professionnel ni l’aide des proches si c’est difficile seul(e).',
          de: 'Sehr hoher Stress. Verschieben Sie kein Gespräch mit Fachpersonen; holen Sie Hilfe, wenn das Alleinschaffen schwerfällt.',
          pt: 'Estresse muito alto. Não adie falar com um profissional e pedir apoio a pessoas próximas se sozinho(a) ficou difícil.',
        );
    }
  }

  static TestDefinition _phq2() => TestDefinition(
        id: 'phq2',
        kind: TestKind.phq2,
        category: TestCategoryId.depression,
        title: const TLoc(ru: 'PHQ-2', en: 'PHQ-2', fr: 'PHQ-2', de: 'PHQ-2', pt: 'PHQ-2'),
        subtitle: const TLoc(
          ru: 'Сверхбыстрый скрининг депрессии',
          en: 'Ultra-short depression screen',
          fr: 'Dépistage très rapide de la dépression',
          de: 'Ultrakurzes Depressionsscreening',
          pt: 'Triagem ultrarrápida para depressão',
        ),
        description: const TLoc(
          ru: 'Два вопроса для первичного фильтра сниженного настроения и потери интереса.',
          en: 'Two items for a fast first-pass depression screen.',
          fr: 'Deux questions pour un premier filtrage de l’humeur dépressive et de la perte d’intérêt.',
          de: 'Zwei Fragen für ein erstes Screening von gedrückter Stimmung und Interessenverlust.',
          pt: 'Duas perguntas para um primeiro rastreio de humor deprimido e perda de interesse.',
        ),
        questions: const [
          TestQuestion(
            id: 'phq2_1',
            text: TLoc(
              ru: 'За последние 2 недели как часто вас беспокоило отсутствие интереса или удовольствия от дел?',
              en: 'Over the last 2 weeks, how often have you had little interest or pleasure in doing things?',
              fr: 'Au cours des 2 dernières semaines, à quelle fréquence avez-vous eu peu d’intérêt ou de plaisir à faire les choses ?',
              de: 'Wie oft hatten Sie in den letzten 2 Wochen wenig Interesse oder Freude an Ihren Tätigkeiten?',
              pt: 'Nas últimas 2 semanas, com que frequência você teve pouco interesse ou prazer em fazer as coisas?',
            ),
            options: optNeverToAlways4,
          ),
          TestQuestion(
            id: 'phq2_2',
            text: TLoc(
              ru: 'За последние 2 недели как часто вас беспокоило чувство подавленности, грусти или безнадёжности?',
              en: 'Over the last 2 weeks, how often have you felt down, depressed, or hopeless?',
              fr: 'Au cours des 2 dernières semaines, à quelle fréquence vous êtes-vous senti(e) triste, déprimé(e) ou sans espoir ?',
              de: 'Wie oft fühlten Sie sich in den letzten 2 Wochen niedergeschlagen, deprimiert oder hoffnungslos?',
              pt: 'Nas últimas 2 semanas, com que frequência você se sentiu triste, deprimido(a) ou sem esperança?',
            ),
            options: optNeverToAlways4,
          ),
        ],
      );

  static TestDefinition _phq9() => TestDefinition(
        id: 'phq9',
        kind: TestKind.phq9,
        category: TestCategoryId.depression,
        title: const TLoc(ru: 'PHQ-9', en: 'PHQ-9', fr: 'PHQ-9', de: 'PHQ-9', pt: 'PHQ-9'),
        subtitle: const TLoc(
          ru: 'Классический скрининг депрессии',
          en: 'Core depression screener',
          fr: 'Dépistage classique de la dépression',
          de: 'Klassisches Depressionsscreening',
          pt: 'Triagem clássica de depressão',
        ),
        description: const TLoc(
          ru: 'Оценивает выраженность депрессивных симптомов за последние 2 недели.',
          en: 'Assesses depressive symptoms over the last 2 weeks.',
          fr: 'Évalue l’intensité des symptômes dépressifs au cours des 2 dernières semaines.',
          de: 'Erfasst die Ausprägung depressiver Symptome in den letzten 2 Wochen.',
          pt: 'Avalia a intensidade dos sintomas depressivos nas últimas 2 semanas.',
        ),
        questions: const [
          TestQuestion(id: 'phq9_1', text: TLoc(ru: 'Отсутствие интереса или удовольствия от дел', en: 'Little interest or pleasure in doing things', fr: 'Peu d’intérêt ou de plaisir à faire les choses', de: 'Wenig Interesse oder Freude an Ihren Tätigkeiten', pt: 'Pouco interesse ou prazer em fazer as coisas'), options: optNeverToAlways4),
          TestQuestion(id: 'phq9_2', text: TLoc(ru: 'Чувство подавленности, грусти или безнадёжности', en: 'Feeling down, depressed, or hopeless', fr: 'Sentiment de tristesse, de déprime ou d’absence d’espoir', de: 'Niedergeschlagenheit, Traurigkeit oder Hoffnungslosigkeit', pt: 'Sentir-se triste, deprimido(a) ou sem esperança'), options: optNeverToAlways4),
          TestQuestion(id: 'phq9_3', text: TLoc(ru: 'Трудности с засыпанием, сном или слишком долгий сон', en: 'Trouble falling or staying asleep, or sleeping too much', fr: 'Difficultés à s’endormir, à rester endormi(e), ou sommeil excessif', de: 'Probleme beim Ein- oder Durchschlafen oder zu viel Schlaf', pt: 'Dificuldade para dormir ou dormir demais'), options: optNeverToAlways4),
          TestQuestion(id: 'phq9_4', text: TLoc(ru: 'Усталость или нехватка энергии', en: 'Feeling tired or having little energy', fr: 'Fatigue ou manque d’énergie', de: 'Müdigkeit oder wenig Energie', pt: 'Cansaço ou falta de energia'), options: optNeverToAlways4),
          TestQuestion(id: 'phq9_5', text: TLoc(ru: 'Плохой аппетит или переедание', en: 'Poor appetite or overeating', fr: 'Perte d’appétit ou excès alimentaires', de: 'Appetitlosigkeit oder übermäßiges Essen', pt: 'Falta de apetite ou comer em excesso'), options: optNeverToAlways4),
          TestQuestion(id: 'phq9_6', text: TLoc(ru: 'Плохое отношение к себе, чувство неудачи или разочарования в себе', en: 'Feeling bad about yourself — or that you are a failure or have let yourself or your family down', fr: 'Mauvaise opinion de vous-même, sentiment d’échec ou d’avoir déçu votre entourage', de: 'Schlechtes Selbstwertgefühl oder das Gefühl, versagt oder andere enttäuscht zu haben', pt: 'Sentir-se mal consigo mesmo(a), fracassado(a) ou como se tivesse decepcionado a si ou aos outros'), options: optNeverToAlways4),
          TestQuestion(id: 'phq9_7', text: TLoc(ru: 'Трудности с концентрацией, например при чтении или просмотре телевизора', en: 'Trouble concentrating on things, such as reading or watching television', fr: 'Difficultés de concentration, par exemple pour lire ou regarder la télévision', de: 'Konzentrationsschwierigkeiten, z. B. beim Lesen oder Fernsehen', pt: 'Dificuldade de concentração, por exemplo ao ler ou assistir TV'), options: optNeverToAlways4),
          TestQuestion(id: 'phq9_8', text: TLoc(ru: 'Замедленность движений или речи либо заметная суетливость и беспокойство', en: 'Moving or speaking slowly or being fidgety / restless', fr: 'Lenteur des gestes ou de la parole, ou agitation et nervosité visibles', de: 'Verlangsamte Bewegungen oder Sprache oder auffällige Unruhe', pt: 'Movimentos ou fala mais lentos, ou inquietação/agitação perceptível'), options: optNeverToAlways4),
          TestQuestion(id: 'phq9_9', text: TLoc(ru: 'Мысли о том, что вам было бы лучше умереть, или о причинении себе вреда', en: 'Thoughts that you would be better off dead or of hurting yourself in some way', fr: 'Pensées qu’il vaudrait mieux être mort(e) ou de vous faire du mal', de: 'Gedanken, dass Sie besser tot wären oder sich selbst verletzen könnten', pt: 'Pensamentos de que seria melhor estar morto(a) ou de machucar a si mesmo(a)'), options: optNeverToAlways4),
        ],
      );

  static TestDefinition _gad7() => TestDefinition(
        id: 'gad7',
        kind: TestKind.gad7,
        category: TestCategoryId.anxiety,
        title: const TLoc(ru: 'GAD-7', en: 'GAD-7', fr: 'GAD-7', de: 'GAD-7', pt: 'GAD-7'),
        subtitle: const TLoc(
          ru: 'Основной тест тревоги',
          en: 'Core anxiety screener',
          fr: 'Test principal d’anxiété',
          de: 'Haupttest für Angst',
          pt: 'Teste principal de ansiedade',
        ),
        description: const TLoc(
          ru: 'Оценивает выраженность генерализованной тревоги за последние 2 недели.',
          en: 'Assesses generalized anxiety over the last 2 weeks.',
          fr: 'Évalue l’intensité de l’anxiété généralisée au cours des 2 dernières semaines.',
          de: 'Erfasst die Ausprägung generalisierter Angst in den letzten 2 Wochen.',
          pt: 'Avalia a intensidade da ansiedade generalizada nas últimas 2 semanas.',
        ),
        questions: const [
          TestQuestion(id: 'gad7_1', text: TLoc(ru: 'Чувство нервозности, тревоги или напряжения', en: 'Feeling nervous, anxious, or on edge', fr: 'Sentiment de nervosité, d’anxiété ou de tension', de: 'Gefühl von Nervosität, Angst oder Anspannung', pt: 'Sentir-se nervoso(a), ansioso(a) ou tenso(a)'), options: optNeverToAlways4),
          TestQuestion(id: 'gad7_2', text: TLoc(ru: 'Невозможность остановить или контролировать беспокойство', en: 'Not being able to stop or control worrying', fr: 'Impossible d’arrêter ou de contrôler les inquiétudes', de: 'Sorgen nicht stoppen oder kontrollieren können', pt: 'Não conseguir parar ou controlar as preocupações'), options: optNeverToAlways4),
          TestQuestion(id: 'gad7_3', text: TLoc(ru: 'Слишком сильное беспокойство по разным поводам', en: 'Worrying too much about different things', fr: 'Trop s’inquiéter à propos de différentes choses', de: 'Sich über verschiedene Dinge zu viele Sorgen machen', pt: 'Preocupar-se demais com diferentes coisas'), options: optNeverToAlways4),
          TestQuestion(id: 'gad7_4', text: TLoc(ru: 'Трудность расслабиться', en: 'Trouble relaxing', fr: 'Difficulté à se détendre', de: 'Schwierigkeiten, sich zu entspannen', pt: 'Dificuldade para relaxar'), options: optNeverToAlways4),
          TestQuestion(id: 'gad7_5', text: TLoc(ru: 'Настолько сильное беспокойство, что трудно усидеть на месте', en: 'Being so restless that it is hard to sit still', fr: 'Agitation telle qu’il est difficile de rester assis(e)', de: 'So unruhig sein, dass stilles Sitzen schwerfällt', pt: 'Estar tão inquieto(a) que é difícil ficar parado(a)'), options: optNeverToAlways4),
          TestQuestion(id: 'gad7_6', text: TLoc(ru: 'Лёгкая раздражительность', en: 'Becoming easily annoyed or irritable', fr: 'Devenir facilement agacé(e) ou irritable', de: 'Leicht gereizt oder ärgerlich werden', pt: 'Ficar facilmente irritado(a)'), options: optNeverToAlways4),
          TestQuestion(id: 'gad7_7', text: TLoc(ru: 'Страх, что может случиться что-то ужасное', en: 'Feeling afraid as if something awful might happen', fr: 'Peur que quelque chose d’horrible puisse arriver', de: 'Angst, dass etwas Schreckliches passieren könnte', pt: 'Medo de que algo terrível possa acontecer'), options: optNeverToAlways4),
        ],
      );

  static TestDefinition _who5() => TestDefinition(
        id: 'who5',
        kind: TestKind.who5,
        category: TestCategoryId.wellbeing,
        title: const TLoc(ru: 'WHO-5', en: 'WHO-5', fr: 'WHO-5', de: 'WHO-5', pt: 'WHO-5'),
        subtitle: const TLoc(
          ru: 'Индекс благополучия',
          en: 'Well-being index',
          fr: 'Indice de bien-être',
          de: 'Wohlbefindensindex',
          pt: 'Índice de bem-estar',
        ),
        description: const TLoc(
          ru: 'Быстрая оценка субъективного благополучия.',
          en: 'Quick subjective well-being screen.',
          fr: 'Évaluation rapide du bien-être subjectif.',
          de: 'Schnelles Screening des subjektiven Wohlbefindens.',
          pt: 'Avaliação rápida do bem-estar subjetivo.',
        ),
        questions: const [
          TestQuestion(id: 'who5_1', text: TLoc(ru: 'Я чувствовал(а) себя бодро и в хорошем настроении', en: 'I have felt cheerful and in good spirits', fr: 'Je me suis senti(e) de bonne humeur et plein(e) d’entrain', de: 'Ich habe mich froh und guter Laune gefühlt', pt: 'Senti-me alegre e bem-disposto(a)'), options: optWho5),
          TestQuestion(id: 'who5_2', text: TLoc(ru: 'Я чувствовал(а) себя спокойно и расслабленно', en: 'I have felt calm and relaxed', fr: 'Je me suis senti(e) calme et détendu(e)', de: 'Ich habe mich ruhig und entspannt gefühlt', pt: 'Senti-me calmo(a) e relaxado(a)'), options: optWho5),
          TestQuestion(id: 'who5_3', text: TLoc(ru: 'Я чувствовал(а) себя активным(ой) и полным(ой) сил', en: 'I have felt active and vigorous', fr: 'Je me suis senti(e) actif(ve) et plein(e) d’énergie', de: 'Ich habe mich aktiv und voller Energie gefühlt', pt: 'Senti-me ativo(a) e cheio(a) de energia'), options: optWho5),
          TestQuestion(id: 'who5_4', text: TLoc(ru: 'Я просыпался(ась) свежим(ей) и отдохнувшим(ей)', en: 'I woke up feeling fresh and rested', fr: 'Je me suis réveillé(e) frais(che) et reposé(e)', de: 'Ich bin frisch und ausgeruht aufgewacht', pt: 'Acordei sentindo-me descansado(a) e revigorado(a)'), options: optWho5),
          TestQuestion(id: 'who5_5', text: TLoc(ru: 'Моя повседневная жизнь была наполнена интересными для меня вещами', en: 'My daily life has been filled with things that interest me', fr: 'Ma vie quotidienne a été remplie de choses qui m’intéressent', de: 'Mein Alltag war mit Dingen gefüllt, die mich interessieren', pt: 'Minha vida diária esteve cheia de coisas que me interessam'), options: optWho5),
        ],
      );

  static TestDefinition _audit() => TestDefinition(
        id: 'audit',
        kind: TestKind.audit,
        category: TestCategoryId.addictions,
        title: const TLoc(ru: 'AUDIT', en: 'AUDIT', fr: 'AUDIT', de: 'AUDIT', pt: 'AUDIT'),
        subtitle: const TLoc(
          ru: 'Скрининг риска, связанного с алкоголем',
          en: 'Alcohol risk screening',
          fr: 'Dépistage du risque lié à l’alcool',
          de: 'Screening auf alkoholkonsumbezogenes Risiko',
          pt: 'Triagem de risco relacionado ao álcool',
        ),
        description: const TLoc(
          ru: 'Инструмент ВОЗ для выявления рискованного и вредного употребления алкоголя.',
          en: 'WHO tool for risky and harmful alcohol use.',
          fr: 'Outil de l’OMS pour repérer un usage à risque ou nocif d’alcool.',
          de: 'WHO-Instrument zur Erkennung riskanten und schädlichen Alkoholkonsums.',
          pt: 'Ferramenta da OMS para identificar consumo de álcool de risco e nocivo.',
        ),
        questions: const [
          TestQuestion(
            id: 'audit_1',
            text: TLoc(
              ru: 'Как часто вы употребляете алкоголь?',
              en: 'How often do you have a drink containing alcohol?',
              fr: 'À quelle fréquence buvez-vous une boisson contenant de l’alcool ?',
              de: 'Wie oft trinken Sie ein alkoholhaltiges Getränk?',
              pt: 'Com que frequência você consome uma bebida que contém álcool?',
            ),
            options: [
              TestOption(label: TLoc(ru: 'Никогда', en: 'Never', fr: 'Jamais', de: 'Nie', pt: 'Nunca'), score: 0),
              TestOption(label: TLoc(ru: 'Раз в месяц или реже', en: 'Monthly or less', fr: 'Une fois par mois ou moins', de: 'Monatlich oder seltener', pt: 'Uma vez por mês ou menos'), score: 1),
              TestOption(label: TLoc(ru: '2–4 раза в месяц', en: '2–4 times a month', fr: '2 à 4 fois par mois', de: '2–4 Mal pro Monat', pt: '2–4 vezes por mês'), score: 2),
              TestOption(label: TLoc(ru: '2–3 раза в неделю', en: '2–3 times a week', fr: '2 à 3 fois par semaine', de: '2–3 Mal pro Woche', pt: '2–3 vezes por semana'), score: 3),
              TestOption(label: TLoc(ru: '4 и более раз в неделю', en: '4 or more times a week', fr: '4 fois ou plus par semaine', de: '4 Mal oder häufiger pro Woche', pt: '4 ou mais vezes por semana'), score: 4),
            ],
          ),
          TestQuestion(
            id: 'audit_2',
            text: TLoc(
              ru: 'Сколько порций алкоголя вы обычно выпиваете в типичный день употребления?',
              en: 'How many drinks do you have on a typical day when drinking?',
              fr: 'Combien de verres buvez-vous habituellement un jour typique où vous buvez ?',
              de: 'Wie viele Getränke trinken Sie typischerweise an einem Tag, an dem Sie trinken?',
              pt: 'Quantas doses você costuma beber em um dia típico em que bebe?',
            ),
            options: [
              TestOption(label: TLoc(ru: '1–2', en: '1–2', fr: '1–2', de: '1–2', pt: '1–2'), score: 0),
              TestOption(label: TLoc(ru: '3–4', en: '3–4', fr: '3–4', de: '3–4', pt: '3–4'), score: 1),
              TestOption(label: TLoc(ru: '5–6', en: '5–6', fr: '5–6', de: '5–6', pt: '5–6'), score: 2),
              TestOption(label: TLoc(ru: '7–9', en: '7–9', fr: '7–9', de: '7–9', pt: '7–9'), score: 3),
              TestOption(label: TLoc(ru: '10 и более', en: '10 or more', fr: '10 ou plus', de: '10 oder mehr', pt: '10 ou mais'), score: 4),
            ],
          ),
          TestQuestion(
            id: 'audit_3',
            text: TLoc(
              ru: 'Как часто вы выпиваете шесть и более порций за один раз?',
              en: 'How often do you have six or more drinks on one occasion?',
              fr: 'À quelle fréquence buvez-vous six verres ou plus en une seule occasion ?',
              de: 'Wie oft trinken Sie bei einer Gelegenheit sechs oder mehr Getränke?',
              pt: 'Com que frequência você consome seis doses ou mais em uma única ocasião?',
            ),
            options: [
              TestOption(label: TLoc(ru: 'Никогда', en: 'Never', fr: 'Jamais', de: 'Nie', pt: 'Nunca'), score: 0),
              TestOption(label: TLoc(ru: 'Реже раза в месяц', en: 'Less than monthly', fr: 'Moins d’une fois par mois', de: 'Seltener als monatlich', pt: 'Menos de uma vez por mês'), score: 1),
              TestOption(label: TLoc(ru: 'Раз в месяц', en: 'Monthly', fr: 'Une fois par mois', de: 'Monatlich', pt: 'Uma vez por mês'), score: 2),
              TestOption(label: TLoc(ru: 'Раз в неделю', en: 'Weekly', fr: 'Une fois par semaine', de: 'Wöchentlich', pt: 'Uma vez por semana'), score: 3),
              TestOption(label: TLoc(ru: 'Почти ежедневно', en: 'Daily or almost daily', fr: 'Tous les jours ou presque', de: 'Täglich oder fast täglich', pt: 'Diariamente ou quase diariamente'), score: 4),
            ],
          ),
          TestQuestion(
            id: 'audit_4',
            text: TLoc(
              ru: 'Как часто, начав пить, вы не могли остановиться?',
              en: 'How often have you found you were not able to stop drinking once you had started?',
              fr: 'À quelle fréquence, une fois que vous avez commencé à boire, n’avez-vous pas pu vous arrêter ?',
              de: 'Wie oft konnten Sie, nachdem Sie angefangen hatten zu trinken, nicht mehr aufhören?',
              pt: 'Com que frequência, depois de começar a beber, você não conseguiu parar?',
            ),
            options: [
              TestOption(label: TLoc(ru: 'Никогда', en: 'Never', fr: 'Jamais', de: 'Nie', pt: 'Nunca'), score: 0),
              TestOption(label: TLoc(ru: 'Реже раза в месяц', en: 'Less than monthly', fr: 'Moins d’une fois par mois', de: 'Seltener als monatlich', pt: 'Menos de uma vez por mês'), score: 1),
              TestOption(label: TLoc(ru: 'Раз в месяц', en: 'Monthly', fr: 'Une fois par mois', de: 'Monatlich', pt: 'Uma vez por mês'), score: 2),
              TestOption(label: TLoc(ru: 'Раз в неделю', en: 'Weekly', fr: 'Une fois par semaine', de: 'Wöchentlich', pt: 'Uma vez por semana'), score: 3),
              TestOption(label: TLoc(ru: 'Почти ежедневно', en: 'Daily or almost daily', fr: 'Tous les jours ou presque', de: 'Täglich oder fast täglich', pt: 'Diariamente ou quase diariamente'), score: 4),
            ],
          ),
          TestQuestion(
            id: 'audit_5',
            text: TLoc(
              ru: 'Как часто из-за алкоголя вы не делали то, что обычно должны были сделать?',
              en: 'How often have you failed to do what was normally expected of you because of drinking?',
              fr: 'À quelle fréquence l’alcool vous a-t-il empêché(e) de faire ce qui était normalement attendu de vous ?',
              de: 'Wie oft haben Sie aufgrund des Trinkens nicht getan, was normalerweise von Ihnen erwartet wurde?',
              pt: 'Com que frequência você deixou de fazer o que normalmente era esperado de você por causa da bebida?',
            ),
            options: [
              TestOption(label: TLoc(ru: 'Никогда', en: 'Never', fr: 'Jamais', de: 'Nie', pt: 'Nunca'), score: 0),
              TestOption(label: TLoc(ru: 'Реже раза в месяц', en: 'Less than monthly', fr: 'Moins d’une fois par mois', de: 'Seltener als monatlich', pt: 'Menos de uma vez por mês'), score: 1),
              TestOption(label: TLoc(ru: 'Раз в месяц', en: 'Monthly', fr: 'Une fois par mois', de: 'Monatlich', pt: 'Uma vez por mês'), score: 2),
              TestOption(label: TLoc(ru: 'Раз в неделю', en: 'Weekly', fr: 'Une fois par semaine', de: 'Wöchentlich', pt: 'Uma vez por semana'), score: 3),
              TestOption(label: TLoc(ru: 'Почти ежедневно', en: 'Daily or almost daily', fr: 'Tous les jours ou presque', de: 'Täglich oder fast täglich', pt: 'Diariamente ou quase diariamente'), score: 4),
            ],
          ),
          TestQuestion(
            id: 'audit_6',
            text: TLoc(
              ru: 'Как часто вам нужен был алкоголь утром, чтобы прийти в себя после выпивки?',
              en: 'How often have you needed a first drink in the morning to get yourself going after heavy drinking?',
              fr: 'À quelle fréquence avez-vous eu besoin de boire dès le matin pour vous remettre après une forte consommation ?',
              de: 'Wie oft brauchten Sie morgens als Erstes einen Drink, um nach starkem Trinken wieder in Gang zu kommen?',
              pt: 'Com que frequência você precisou beber logo de manhã para se recuperar depois de beber muito?',
            ),
            options: [
              TestOption(label: TLoc(ru: 'Никогда', en: 'Never', fr: 'Jamais', de: 'Nie', pt: 'Nunca'), score: 0),
              TestOption(label: TLoc(ru: 'Реже раза в месяц', en: 'Less than monthly', fr: 'Moins d’une fois par mois', de: 'Seltener als monatlich', pt: 'Menos de uma vez por mês'), score: 1),
              TestOption(label: TLoc(ru: 'Раз в месяц', en: 'Monthly', fr: 'Une fois par mois', de: 'Monatlich', pt: 'Uma vez por mês'), score: 2),
              TestOption(label: TLoc(ru: 'Раз в неделю', en: 'Weekly', fr: 'Une fois par semaine', de: 'Wöchentlich', pt: 'Uma vez por semana'), score: 3),
              TestOption(label: TLoc(ru: 'Почти ежедневно', en: 'Daily or almost daily', fr: 'Tous les jours ou presque', de: 'Täglich oder fast täglich', pt: 'Diariamente ou quase diariamente'), score: 4),
            ],
          ),
          TestQuestion(
            id: 'audit_7',
            text: TLoc(
              ru: 'Как часто после выпивки вы испытывали чувство вины или сожаления?',
              en: 'How often have you had a feeling of guilt or remorse after drinking?',
              fr: 'À quelle fréquence avez-vous ressenti de la culpabilité ou des remords après avoir bu ?',
              de: 'Wie oft hatten Sie nach dem Trinken Schuldgefühle oder Reue?',
              pt: 'Com que frequência você sentiu culpa ou remorso depois de beber?',
            ),
            options: [
              TestOption(label: TLoc(ru: 'Никогда', en: 'Never', fr: 'Jamais', de: 'Nie', pt: 'Nunca'), score: 0),
              TestOption(label: TLoc(ru: 'Реже раза в месяц', en: 'Less than monthly', fr: 'Moins d’une fois par mois', de: 'Seltener als monatlich', pt: 'Menos de uma vez por mês'), score: 1),
              TestOption(label: TLoc(ru: 'Раз в месяц', en: 'Monthly', fr: 'Une fois par mois', de: 'Monatlich', pt: 'Uma vez por mês'), score: 2),
              TestOption(label: TLoc(ru: 'Раз в неделю', en: 'Weekly', fr: 'Une fois par semaine', de: 'Wöchentlich', pt: 'Uma vez por semana'), score: 3),
              TestOption(label: TLoc(ru: 'Почти ежедневно', en: 'Daily or almost daily', fr: 'Tous les jours ou presque', de: 'Täglich oder fast täglich', pt: 'Diariamente ou quase diariamente'), score: 4),
            ],
          ),
          TestQuestion(
            id: 'audit_8',
            text: TLoc(
              ru: 'Как часто вы не могли вспомнить, что было накануне вечером из-за выпивки?',
              en: 'How often have you been unable to remember what happened the night before because of drinking?',
              fr: 'À quelle fréquence n’avez-vous pas pu vous souvenir de ce qui s’était passé la veille au soir à cause de l’alcool ?',
              de: 'Wie oft konnten Sie sich wegen des Trinkens nicht erinnern, was am Abend zuvor passiert ist?',
              pt: 'Com que frequência você não conseguiu se lembrar do que aconteceu na noite anterior por causa da bebida?',
            ),
            options: [
              TestOption(label: TLoc(ru: 'Никогда', en: 'Never', fr: 'Jamais', de: 'Nie', pt: 'Nunca'), score: 0),
              TestOption(label: TLoc(ru: 'Реже раза в месяц', en: 'Less than monthly', fr: 'Moins d’une fois par mois', de: 'Seltener als monatlich', pt: 'Menos de uma vez por mês'), score: 1),
              TestOption(label: TLoc(ru: 'Раз в месяц', en: 'Monthly', fr: 'Une fois par mois', de: 'Monatlich', pt: 'Uma vez por mês'), score: 2),
              TestOption(label: TLoc(ru: 'Раз в неделю', en: 'Weekly', fr: 'Une fois par semaine', de: 'Wöchentlich', pt: 'Uma vez por semana'), score: 3),
              TestOption(label: TLoc(ru: 'Почти ежедневно', en: 'Daily or almost daily', fr: 'Tous les jours ou presque', de: 'Täglich oder fast täglich', pt: 'Diariamente ou quase diariamente'), score: 4),
            ],
          ),
          TestQuestion(
            id: 'audit_9',
            text: TLoc(
              ru: 'Получали ли вы травмы или причиняли вред себе/другим из-за выпивки?',
              en: 'Have you or someone else been injured as a result of your drinking?',
              fr: 'Vous (ou quelqu’un d’autre) êtes-vous déjà blessé(e) à cause de votre consommation d’alcool ?',
              de: 'Wurden Sie oder jemand anderes infolge Ihres Alkoholkonsums verletzt?',
              pt: 'Você ou outra pessoa já se feriu em consequência do seu consumo de álcool?',
            ),
            options: [
              TestOption(label: TLoc(ru: 'Нет', en: 'No', fr: 'Non', de: 'Nein', pt: 'Não'), score: 0),
              TestOption(label: TLoc(ru: 'Да, но не в последние 12 месяцев', en: 'Yes, but not in the last year', fr: 'Oui, mais pas au cours des 12 derniers mois', de: 'Ja, aber nicht in den letzten 12 Monaten', pt: 'Sim, mas não nos últimos 12 meses'), score: 2),
              TestOption(label: TLoc(ru: 'Да, в последние 12 месяцев', en: 'Yes, during the last year', fr: 'Oui, au cours des 12 derniers mois', de: 'Ja, in den letzten 12 Monaten', pt: 'Sim, nos últimos 12 meses'), score: 4),
            ],
          ),
          TestQuestion(
            id: 'audit_10',
            text: TLoc(
              ru: 'Говорили ли близкие или специалист, что стоит уменьшить употребление алкоголя?',
              en: 'Has a relative, friend, doctor or health worker suggested you cut down?',
              fr: 'Un proche, un ami, un médecin ou un professionnel de santé vous a-t-il suggéré de réduire votre consommation ?',
              de: 'Hat ein(e) Angehörige(r), Freund(in), Arzt/Ärztin oder Gesundheitsfachkraft Ihnen empfohlen, weniger zu trinken?',
              pt: 'Algum familiar, amigo, médico ou profissional de saúde sugeriu que você reduzisse o consumo?',
            ),
            options: [
              TestOption(label: TLoc(ru: 'Нет', en: 'No', fr: 'Non', de: 'Nein', pt: 'Não'), score: 0),
              TestOption(label: TLoc(ru: 'Да, но не в последние 12 месяцев', en: 'Yes, but not in the last year', fr: 'Oui, mais pas au cours des 12 derniers mois', de: 'Ja, aber nicht in den letzten 12 Monaten', pt: 'Sim, mas não nos últimos 12 meses'), score: 2),
              TestOption(label: TLoc(ru: 'Да, в последние 12 месяцев', en: 'Yes, during the last year', fr: 'Oui, au cours des 12 derniers mois', de: 'Ja, in den letzten 12 Monaten', pt: 'Sim, nos últimos 12 meses'), score: 4),
            ],
          ),
        ],
      );

  static TestDefinition _ftnd() => TestDefinition(
        id: 'ftnd',
        kind: TestKind.ftnd,
        category: TestCategoryId.addictions,
        title: const TLoc(ru: 'FTND', en: 'FTND', fr: 'FTND', de: 'FTND', pt: 'FTND'),
        subtitle: const TLoc(
          ru: 'Тест Фагерстрема на никотиновую зависимость',
          en: 'Fagerstrom nicotine dependence test',
          fr: 'Test de Fagerström pour la dépendance à la nicotine',
          de: 'Fagerström-Test zur Nikotinabhängigkeit',
          pt: 'Teste de Fagerström para dependência de nicotina',
        ),
        description: const TLoc(
          ru: 'Короткая шкала для оценки физической зависимости от никотина.',
          en: 'Short scale for estimating physical nicotine dependence.',
          fr: 'Échelle courte pour estimer la dépendance physique à la nicotine.',
          de: 'Kurze Skala zur Einschätzung der körperlichen Nikotinabhängigkeit.',
          pt: 'Escala curta para estimar a dependência física de nicotina.',
        ),
        questions: const [
          TestQuestion(
            id: 'ftnd_1',
            text: TLoc(
              ru: 'Как скоро после пробуждения вы выкуриваете первую сигарету?',
              en: 'How soon after you wake up do you smoke your first cigarette?',
              fr: 'Combien de temps après le réveil fumez-vous votre première cigarette ?',
              de: 'Wie bald nach dem Aufwachen rauchen Sie Ihre erste Zigarette?',
              pt: 'Quanto tempo após acordar você fuma o primeiro cigarro?',
            ),
            options: [
              TestOption(label: TLoc(ru: 'Через 60 минут и позже', en: 'After 60 minutes', fr: 'Après 60 minutes', de: 'Nach 60 Minuten', pt: 'Após 60 minutos'), score: 0),
              TestOption(label: TLoc(ru: '31–60 минут', en: '31–60 minutes', fr: '31–60 minutes', de: '31–60 Minuten', pt: '31–60 minutos'), score: 1),
              TestOption(label: TLoc(ru: '6–30 минут', en: '6–30 minutes', fr: '6–30 minutes', de: '6–30 Minuten', pt: '6–30 minutos'), score: 2),
              TestOption(label: TLoc(ru: 'В течение 5 минут', en: 'Within 5 minutes', fr: 'Dans les 5 minutes', de: 'Innerhalb von 5 Minuten', pt: 'Dentro de 5 minutos'), score: 3),
            ],
          ),
          TestQuestion(
            id: 'ftnd_2',
            text: TLoc(
              ru: 'Трудно ли вам воздержаться от курения в местах, где это запрещено?',
              en: 'Do you find it difficult to refrain from smoking in places where it is forbidden?',
              fr: 'Vous est-il difficile de ne pas fumer dans les lieux où c’est interdit ?',
              de: 'Fällt es Ihnen schwer, an Orten nicht zu rauchen, an denen es verboten ist?',
              pt: 'É difícil para você não fumar em locais onde é proibido?',
            ),
            options: [
              TestOption(label: TLoc(ru: 'Нет', en: 'No', fr: 'Non', de: 'Nein', pt: 'Não'), score: 0),
              TestOption(label: TLoc(ru: 'Да', en: 'Yes', fr: 'Oui', de: 'Ja', pt: 'Sim'), score: 1),
            ],
          ),
          TestQuestion(
            id: 'ftnd_3',
            text: TLoc(
              ru: 'От какой сигареты вам было бы труднее всего отказаться?',
              en: 'Which cigarette would you hate most to give up?',
              fr: 'À quelle cigarette vous serait-il le plus difficile de renoncer ?',
              de: 'Auf welche Zigarette könnten Sie am schwersten verzichten?',
              pt: 'De qual cigarro seria mais difícil abrir mão?',
            ),
            options: [
              TestOption(label: TLoc(ru: 'От любой другой', en: 'Any other one', fr: 'N’importe quelle autre', de: 'Auf jede andere', pt: 'Qualquer outro'), score: 0),
              TestOption(label: TLoc(ru: 'От первой утром', en: 'The first one in the morning', fr: 'De la première du matin', de: 'Auf die erste am Morgen', pt: 'Do primeiro da manhã'), score: 1),
            ],
          ),
          TestQuestion(
            id: 'ftnd_4',
            text: TLoc(
              ru: 'Сколько сигарет в день вы обычно выкуриваете?',
              en: 'How many cigarettes a day do you smoke?',
              fr: 'Combien de cigarettes fumez-vous par jour ?',
              de: 'Wie viele Zigaretten rauchen Sie pro Tag?',
              pt: 'Quantos cigarros você fuma por dia?',
            ),
            options: [
              TestOption(label: TLoc(ru: '10 или меньше', en: '10 or less', fr: '10 ou moins', de: '10 oder weniger', pt: '10 ou menos'), score: 0),
              TestOption(label: TLoc(ru: '11–20', en: '11–20', fr: '11–20', de: '11–20', pt: '11–20'), score: 1),
              TestOption(label: TLoc(ru: '21–30', en: '21–30', fr: '21–30', de: '21–30', pt: '21–30'), score: 2),
              TestOption(label: TLoc(ru: '31 и более', en: '31 or more', fr: '31 ou plus', de: '31 oder mehr', pt: '31 ou mais'), score: 3),
            ],
          ),
          TestQuestion(
            id: 'ftnd_5',
            text: TLoc(
              ru: 'Курите ли вы чаще в первые часы после пробуждения, чем в остальное время дня?',
              en: 'Do you smoke more frequently during the first hours after waking than during the rest of the day?',
              fr: 'Fumez-vous plus souvent pendant les premières heures après le réveil que pendant le reste de la journée ?',
              de: 'Rauchen Sie in den ersten Stunden nach dem Aufwachen häufiger als im restlichen Tagesverlauf?',
              pt: 'Você fuma com mais frequência nas primeiras horas após acordar do que no resto do dia?',
            ),
            options: [
              TestOption(label: TLoc(ru: 'Нет', en: 'No', fr: 'Non', de: 'Nein', pt: 'Não'), score: 0),
              TestOption(label: TLoc(ru: 'Да', en: 'Yes', fr: 'Oui', de: 'Ja', pt: 'Sim'), score: 1),
            ],
          ),
          TestQuestion(
            id: 'ftnd_6',
            text: TLoc(
              ru: 'Курите ли вы, даже когда настолько больны, что почти весь день проводите в постели?',
              en: 'Do you smoke even when you are so ill that you are in bed most of the day?',
              fr: 'Fumez-vous même lorsque vous êtes si malade que vous restez au lit presque toute la journée ?',
              de: 'Rauchen Sie auch dann, wenn Sie so krank sind, dass Sie den größten Teil des Tages im Bett liegen?',
              pt: 'Você fuma mesmo quando está tão doente que passa a maior parte do dia na cama?',
            ),
            options: [
              TestOption(label: TLoc(ru: 'Нет', en: 'No', fr: 'Non', de: 'Nein', pt: 'Não'), score: 0),
              TestOption(label: TLoc(ru: 'Да', en: 'Yes', fr: 'Oui', de: 'Ja', pt: 'Sim'), score: 1),
            ],
          ),
        ],
      );

  static TestDefinition _rses() => TestDefinition(
        id: 'rses',
        kind: TestKind.rses,
        category: TestCategoryId.personality,
        title: const TLoc(ru: 'RSES', en: 'RSES', fr: 'RSES', de: 'RSES', pt: 'RSES'),
        subtitle: const TLoc(
          ru: 'Шкала самооценки Розенберга',
          en: 'Rosenberg Self-Esteem Scale',
          fr: 'Échelle d’estime de soi de Rosenberg',
          de: 'Rosenberg-Selbstwertskala',
          pt: 'Escala de Autoestima de Rosenberg',
        ),
        description: const TLoc(
          ru: 'Классическая шкала общей самооценки.',
          en: 'Classic global self-esteem scale.',
          fr: 'Échelle classique d’estime de soi globale.',
          de: 'Klassische Skala für globalen Selbstwert.',
          pt: 'Escala clássica de autoestima global.',
        ),
        questions: const [
          TestQuestion(id: 'rses_1', text: TLoc(ru: 'В целом я доволен(льна) собой.', en: 'On the whole, I am satisfied with myself.', fr: 'Dans l’ensemble, je suis satisfait(e) de moi-même', de: 'Im Großen und Ganzen bin ich mit mir zufrieden', pt: 'No geral, estou satisfeito(a) comigo mesmo(a)'), options: optAgreePositive),
          TestQuestion(id: 'rses_2', text: TLoc(ru: 'Иногда я думаю, что совершенно ни на что не годен(на).', en: 'At times I think I am no good at all.', fr: 'Parfois, je pense que je ne vaux rien du tout', de: 'Manchmal denke ich, dass ich überhaupt nichts tauge', pt: 'Às vezes penso que não sirvo para nada'), options: optAgreeNegative),
          TestQuestion(id: 'rses_3', text: TLoc(ru: 'Мне кажется, что у меня есть немало хороших качеств.', en: 'I feel that I have a number of good qualities.', fr: 'Je pense avoir un certain nombre de bonnes qualités', de: 'Ich finde, dass ich eine Reihe guter Eigenschaften habe', pt: 'Acho que tenho várias boas qualidades'), options: optAgreePositive),
          TestQuestion(id: 'rses_4', text: TLoc(ru: 'Я способен(на) делать что-то не хуже большинства людей.', en: 'I am able to do things as well as most other people.', fr: 'Je suis capable de faire les choses aussi bien que la plupart des gens', de: 'Ich kann Dinge genauso gut tun wie die meisten anderen Menschen', pt: 'Sou capaz de fazer as coisas tão bem quanto a maioria das pessoas'), options: optAgreePositive),
          TestQuestion(id: 'rses_5', text: TLoc(ru: 'Мне кажется, что мне нечем особенно гордиться.', en: 'I feel I do not have much to be proud of.', fr: 'J’ai l’impression de ne pas avoir grand-chose dont je puisse être fier(ère)', de: 'Ich habe das Gefühl, nicht viel zu haben, worauf ich stolz sein kann', pt: 'Sinto que não tenho muito do que me orgulhar'), options: optAgreeNegative),
          TestQuestion(id: 'rses_6', text: TLoc(ru: 'Иногда я чувствую себя бесполезным(ой).', en: 'I certainly feel useless at times.', fr: 'Il m’arrive de me sentir inutile', de: 'Manchmal fühle ich mich nutzlos', pt: 'Às vezes me sinto inútil'), options: optAgreeNegative),
          TestQuestion(id: 'rses_7', text: TLoc(ru: 'Я чувствую, что являюсь ценным человеком, не хуже других.', en: 'I feel that I’m a person of worth, at least on an equal plane with others.', fr: 'Je sens que je suis une personne de valeur, au moins autant que les autres', de: 'Ich habe das Gefühl, ein wertvoller Mensch zu sein, mindestens gleichwertig mit anderen', pt: 'Sinto que sou uma pessoa de valor, pelo menos tão importante quanto os outros'), options: optAgreePositive),
          TestQuestion(id: 'rses_8', text: TLoc(ru: 'Мне хотелось бы больше уважать себя.', en: 'I wish I could have more respect for myself.', fr: 'J’aimerais avoir plus de respect pour moi-même', de: 'Ich wünschte, ich könnte mehr Respekt vor mir selbst haben', pt: 'Gostaria de ter mais respeito por mim mesmo(a)'), options: optAgreeNegative),
          TestQuestion(id: 'rses_9', text: TLoc(ru: 'В целом я склонен(на) считать себя неудачником(цей).', en: 'All in all, I am inclined to feel that I am a failure.', fr: 'Dans l’ensemble, j’ai tendance à penser que je suis un échec', de: 'Alles in allem neige ich dazu, mich als Versager(in) zu fühlen', pt: 'No geral, tendo a sentir que sou um fracasso'), options: optAgreeNegative),
          TestQuestion(id: 'rses_10', text: TLoc(ru: 'Я отношусь к себе в целом положительно.', en: 'I take a positive attitude toward myself.', fr: 'J’ai une attitude positive envers moi-même', de: 'Ich habe eine positive Einstellung zu mir selbst', pt: 'Tenho uma atitude positiva em relação a mim mesmo(a)'), options: optAgreePositive),
        ],
      );

  static TestDefinition _dass21() => TestDefinition(
        id: 'dass21',
        kind: TestKind.dass21,
        category: TestCategoryId.stress,
        title: const TLoc(ru: 'DASS-21', en: 'DASS-21', fr: 'DASS-21', de: 'DASS-21', pt: 'DASS-21'),
        subtitle: const TLoc(
          ru: 'Депрессия, тревога и стресс',
          en: 'Depression, anxiety and stress',
          fr: 'Dépression, anxiété et stress',
          de: 'Depression, Angst und Stress',
          pt: 'Depressão, ansiedade e estresse',
        ),
        description: const TLoc(
          ru: 'Даёт три отдельные шкалы за последнюю неделю.',
          en: 'Provides three separate scales for the past week.',
          fr: 'Fournit trois échelles distinctes pour la dernière semaine.',
          de: 'Liefert drei separate Skalen für die letzte Woche.',
          pt: 'Fornece três escalas separadas para a última semana.',
        ),
        questions: const [
          TestQuestion(
            id: 'dass_1',
            text: TLoc(
              ru: 'Мне было трудно успокоиться.',
              en: 'I found it hard to wind down.',
              fr: 'J’ai eu du mal à me calmer.',
              de: 'Es fiel mir schwer, herunterzufahren.',
              pt: 'Achei difícil me acalmar.',
            ),
            options: optDass,
          ),
          TestQuestion(
            id: 'dass_2',
            text: TLoc(
              ru: 'Я ощущал(а) сухость во рту.',
              en: 'I was aware of dryness of my mouth.',
              fr: 'J’ai eu la bouche sèche.',
              de: 'Ich hatte einen trockenen Mund.',
              pt: 'Percebi a boca seca.',
            ),
            options: optDass,
          ),
          TestQuestion(
            id: 'dass_3',
            text: TLoc(
              ru: 'Я совсем не мог(ла) испытывать положительные чувства.',
              en: 'I couldn’t seem to experience any positive feeling at all.',
              fr: 'Je n’arrivais pas à ressentir de sentiments positifs.',
              de: 'Ich schien überhaupt keine positiven Gefühle erleben zu können.',
              pt: 'Parei de conseguir sentir qualquer sentimento positivo.',
            ),
            options: optDass,
          ),
          TestQuestion(
            id: 'dass_4',
            text: TLoc(
              ru: 'У меня были трудности с дыханием.',
              en: 'I experienced breathing difficulty.',
              fr: 'J’ai eu des difficultés à respirer.',
              de: 'Ich hatte Atembeschwerden.',
              pt: 'Tive dificuldade para respirar.',
            ),
            options: optDass,
          ),
          TestQuestion(
            id: 'dass_5',
            text: TLoc(
              ru: 'Мне было трудно заставить себя что-либо делать.',
              en: 'I found it difficult to work up the initiative to do things.',
              fr: 'J’ai eu du mal à me motiver à faire des choses.',
              de: 'Es war für mich schwierig, die Initiative aufzubringen, Dinge zu tun.',
              pt: 'Tive dificuldade para tomar iniciativa e fazer coisas.',
            ),
            options: optDass,
          ),
          TestQuestion(
            id: 'dass_6',
            text: TLoc(
              ru: 'Я слишком бурно реагировал(а) на ситуации.',
              en: 'I tended to over-react to situations.',
              fr: 'J’avais tendance à réagir de manière excessive aux situations.',
              de: 'Ich neigte dazu, auf Situationen überzureagieren.',
              pt: 'Tive tendência a reagir de forma exagerada às situações.',
            ),
            options: optDass,
          ),
          TestQuestion(
            id: 'dass_7',
            text: TLoc(
              ru: 'Я ощущал(а) дрожь.',
              en: 'I experienced trembling.',
              fr: 'J’ai eu des tremblements.',
              de: 'Ich hatte Zittern.',
              pt: 'Senti tremores.',
            ),
            options: optDass,
          ),
          TestQuestion(
            id: 'dass_8',
            text: TLoc(
              ru: 'Я чувствовал(а), что трачу много нервной энергии.',
              en: 'I felt that I was using a lot of nervous energy.',
              fr: 'J’avais l’impression de dépenser beaucoup d’énergie nerveuse.',
              de: 'Ich hatte das Gefühl, viel nervöse Energie zu verbrauchen.',
              pt: 'Senti que estava gastando muita energia nervosa.',
            ),
            options: optDass,
          ),
          TestQuestion(
            id: 'dass_9',
            text: TLoc(
              ru: 'Я беспокоился(ась) о ситуациях, в которых могу запаниковать.',
              en: 'I was worried about situations in which I might panic.',
              fr: 'Je m’inquiétais des situations où je pourrais paniquer.',
              de: 'Ich machte mir Sorgen über Situationen, in denen ich in Panik geraten könnte.',
              pt: 'Fiquei preocupado(a) com situações em que eu poderia entrar em pânico.',
            ),
            options: optDass,
          ),
          TestQuestion(
            id: 'dass_10',
            text: TLoc(
              ru: 'Мне казалось, что мне нечего ждать впереди.',
              en: 'I felt that I had nothing to look forward to.',
              fr: 'J’avais l’impression de n’avoir rien à attendre.',
              de: 'Ich hatte das Gefühl, dass ich nichts habe, worauf ich mich freuen kann.',
              pt: 'Senti que não tinha nada pelo que ansiar.',
            ),
            options: optDass,
          ),
          TestQuestion(
            id: 'dass_11',
            text: TLoc(
              ru: 'Я замечал(а), что становлюсь раздражённым(ой) и взвинченным(ой).',
              en: 'I found myself getting agitated.',
              fr: 'Je me suis senti(e) agité(e).',
              de: 'Ich merkte, dass ich unruhig/aufgeregt wurde.',
              pt: 'Percebi que estava ficando agitado(a).',
            ),
            options: optDass,
          ),
          TestQuestion(
            id: 'dass_12',
            text: TLoc(
              ru: 'Мне было трудно расслабиться.',
              en: 'I found it difficult to relax.',
              fr: 'J’ai eu du mal à me détendre.',
              de: 'Es fiel mir schwer, mich zu entspannen.',
              pt: 'Achei difícil relaxar.',
            ),
            options: optDass,
          ),
          TestQuestion(
            id: 'dass_13',
            text: TLoc(
              ru: 'Я чувствовал(а) уныние и подавленность.',
              en: 'I felt down-hearted and blue.',
              fr: 'Je me suis senti(e) abattu(e) et triste.',
              de: 'Ich fühlte mich niedergeschlagen und traurig.',
              pt: 'Senti-me abatido(a) e triste.',
            ),
            options: optDass,
          ),
          TestQuestion(
            id: 'dass_14',
            text: TLoc(
              ru: 'Я плохо переносил(а) всё, что мешало мне заниматься делом.',
              en: 'I was intolerant of anything that kept me from getting on with what I was doing.',
              fr: 'Je supportais mal tout ce qui m’empêchait de faire ce que je faisais.',
              de: 'Ich war intolerant gegenüber allem, was mich davon abhielt, mit dem weiterzumachen, was ich tat.',
              pt: 'Fiquei intolerante a qualquer coisa que me impedisse de continuar o que eu estava fazendo.',
            ),
            options: optDass,
          ),
          TestQuestion(
            id: 'dass_15',
            text: TLoc(
              ru: 'Я чувствовал(а), что близок(ка) к панике.',
              en: 'I felt I was close to panic.',
              fr: 'Je me suis senti(e) proche de la panique.',
              de: 'Ich hatte das Gefühl, kurz vor einer Panik zu stehen.',
              pt: 'Senti que estava perto do pânico.',
            ),
            options: optDass,
          ),
          TestQuestion(
            id: 'dass_16',
            text: TLoc(
              ru: 'Я не мог(ла) по-настоящему чем-либо воодушевиться.',
              en: 'I was unable to become enthusiastic about anything.',
              fr: 'Je n’arrivais pas à m’enthousiasmer pour quoi que ce soit.',
              de: 'Ich konnte mich für nichts begeistern.',
              pt: 'Não consegui me entusiasmar com nada.',
            ),
            options: optDass,
          ),
          TestQuestion(
            id: 'dass_17',
            text: TLoc(
              ru: 'Я чувствовал(а), что мало чего стою как человек.',
              en: 'I felt I wasn’t worth much as a person.',
              fr: 'Je me suis senti(e) sans grande valeur en tant que personne.',
              de: 'Ich fühlte mich als Person nicht viel wert.',
              pt: 'Senti que eu não valia muito como pessoa.',
            ),
            options: optDass,
          ),
          TestQuestion(
            id: 'dass_18',
            text: TLoc(
              ru: 'Я чувствовал(а), что стал(а) слишком обидчивым(ой).',
              en: 'I felt that I was rather touchy.',
              fr: 'Je me suis senti(e) plutôt susceptible.',
              de: 'Ich hatte das Gefühl, ziemlich empfindlich/schnell gekränkt zu sein.',
              pt: 'Senti que estava bastante sensível/suscetível.',
            ),
            options: optDass,
          ),
          TestQuestion(
            id: 'dass_19',
            text: TLoc(
              ru: 'Я ощущал(а) работу сердца без физической нагрузки.',
              en: 'I was aware of the action of my heart in the absence of physical exertion.',
              fr: 'Je sentais les battements de mon cœur sans effort physique.',
              de: 'Ich spürte mein Herz schlagen, obwohl ich mich nicht körperlich anstrengte.',
              pt: 'Percebi as batidas do meu coração sem esforço físico.',
            ),
            options: optDass,
          ),
          TestQuestion(
            id: 'dass_20',
            text: TLoc(
              ru: 'Я испытывал(а) страх без веской причины.',
              en: 'I felt scared without any good reason.',
              fr: 'J’ai eu peur sans bonne raison.',
              de: 'Ich hatte Angst ohne einen guten Grund.',
              pt: 'Senti medo sem uma boa razão.',
            ),
            options: optDass,
          ),
          TestQuestion(
            id: 'dass_21',
            text: TLoc(
              ru: 'Мне казалось, что жизнь лишена смысла.',
              en: 'I felt that life was meaningless.',
              fr: 'J’avais l’impression que la vie n’avait pas de sens.',
              de: 'Ich hatte das Gefühl, dass das Leben sinnlos ist.',
              pt: 'Senti que a vida não tinha sentido.',
            ),
            options: optDass,
          ),
        ],
      );

  static TestDefinition _pcl5() => TestDefinition(
        id: 'pcl5',
        kind: TestKind.pcl5,
        category: TestCategoryId.stress,
        title: const TLoc(ru: 'PCL-5', en: 'PCL-5', fr: 'PCL-5', de: 'PCL-5', pt: 'PCL-5'),
        subtitle: const TLoc(
          ru: 'Скрининг симптомов ПТСР',
          en: 'PTSD symptom screening',
          fr: 'Dépistage des symptômes du TSPT',
          de: 'Screening auf PTBS-Symptome',
          pt: 'Triagem de sintomas de TEPT',
        ),
        description: const TLoc(
          ru: 'Оценивает, насколько сильно вас беспокоили травматические симптомы за последний месяц.',
          en: 'Assesses how much traumatic stress symptoms bothered you over the last month.',
          fr: 'Évalue dans quelle mesure des symptômes liés au traumatisme vous ont dérangé(e) au cours du dernier mois.',
          de: 'Erfasst, wie stark Sie traumabezogene Symptome im letzten Monat belastet haben.',
          pt: 'Avalia o quanto sintomas relacionados ao trauma incomodaram você no último mês.',
        ),
        questions: const [
          TestQuestion(
            id: 'pcl5_1',
            text: TLoc(
              ru: 'Повторяющиеся, нежелательные воспоминания о травмирующем событии',
              en: 'Repeated, disturbing, and unwanted memories of the stressful experience?',
              fr: 'Souvenirs répétitifs, perturbants et non désirés de l’événement stressant ?',
              de: 'Wiederkehrende, belastende und unerwünschte Erinnerungen an das belastende Ereignis?',
              pt: 'Memórias repetidas, perturbadoras e indesejadas da experiência estressante?',
            ),
            options: optPcl5,
          ),
          TestQuestion(
            id: 'pcl5_2',
            text: TLoc(
              ru: 'Повторяющиеся неприятные сны о событии',
              en: 'Repeated, disturbing dreams of the stressful experience?',
              fr: 'Rêves répétitifs et perturbants de l’événement stressant ?',
              de: 'Wiederkehrende, belastende Träume über das belastende Ereignis?',
              pt: 'Sonhos repetidos e perturbadores sobre a experiência estressante?',
            ),
            options: optPcl5,
          ),
          TestQuestion(
            id: 'pcl5_3',
            text: TLoc(
              ru: 'Чувство, будто событие происходит снова',
              en: 'Suddenly feeling or acting as if the stressful experience were actually happening again?',
              fr: 'Sensation soudaine que l’événement stressant se reproduit (ou agir comme si c’était le cas) ?',
              de: 'Plötzliches Gefühl oder Verhalten, als ob das belastende Ereignis erneut tatsächlich passieren würde?',
              pt: 'Sentir ou agir de repente como se a experiência estressante estivesse acontecendo novamente?',
            ),
            options: optPcl5,
          ),
          TestQuestion(
            id: 'pcl5_4',
            text: TLoc(
              ru: 'Сильное расстройство при напоминаниях о событии',
              en: 'Feeling very upset when something reminded you of the stressful experience?',
              fr: 'Être très bouleversé(e) lorsque quelque chose vous rappelait l’événement stressant ?',
              de: 'Sehr aufgewühlt sein, wenn Sie etwas an das belastende Ereignis erinnert hat?',
              pt: 'Ficar muito abalado(a) quando algo lembrava você da experiência estressante?',
            ),
            options: optPcl5,
          ),
          TestQuestion(
            id: 'pcl5_5',
            text: TLoc(
              ru: 'Сильные телесные реакции на напоминания',
              en: 'Having strong physical reactions when something reminded you of the stressful experience?',
              fr: 'Avoir de fortes réactions physiques lorsque quelque chose vous rappelait l’événement stressant ?',
              de: 'Starke körperliche Reaktionen haben, wenn Sie etwas an das belastende Ereignis erinnert hat?',
              pt: 'Ter reações físicas fortes quando algo lembrava você da experiência estressante?',
            ),
            options: optPcl5,
          ),
          TestQuestion(
            id: 'pcl5_6',
            text: TLoc(
              ru: 'Избегание мыслей или чувств, связанных с событием',
              en: 'Avoiding memories, thoughts, or feelings related to the stressful experience?',
              fr: 'Éviter les souvenirs, pensées ou émotions liés à l’événement stressant ?',
              de: 'Erinnerungen, Gedanken oder Gefühle im Zusammenhang mit dem belastenden Ereignis vermeiden?',
              pt: 'Evitar memórias, pensamentos ou sentimentos relacionados à experiência estressante?',
            ),
            options: optPcl5,
          ),
          TestQuestion(
            id: 'pcl5_7',
            text: TLoc(
              ru: 'Избегание внешних напоминаний о событии',
              en: 'Avoiding external reminders of the stressful experience?',
              fr: 'Éviter les rappels externes de l’événement stressant ?',
              de: 'Äußere Erinnerungsreize an das belastende Ereignis vermeiden?',
              pt: 'Evitar lembretes externos da experiência estressante?',
            ),
            options: optPcl5,
          ),
          TestQuestion(
            id: 'pcl5_8',
            text: TLoc(
              ru: 'Трудности вспомнить важные части события',
              en: 'Trouble remembering important parts of the stressful experience?',
              fr: 'Difficulté à se souvenir de parties importantes de l’événement stressant ?',
              de: 'Schwierigkeiten, sich an wichtige Teile des belastenden Ereignisses zu erinnern?',
              pt: 'Dificuldade para lembrar partes importantes da experiência estressante?',
            ),
            options: optPcl5,
          ),
          TestQuestion(
            id: 'pcl5_9',
            text: TLoc(
              ru: 'Сильные негативные убеждения о себе, других или мире',
              en: 'Having strong negative beliefs about yourself, other people, or the world?',
              fr: 'Avoir de fortes croyances négatives sur vous-même, les autres ou le monde ?',
              de: 'Starke negative Überzeugungen über sich selbst, andere Menschen oder die Welt haben?',
              pt: 'Ter fortes crenças negativas sobre você, outras pessoas ou o mundo?',
            ),
            options: optPcl5,
          ),
          TestQuestion(
            id: 'pcl5_10',
            text: TLoc(
              ru: 'Обвинение себя или других в событии',
              en: 'Blaming yourself or someone else for the stressful experience?',
              fr: 'Vous blâmer (ou blâmer quelqu’un d’autre) pour l’événement stressant ?',
              de: 'Sich selbst oder jemand anderen für das belastende Ereignis die Schuld geben?',
              pt: 'Culpar a si mesmo(a) ou a outra pessoa pela experiência estressante?',
            ),
            options: optPcl5,
          ),
          TestQuestion(
            id: 'pcl5_11',
            text: TLoc(
              ru: 'Сильные негативные чувства (страх, злость, вина и т.д.)',
              en: 'Having strong negative feelings such as fear, horror, anger, guilt, or shame?',
              fr: 'Avoir de fortes émotions négatives (peur, horreur, colère, culpabilité, honte, etc.) ?',
              de: 'Starke negative Gefühle wie Angst, Entsetzen, Wut, Schuld oder Scham haben?',
              pt: 'Ter sentimentos negativos intensos, como medo, horror, raiva, culpa ou vergonha?',
            ),
            options: optPcl5,
          ),
          TestQuestion(
            id: 'pcl5_12',
            text: TLoc(
              ru: 'Потеря интереса к важным для вас занятиям',
              en: 'Loss of interest in activities that you used to enjoy?',
              fr: 'Perte d’intérêt pour des activités que vous aimiez auparavant ?',
              de: 'Verlust des Interesses an Aktivitäten, die Ihnen früher Freude gemacht haben?',
              pt: 'Perda de interesse em atividades que você costumava gostar?',
            ),
            options: optPcl5,
          ),
          TestQuestion(
            id: 'pcl5_13',
            text: TLoc(
              ru: 'Чувство отстранённости от других людей',
              en: 'Feeling distant or cut off from other people?',
              fr: 'Se sentir distant(e) ou coupé(e) des autres ?',
              de: 'Sich von anderen Menschen distanziert oder abgeschnitten fühlen?',
              pt: 'Sentir-se distante ou desligado(a) das outras pessoas?',
            ),
            options: optPcl5,
          ),
          TestQuestion(
            id: 'pcl5_14',
            text: TLoc(
              ru: 'Трудность испытывать положительные чувства',
              en: 'Trouble experiencing positive feelings?',
              fr: 'Difficulté à ressentir des émotions positives ?',
              de: 'Schwierigkeiten, positive Gefühle zu empfinden?',
              pt: 'Dificuldade para sentir emoções positivas?',
            ),
            options: optPcl5,
          ),
          TestQuestion(
            id: 'pcl5_15',
            text: TLoc(
              ru: 'Раздражительность, злость, вспышки гнева',
              en: 'Irritable behavior, angry outbursts, or acting aggressively?',
              fr: 'Irritabilité, accès de colère ou comportement agressif ?',
              de: 'Reizbares Verhalten, Wutausbrüche oder aggressives Verhalten?',
              pt: 'Comportamento irritável, explosões de raiva ou agir de forma agressiva?',
            ),
            options: optPcl5,
          ),
          TestQuestion(
            id: 'pcl5_16',
            text: TLoc(
              ru: 'Рискованное или саморазрушающее поведение',
              en: 'Taking too many risks or doing things that could cause you harm?',
              fr: 'Prendre trop de risques ou faire des choses pouvant vous nuire ?',
              de: 'Zu viele Risiken eingehen oder Dinge tun, die Ihnen schaden könnten?',
              pt: 'Assumir riscos demais ou fazer coisas que poderiam causar dano a você?',
            ),
            options: optPcl5,
          ),
          TestQuestion(
            id: 'pcl5_17',
            text: TLoc(
              ru: 'Повышенная настороженность',
              en: 'Being superalert or watchful or on guard?',
              fr: 'Être en hypervigilance, sur le qui-vive, en alerte ?',
              de: 'Übermäßig wachsam/aufmerksam oder ständig auf der Hut sein?',
              pt: 'Ficar hiperalerta, vigilante ou em guarda?',
            ),
            options: optPcl5,
          ),
          TestQuestion(
            id: 'pcl5_18',
            text: TLoc(
              ru: 'Лёгкая пугаемость',
              en: 'Feeling jumpy or easily startled?',
              fr: 'Être sursauter facilement ou se sentir facilement effrayé(e) ?',
              de: 'Schreckhaft sein oder leicht zusammenzucken?',
              pt: 'Sentir-se assustado(a) ou sobressaltar-se facilmente?',
            ),
            options: optPcl5,
          ),
          TestQuestion(
            id: 'pcl5_19',
            text: TLoc(
              ru: 'Трудности с концентрацией',
              en: 'Having difficulty concentrating?',
              fr: 'Avoir des difficultés à se concentrer ?',
              de: 'Konzentrationsschwierigkeiten haben?',
              pt: 'Ter dificuldade para se concentrar?',
            ),
            options: optPcl5,
          ),
          TestQuestion(
            id: 'pcl5_20',
            text: TLoc(
              ru: 'Трудности со сном',
              en: 'Trouble falling or staying asleep?',
              fr: 'Difficulté à s’endormir ou à rester endormi(e) ?',
              de: 'Schwierigkeiten beim Einschlafen oder Durchschlafen?',
              pt: 'Dificuldade para adormecer ou permanecer dormindo?',
            ),
            options: optPcl5,
          ),
        ],
      );

  static TestDefinition _swls() => TestDefinition(
        id: 'swls',
        kind: TestKind.swls,
        category: TestCategoryId.wellbeing,
        title: const TLoc(ru: 'SWLS', en: 'SWLS', fr: 'SWLS', de: 'SWLS', pt: 'SWLS'),
        subtitle: const TLoc(
          ru: 'Удовлетворённость жизнью',
          en: 'Satisfaction with Life Scale',
          fr: 'Échelle de satisfaction de vie',
          de: 'Skala der Lebenszufriedenheit',
          pt: 'Escala de Satisfação com a Vida',
        ),
        description: const TLoc(
          ru: 'Оценивает, насколько вы в целом довольны своей жизнью.',
          en: 'Assesses how satisfied you are with your life overall.',
          fr: 'Évalue à quel point vous êtes globalement satisfait(e) de votre vie.',
          de: 'Erfasst, wie zufrieden Sie insgesamt mit Ihrem Leben sind.',
          pt: 'Avalia o quanto você está satisfeito(a) com sua vida em geral.',
        ),
        questions: const [
          TestQuestion(id: 'swls_1', text: TLoc(ru: 'Во многих отношениях моя жизнь близка к идеалу.', en: 'In most ways my life is close to my ideal.', fr: 'À bien des égards, ma vie est proche de mon idéal', de: 'In vielerlei Hinsicht ist mein Leben nahe an meinem Ideal', pt: 'Em muitos aspectos, minha vida está próxima do meu ideal'), options: optSwls),
          TestQuestion(id: 'swls_2', text: TLoc(ru: 'Условия моей жизни превосходны.', en: 'The conditions of my life are excellent.', fr: 'Les conditions de ma vie sont excellentes', de: 'Die Bedingungen meines Lebens sind ausgezeichnet', pt: 'As condições da minha vida são excelentes'), options: optSwls),
          TestQuestion(id: 'swls_3', text: TLoc(ru: 'Я доволен(льна) своей жизнью.', en: 'I am satisfied with my life.', fr: 'Je suis satisfait(e) de ma vie', de: 'Ich bin mit meinem Leben zufrieden', pt: 'Estou satisfeito(a) com minha vida'), options: optSwls),
          TestQuestion(id: 'swls_4', text: TLoc(ru: 'До сих пор я получал(а) от жизни то, что считаю важным.', en: 'So far I have gotten the important things I want in life.', fr: 'J’ai obtenu jusqu’à présent les choses importantes que je voulais dans ma vie', de: 'Bisher habe ich die wichtigen Dinge erreicht, die ich vom Leben wollte', pt: 'Até agora consegui as coisas importantes que quero na vida'), options: optSwls),
          TestQuestion(id: 'swls_5', text: TLoc(ru: 'Если бы я мог(ла) прожить жизнь заново, я почти ничего бы не изменил(а).', en: 'If I could live my life over, I would change almost nothing.', fr: 'Si je pouvais recommencer ma vie, je ne changerais presque rien', de: 'Wenn ich mein Leben noch einmal leben könnte, würde ich fast nichts ändern', pt: 'Se eu pudesse viver minha vida novamente, quase nada mudaria'), options: optSwls),
        ],
      );
}
