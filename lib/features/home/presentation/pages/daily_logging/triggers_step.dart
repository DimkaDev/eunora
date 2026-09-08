import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:eunora/features/onboarding/domain/models/trigger.dart';
import 'package:eunora/features/onboarding/presentation/providers/triggers_provider.dart';

class TriggersStep extends ConsumerWidget {
  final Set<String> selectedTriggerIds;
  final ValueChanged<String> onTriggerToggled;

  const TriggersStep({
    super.key,
    required this.selectedTriggerIds,
    required this.onTriggerToggled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(triggersProvider);
    final library = ref.watch(triggerLibraryProvider);

    // Get active triggers currently marked as tracked
    final activeTriggers = state.activeTriggerIds.map((id) {
      return library.firstWhere(
        (t) => t.id == id,
        orElse: () => TriggerOption(
          id: id,
          name: id.replaceAll('t_', '').toUpperCase(),
          description: '',
          iconName: 'warning_amber',
          category: 'Other',
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Daily Triggers',
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select all that apply to today\'s entry',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: AppTheme.primary.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 32),
        ...activeTriggers.map((trigger) {
          final trigId = trigger.id;
          final isSelected = selectedTriggerIds.contains(trigId);
          final name = trigger.name;
          final desc = trigger.description;
          final icon = trigger.getIconData();
          final bg = trigger.getIconColor().withOpacity(0.1);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Bounceable(
              scaleFactor: 0.96,
              duration: const Duration(milliseconds: 140),
              onTap: () {
                HapticFeedback.lightImpact();
                onTriggerToggled(trigId);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEDE8F4).withOpacity(0.4) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary.withOpacity(0.3) : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected ? trigger.getIconColor().withOpacity(0.22) : bg,
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedScale(
                        scale: isSelected ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        child: Icon(icon, color: trigger.getIconColor(), size: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppTheme.primary.withOpacity(0.6),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
         const SizedBox(height: 24),
       ],
     );
   }
 }
