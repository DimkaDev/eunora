import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';

class TriggerLoggingSheet extends StatefulWidget {
  final Function(String name, String value, IconData icon) onSave;

  const TriggerLoggingSheet({super.key, required this.onSave});

  @override
  State<TriggerLoggingSheet> createState() => _TriggerLoggingSheetState();
}

class _TriggerLoggingSheetState extends State<TriggerLoggingSheet> {
  final List<Map<String, dynamic>> _popularTriggers = [
    {'name': 'Stress', 'icon': Icons.psychology, 'values': ['Low', 'Moderate', 'High']},
    {'name': 'Caffeine', 'icon': Icons.coffee, 'values': ['1 Cup', '2 Cups', '3 Cups']},
    {'name': 'Alcohol', 'icon': Icons.wine_bar, 'values': ['1 Glass', '2 Glasses', '3 Glasses']},
    {'name': 'Sugar', 'icon': Icons.restaurant, 'values': ['Low', 'Moderate', 'High']},
    {'name': 'Lack of Sleep', 'icon': Icons.bed, 'values': ['Mild', 'Moderate', 'Severe']},
    {'name': 'Spicy Food', 'icon': Icons.local_fire_department, 'values': ['Low', 'High']},
  ];

  Map<String, dynamic>? _selectedTrigger;
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    // Default select first trigger to make layout intuitive
    _selectedTrigger = _popularTriggers[0];
    _selectedValue = _selectedTrigger!['values'][1]; // Select Moderate
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: const Color(0xFFD0C4BC).withOpacity(0.3),
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
                  'Add Daily Trigger',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Choose Trigger
                  Text(
                    'CHOOSE TRIGGER',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurfaceVariant.withOpacity(0.6),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: _popularTriggers.length,
                    itemBuilder: (context, index) {
                      final item = _popularTriggers[index];
                      final isSelected = _selectedTrigger?['name'] == item['name'];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTrigger = item;
                            _selectedValue = item['values'][1]; // Select middle option as default
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFFDAD3)
                                : const Color(0xFFF2EDEA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFF9B7A9)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item['icon'] as IconData,
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.onSurfaceVariant,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item['name'] as String,
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected
                                        ? const Color(0xFF683A31)
                                        : AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Choose Level/Value
                  Text(
                    'TRIGGER LEVEL / QUANTITY',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurfaceVariant.withOpacity(0.6),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_selectedTrigger != null)
                    Row(
                      children: (_selectedTrigger!['values'] as List<String>).map((val) {
                        final isSelected = _selectedValue == val;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedValue = val;
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : const Color(0xFFD0C4BC),
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.primary.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  val,
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _selectedTrigger == null || _selectedValue == null
                    ? null
                    : () {
                        widget.onSave(
                          _selectedTrigger!['name'] as String,
                          _selectedValue!,
                          _selectedTrigger!['icon'] as IconData,
                        );
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.primary.withOpacity(0.4),
                  disabledForegroundColor: Colors.white.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Save Trigger',
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
}
