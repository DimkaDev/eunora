import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/utils/animation_system.dart';
import '../providers/symptoms_provider.dart';
import '../providers/symptom_quick_access_provider.dart';
import '../../domain/models/symptom.dart';
import '../widgets/add_custom_symptom_modal.dart';

class SymptomLibraryPage extends ConsumerStatefulWidget {
  const SymptomLibraryPage({super.key});

  @override
  ConsumerState<SymptomLibraryPage> createState() => _SymptomLibraryPageState();
}

class _SymptomLibraryPageState extends ConsumerState<SymptomLibraryPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(symptomLibraryProvider);
    final notifier = ref.read(symptomsProvider.notifier);
    final qaNotifier = ref.read(symptomQuickAccessProvider.notifier);
    final qaState = ref.watch(symptomQuickAccessProvider);

    // Group symptoms by category
    final groupedSymptoms = <String, List<Symptom>>{};
    for (var symptom in library) {
      final category = symptom.category ?? 'Other';
      groupedSymptoms.putIfAbsent(category, () => []).add(symptom);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEF8F6).withOpacity(0.9),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFFD0C4BC).withOpacity(0.3),
            height: 1.0,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF67594E)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Symptom Library',
          style: TextStyle(
            fontFamily: 'Noto Serif',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF67594E),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
        child: Column(
          children: [
            _buildExplanationHeader(),
            _buildSearchBar(),
            const SizedBox(height: 24),
            ...groupedSymptoms.entries.map((entry) {
              return _buildCategorySection(
                context,
                entry.key,
                entry.value,
                notifier,
                qaNotifier,
                qaState,
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: const Color(0xFFFEF8F6),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF67594E),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'CONFIRM',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExplanationHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7E5).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD0C4BC).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF67594E), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Symptom Library',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D1B1A),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to log a symptom today. Hold any symptom to add or remove it from your quick-access grid.',
                  style: TextStyle(
                    color: const Color(0xFF4D453F).withOpacity(0.8),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7E5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(fontSize: 14, color: Color(0xFF1D1B1A)),
        decoration: InputDecoration(
          hintText: 'Search all symptoms...',
          hintStyle: TextStyle(color: const Color(0xFF4D453F).withOpacity(0.6)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF4D453F)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String title,
    List<Symptom> symptoms,
    SymptomsNotifier notifier,
    SymptomQuickAccessNotifier qaNotifier,
    SymptomQuickAccessState qaState,
  ) {
    final filtered = symptoms
        .where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Noto Serif',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF67594E),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(height: 1, color: const Color(0xFFD0C4BC)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: filtered.map((s) {
            final isFrequent = notifier.isFrequent(s.id);
            final isInQA =
                qaState.prefs[s.id] != kPrefRemoved &&
                (qaState.prefs[s.id] == kPrefOnboarding ||
                    qaState.prefs[s.id] == kPrefPromoted);
            return _buildLibrarySymptomCard(
              context,
              s,
              isFrequent,
              isInQA: isInQA,
              onTap: () => notifier.toggleFrequent(s.id),
              onLongPress: () =>
                  _handleLongPress(context, s, qaNotifier, isInQA),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  void _handleLongPress(
    BuildContext context,
    Symptom symptom,
    SymptomQuickAccessNotifier qaNotifier,
    bool isCurrentlyInQA,
  ) {
    // Core fixed pins cannot be removed by the user.
    if (kCoreFixedPins.contains(symptom.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${symptom.name} is always in quick access.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF67594E),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFFEF8F6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle indicator
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0C4BC),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  symptom.name,
                  style: const TextStyle(
                    fontFamily: 'Noto Serif',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D1B1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isCurrentlyInQA
                      ? 'Remove from your quick-access grid? You can re-add it later.'
                      : 'Add to your quick-access grid for faster logging.',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF4D453F).withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      if (isCurrentlyInQA) {
                        await qaNotifier.setRemoved(symptom.id);
                      } else {
                        await qaNotifier.setAdded(symptom.id);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentlyInQA
                          ? const Color(0xFFD0C4BC)
                          : const Color(0xFF67594E),
                      foregroundColor: isCurrentlyInQA
                          ? const Color(0xFF4D453F)
                          : Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isCurrentlyInQA
                          ? 'Remove from quick access'
                          : 'Add to quick access',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Color(0xFF9B8B7E)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLibrarySymptomCard(
    BuildContext context,
    Symptom symptom,
    bool isSelected, {
    required bool isInQA,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    final Color iconColor = symptom.getIconColor();
    final Color iconBgColor = iconColor.withOpacity(0.1);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Bounceable(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF9B8B7E)
                      : Colors.transparent,
                  width: isSelected ? 2 : 0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isSelected ? 0.08 : 0.03),
                    blurRadius: isSelected ? 15 : 10,
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
                      color: isSelected
                          ? iconColor.withOpacity(0.2)
                          : iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      symptom.getIconData(),
                      color: iconColor,
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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? const Color(0xFF1D1B1A)
                            : const Color(0xFF9B8B7E),
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Quick-access badge: sleek pill tag in the top-right corner
            if (isInQA)
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF67594E).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF67594E).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        size: 11,
                        color: Color(0xFF67594E),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'QUICK',
                        style: GoogleFonts.manrope(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF67594E),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
