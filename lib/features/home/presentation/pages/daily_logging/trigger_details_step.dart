import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:eunora/features/onboarding/presentation/providers/triggers_provider.dart';

class TriggerDetailsStep extends ConsumerWidget {
  final Set<String> selectedTriggerIds;
  final int caffeineCups;
  final int alcoholGlasses;
  final String stressLevel;
  final bool foodsTriggered;
  final String foodsNotes;
  final Map<String, int> customTriggerCounters;
  final Map<String, String> customTriggerTexts;

  final ValueChanged<int> onCaffeineCupsChanged;
  final ValueChanged<int> onAlcoholGlassesChanged;
  final ValueChanged<String> onStressLevelChanged;
  final ValueChanged<bool> onFoodsTriggeredChanged;
  final ValueChanged<String> onFoodsNotesChanged;
  final Function(String, int) onCustomTriggerCounterChanged;
  final Function(String, String) onCustomTriggerTextChanged;

  const TriggerDetailsStep({
    super.key,
    required this.selectedTriggerIds,
    required this.caffeineCups,
    required this.alcoholGlasses,
    required this.stressLevel,
    required this.foodsTriggered,
    required this.foodsNotes,
    required this.customTriggerCounters,
    required this.customTriggerTexts,
    required this.onCaffeineCupsChanged,
    required this.onAlcoholGlassesChanged,
    required this.onStressLevelChanged,
    required this.onFoodsTriggeredChanged,
    required this.onFoodsNotesChanged,
    required this.onCustomTriggerCounterChanged,
    required this.onCustomTriggerTextChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedTriggerIds.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.playlist_add_check, size: 64, color: Color(0xFFD0C4BC)),
              const SizedBox(height: 16),
              Text(
                'No influences selected',
                style: GoogleFonts.notoSerif(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              const SizedBox(height: 8),
              Text(
                'Go back and select influences to details.',
                style: GoogleFonts.manrope(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final library = ref.watch(triggerLibraryProvider);
    final triggerMap = {for (var t in library) t.id: t};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Journal Your Influences',
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Reflect on today\'s triggers',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        ...selectedTriggerIds.map((trigId) {
          final isBuiltIn = triggerMap.containsKey(trigId);
          if (!isBuiltIn) {
            return _buildCustomTriggerDetailCard(trigId);
          }

          final trigger = triggerMap[trigId]!;
          final name = trigger.name;

          if (trigId == 't_caffeine') {
            return _buildCaffeineDetailCard();
          } else if (trigId == 't_alcohol') {
            return _buildAlcoholDetailCard();
          } else if (trigId == 't_foods') {
            return _buildFoodsDetailCard();
          } else if (trigId == 't_stress') {
            return _buildStressDetailCard(context);
          } else {
            final currentVal = customTriggerTexts[trigId] ?? _getTriggerValues(name)[1];
            return _buildOtherTriggerDetailCard(context, trigId, name, currentVal, trigger.getIconData());
          }
        }),
        const SizedBox(height: 20),
        // Reflection tip
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFEDDDF5).withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb, color: AppTheme.primaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.onSurfaceVariant, height: 1.5),
                    children: [
                      TextSpan(text: 'Pro Tip: ', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      const TextSpan(text: 'High sodium can increase water retention and worsen night sweats. Try reducing salt in your evening meals.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCaffeineDetailCard() {
    const trigColor = Color(0xFF9B8B7E);
    final trigBg = trigColor.withOpacity(0.1);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: trigColor.withOpacity(0.04),
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
                child: const Icon(Icons.coffee, color: trigColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Caffeine',
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
            'HOW MUCH TODAY?',
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
              color: const Color(0xFFF7F5F0).withOpacity(0.6),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    if (caffeineCups > 0) {
                      onCaffeineCupsChanged(caffeineCups - 1);
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.remove, color: AppTheme.primary),
                  ),
                ),
                Text(
                  '$caffeineCups cups',
                  style: GoogleFonts.notoSerif(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
                GestureDetector(
                  onTap: () => onCaffeineCupsChanged(caffeineCups + 1),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlcoholDetailCard() {
    const trigColor = Color(0xFFD4A5A5);
    final trigBg = trigColor.withOpacity(0.1);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: trigColor.withOpacity(0.04),
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
                child: const Icon(Icons.local_bar, color: trigColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Alcohol',
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
            'CONSUMPTION LOG',
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
              color: const Color(0xFFF7F5F0).withOpacity(0.6),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    if (alcoholGlasses > 0) {
                      onAlcoholGlassesChanged(alcoholGlasses - 1);
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.remove, color: AppTheme.primary),
                  ),
                ),
                Text(
                  '$alcoholGlasses glass',
                  style: GoogleFonts.notoSerif(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
                GestureDetector(
                  onTap: () => onAlcoholGlassesChanged(alcoholGlasses + 1),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStressDetailCard(BuildContext context) {
    const trigColor = Color(0xFFB8A7C5);
    final trigBg = trigColor.withOpacity(0.1);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: trigColor.withOpacity(0.04),
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
                child: const Icon(Icons.psychology, color: trigColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Stress',
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
            'INTENSITY LEVEL',
            style: GoogleFonts.manrope(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: const Color(0xFF8A817C),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE2F5E2), // Soft Green (Calm)
                  Color(0xFFFFF1D0), // Soft Yellow/Orange (Moderate)
                  Color(0xFFFFE0E0), // Soft Red (High)
                ],
              ),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Stack(
              children: [
                // White sliding thumb selector
                AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: stressLevel == 'Calm'
                      ? Alignment.centerLeft
                      : stressLevel == 'Moderate'
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
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                  ),
                ),
                // Three Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onStressLevelChanged('Calm'),
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_getEmojiForValue('Stress', 'Calm'), style: const TextStyle(fontSize: 18)),
                              const SizedBox(height: 2),
                              Text(
                                'Calm',
                                style: GoogleFonts.manrope(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: stressLevel == 'Calm' ? AppTheme.primary : const Color(0xFF8A817C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onStressLevelChanged('Moderate'),
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_getEmojiForValue('Stress', 'Moderate'), style: const TextStyle(fontSize: 18)),
                              const SizedBox(height: 2),
                              Text(
                                'Moderate',
                                style: GoogleFonts.manrope(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: stressLevel == 'Moderate' ? AppTheme.primary : const Color(0xFF8A817C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onStressLevelChanged('High'),
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_getEmojiForValue('Stress', 'High'), style: const TextStyle(fontSize: 18)),
                              const SizedBox(height: 2),
                              Text(
                                'High',
                                style: GoogleFonts.manrope(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: stressLevel == 'High' ? AppTheme.primary : const Color(0xFF8A817C),
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
        ],
      ),
    );
  }

  Widget _buildFoodsDetailCard() {
    const trigColor = Color(0xFFE5989B);
    final trigBg = trigColor.withOpacity(0.1);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: trigColor.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: trigBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.restaurant, color: trigColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Foods',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              AnimatedSwitch(
                value: foodsTriggered,
                onChanged: onFoodsTriggeredChanged,
                activeColor: AppTheme.primary,
              ),
            ],
          ),
          if (foodsTriggered) ...[
            const SizedBox(height: 20),
            TextFormField(
              initialValue: foodsNotes,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceContainerLow,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                hintText: 'Spicy foods, heavy dinner...',
              ),
              style: GoogleFonts.notoSerif(fontSize: 14, fontStyle: FontStyle.italic),
              maxLines: 2,
              onChanged: onFoodsNotesChanged,
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildCustomTriggerDetailCard(String trigId) {
    final counter = customTriggerCounters[trigId] ?? 1;
    final note = customTriggerTexts[trigId] ?? '';
    const trigColor = Color(0xFF8EB8B5);
    final trigBg = trigColor.withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: trigColor.withOpacity(0.04),
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
                child: const Icon(Icons.stars, color: trigColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  trigId,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // simple increment
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Occurrence Level:',
                style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (counter > 1) {
                        onCustomTriggerCounterChanged(trigId, counter - 1);
                      }
                    },
                  ),
                  Text('$counter times', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      onCustomTriggerCounterChanged(trigId, counter + 1);
                    },
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: note,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.surfaceContainerLow,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              hintText: 'Add any details...',
            ),
            style: GoogleFonts.manrope(fontSize: 13),
            onChanged: (val) => onCustomTriggerTextChanged(trigId, val),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherTriggerDetailCard(BuildContext context, String trigId, String name, String value, IconData icon) {
    final trigColor = _getTriggerColor(name);
    final trigBg = trigColor.withValues(alpha: 0.1);
    final values = _getTriggerValues(name);
    final isSelectedValue = values.contains(value) ? value : values[values.length ~/ 2];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
                decoration: BoxDecoration(color: trigBg, shape: BoxShape.circle),
                child: Icon(icon, color: trigColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
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
          const SizedBox(height: 12),
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
                // White sliding thumb selector
                AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: isSelectedValue == values[0]
                      ? Alignment.centerLeft
                      : isSelectedValue == values[1]
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
                  children: values.map((val) {
                    final isSelected = isSelectedValue == val;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onCustomTriggerTextChanged(trigId, val),
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_getEmojiForValue(name, val), style: const TextStyle(fontSize: 18)),
                              const SizedBox(height: 2),
                              Text(
                                val,
                                style: GoogleFonts.manrope(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppTheme.primary : const Color(0xFF8A817C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getTriggerValues(String name) {
    switch (name.toLowerCase()) {
      case 'caffeine':
        return ['1 Cup', '2 Cups', '3 Cups'];
      case 'alcohol':
        return ['1 Glass', '2 Glasses', '3 Glasses'];
      case 'stress':
        return ['Calm', 'Moderate', 'High'];
      case 'poor sleep':
      case 'lack of sleep':
      case 'dehydration':
        return ['Mild', 'Moderate', 'Severe'];
      case 'exercise':
        return ['Light', 'Moderate', 'Intense'];
      case 'weather':
        return ['Sunny', 'Humid', 'Cold/Change'];
      case 'foods':
      case 'spicy food':
        return ['Low', 'Moderate', 'High'];
      case 'smoking':
      case 'smoking/tobacco':
        return ['Low', 'Moderate', 'High'];
      case 'travel':
        return ['Short', 'Medium', 'Long'];
      case 'work':
      case 'overworking':
        return ['1-2 hours', '3-4 hours', '5+ hours'];
      case 'sugar':
      case 'sugar & sweets':
        return ['Low', 'Moderate', 'High'];
      case 'relaxation':
      case 'lack of rest':
        return ['Low', 'Moderate', 'High'];
      default:
        return ['Low', 'Moderate', 'High'];
    }
  }

  Color _getTriggerColor(String name) {
    switch (name.toLowerCase()) {
      case 'stress':
        return const Color(0xFFB8A7C5); // brand-lavender
      case 'caffeine':
        return const Color(0xFF9B8B7E);
      case 'alcohol':
        return const Color(0xFFD4A5A5); // brand-rose
      case 'sugar':
      case 'sugar & sweets':
        return const Color(0xFFA9B388);
      case 'lack of sleep':
      case 'poor sleep':
        return const Color(0xFFA7C5D8);
      case 'spicy food':
      case 'foods':
        return const Color(0xFFE5989B);
      default:
        return const Color(0xFF8EB8B5); // brand-teal
    }
  }

  String _getEmojiForValue(String name, String value) {
    final nameLower = name.toLowerCase();
    final valLower = value.toLowerCase();

    if (nameLower == 'stress') {
      if (valLower == 'calm') return '😊';
      if (valLower == 'moderate') return '😐';
      if (valLower == 'high') return '😟';
    }
    if (nameLower == 'poor sleep' || nameLower == 'lack of sleep') {
      if (valLower == 'mild') return '😊';
      if (valLower == 'moderate') return '😐';
      if (valLower == 'severe') return '😟';
    }
    if (nameLower == 'dehydration') {
      if (valLower == 'mild') return '😊';
      if (valLower == 'moderate') return '😐';
      if (valLower == 'severe') return '😟';
    }
    if (nameLower == 'exercise') {
      if (valLower == 'light') return '🚶';
      if (valLower == 'moderate') return '🏃';
      if (valLower == 'intense') return '🏋️';
    }
    if (nameLower == 'weather') {
      if (valLower == 'sunny') return '☀️';
      if (valLower == 'humid') return '☁️';
      if (valLower == 'cold/change' || valLower.contains('cold')) return '❄️';
    }
    if (nameLower == 'travel') {
      if (valLower == 'short') return '🚗';
      if (valLower == 'medium') return '✈️';
      if (valLower == 'long') return '🌍';
    }
    if (nameLower == 'work' || nameLower == 'overworking') {
      if (valLower == '1-2 hours') return '⌚';
      if (valLower == '3-4 hours') return '⏰';
      if (valLower == '5+ hours') return '⏳';
    }

    switch (valLower) {
      case 'calm':
      case 'mild':
      case 'low':
        return '😊';
      case 'moderate':
        return '😐';
      case 'high':
      case 'severe':
      case 'intense':
        return '😟';
      case 'light':
        return '🚶';
      case 'sunny':
        return '☀️';
      case 'humid':
        return '☁️';
      case 'cold/change':
        return '❄️';
      case 'short':
        return '🚗';
      case 'medium':
        return '✈️';
      case 'long':
        return '🌍';
      case '1-2 hours':
        return '⌚';
      case '3-4 hours':
        return '⏰';
      case '5+ hours':
        return '⏳';
      default:
        return '✨';
    }
  }
}
