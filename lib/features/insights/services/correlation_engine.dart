import 'dart:math';
import 'package:eunora/features/onboarding/domain/models/medication.dart';

class CorrelationResult {
  final double r;
  final double effectSize;
  final int eventCount;

  const CorrelationResult({
    required this.r,
    required this.effectSize,
    required this.eventCount,
  });
}

class CorrelationEngine {
  /// Computes Pearson correlation and effect size between two series X and Y.
  /// X is trigger presence (1.0 or 0.0).
  /// Y is symptom intensity (0.0 to 5.0).
  static CorrelationResult calculate({
    required List<double> xSeries,
    required List<double> ySeries,
  }) {
    if (xSeries.length != ySeries.length || xSeries.isEmpty) {
      return const CorrelationResult(r: 0.0, effectSize: 0.0, eventCount: 0);
    }

    final int n = xSeries.length;
    double sumX = 0.0;
    double sumY = 0.0;
    double sumXY = 0.0;
    double sumX2 = 0.0;
    double sumY2 = 0.0;

    final List<double> yGivenX1 = [];
    final List<double> yGivenX0 = [];
    int eventCount = 0;

    for (int i = 0; i < n; i++) {
      final double x = xSeries[i];
      final double y = ySeries[i];

      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
      sumY2 += y * y;

      if (x == 1.0) {
        yGivenX1.add(y);
        // Event co-occurrence: trigger present (X=1) and symptom experienced/logged (Y>0)
        if (y > 0.0) {
          eventCount++;
        }
      } else {
        yGivenX0.add(y);
      }
    }

    // Pearson r computation
    final double numerator = (n * sumXY) - (sumX * sumY);
    final double denominatorPart1 = (n * sumX2) - (sumX * sumX);
    final double denominatorPart2 = (n * sumY2) - (sumY * sumY);
    final double denominator = sqrt(denominatorPart1 * denominatorPart2);

    double r = 0.0;
    if (denominator != 0.0) {
      r = numerator / denominator;
      if (r.isNaN || r.isInfinite) {
        r = 0.0;
      }
    }

    r = r.clamp(-1.0, 1.0);

    // effectSize = mean(Y | X=1) - mean(Y | X=0)
    final double meanY1 = yGivenX1.isEmpty ? 0.0 : yGivenX1.reduce((a, b) => a + b) / yGivenX1.length;
    final double meanY0 = yGivenX0.isEmpty ? 0.0 : yGivenX0.reduce((a, b) => a + b) / yGivenX0.length;
    final double effectSize = meanY1 - meanY0;

    return CorrelationResult(
      r: r,
      effectSize: effectSize,
      eventCount: eventCount,
    );
  }

  // ---------------------------------------------------------------------------
  // HRT Drug Library v2 — Correlation guards
  // Apply these filters BEFORE building xSeries/ySeries to prevent misleading
  // correlation cards. The Pearson math above is untouched.
  // ---------------------------------------------------------------------------

  /// Returns true if this medication should be excluded from systemic symptom
  /// correlation (e.g. vasomotor symptom analysis).
  ///
  /// Low-dose local vaginal oestrogen is not expected to affect vasomotor
  /// symptoms. Including it would generate misleading correlation cards.
  static bool shouldExcludeFromSystemicCorrelation(Medication med) {
    return med.drugCategory == 'vaginalLocal';
  }

  /// Returns true if [candidate] is a standalone progestogen-only entry that
  /// would double-count a combined product already in [activeMeds].
  ///
  /// When a combined product (e.g. Evorel Conti) is active, a separate
  /// progestogen entry logged on the same dates would cause the dose-change
  /// comparison window to be counted twice.
  static bool isRedundantProgestogen({
    required Medication candidate,
    required List<Medication> activeMeds,
  }) {
    if (candidate.drugCategory != 'progestogenOnly') return false;
    // If any active combined product exists, the progestogen is redundant.
    return activeMeds.any((m) => m.isCombinedProduct);
  }

  /// Filters a list of medications to only those valid for systemic correlation.
  /// Excludes vaginalLocal and progestogens that are made redundant by a
  /// combined product in the same active regimen.
  static List<Medication> filterForCorrelation(List<Medication> meds) {
    return meds.where((m) {
      if (shouldExcludeFromSystemicCorrelation(m)) return false;
      if (isRedundantProgestogen(candidate: m, activeMeds: meds)) return false;
      return true;
    }).toList();
  }
}
