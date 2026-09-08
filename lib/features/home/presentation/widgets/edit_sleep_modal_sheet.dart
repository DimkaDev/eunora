import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';

class EditSleepModalSheet extends StatefulWidget {
  final String initialSleepInfo;
  final double? initialDuration;
  final DateTime? selectedDate;
  final void Function(double duration, int? quality, String formattedSleepInfo) onSave;

  const EditSleepModalSheet({
    super.key,
    required this.initialSleepInfo,
    this.initialDuration,
    this.selectedDate,
    required this.onSave,
  });

  @override
  State<EditSleepModalSheet> createState() => _EditSleepModalSheetState();
}

class _EditSleepModalSheetState extends State<EditSleepModalSheet> {
  late double _duration;
  late int? _qualityScore;

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
    // Parse duration
    if (widget.initialDuration != null && widget.initialDuration! > 0) {
      _duration = widget.initialDuration!;
    } else {
      final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(widget.initialSleepInfo);
      if (match != null) {
        _duration = double.tryParse(match.group(1) ?? '7.0') ?? 7.0;
      } else {
        _duration = 7.0;
      }
    }
    _duration = _duration.clamp(0.0, 14.0);

    // Parse quality score
    final qualityMatch = RegExp(r'quality\s*(\d)/5', caseSensitive: false).firstMatch(widget.initialSleepInfo);
    if (qualityMatch != null) {
      _qualityScore = int.tryParse(qualityMatch.group(1) ?? '');
    } else {
      final slashMatch = RegExp(r'(\d)/5').firstMatch(widget.initialSleepInfo);
      if (slashMatch != null) {
        _qualityScore = int.tryParse(slashMatch.group(1) ?? '');
      } else {
        _qualityScore = 3;
      }
    }
  }

  String _formatDateSubtitle() {
    final d = widget.selectedDate;
    if (d == null) return 'For selected date';
    return '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';
  }

  void _handleSave() {
    final formattedHours = _duration.toStringAsFixed(_duration == _duration.toInt() ? 0 : 1);
    final formatted = _qualityScore != null
        ? '$formattedHours hours · quality $_qualityScore/5'
        : '$formattedHours hours';
    widget.onSave(_duration, _qualityScore, formatted);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const sleepPurple = Color(0xFF8B5CF6);

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
                  'Edit Sleep',
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
                  // Duration Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: sleepPurple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.bedtime,
                                    color: sleepPurple,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'SLEEP DURATION',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  _duration.toStringAsFixed(_duration == _duration.toInt() ? 0 : 1),
                                  style: GoogleFonts.manrope(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'hrs',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: sleepPurple,
                            inactiveTrackColor: sleepPurple.withValues(alpha: 0.15),
                            thumbColor: sleepPurple,
                            overlayColor: sleepPurple.withValues(alpha: 0.2),
                            trackHeight: 6,
                          ),
                          child: Slider(
                            value: _duration,
                            min: 0,
                            max: 14,
                            divisions: 28,
                            onChanged: (val) {
                              setState(() {
                                _duration = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Presets
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [5.0, 6.0, 7.0, 7.5, 8.0, 9.0].map((preset) {
                            final isSelected = (_duration - preset).abs() < 0.1;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _duration = preset;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? sleepPurple : const Color(0xFFF7F5F2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? sleepPurple
                                        : AppTheme.outlineVariant.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  '${preset == preset.toInt() ? preset.toInt() : preset}h',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quality Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFF59E0B),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'SLEEP QUALITY',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildQualityOption(1, '😫', 'Poor', 'Disrupted / restless'),
                        const SizedBox(height: 8),
                        _buildQualityOption(2, '🥱', 'Fair', 'Woke up multiple times'),
                        const SizedBox(height: 8),
                        _buildQualityOption(3, '😐', 'Moderate', 'Average night sleep'),
                        const SizedBox(height: 8),
                        _buildQualityOption(4, '😊', 'Good', 'Felt well-rested'),
                        const SizedBox(height: 8),
                        _buildQualityOption(5, '😴', 'Restful & Deep', 'Optimal uninterrupted sleep'),
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
                  'Save Sleep',
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

  Widget _buildQualityOption(int score, String emoji, String title, String subtitle) {
    final isSelected = _qualityScore == score;
    const activeBorderColor = Color(0xFF8B5CF6);

    return InkWell(
      onTap: () {
        setState(() {
          _qualityScore = score;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? activeBorderColor.withValues(alpha: 0.08)
              : const Color(0xFFF9F7F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? activeBorderColor
                : AppTheme.outlineVariant.withValues(alpha: 0.25),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? activeBorderColor : AppTheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (starIdx) {
                final filled = starIdx < score;
                return Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 16,
                  color: filled
                      ? (isSelected ? const Color(0xFFF59E0B) : Colors.amber.shade400)
                      : const Color(0xFFD0C4BC).withValues(alpha: 0.4),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
