import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eunora/core/utils/animation_system.dart';
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
    final notifier = ref.read(symptomsProvider.notifier);
    
    // Group symptoms by category
    final groupedSymptoms = <String, List<Symptom>>{};
    for (var symptom in library) {
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text(
              'CONFIRM',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ),
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
                    color: const Color(0xFF67594E).withOpacity(0.1), // primary container / 10
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Color(0xFF67594E)), // primary
                ),
                const SizedBox(width: 16),
                const Text(
                  'Add your own symptom',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF67594E),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF67594E)),
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
          childAspectRatio: 0.75,
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
    final Color iconColor = symptom.getIconColor();
    final Color iconBgColor = iconColor.withOpacity(0.1);

    return Bounceable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isSelected ? const Color(0xFF9B8B7E) : Colors.transparent,
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
                color: isSelected ? iconColor.withOpacity(0.2) : iconBgColor,
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
    );
  }
}
