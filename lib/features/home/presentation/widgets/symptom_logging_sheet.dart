import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';
import 'package:eunora/features/onboarding/presentation/providers/symptoms_provider.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/logging_card_wrapper.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/gradient_slider_selector.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/quantity_counter_selector.dart';
import 'package:eunora/features/symptom_log/data/symptom_library.dart';
import 'package:eunora/features/onboarding/presentation/providers/menopause_stage_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/onboarding_profile_provider.dart';

class SymptomLoggingSheet extends ConsumerStatefulWidget {
  final List<Map<String, String>> loggedSymptoms;
  final Function(String name, String severity, int duration) onSave;

  const SymptomLoggingSheet({
    super.key,
    required this.loggedSymptoms,
    required this.onSave,
  });

  @override
  ConsumerState<SymptomLoggingSheet> createState() => _SymptomLoggingSheetState();
}

class _SymptomLoggingSheetState extends ConsumerState<SymptomLoggingSheet> {
  int _currentStep = 0; // 0: Select Symptom, 1: Select Severity
  Symptom? _selectedSymptom;
  String? _tappingSymptomId;
  String _selectedSeverity = 'Mild';
  int _selectedDuration = 15;
  
  String _searchQuery = '';
  bool _showAllSymptoms = false;

  void _selectSymptom(Symptom symptom) async {
    HapticFeedback.lightImpact();
    setState(() {
      _tappingSymptomId = symptom.id;
      _selectedSymptom = symptom;
    });

    // Short micro-delay to let the card scale, fill, and checkmark animate
    await Future.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;

    setState(() {
      _tappingSymptomId = null;
      _currentStep = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(symptomLibraryProvider);
    final loggedNames = widget.loggedSymptoms.map((s) => s['name']?.toLowerCase()).toSet();

    final stage = ref.watch(menopauseStageProvider).selectedStage ?? 
        ref.watch(onboardingProfileProvider)?.menopauseStage;
    final isPerimenopause = stage == MenopauseStage.irregular;

    // Filter display symptoms
    final displaySymptoms = library.where((symptom) {
      final matchesLogged = !loggedNames.contains(symptom.name.toLowerCase());
      final matchesSearch = _searchQuery.isEmpty ||
          symptom.name.toLowerCase().contains(_searchQuery.toLowerCase());
      
      if (!matchesSearch) return false;

      // Find definition in the new kSymptomLibrary
      final def = kSymptomLibrary.where((d) => d.id == symptom.id).firstOrNull;
      if (def == null) return matchesLogged; // fallback for custom/unknown

      // Gating for Cycle / PerimenopauseOnly
      if (def.perimenopauseOnly && !isPerimenopause) return false;

      // Search ignores tier filtering
      if (_searchQuery.isNotEmpty) return matchesLogged;

      // Tier filtering: if not showing all, show core or cycle (if perimenopause)
      final isCore = def.tier == SymptomTier.core;
      final isCycle = def.category == SymptomCategory.cycle;
      
      if (_showAllSymptoms) {
        return matchesLogged;
      } else {
        return matchesLogged && (isCore || (isCycle && isPerimenopause));
      }
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.only(bottom: 24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFD0C4BC).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep == 1)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _currentStep = 0;
                        _selectedSymptom = null;
                      });
                    },
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF2EDEA),
                      foregroundColor: AppTheme.onSurfaceVariant,
                    ),
                  )
                else
                  const SizedBox(width: 40),
                Text(
                  _currentStep == 0 ? 'Add Symptom' : 'Rate Symptom',
                  style: GoogleFonts.notoSerif(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF2EDEA),
                    foregroundColor: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Body
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                final isForward = _currentStep == 1;
                final inOffset = isForward ? const Offset(0.08, 0.0) : const Offset(-0.08, 0.0);
                return FadeTransition(
                  opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: inOffset,
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _currentStep == 0
                  ? KeyedSubtree(
                      key: const ValueKey<int>(0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            child: TextField(
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Search symptoms...',
                                prefixIcon: const Icon(Icons.search, color: Color(0xFF9B8B7E)),
                                filled: true,
                                fillColor: const Color(0xFFF2EDEA).withValues(alpha: 0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              style: GoogleFonts.manrope(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: _buildSymptomSelection(displaySymptoms, isPerimenopause),
                            ),
                          ),
                        ],
                      ),
                    )
                  : KeyedSubtree(
                      key: const ValueKey<int>(1),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildSeveritySelection(),
                      ),
                    ),
            ),
          ),

          // Action button
          if (_currentStep == 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedSymptom != null) {
                      widget.onSave(_selectedSymptom!.name, _selectedSeverity, _selectedDuration);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Save Symptom',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSymptomSelection(List<Symptom> displaySymptoms, bool isPerimenopause) {
    if (displaySymptoms.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No symptoms found',
            style: GoogleFonts.manrope(
              color: AppTheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    // Grouping logic (only when not searching)
    if (_searchQuery.isEmpty) {
      // Grouping order: Vasomotor, Sleep, Mood & Cognitive, Physical, Urogenital, Cycle (if perimenopause)
      final categories = [
        SymptomCategory.vasomotor,
        SymptomCategory.sleep,
        SymptomCategory.moodCognitive,
        SymptomCategory.physical,
        SymptomCategory.urogenital,
        if (isPerimenopause) SymptomCategory.cycle,
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final cat in categories) ...[
            _buildCategoryGroup(cat, displaySymptoms),
          ],
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _showAllSymptoms = !_showAllSymptoms;
                });
              },
              icon: Icon(
                _showAllSymptoms ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: AppTheme.primary,
              ),
              label: Text(
                _showAllSymptoms ? 'Show less' : 'More symptoms',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      );
    }

    // Flat view during active search
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: displaySymptoms.length,
      itemBuilder: (context, index) {
        return _buildSymptomCard(displaySymptoms[index]);
      },
    );
  }

  Widget _buildCategoryGroup(SymptomCategory category, List<Symptom> symptoms) {
    final catSymptoms = symptoms.where((s) {
      final def = kSymptomLibrary.where((d) => d.id == s.id).firstOrNull;
      return def != null && def.category == category;
    }).toList();

    if (catSymptoms.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            category.displayName.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF9B8B7E),
              letterSpacing: 1.2,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: catSymptoms.length,
          itemBuilder: (context, index) {
            return _buildSymptomCard(catSymptoms[index]);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSymptomCard(Symptom symptom) {
    final symColor = symptom.getIconColor();
    final symBg = symColor.withValues(alpha: 0.1);
    final loggedNames = widget.loggedSymptoms.map((s) => s['name']?.toLowerCase()).toSet();
    final isAlreadyLogged = loggedNames.contains(symptom.name.toLowerCase());
    final isSelected = (_selectedSymptom?.id == symptom.id) || (_tappingSymptomId == symptom.id);

    return Bounceable(
      scaleFactor: 0.92,
      duration: const Duration(milliseconds: 140),
      onTap: () => _selectSymptom(symptom),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            decoration: BoxDecoration(
              color: isSelected
                  ? symColor.withValues(alpha: 0.12)
                  : (isAlreadyLogged ? Colors.white : const Color(0xFFFFFFFF)),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: isSelected
                    ? symColor
                    : (isAlreadyLogged ? const Color(0xFF9B8B7E) : Colors.transparent),
                width: isSelected ? 2.5 : (isAlreadyLogged ? 2 : 0),
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? symColor.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: isAlreadyLogged ? 0.08 : 0.03),
                  blurRadius: isSelected ? 16 : (isAlreadyLogged ? 15 : 10),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? symColor.withValues(alpha: 0.25)
                        : (isAlreadyLogged ? symColor.withValues(alpha: 0.2) : symBg),
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedScale(
                    scale: isSelected ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      symptom.getIconData(),
                      color: symColor,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    symptom.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: (isSelected || isAlreadyLogged) ? const Color(0xFF1D1B1A) : const Color(0xFF9B8B7E),
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isSelected && !isAlreadyLogged)
            Positioned(
              top: 10,
              right: 12,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 200),
                curve: Curves.elasticOut,
                builder: (context, val, child) => Transform.scale(
                  scale: val,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: symColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            )
          else if (isAlreadyLogged)
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF4A5E4A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSeveritySelection() {
    if (_selectedSymptom == null) return const SizedBox.shrink();

    final symptom = _selectedSymptom!;
    final symName = symptom.name;
    final symIcon = symptom.getIconData();
    final symColor = symptom.getIconColor();
    final symBg = symColor.withValues(alpha: 0.1);
    final symId = symptom.id.toLowerCase();
    final symNameLower = symName.toLowerCase();
    final hasDuration = symId == 'hot_flash' ||
        symId == 'night_sweats' ||
        symId == 's_hot_flashes' ||
        symId == 's_night_sweats' ||
        symId == 's_hot_flash' ||
        symNameLower == 'hot flashes' ||
        symNameLower == 'night sweats';

    return LoggingCardWrapper(
      name: symName,
      icon: symIcon,
      color: symColor,
      backgroundColor: symBg,
      triggerValue: _selectedSeverity,
      children: [
        GradientSliderSelector(
          values: const ['Mild', 'Moderate', 'Severe'],
          currentValue: _selectedSeverity,
          onChanged: (val) {
            setState(() {
              _selectedSeverity = val;
            });
          },
          label: 'INTENSITY',
          emojiGetter: (val) => _getEmojiForValue(symName, val),
        ),
        if (hasDuration) ...[
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF7F5F0), height: 1),
          QuantityCounterSelector(
            value: _selectedDuration,
            label: 'DURATION',
            onChanged: (val) {
              setState(() {
                _selectedDuration = val;
              });
            },
            displayValueBuilder: (val) => val > 0 ? '$val min' : 'Not set',
            stepValue: 5,
            minValue: 0,
            maxValue: 240,
          ),
        ],
      ],
    );
  }

  String _getEmojiForValue(String name, String value) {
    final nameLower = name.toLowerCase();
    final valLower = value.toLowerCase();

    if (nameLower == 'hot flashes' || nameLower == 'night sweats') {
      if (valLower == 'mild') return '🌡️';
      if (valLower == 'moderate') return '🔥';
      if (valLower == 'severe') return '🥵';
    }

    switch (valLower) {
      case 'mild':
      case 'low':
        return '😊';
      case 'moderate':
      case 'medium':
        return '😐';
      case 'severe':
      case 'high':
      case 'intense':
        return '😟';
      default:
        return '✨';
    }
  }
}
