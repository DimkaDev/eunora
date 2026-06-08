import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';
import 'package:eunora/features/onboarding/presentation/widgets/add_medication_modal.dart';
import 'package:eunora/features/onboarding/presentation/pages/other_medications_page.dart';

class DailyEntryStep extends ConsumerStatefulWidget {
  final bool estradiolChecked;
  final double estradiolDose;
  final String estradiolUnit;
  final String estradiolTime;
  final bool progesteroneChecked;
  final double progesteroneDose;
  final String progesteroneUnit;
  final String progesteroneTime;
  final bool vitaminDChecked;
  final bool magnesiumChecked;
  final double sleepDuration;
  final int hydrationCups;
  final String additionalNotes;

  final ValueChanged<bool> onEstradiolCheckedToggled;
  final ValueChanged<double> onEstradiolDoseChanged;
  final ValueChanged<String> onEstradiolUnitChanged;
  final ValueChanged<String> onEstradiolTimeChanged;
  final ValueChanged<bool> onProgesteroneCheckedToggled;
  final ValueChanged<double> onProgesteroneDoseChanged;
  final ValueChanged<String> onProgesteroneUnitChanged;
  final ValueChanged<String> onProgesteroneTimeChanged;
  final ValueChanged<bool> onVitaminDCheckedToggled;
  final ValueChanged<bool> onMagnesiumCheckedToggled;
  final ValueChanged<double> onSleepDurationChanged;
  final ValueChanged<int> onHydrationCupsChanged;
  final ValueChanged<String> onAdditionalNotesChanged;

  const DailyEntryStep({
    super.key,
    required this.estradiolChecked,
    required this.estradiolDose,
    required this.estradiolUnit,
    required this.estradiolTime,
    required this.progesteroneChecked,
    required this.progesteroneDose,
    required this.progesteroneUnit,
    required this.progesteroneTime,
    required this.vitaminDChecked,
    required this.magnesiumChecked,
    required this.sleepDuration,
    required this.hydrationCups,
    required this.additionalNotes,
    required this.onEstradiolCheckedToggled,
    required this.onEstradiolDoseChanged,
    required this.onEstradiolUnitChanged,
    required this.onEstradiolTimeChanged,
    required this.onProgesteroneCheckedToggled,
    required this.onProgesteroneDoseChanged,
    required this.onProgesteroneUnitChanged,
    required this.onProgesteroneTimeChanged,
    required this.onVitaminDCheckedToggled,
    required this.onMagnesiumCheckedToggled,
    required this.onSleepDurationChanged,
    required this.onHydrationCupsChanged,
    required this.onAdditionalNotesChanged,
  });

  @override
  ConsumerState<DailyEntryStep> createState() => _DailyEntryStepState();
}

class _DailyEntryStepState extends ConsumerState<DailyEntryStep> {
  List<double> _getAvailableDoses(String unit) {
    final u = unit.toLowerCase();
    if (u == 'mcg') {
      return [12.5, 25.0, 37.5, 50.0, 62.5, 75.0, 87.5, 100.0, 112.5, 125.0, 150.0, 175.0, 200.0, 250.0];
    } else if (u == 'mg') {
      return [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 10.0, 20.0, 50.0, 100.0, 150.0, 200.0, 300.0, 400.0];
    } else {
      return List.generate(10, (i) => (i + 1).toDouble());
    }
  }

  void _openDosePicker({
    required String unit,
    required double currentDose,
    required ValueChanged<double> onDoseChanged,
  }) {
    final doses = _getAvailableDoses(unit);
    int initialIndex = doses.indexWhere((d) => (d - currentDose).abs() < 0.01);
    if (initialIndex == -1) initialIndex = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFEF8F6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFD0C4BC).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: const Color(0xFF8A817C)),
                    ),
                  ),
                  Text(
                    'Select Dose',
                    style: GoogleFonts.notoSerif(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Done',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: initialIndex),
                  itemExtent: 44,
                  onSelectedItemChanged: (index) {
                    onDoseChanged(doses[index]);
                  },
                  children: doses.map((d) {
                    return Center(
                      child: Text(
                        d.toStringAsFixed(d == d.toInt() ? 0 : 2).replaceAll(RegExp(r'\.00$'), ''),
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInlineMedicationDetails(String medKey) {
    bool isEstradiol = medKey == 'estradiol';
    double dose = isEstradiol ? widget.estradiolDose : widget.progesteroneDose;
    String unit = isEstradiol ? widget.estradiolUnit : widget.progesteroneUnit;
    String time = isEstradiol ? widget.estradiolTime : widget.progesteroneTime;
    
    // Dynamic unit options
    List<String> unitOptions = ['mg', 'mcg'];
    if (!unitOptions.contains(unit)) {
      unitOptions.add(unit);
    }
    final onboardingMeds = ref.read(medicationsProvider).medications;
    for (var m in onboardingMeds) {
      if (!unitOptions.contains(m.unit)) {
        unitOptions.add(m.unit);
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F0).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD0C4BC).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Dose selection field
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DOSE',
                      style: GoogleFonts.manrope(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF8A817C), letterSpacing: 1),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _openDosePicker(
                        unit: unit,
                        currentDose: dose,
                        onDoseChanged: (newDose) {
                          if (isEstradiol) {
                            widget.onEstradiolDoseChanged(newDose);
                          } else {
                            widget.onProgesteroneDoseChanged(newDose);
                          }
                        },
                      ),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD0C4BC).withOpacity(0.4)),
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          dose.toStringAsFixed(dose == dose.toInt() ? 0 : 2).replaceAll(RegExp(r'\.00$'), ''),
                          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Unit selection field
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UNIT',
                      style: GoogleFonts.manrope(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF8A817C), letterSpacing: 1),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE7E5).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Row(
                        children: unitOptions.map((opt) {
                          final isSelected = unit == opt;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (isEstradiol) {
                                  widget.onEstradiolUnitChanged(opt);
                                } else {
                                  widget.onProgesteroneUnitChanged(opt);
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          )
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  opt,
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? AppTheme.primary : const Color(0xFF9B8B7E),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Time selection field
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIME',
                      style: GoogleFonts.manrope(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF8A817C), letterSpacing: 1),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final timeOfDay = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (timeOfDay != null) {
                          final formattedTime = timeOfDay.format(context);
                          if (isEstradiol) {
                            widget.onEstradiolTimeChanged(formattedTime);
                          } else {
                            widget.onProgesteroneTimeChanged(formattedTime);
                          }
                        }
                      },
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD0C4BC).withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.schedule, size: 14, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                time,
                                style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool checked,
    required ValueChanged<bool?> onCheckedChange,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: const Color(0xFFEDDDF5).withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
      title: Text(title, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
      subtitle: Text(subtitle, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.outline)),
      trailing: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: checked ? AppTheme.primary : Colors.transparent,
          shape: BoxShape.circle,
          border: checked ? null : Border.all(color: const Color(0xFFD0C4BC), width: 2),
        ),
        child: checked ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
      ),
    );
  }

  Widget _buildSupplementRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool checked,
    required ValueChanged<bool?> onCheckedChange,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: const Color(0xFFEDDDF5).withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
      title: Text(title, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
      subtitle: Text(subtitle, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.outline)),
      trailing: AnimatedCheckbox(
        value: checked,
        onChanged: (val) => onCheckedChange(val),
        activeColor: AppTheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Log HRT, Sleep & Hydration',
          style: GoogleFonts.notoSerif(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Record your hormone replacement therapy, sleep duration, and water intake for today.',
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: AppTheme.outline,
          ),
        ),
        const SizedBox(height: 28),

        // HRT SECTION
        Text(
          'HRT MEDICATIONS',
          style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.3)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildMedRow(
                title: 'Estradiol Patch',
                subtitle: '${widget.estradiolDose.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')} ${widget.estradiolUnit} • ${widget.estradiolTime}',
                icon: Icons.medication,
                checked: widget.estradiolChecked,
                onCheckedChange: (val) => widget.onEstradiolCheckedToggled(val!),
                onTap: () => widget.onEstradiolCheckedToggled(!widget.estradiolChecked),
              ),
              if (widget.estradiolChecked) _buildInlineMedicationDetails('estradiol'),
              const Divider(color: Color(0xFFF2EDEA), height: 1),
              _buildMedRow(
                title: 'Progesterone',
                subtitle: '${widget.progesteroneDose.toStringAsFixed(0)} ${widget.progesteroneUnit} • ${widget.progesteroneTime}',
                icon: Icons.medication,
                checked: widget.progesteroneChecked,
                onCheckedChange: (val) => widget.onProgesteroneCheckedToggled(val!),
                onTap: () => widget.onProgesteroneCheckedToggled(!widget.progesteroneChecked),
              ),
              if (widget.progesteroneChecked) _buildInlineMedicationDetails('progesterone'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddMedicationModal(),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Add HRT Medication',
                  style: GoogleFonts.manrope(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // SUPPLEMENTS SECTION
        Text(
          'OTHER DAILY SUPPLEMENTS',
          style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.3)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildSupplementRow(
                title: 'Daily Vitamin D',
                subtitle: '2000 IU • With Food',
                icon: Icons.spa,
                checked: widget.vitaminDChecked,
                onCheckedChange: (val) => widget.onVitaminDCheckedToggled(val!),
              ),
              const Divider(color: Color(0xFFF2EDEA), height: 1),
              _buildSupplementRow(
                title: 'Magnesium Glycinate',
                subtitle: '200 mg • Before Sleep',
                icon: Icons.spa,
                checked: widget.magnesiumChecked,
                onCheckedChange: (val) => widget.onMagnesiumCheckedToggled(val!),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddOtherMedicationModal(),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Add Supplement',
                  style: GoogleFonts.manrope(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // SLIDERS SECTION (Sleep & Hydration)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.surfaceContainer),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.brightness_3, color: Color(0xFF8B5CF6), size: 18),
                      const SizedBox(width: 8),
                      Text('Sleep Duration', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 1)),
                    ],
                  ),
                  Row(
                    children: [
                      Text('${widget.sleepDuration}', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                      const SizedBox(width: 4),
                      Text('hrs', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.outline)),
                    ],
                  )
                ],
              ),
              Slider(
                value: widget.sleepDuration,
                min: 0,
                max: 12,
                divisions: 24,
                activeColor: AppTheme.primary,
                onChanged: widget.onSleepDurationChanged,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.water_drop, color: Color(0xFF0EA5E9), size: 18),
                      const SizedBox(width: 8),
                      Text('Hydration', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 1)),
                    ],
                  ),
                  Row(
                    children: [
                      Text('${widget.hydrationCups}', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                      const SizedBox(width: 4),
                      Text('cups', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.outline)),
                    ],
                  )
                ],
              ),
              Slider(
                value: widget.hydrationCups.toDouble(),
                min: 0,
                max: 15,
                divisions: 15,
                activeColor: AppTheme.primary,
                onChanged: (val) => widget.onHydrationCupsChanged(val.toInt()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // NOTES
        Text(
          'ADDITIONAL NOTES',
          style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: widget.additionalNotes,
          maxLines: 3,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFD0C4BC))),
            hintText: 'How are you feeling today? Any specific symptoms?',
            hintStyle: GoogleFonts.notoSerif(fontStyle: FontStyle.italic, color: Colors.grey.withOpacity(0.6)),
          ),
          style: GoogleFonts.manrope(fontSize: 14),
          onChanged: widget.onAdditionalNotesChanged,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
