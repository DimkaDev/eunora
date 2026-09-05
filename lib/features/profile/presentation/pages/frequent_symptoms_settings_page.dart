import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';
import 'package:eunora/features/onboarding/presentation/providers/symptoms_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/symptom_quick_access_provider.dart';

class FrequentSymptomsSettingsPage extends ConsumerStatefulWidget {
  const FrequentSymptomsSettingsPage({super.key});

  @override
  ConsumerState<FrequentSymptomsSettingsPage> createState() =>
      _FrequentSymptomsSettingsPageState();
}

class _FrequentSymptomsSettingsPageState
    extends ConsumerState<FrequentSymptomsSettingsPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(symptomLibraryProvider);
    final activeChips = ref.watch(quickAccessChipListProvider);
    final qaNotifier = ref.read(symptomQuickAccessProvider.notifier);
    final qaState = ref.watch(symptomQuickAccessProvider);

    final Set<String> activeChipIds = activeChips.map((s) => s.id).toSet();

    // Group symptoms by category
    final Map<String, List<Symptom>> grouped = {};
    for (final symptom in library) {
      final cat = symptom.category ?? 'Other';
      grouped.putIfAbsent(cat, () => []).add(symptom);
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Frequent Symptoms',
          style: GoogleFonts.notoSerif(
            color: AppTheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header / Info banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.outlineVariant.withOpacity(0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Quick-Log Symptoms',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select which symptoms appear in your daily quick log grid (up to 8). Core symptoms are always included.',
                        style: GoogleFonts.manrope(
                          fontSize: 12.5,
                          color: AppTheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search symptoms...',
                hintStyle: GoogleFonts.manrope(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search, color: AppTheme.outline),
                filled: true,
                fillColor: AppTheme.surfaceContainerLowest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Symptoms checklist by category
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              children: grouped.entries.map((entry) {
                final categoryName = entry.key;
                final symptoms = entry.value
                    .where((s) => s.name
                        .toLowerCase()
                        .contains(_searchQuery.trim().toLowerCase()))
                    .toList();

                if (symptoms.isEmpty) return const SizedBox.shrink();

                return _buildCategorySection(
                  context,
                  categoryName,
                  symptoms,
                  activeChipIds,
                  activeChips,
                  qaNotifier,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String categoryName,
    List<Symptom> symptoms,
    Set<String> activeChipIds,
    List<Symptom> activeChips,
    SymptomQuickAccessNotifier qaNotifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            categoryName,
            style: GoogleFonts.notoSerif(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: List.generate(symptoms.length, (index) {
              final symptom = symptoms[index];
              final isCore = kCoreFixedPins.contains(symptom.id);
              final isChecked = isCore || activeChipIds.contains(symptom.id);
              final showDivider = index < symptoms.length - 1;

              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: symptom.getIconColor().withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        symptom.getIconData(),
                        color: symptom.getIconColor(),
                        size: 22,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            symptom.name,
                            style: GoogleFonts.manrope(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ),
                        if (isCore) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.outlineVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Core',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: Checkbox(
                      value: isChecked,
                      activeColor: isCore ? AppTheme.outline : AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: isCore
                          ? (_) => _explainCoreSymptom(context, symptom)
                          : (bool? value) => _toggleSymptom(
                                context,
                                symptom,
                                isChecked,
                                activeChips,
                                qaNotifier,
                              ),
                    ),
                    onTap: isCore
                        ? () => _explainCoreSymptom(context, symptom)
                        : () => _toggleSymptom(
                              context,
                              symptom,
                              isChecked,
                              activeChips,
                              qaNotifier,
                            ),
                  ),
                  if (showDivider)
                    const Divider(
                      height: 1,
                      indent: 64,
                      endIndent: 16,
                      color: AppTheme.surfaceContainerLow,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  void _explainCoreSymptom(BuildContext context, Symptom symptom) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${symptom.name} is a core symptom and is always included in your quick-access grid.',
          style: GoogleFonts.manrope(),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleSymptom(
    BuildContext context,
    Symptom symptom,
    bool isCurrentlyChecked,
    List<Symptom> activeChips,
    SymptomQuickAccessNotifier qaNotifier,
  ) async {
    if (isCurrentlyChecked) {
      // Uncheck / Remove from quick access
      await qaNotifier.setRemoved(symptom.id);
    } else {
      // Check / Add to quick access
      if (activeChips.length >= kQuickAccessMax) {
        // Cap of 8 reached. Identify displaced symptom.
        final displacedSymptom = activeChips.last;
        _showCapExceededDialog(context, symptom, displacedSymptom, qaNotifier);
      } else {
        await qaNotifier.setAdded(symptom.id);
      }
    }
  }

  void _showCapExceededDialog(
    BuildContext context,
    Symptom newSymptom,
    Symptom displacedSymptom,
    SymptomQuickAccessNotifier qaNotifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Quick-Access Limit Reached',
          style: GoogleFonts.notoSerif(
            color: AppTheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Your quick-access grid can feature up to $kQuickAccessMax symptoms to keep daily logging fast. '
          'Adding "${newSymptom.name}" will replace "${displacedSymptom.name}" in your quick-access grid.',
          style: GoogleFonts.manrope(
            color: AppTheme.onSurfaceVariant,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(
                color: AppTheme.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await qaNotifier.setRemoved(displacedSymptom.id);
              await qaNotifier.setAdded(newSymptom.id);
            },
            child: Text(
              'Replace ${displacedSymptom.name}',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
