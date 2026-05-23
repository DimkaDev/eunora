import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/onboarding_header.dart';

class HealthConditionsPage extends ConsumerStatefulWidget {
  const HealthConditionsPage({super.key});

  @override
  ConsumerState<HealthConditionsPage> createState() => _HealthConditionsPageState();
}

class _HealthConditionsPageState extends ConsumerState<HealthConditionsPage> {
  final Set<String> _selectedConditions = {};
  final TextEditingController _otherConditionController = TextEditingController();
  bool _noneOfAbove = false;

  @override
  void dispose() {
    _otherConditionController.dispose();
    super.dispose();
  }

  void _toggleCondition(String id) {
    setState(() {
      if (_selectedConditions.contains(id)) {
        _selectedConditions.remove(id);
      } else {
        _selectedConditions.add(id);
        _noneOfAbove = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F6), // surface
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const OnboardingHeader(currentStep: 6), // Step 7 of 11 (0-indexed 6)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(),
                        const SizedBox(height: 32),
                        _buildAccordionSection(
                          title: 'Chronic Illnesses',
                          icon: Icons.monitor_heart,
                          children: [
                            _buildConditionCard('heart_bp', 'Heart / BP', 'HRT Risk', Icons.favorite),
                            _buildConditionCard('diabetes', 'Diabetes', 'Blood Sugar', Icons.bloodtype),
                            _buildConditionCard('blood_clots', 'Blood Clots', 'DVT History', Icons.water_drop),
                            _buildConditionCard('thyroid', 'Thyroid', 'Interactions', Icons.monitor_heart),
                            _buildConditionCard('autoimmune', 'Autoimmune', 'Lupus, RA', Icons.vaccines),
                            _buildConditionCard('liver_disease', 'Liver Disease', 'Metabolism', Icons.medical_services),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildAccordionSection(
                          title: 'Reproductive Health',
                          icon: Icons.female,
                          children: [
                            _buildConditionCard('breast_cancer', 'Breast Cancer', 'Med Planning', Icons.medical_services),
                            _buildConditionCard('endometriosis', 'Endometriosis', 'Symptom Tracking', Icons.egg),
                            _buildConditionCard('uterine_fibroids', 'Uterine Fibroids', 'Pelvic Care', Icons.pregnant_woman),
                            _buildConditionCard('migraine_aura', 'Migraine+Aura', 'Estrogen Risk', Icons.psychology),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildAccordionSection(
                          title: 'Mental Wellbeing',
                          icon: Icons.psychology,
                          children: [
                            _buildConditionCard('depression', 'Depression', '', Icons.mood_bad),
                            _buildConditionCard('anxiety', 'Anxiety', '', Icons.self_improvement),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildAccordionSection(
                          title: 'Family History',
                          icon: Icons.people,
                          isGrid: false,
                          children: [
                            _buildListCondition('family_breast_cancer', 'Family history of breast cancer'),
                            _buildListCondition('family_early_menopause', 'Family history of early menopause'),
                            _buildListCondition('family_blood_clots', 'Family history of blood clots'),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildOtherSection(),
                        const SizedBox(height: 24),
                        _buildInfoCard(),
                        const SizedBox(height: 160), // Footer space
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildStickyFooter(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HEALTH CONDITIONS & MEDICAL HISTORY',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: const Color(0xFF1D1B1A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select any conditions that apply. This helps personalize your MenoSync experience.',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            color: const Color(0xFF4D453F),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAccordionSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool isGrid = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F2F0), // surface-container-low
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF7F756E).withOpacity(0.1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: title == 'Chronic Illnesses',
          leading: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Icon(icon, color: const Color(0xFF67594E), size: 20),
          ),
          title: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Color(0xFF1D1B1A),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: isGrid
                  ? GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: children,
                    )
                  : Column(children: children),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionCard(String id, String title, String subtitle, IconData icon) {
    final isSelected = _selectedConditions.contains(id);
    return GestureDetector(
      onTap: () => _toggleCondition(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8F2F0) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF67594E) : const Color(0xFFF8F2F0),
            width: 2,
          ),
          boxShadow: isSelected ? null : [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Stack(
          children: [
            if (isSelected)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.check_circle, color: Color(0xFF67594E), size: 16),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? const Color(0xFF67594E) : const Color(0xFF7F756E).withOpacity(0.5),
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1D1B1A),
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        color: const Color(0xFF4D453F).withOpacity(0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCondition(String id, String label) {
    final isSelected = _selectedConditions.contains(id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _toggleCondition(id),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF67594E) : const Color(0xFFF8F2F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF67594E) : const Color(0xFFD0C4BC),
                    width: 2,
                  ),
                  color: isSelected ? const Color(0xFF67594E) : Colors.transparent,
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF1D1B1A)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtherSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F2F0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF7F756E).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _selectedConditions.contains('other'),
                onChanged: (val) {
                  if (val == true) {
                    _toggleCondition('other');
                  } else {
                    _selectedConditions.remove('other');
                    setState(() {});
                  }
                },
                activeColor: const Color(0xFF67594E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              const Text(
                'OTHER CONDITION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
            ],
          ),
          if (_selectedConditions.contains('other'))
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 8),
              child: TextField(
                controller: _otherConditionController,
                maxLines: 2,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Briefly detail your health experience...',
                  hintStyle: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
          const Divider(height: 32),
          GestureDetector(
            onTap: () {
              setState(() {
                _noneOfAbove = !_noneOfAbove;
                if (_noneOfAbove) {
                  _selectedConditions.clear();
                  _otherConditionController.clear();
                }
              });
            },
            child: Row(
              children: [
                Checkbox(
                  value: _noneOfAbove,
                  onChanged: (val) {
                    setState(() {
                      _noneOfAbove = val ?? false;
                      if (_noneOfAbove) {
                        _selectedConditions.clear();
                        _otherConditionController.clear();
                      }
                    });
                  },
                  activeColor: const Color(0xFF67594E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                const Expanded(
                  child: Text(
                    'None of the above / Prefer not to disclose',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF4D453F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFF67594E), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'These conditions don\'t disqualify you from using MenoSync. They help us provide safe guidance and encourage conversation with your care provider.',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Color(0xFF4D453F),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyFooter(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => context.push('/contraception_screening'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF67594E),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Continue', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push('/contraception_screening'),
              child: const Text(
                'I\'d rather not share this right now',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4D453F),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
