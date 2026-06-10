import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/utils/animation_system.dart';

class TriggerLoggingSheet extends StatefulWidget {
  final Function(String name, String value, IconData icon) onSave;

  const TriggerLoggingSheet({super.key, required this.onSave});

  @override
  State<TriggerLoggingSheet> createState() => _TriggerLoggingSheetState();
}

class _TriggerLoggingSheetState extends State<TriggerLoggingSheet> {
  int _currentStep = 0; // 0: Select Trigger, 1: Select Level
  
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

  Color _getTriggerColor(String name) {
    switch (name.toLowerCase()) {
      case 'stress':
        return const Color(0xFFB8A7C5);
      case 'caffeine':
        return const Color(0xFF9B8B7E);
      case 'alcohol':
        return const Color(0xFFD4A5A5);
      case 'sugar':
        return const Color(0xFFA9B388);
      case 'lack of sleep':
        return const Color(0xFFA7C5D8);
      case 'spicy food':
        return const Color(0xFFE5989B);
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  _currentStep == 0 ? 'Add Daily Trigger' : 'Rate Trigger',
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
                  ? _buildTriggerSelection()
                  : _buildLevelSelection(),
            ),
          ),

          // Action Button (Only in Step 2)
          if (_currentStep == 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                    disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.4),
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
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

  Widget _buildTriggerSelection() {
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
          itemCount: _popularTriggers.length,
          itemBuilder: (context, index) {
            final item = _popularTriggers[index];
            final name = item['name'] as String;
            final icon = item['icon'] as IconData;
            final trigColor = _getTriggerColor(name);
            final trigBg = trigColor.withValues(alpha: 0.1);

            return Bounceable(
              onTap: () {
                setState(() {
                  _selectedTrigger = item;
                  _selectedValue = item['values'][1]; // default middle value
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
                        color: trigBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: trigColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF9B8B7E),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/trigger-library');
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFD0C4BC)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Add custom influence',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLevelSelection() {
    if (_selectedTrigger == null) return const SizedBox.shrink();

    final name = _selectedTrigger!['name'] as String;
    final icon = _selectedTrigger!['icon'] as IconData;
    final trigColor = _getTriggerColor(name);
    final trigBg = trigColor.withValues(alpha: 0.1);
    final values = _selectedTrigger!['values'] as List<String>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: trigColor.withValues(alpha: 0.04),
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
                      color: trigBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: trigColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    name,
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
                'TRIGGER LEVEL / QUANTITY',
                style: GoogleFonts.manrope(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: const Color(0xFF8A817C),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: values.map((val) {
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primary : const Color(0xFFF8F2F0),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppTheme.primary : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            val,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
