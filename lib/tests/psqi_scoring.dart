/// Pittsburgh Sleep Quality Index (Buysse et al., 1989) component scoring.
/// Expects [answers] in the order produced by `assets/tests/custom/psqi_buysse_1989.json`.
class PsqiScoring {
  PsqiScoring._();

  /// Minutes in bed from usual bedtime to usual rising time (handles crossing midnight).
  static int timeInBedMinutes(int bedMin, int wakeMin) {
    if (wakeMin > bedMin) return wakeMin - bedMin;
    return (24 * 60 - bedMin) + wakeMin;
  }

  static int _component1(int q6) => q6.clamp(0, 3);

  static int _component2(int q2, int q5a) {
    final s = (q2 + q5a).clamp(0, 6);
    if (s <= 0) return 0;
    if (s <= 2) return 1;
    if (s <= 4) return 2;
    return 3;
  }

  static int _component3(int sleepMinutes) {
    final h = sleepMinutes / 60.0;
    if (h >= 7) return 0;
    if (h >= 6) return 1;
    if (h >= 5) return 2;
    return 3;
  }

  static int _component4(int bedMin, int wakeMin, int sleepMinutes) {
    final tib = timeInBedMinutes(bedMin, wakeMin);
    if (tib <= 0) return 3;
    final eff = (sleepMinutes / tib) * 100.0;
    if (eff > 85) return 0;
    if (eff > 75) return 1;
    if (eff > 65) return 2;
    return 3;
  }

  /// Sum of Q5b–Q5j (nine items), each 0–3.
  static int _component5(int sum5bTo5j) {
    final s = sum5bTo5j.clamp(0, 27);
    if (s == 0) return 0;
    if (s <= 9) return 1;
    if (s <= 18) return 2;
    return 3;
  }

  static int _component6(int q7) => q7.clamp(0, 3);

  static int _component7(int q8, int q9) {
    final s = (q8 + q9).clamp(0, 6);
    if (s <= 0) return 0;
    if (s <= 2) return 1;
    if (s <= 4) return 2;
    return 3;
  }

  /// Seven component scores, each 0–3.
  static List<int> componentScores(List<int> answers) {
    if (answers.length < 18) {
      return List<int>.filled(7, 0);
    }
    final bed = answers[0];
    final q2 = answers[1];
    final wake = answers[2];
    final sleepMin = answers[3];
    final q5a = answers[4];
    var sumDist = 0;
    for (var i = 5; i <= 13; i++) {
      sumDist += answers[i];
    }
    final q6 = answers[14];
    final q7 = answers[15];
    final q8 = answers[16];
    final q9 = answers[17];

    return [
      _component1(q6),
      _component2(q2, q5a),
      _component3(sleepMin),
      _component4(bed, wake, sleepMin),
      _component5(sumDist),
      _component6(q7),
      _component7(q8, q9),
    ];
  }

  static int globalScore(List<int> answers) {
    return componentScores(answers).fold<int>(0, (a, b) => a + b);
  }
}
