import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';
import 'package:eunora/features/onboarding/presentation/providers/symptom_quick_access_provider.dart';

import 'package:eunora/core/utils/logging_helpers.dart';
import 'package:eunora/features/onboarding/presentation/providers/symptoms_provider.dart';

class SymptomsStep extends ConsumerStatefulWidget {
  final Set<String> selectedSymptomIds;
  final ValueChanged<String> onSymptomToggled;

  const SymptomsStep({
    super.key,
    required this.selectedSymptomIds,
    required this.onSymptomToggled,
  });

  @override
  ConsumerState<SymptomsStep> createState() => _SymptomsStepState();
}

class _SymptomsStepState extends ConsumerState<SymptomsStep> {
  bool _isLibraryExpanded = false;

  Widget _buildTierBadge(String symId) {
    final cleanId = sanitizeSymptomId(symId);
    final isCore = kCoreFixedPins.contains(cleanId);
    final qaState = ref.watch(symptomQuickAccessProvider);
    final isQuick = !isCore && (qaState.prefs[cleanId] == kPrefOnboarding || qaState.prefs[cleanId] == kPrefPromoted);

    if (!isCore && !isQuick) {
      return const SizedBox.shrink();
    }

    final Color badgeBg = isCore
        ? const Color(0xFF9B8B7E).withOpacity(0.18)
        : const Color(0xFF6B8E23).withOpacity(0.18);
    final Color textColor = isCore
        ? const Color(0xFF63564B)
        : const Color(0xFF3F5A10);
    final String label = isCore ? 'CORE' : 'QUICK';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Adaptive quick-access list: ≤8 chips, core pins always first, then
    // onboarding selections, then frequency-promoted symptoms.
    final quickAccess = ref.watch(quickAccessChipListProvider);
    final library = ref.watch(symptomLibraryProvider);
    final byId = {for (final s in library) s.id: s};

    final List<Symptom> displaySymptoms = List.from(quickAccess);
    final Set<String> existingIds = displaySymptoms.map((s) => s.id).toSet();

    for (final id in widget.selectedSymptomIds) {
      final cleanId = sanitizeSymptomId(id);
      if (!existingIds.contains(cleanId) && byId.containsKey(cleanId)) {
        displaySymptoms.add(byId[cleanId]!);
        existingIds.add(cleanId);
      }
    }

    if (_isLibraryExpanded) {
      for (final s in library) {
        if (!existingIds.contains(s.id)) {
          displaySymptoms.add(s);
          existingIds.add(s.id);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'How are you feeling right now?',
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D1B1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select any symptoms that have been bothering you today. We\'re here to listen.',
          style: GoogleFonts.manrope(
            fontSize: 16,
            color: const Color(0xFF1D1B1A).withOpacity(0.6),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF6B8E23).withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF6B8E23).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.touch_app_outlined, color: Color(0xFF4A6B10), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tip: Press & hold any symptom chip to add or remove it from Quick Access.',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3F5A10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: displaySymptoms.length + (_isLibraryExpanded ? 0 : 1),
          itemBuilder: (context, index) {
            if (!_isLibraryExpanded && index == displaySymptoms.length) {
              // Add Custom Other Button (expands library in place)
              return Bounceable(
                onTap: () {
                  setState(() {
                    _isLibraryExpanded = true;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF9F6),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: const Color(0xFF9B8B7E).withOpacity(0.2),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9B8B7E).withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          color: const Color(0xFF9B8B7E).withOpacity(0.4),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Other',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF9B8B7E).withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final symptom = displaySymptoms[index];
            final symId = symptom.id;
            final cleanSymId = sanitizeSymptomId(symId);
            final isSelected = widget.selectedSymptomIds.contains(symId) || widget.selectedSymptomIds.contains(cleanSymId);
            final symName = symptom.name;
            final iconColor = symptom.getIconColor();
            final iconBgColor = iconColor.withOpacity(0.1);

            return Bounceable(
              onTap: () => widget.onSymptomToggled(symId),
              child: GestureDetector(
                onLongPress: () async {
                  if (kCoreFixedPins.contains(cleanSymId)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Core symptoms are permanently pinned to Quick Access.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  final qaNotifier = ref.read(symptomQuickAccessProvider.notifier);
                  if (qaNotifier.isInQuickAccess(cleanSymId)) {
                    await qaNotifier.setRemoved(cleanSymId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$symName removed from Quick Access'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } else {
                    await qaNotifier.setAdded(cleanSymId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$symName added to Quick Access'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF9B8B7E) : Colors.transparent,
                      width: isSelected ? 2 : 0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isSelected ? 0.08 : 0.03),
                        blurRadius: isSelected ? 15 : 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: isSelected ? iconColor.withOpacity(0.2) : iconBgColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                symptom.getIconData(),
                                color: iconColor,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                symName,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? const Color(0xFF1D1B1A)
                                      : const Color(0xFF9B8B7E),
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 12,
                        child: _buildTierBadge(symId),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 40),
        // Tip banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF9B8B7E).withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF9B8B7E).withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline, color: Color(0xFF9B8B7E), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '"It\'s common to experience multiple symptoms. Logging them helps us spot patterns in your journey."',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF9B8B7E),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
