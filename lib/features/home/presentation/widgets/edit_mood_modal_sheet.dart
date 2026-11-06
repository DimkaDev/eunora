import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';

class MoodOption {
  final String name;
  final String emoji;
  final int defaultScore;
  final String subtitle;
  final String stress;
  final Color color;

  const MoodOption({
    required this.name,
    required this.emoji,
    required this.defaultScore,
    required this.subtitle,
    required this.stress,
    required this.color,
  });
}

const kMoodDefinitions = [
  MoodOption(
    name: 'Great',
    emoji: '🌟',
    defaultScore: 5,
    subtitle: 'Energized, balanced & positive',
    stress: 'Calm',
    color: Color(0xFF10B981),
  ),
  MoodOption(
    name: 'Good',
    emoji: '😊',
    defaultScore: 4,
    subtitle: 'Feeling calm and in good spirits',
    stress: 'Calm',
    color: Color(0xFF0EA5E9),
  ),
  MoodOption(
    name: 'Okay',
    emoji: '😐',
    defaultScore: 3,
    subtitle: 'Neutral, managing daily tasks fine',
    stress: 'Moderate',
    color: Color(0xFFF59E0B),
  ),
  MoodOption(
    name: 'Low',
    emoji: '😔',
    defaultScore: 2,
    subtitle: 'Down, fatigued or emotionally drained',
    stress: 'Moderate',
    color: Color(0xFF8B5CF6),
  ),
  MoodOption(
    name: 'Anxious',
    emoji: '😰',
    defaultScore: 2,
    subtitle: 'Tense, restless or worried',
    stress: 'High',
    color: Color(0xFFEC4899),
  ),
  MoodOption(
    name: 'Stressed',
    emoji: '😫',
    defaultScore: 1,
    subtitle: 'Overwhelmed or high pressure',
    stress: 'High',
    color: Color(0xFFEF4444),
  ),
];

class EditMoodModalSheet extends StatefulWidget {
  final String initialMoodInfo;
  final String? initialStressLevel;
  final DateTime? selectedDate;
  final void Function(String moodName, int score, String formattedMoodInfo, String stressLevel) onSave;

  const EditMoodModalSheet({
    super.key,
    required this.initialMoodInfo,
    this.initialStressLevel,
    this.selectedDate,
    required this.onSave,
  });

  @override
  State<EditMoodModalSheet> createState() => _EditMoodModalSheetState();
}

class _EditMoodModalSheetState extends State<EditMoodModalSheet> {
  late String _selectedMood;
  late int _score;
  late String _stressLevel;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  @override
  void initState() {
    super.initState();
    _parseInitialData();
  }

  void _parseInitialData() {
    final raw = widget.initialMoodInfo.trim();
    String detectedMood = 'Good';
    int detectedScore = 4;
    String detectedStress = widget.initialStressLevel ?? 'Moderate';

    for (final def in kMoodDefinitions) {
      final name = def.name;
      if (raw.toLowerCase().contains(name.toLowerCase())) {
        detectedMood = name;
        detectedScore = def.defaultScore;
        detectedStress = def.stress;
        break;
      }
    }

    // Try parsing score
    final scoreMatch = RegExp(r'(\d)/5').firstMatch(raw);
    if (scoreMatch != null) {
      final s = int.tryParse(scoreMatch.group(1) ?? '');
      if (s != null && s >= 1 && s <= 5) {
        detectedScore = s;
      }
    }

    _selectedMood = detectedMood;
    _score = detectedScore;
    _stressLevel = detectedStress;
  }

  String _formatDateSubtitle() {
    final d = widget.selectedDate;
    if (d == null) return 'For selected date';
    return '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';
  }

  void _handleSave() {
    final formatted = '$_selectedMood · $_score/5';
    widget.onSave(_selectedMood, _score, formatted, _stressLevel);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(width: 40),
                Text(
                  'Edit Mood & Well-being',
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
          const SizedBox(height: 4),
          Text(
            _formatDateSubtitle(),
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HOW WERE YOU FEELING?',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mood list
                  ...kMoodDefinitions.map((def) {
                    final name = def.name;
                    final emoji = def.emoji;
                    final subtitle = def.subtitle;
                    final stress = def.stress;
                    final defScore = def.defaultScore;
                    final color = def.color;
                    final isSelected = _selectedMood == name;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedMood = name;
                            _score = defScore;
                            _stressLevel = stress;
                          });
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : AppTheme.outlineVariant.withValues(alpha: 0.25),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? color : AppTheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      subtitle,
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        color: AppTheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$_score/5',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 16),

                  // Rating score adjustment card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SCORE RATING',
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              '$_score / 5',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(5, (idx) {
                            final rating = idx + 1;
                            final isCurrent = _score == rating;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _score = rating;
                                });
                              },
                              child: Container(
                                width: 48,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? AppTheme.primary
                                      : const Color(0xFFF7F5F2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isCurrent
                                        ? AppTheme.primary
                                        : AppTheme.outlineVariant.withValues(alpha: 0.4),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$rating',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrent ? Colors.white : AppTheme.onSurface,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Save button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Save Mood',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
