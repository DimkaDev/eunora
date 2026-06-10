import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';
import 'package:eunora/features/onboarding/presentation/providers/symptoms_provider.dart';

class SymptomLoggingSheet extends ConsumerStatefulWidget {
  final Function(String name, String severity) onSave;

  const SymptomLoggingSheet({super.key, required this.onSave});

  @override
  ConsumerState<SymptomLoggingSheet> createState() => _SymptomLoggingSheetState();
}

class _SymptomLoggingSheetState extends ConsumerState<SymptomLoggingSheet> {
  int _currentStep = 0; // 0: Select Symptom, 1: Select Severity
  Symptom? _selectedSymptom;
  String _selectedSeverity = 'Mild';
  int _selectedDuration = 15;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(symptomsProvider);
    final library = ref.watch(symptomLibraryProvider);

    // Get frequent symptoms
    final frequentSymptoms = state.frequentSymptomIds.map((id) {
      return library.firstWhere(
        (s) => s.id == id,
        orElse: () => Symptom(
          id: id,
          name: id.replaceAll('s_', '').replaceAll('_', ' '),
          iconName: 'medical_services',
        ),
      );
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.70,
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

          // Scrollable Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _currentStep == 0
                  ? _buildSymptomSelection(frequentSymptoms)
                  : _buildSeveritySelection(),
            ),
          ),

          // Action button (Only in Step 2)
          if (_currentStep == 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedSymptom != null) {
                      widget.onSave(_selectedSymptom!.name, _selectedSeverity);
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

  Widget _buildSymptomSelection(List<Symptom> frequentSymptoms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: frequentSymptoms.length + 1,
          itemBuilder: (context, index) {
            if (index == frequentSymptoms.length) {
              return Bounceable(
                onTap: () {
                  Navigator.pop(context);
                  context.push('/symptom-library');
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF9F6),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: const Color(0xFF9B8B7E).withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9B8B7E).withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          color: const Color(0xFF9B8B7E).withValues(alpha: 0.4),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Other',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF9B8B7E).withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final symptom = frequentSymptoms[index];
            final symColor = symptom.getIconColor();
            final symBg = symColor.withValues(alpha: 0.1);

            return Bounceable(
              onTap: () {
                setState(() {
                  _selectedSymptom = symptom;
                  _currentStep = 1;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: symBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        symptom.getIconData(),
                        color: symColor,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        symptom.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF9B8B7E),
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSeveritySelection() {
    if (_selectedSymptom == null) return const SizedBox.shrink();

    final symptom = _selectedSymptom!;
    final symName = symptom.name;
    final symIcon = symptom.getIconData();
    final symColor = symptom.getIconColor();
    final symBg = symColor.withValues(alpha: 0.1);
    final hasDuration = symptom.id == 's_hot_flashes' || symptom.id == 's_night_sweats';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: symColor.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: symBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(symIcon, color: symColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    symName,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'INTENSITY',
                style: GoogleFonts.manrope(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: const Color(0xFF8A817C),
                ),
              ),
              const SizedBox(height: 12),
              // fluid severity slider
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE2F5E2),
                      Color(0xFFFFF1D0),
                      Color(0xFFFFE0E0),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      alignment: _selectedSeverity == 'Mild'
                          ? Alignment.centerLeft
                          : _selectedSeverity == 'Moderate'
                              ? Alignment.center
                              : Alignment.centerRight,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.26,
                        height: 48,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedSeverity = 'Mild';
                              });
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('😊', style: TextStyle(fontSize: 18)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Mild',
                                    style: GoogleFonts.manrope(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedSeverity == 'Mild' ? AppTheme.primary : const Color(0xFF8A817C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedSeverity = 'Moderate';
                              });
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('😐', style: TextStyle(fontSize: 18)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Moderate',
                                    style: GoogleFonts.manrope(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedSeverity == 'Moderate' ? AppTheme.primary : const Color(0xFF8A817C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedSeverity = 'Severe';
                              });
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('😟', style: TextStyle(fontSize: 18)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Severe',
                                    style: GoogleFonts.manrope(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedSeverity == 'Severe' ? AppTheme.primary : const Color(0xFF8A817C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (hasDuration) ...[
                const SizedBox(height: 20),
                const Divider(color: Color(0xFFF7F5F0), height: 1),
                const SizedBox(height: 20),
                Text(
                  'DURATION',
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: const Color(0xFF8A817C),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F5F0).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_selectedDuration > 5) {
                            setState(() {
                              _selectedDuration -= 5;
                            });
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                              )
                            ],
                          ),
                          child: const Icon(Icons.remove, color: AppTheme.primary),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$_selectedDuration',
                            style: GoogleFonts.notoSerif(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'min',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF8A817C),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDuration += 5;
                          });
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                              )
                            ],
                          ),
                          child: const Icon(Icons.add, color: AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
