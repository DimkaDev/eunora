import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/utils/animation_system.dart';

class TriggerDetailsStep extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
          if (trigId == 't_caffeine') {
            return _buildCaffeineDetailCard();
          } else if (trigId == 't_alcohol') {
            return _buildAlcoholDetailCard();
          } else if (trigId == 't_stress') {
            return _buildStressDetailCard(context);
          } else if (trigId == 't_foods') {
            return _buildFoodsDetailCard();
          } else {
            return _buildCustomTriggerDetailCard(trigId);
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
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Caffeine',
                    style: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'HOW MUCH TODAY?',
                    style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1),
                  ),
                ],
              ),
              const Icon(Icons.coffee, color: Color(0xFF9D675C)),
            ],
          ),
          const SizedBox(height: 20),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alcohol',
                    style: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CONSUMPTION LOG',
                    style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1),
                  ),
                ],
              ),
              const Icon(Icons.local_bar, color: Color(0xFF9D675C)),
            ],
          ),
          const SizedBox(height: 20),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stress',
                    style: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'INTENSITY LEVEL',
                    style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1),
                  ),
                ],
              ),
              const Icon(Icons.psychology, color: Color(0xFF9D675C)),
            ],
          ),
          const SizedBox(height: 20),
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
                              const Text('😊', style: TextStyle(fontSize: 18)),
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
                              const Text('😐', style: TextStyle(fontSize: 18)),
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
                              const Text('😟', style: TextStyle(fontSize: 18)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Foods',
                    style: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SPECIFIC TRIGGERS?',
                    style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1),
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
            const SizedBox(height: 16),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trigId,
                style: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
              ),
              const Icon(Icons.stars, color: Color(0xFF9D675C)),
            ],
          ),
          const SizedBox(height: 16),
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
}
