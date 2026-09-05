import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:eunora/core/services/firestore_service.dart';
import 'package:eunora/core/utils/logging_helpers.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';
import 'package:eunora/features/onboarding/domain/models/user_profile.dart';
import 'package:eunora/features/onboarding/presentation/providers/symptoms_provider.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';

// ─── Tunable constants ────────────────────────────────────────────────────────
/// Maximum number of chips ever shown in the quick-access grid.
const int kQuickAccessMax = 8;

/// Minimum number of distinct calendar days within the window a symptom must
/// be logged before it is automatically promoted.
const int kPromotionThresholdDays = 3;

/// Rolling look-back window used for promotion evaluation (days).
const int kPromotionWindowDays = 30;

/// Symptom IDs that are always pinned regardless of user behaviour.
/// These are never bumped out to make room for promoted symptoms.
const List<String> kCoreFixedPins = ['hot_flash', 'fatigue', 'night_wakings'];

// ─── Preference value constants ───────────────────────────────────────────────
const String kPrefOnboarding = 'onboarding';
const String kPrefPromoted = 'promoted';
const String kPrefRemoved = 'removed';

// ─── State ────────────────────────────────────────────────────────────────────
class SymptomQuickAccessState {
  /// Map from symptom ID → preference value ('onboarding' | 'promoted' | 'removed').
  final Map<String, String> prefs;

  /// Count of distinct days each symptom was logged in the last 30 days.
  /// Used for ordering promoted symptoms (highest frequency first).
  final Map<String, int> recentDayCounts;

  const SymptomQuickAccessState({
    this.prefs = const {},
    this.recentDayCounts = const {},
  });

  SymptomQuickAccessState copyWith({
    Map<String, String>? prefs,
    Map<String, int>? recentDayCounts,
  }) {
    return SymptomQuickAccessState(
      prefs: prefs ?? this.prefs,
      recentDayCounts: recentDayCounts ?? this.recentDayCounts,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────
class SymptomQuickAccessNotifier
    extends StateNotifier<SymptomQuickAccessState> {
  final Ref _ref;

  SymptomQuickAccessNotifier(this._ref)
      : super(const SymptomQuickAccessState());

  // ── Bootstrap ──────────────────────────────────────────────────────────────

  /// Call once after the user profile is loaded (from [OnboardingProfileNotifier]).
  /// Merges persisted prefs from Firestore with a cold-start seed derived from
  /// [selectedStageSymptoms]. Existing onboarding data is never overwritten.
  void loadFromProfile(UserProfile profile) {
    final Map<String, String> merged = {};

    // Cold-start: mark all onboarding-selected symptoms as 'onboarding'
    // if they have no existing pref entry yet.
    for (final id in profile.selectedStageSymptoms) {
      final cleanId = sanitizeSymptomId(id);
      merged[cleanId] = kPrefOnboarding;
    }

    // Overlay persisted prefs — they win over the cold-start defaults,
    // so existing 'removed' or 'promoted' entries are respected.
    merged.addAll(profile.symptomQuickAccessPrefs);

    state = state.copyWith(prefs: merged);
  }

  // ── Promotion check ────────────────────────────────────────────────────────

  /// Called immediately after a completed daily log is saved.
  /// Evaluates whether any symptom has crossed the promotion threshold and
  /// silently promotes it. Never touches the UI or emits any notification.
  Future<void> runPromotionCheck(List<DailyLog> recentLogs) async {
    final cutoff =
        DateTime.now().subtract(const Duration(days: kPromotionWindowDays));

    // Count distinct calendar days per symptom within the rolling window.
    final Map<String, Set<String>> distinctDates = {};
    for (final log in recentLogs) {
      // Only completed logs count toward promotion.
      if (!log.isCompleted) continue;
      // Strictly within the 30-day window.
      if (log.date.isBefore(cutoff)) continue;

      final dateKey =
          '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}';

      for (final ls in log.symptoms) {
        final id = ls.symptom.id;
        distinctDates.putIfAbsent(id, () => {}).add(dateKey);
      }
    }

    final Map<String, int> dayCounts = {
      for (final e in distinctDates.entries) e.key: e.value.length,
    };

    bool didPromote = false;
    final updated = Map<String, String>.from(state.prefs);

    for (final entry in dayCounts.entries) {
      final id = entry.key;
      final days = entry.value;

      // Skip if already in quick access or explicitly removed.
      final existing = updated[id];
      if (existing == kPrefRemoved ||
          existing == kPrefOnboarding ||
          existing == kPrefPromoted) continue;

      if (days >= kPromotionThresholdDays) {
        updated[id] = kPrefPromoted;
        didPromote = true;
      }
    }

    if (didPromote) {
      state = state.copyWith(prefs: updated, recentDayCounts: dayCounts);
      await _persistPrefs(updated);
    } else {
      // Still update day counts so ordering stays accurate.
      state = state.copyWith(recentDayCounts: dayCounts);
    }
  }

  // ── Manual override (library long-press only) ──────────────────────────────

  /// Permanently removes a symptom from quick access and blocks future
  /// auto-promotion. Only callable from the library screen.
  Future<void> setRemoved(String id) async {
    final updated = Map<String, String>.from(state.prefs)..[id] = kPrefRemoved;
    state = state.copyWith(prefs: updated);
    await _persistPrefs(updated);
  }

  /// Re-adds a previously removed symptom as an 'onboarding' entry (user intent).
  /// Only callable from the library screen.
  Future<void> setAdded(String id) async {
    final updated = Map<String, String>.from(state.prefs)..[id] = kPrefOnboarding;
    state = state.copyWith(prefs: updated);
    await _persistPrefs(updated);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool isInQuickAccess(String id) {
    final pref = state.prefs[id];
    return pref == kPrefOnboarding || pref == kPrefPromoted;
  }

  bool isRemoved(String id) => state.prefs[id] == kPrefRemoved;

  Future<void> _persistPrefs(Map<String, String> prefs) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _ref
          .read(firestoreServiceProvider)
          .updateSymptomQuickAccessPrefs(user.uid, prefs);
    } catch (e) {
      debugPrint('SymptomQuickAccess: failed to persist prefs: $e');
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final symptomQuickAccessProvider = StateNotifierProvider<
    SymptomQuickAccessNotifier, SymptomQuickAccessState>((ref) {
  return SymptomQuickAccessNotifier(ref);
});

/// The ordered, de-duplicated, ≤8 chip list used by [SymptomsStep].
///
/// Assembly order:
///   1. Fixed core pins (always present, not bumped)
///   2. 'onboarding' selections not already included
///   3. 'promoted' symptoms ordered by 30-day frequency descending
///   4. Cap at [kQuickAccessMax]; if overflow, drop the least-frequent promoted
final quickAccessChipListProvider = Provider<List<Symptom>>((ref) {
  final qaState = ref.watch(symptomQuickAccessProvider);
  final library = ref.watch(symptomLibraryProvider);

  final Map<String, Symptom> byId = {for (final s in library) s.id: s};

  final List<Symptom> result = [];
  final Set<String> seen = {};

  // 1. Fixed core pins
  for (final id in kCoreFixedPins) {
    if (byId.containsKey(id)) {
      result.add(byId[id]!);
      seen.add(id);
    }
  }

  // 2. Onboarding selections (preserving their original order)
  final onboardingIds = qaState.prefs.entries
      .where((e) => e.value == kPrefOnboarding)
      .map((e) => sanitizeSymptomId(e.key));
  for (final id in onboardingIds) {
    if (!seen.contains(id) && byId.containsKey(id)) {
      result.add(byId[id]!);
      seen.add(id);
    }
  }

  // 3. Promoted symptoms, sorted by recent day-count descending (tie-break: id alphabetically)
  final promotedIds = qaState.prefs.entries
      .where((e) => e.value == kPrefPromoted)
      .map((e) => sanitizeSymptomId(e.key))
      .toList()
    ..sort((a, b) {
      final countA = qaState.recentDayCounts[a] ?? 0;
      final countB = qaState.recentDayCounts[b] ?? 0;
      if (countB != countA) return countB.compareTo(countA);
      return a.compareTo(b); // stable alphabetical tie-break
    });

  for (final id in promotedIds) {
    if (!seen.contains(id) && byId.containsKey(id)) {
      result.add(byId[id]!);
      seen.add(id);
    }
  }

  // 4. Cap — core pins are in the first [kCoreFixedPins.length] slots and
  //    are never removed. Only trailing promoted/onboarding slots are trimmed.
  if (result.length > kQuickAccessMax) {
    return result.sublist(0, kQuickAccessMax);
  }

  return result;
});
