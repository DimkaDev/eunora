import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:eunora/core/theme/app_theme.dart';
import '../widgets/onboarding_header.dart';
import '../providers/onboarding_profile_provider.dart';

class HealthConditionsPage extends ConsumerStatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  const HealthConditionsPage({super.key, this.onNext, this.onBack});

  @override
  ConsumerState<HealthConditionsPage> createState() => _HealthConditionsPageState();
}

class _HealthConditionsPageState extends ConsumerState<HealthConditionsPage> {
  final Set<String> _selectedConditions = {};
  final TextEditingController _otherConditionController = TextEditingController();
  bool _noneOfAbove = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(onboardingProfileProvider);
      if (profile != null) {
        setState(() {
          _selectedConditions.addAll(profile.healthConditions);
          _otherConditionController.text = profile.healthConditionsOther ?? '';
          _noneOfAbove = profile.noneOfAboveConditions ?? false;
        });
      }
    });
  }

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
                OnboardingHeader(
                  currentStep: 5,
                  subtitle: 'HEALTH CONDITIONS',
                  onBack: widget.onBack,
                  onSkip: () => _showInfoDialog(context),
                ),
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
          'Health Conditions & Medical History',
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D1B1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select any conditions that apply. This helps personalize your Eunora experience.',
          style: GoogleFonts.manrope(
            fontSize: 16,
            color: const Color(0xFF1D1B1A).withOpacity(0.6),
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
    Color iconColor;
    switch (id) {
      case 'heart_bp':
      case 'blood_clots':
      case 'breast_cancer':
        iconColor = const Color(0xFFD4A5A5);
        break;
      case 'diabetes':
      case 'autoimmune':
        iconColor = const Color(0xFFA9B388);
        break;
      case 'thyroid':
      case 'liver_disease':
        iconColor = const Color(0xFF8EB8B5);
        break;
      case 'endometriosis':
      case 'uterine_fibroids':
        iconColor = const Color(0xFFB8A7C5);
        break;
      case 'migraine_aura':
      case 'depression':
      case 'anxiety':
        iconColor = const Color(0xFFA7C5D8);
        break;
      default:
        iconColor = const Color(0xFF9B8B7E);
    }

    return Bounceable(
      onTap: () => _toggleCondition(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(24),
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
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                top: 10,
                right: 10,
                child: Icon(Icons.check_circle, color: iconColor, size: 16),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? iconColor.withOpacity(0.2) : iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF1D1B1A) : const Color(0xFF9B8B7E),
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        color: isSelected ? const Color(0xFF4D453F) : const Color(0xFF9B8B7E).withOpacity(0.7),
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
      child: Bounceable(
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
              AnimatedCheckbox(
                value: _selectedConditions.contains('other'),
                onChanged: (val) {
                  if (val) {
                    _toggleCondition('other');
                  } else {
                    _selectedConditions.remove('other');
                    setState(() {});
                  }
                },
                activeColor: const Color(0xFF67594E),
              ),
              const SizedBox(width: 12),
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
                AnimatedCheckbox(
                  value: _noneOfAbove,
                  onChanged: (val) {
                    setState(() {
                      _noneOfAbove = val;
                      if (_noneOfAbove) {
                        _selectedConditions.clear();
                        _otherConditionController.clear();
                      }
                    });
                  },
                  activeColor: const Color(0xFF67594E),
                ),
                const SizedBox(width: 12),
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
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'These conditions don\'t disqualify you from using Eunora. They help us provide safe guidance and encourage conversation with your care provider.',
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 10,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFEF8F6).withOpacity(0),
                  const Color(0xFFFEF8F6),
                ],
              ),
            ),
          ),
          Container(
            color: const Color(0xFFFEF8F6),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 ElevatedButton(
                  onPressed: () {
                    ref.read(onboardingProfileProvider.notifier).updateProfile((p) => p.copyWith(
                      healthConditions: _selectedConditions.toList(),
                      healthConditionsOther: _otherConditionController.text,
                      noneOfAboveConditions: _noneOfAbove,
                    ));
                    if (widget.onNext != null) {
                      widget.onNext!();
                    } else {
                      context.push('/contraception_screening');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF67594E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('CONTINUE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    ref.read(onboardingProfileProvider.notifier).updateProfile((p) => p.copyWith(
                      healthConditions: const [],
                      healthConditionsOther: '',
                      noneOfAboveConditions: true,
                    ));
                    if (widget.onNext != null) {
                      widget.onNext!();
                    } else {
                      context.push('/contraception_screening');
                    }
                  },
                  child: Text(
                    'SKIP THIS STEP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4D453F).withOpacity(0.6),
                      letterSpacing: 1,
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

  void _showInfoDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFEF8F6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Medical History Info',
                  style: GoogleFonts.notoSerif(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1D1B1A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF9B8B7E)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Your overall medical history helps us customize your experience and identify any safe guidance precautions.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF4D453F),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoRow(
              icon: Icons.monitor_heart,
              title: 'Chronic Conditions',
              desc: 'Blood pressure, cardiovascular health, thyroid levels, and diabetes affect how your body responds to menopause.',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.family_restroom,
              title: 'Family History',
              desc: 'Genetic factors can influence early menopause, bone density, or risks related to hormonal treatments.',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.shield,
              title: 'Personalized Guidance',
              desc: 'These details help compile a comprehensive health profile that you can export for your doctor.',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Got it',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF1D1B1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: const Color(0xFF4D453F),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
