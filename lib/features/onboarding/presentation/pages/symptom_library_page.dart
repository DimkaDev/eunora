import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/symptoms_provider.dart';
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
    final symptomsState = ref.watch(symptomsProvider);
    final notifier = ref.read(symptomsProvider.notifier);
    
    // Group symptoms by category
    final groupedSymptoms = <String, List<Symptom>>{};
    for (var symptom in library) {
      if (symptom.category == 'Common') continue; // Skip the "Common" mapping category
      final category = symptom.category ?? 'Other';
      groupedSymptoms.putIfAbsent(category, () => []).add(symptom);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F6), // background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEF8F6).withOpacity(0.9),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFD0C4BC).withOpacity(0.3), height: 1.0), // border-b
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF67594E)), // primary
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
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF67594E)),
            onPressed: () {
              // Toggle search focus or show search bar
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 24),
            _buildAddCustomSymptomButton(context),
            const SizedBox(height: 32),
            ...groupedSymptoms.entries.map((entry) {
              return _buildCategorySection(context, entry.key, entry.value, notifier);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7E5), // surface-container-high
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildAddCustomSymptomButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const AddCustomSymptomModal(),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD0C4BC)), // outline-variant
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9D675C).withOpacity(0.1), // tertiary-container / 10
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Color(0xFF814F45)), // tertiary
                ),
                const SizedBox(width: 16),
                const Text(
                  '+ Add your own symptom',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF814F45),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF814F45)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, String title, List<Symptom> symptoms, SymptomsNotifier notifier) {
    // Filter symptoms if search is active
    final filtered = symptoms.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
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
            Expanded(child: Container(height: 1, color: const Color(0xFFD0C4BC))),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: filtered.map((s) {
            final isFrequent = notifier.isFrequent(s.id);
            return _buildLibrarySymptomCard(context, s, isFrequent, () => notifier.toggleFrequent(s.id));
          }).toList(),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildLibrarySymptomCard(BuildContext context, Symptom symptom, bool isSelected, VoidCallback onTap) {
    // Style variables
    Color bgColor = const Color(0xFFFFFFFF);
    Color borderColor = const Color(0xFFD0C4BC);
    Color iconBgColor = const Color(0xFFE7E1DF); // surface-variant default
    Color iconColor = const Color(0xFF4D453F); // on-surface-variant default
    Color textColor = const Color(0xFF1D1B1A); // on-surface
    FontWeight textWeight = FontWeight.w600;

    if (isSelected) {
      bgColor = const Color(0xFFF2DFD0); // primary-fixed
      borderColor = const Color(0xFF67594E).withOpacity(0.2); // primary / 20
      iconBgColor = const Color(0xFF67594E).withOpacity(0.1);
      iconColor = const Color(0xFF67594E);
      textColor = const Color(0xFF67594E);
      textWeight = FontWeight.bold;
    } else {
      // Determine colors based on category to match design subtly
      switch (symptom.category) {
        case 'Vasomotor Symptoms':
        case 'Emotional & Cognitive':
          if (symptom.name == 'Night sweats' || symptom.name == 'Mood swings') {
            iconBgColor = const Color(0xFFEDDDF5); // secondary-container
            iconColor = const Color(0xFF655A6E); // secondary
          } else if (symptom.name == 'Anxiety' || symptom.name == 'Memory lapses') {
            iconBgColor = const Color(0xFF9D675C).withOpacity(0.2); // tertiary-container
            iconColor = const Color(0xFF814F45); // tertiary
          }
          break;
        case 'Physical Wellbeing':
          if (symptom.name == 'Joint pain' || symptom.name == 'Dry skin') {
            iconBgColor = const Color(0xFFEDDDF5);
            iconColor = const Color(0xFF655A6E);
          } else if (symptom.name == 'Heart palpitation') {
            iconBgColor = const Color(0xFF9D675C).withOpacity(0.2);
            iconColor = const Color(0xFF814F45);
          }
          break;
        case 'Sleep & Energy':
          if (symptom.name == 'Low energy') {
            iconBgColor = const Color(0xFFEDDDF5);
            iconColor = const Color(0xFF655A6E);
          } else if (symptom.name == 'Waking night') {
            iconBgColor = const Color(0xFF9D675C).withOpacity(0.2);
            iconColor = const Color(0xFF814F45);
          }
          break;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.check_circle, color: const Color(0xFF67594E), size: 18),
              )
            else
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor),
                  ),
                ),
              ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIconData(symptom.iconName),
                        color: iconColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      symptom.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: textWeight,
                        color: textColor,
                        height: 1.1,
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

  IconData _getIconData(String name) {
    switch (name) {
      case 'thermostat': return Icons.thermostat;
      case 'bedtime': return Icons.bedtime;
      case 'ac_unit': return Icons.ac_unit;
      case 'psychology': return Icons.psychology;
      case 'sentiment_dissatisfied': return Icons.sentiment_dissatisfied;
      case 'reorder': return Icons.reorder;
      case 'cloud': return Icons.cloud;
      case 'settings_backup_restore': return Icons.settings_backup_restore;
      case 'accessibility_new': return Icons.accessibility_new;
      case 'skull': return Icons.sentiment_neutral; // Approximation
      case 'battery_low': return Icons.battery_0_bar;
      case 'favorite': return Icons.favorite;
      case 'dry_cleaning': return Icons.dry_cleaning;
      case 'bed': return Icons.bed;
      case 'alarm_on': return Icons.alarm_on;
      case 'bolt': return Icons.bolt;
      default: return Icons.medical_services;
    }
  }
}
