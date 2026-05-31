import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/onboarding/presentation/widgets/onboarding_header.dart';
import 'package:eunora/features/onboarding/presentation/widgets/profile_radio_card.dart';

class PCOSProfilePage extends StatefulWidget {
  const PCOSProfilePage({super.key});

  @override
  State<PCOSProfilePage> createState() => _PCOSProfilePageState();
}

class _PCOSProfilePageState extends State<PCOSProfilePage> {
  final Set<String> _conditions = {};
  String? _cycleType;
  bool? _seesSpecialist;
  bool? _tryingToConceive;
  final Set<String> _interests = {};
  String? _hrtStatus;
  String? _hrtType;

  void _showInfoDialog() {
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
                Expanded(
                  child: Text(
                    'PCOS & Hormonal Conditions Info',
                    style: GoogleFonts.notoSerif(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1D1B1A),
                    ),
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
              'Polycystic Ovary Syndrome (PCOS) and other hormonal conditions require customized metabolic and cycle support. Logging whether you are trying to conceive and your current hormone treatments helps Eunora tailor metabolic health trackers and ovulation guidelines.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF4D453F),
                height: 1.5,
              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                OnboardingHeader(
                  currentStep: 1,
                  title: 'Health Profile',
                  subtitle: 'PCOS & HORMONE CONDITION',
                  onSkip: _showInfoDialog,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitleSection(),
                        const SizedBox(height: 32),
                        _buildConditionsSection(),
                        const SizedBox(height: 24),
                        _buildCyclesSection(),
                        const SizedBox(height: 24),
                        _buildSpecialistSection(),
                        const SizedBox(height: 24),
                        _buildHRTSection(),
                        const SizedBox(height: 24),
                        _buildConceiveSection(),
                        const SizedBox(height: 24),
                        _buildInterestsSection(),
                        const SizedBox(height: 160), // Space for footer
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

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your PCOS & Hormone Condition Profile',
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D1B1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Different conditions need different tracking. Let\'s customize your experience.',
          style: GoogleFonts.manrope(
            fontSize: 16,
            color: const Color(0xFF1D1B1A).withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionsSection() {
    final List<Map<String, String>> conditions = [
      {
        'id': 'pcos',
        'title': 'PCOS',
        'subtitle': 'Polycystic Ovary Syndrome involves hormonal imbalances that can affect your metabolism and regular cycle.'
      },
      {
        'id': 'pmdd',
        'title': 'PMDD',
        'subtitle': 'Premenstrual Dysphoric Disorder is a severe form of PMS that requires specialized mood and symptom support.'
      },
      {
        'id': 'thyroid',
        'title': 'Thyroid',
        'subtitle': 'Conditions like hypothyroidism can impact your energy levels and cycle regularity significantly.'
      },
      {
        'id': 'other',
        'title': 'Other',
        'subtitle': 'Select this if you are managing a condition not listed above.'
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Which condition are you managing?',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D1B1A),
            ),
          ),
          const SizedBox(height: 20),
          ...conditions.map((c) => _buildConditionCard(c)),
          if (_conditions.contains('other')) ...[
            const SizedBox(height: 16),
            Text(
              'SPECIFY YOUR CONDITION',
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: const Color(0xFF1D1B1A),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Please describe your condition here...',
                hintStyle: GoogleFonts.manrope(fontSize: 14, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFF2EDEA)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFF2EDEA)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConditionCard(Map<String, String> data) {
    final bool isSelected = _conditions.contains(data['id']);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _conditions.remove(data['id']);
          } else {
            _conditions.add(data['id']!);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFFBFA) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFF2EDEA),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title']!,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1D1B1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['subtitle']!,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: const Color(0xFF1D1B1A).withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : const Color(0xFFD0C4BC),
                ),
                color: isSelected ? AppTheme.primary : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCyclesSection() {
    final cycleTypes = [
      {'id': 'regular', 'name': 'REGULAR', 'icon': Icons.grid_view},
      {'id': 'heavy', 'name': 'HEAVY', 'icon': Icons.opacity},
      {'id': 'light', 'name': 'LIGHT', 'icon': Icons.circle_outlined},
      {'id': 'absent', 'name': 'ABSENT', 'icon': Icons.not_interested},
      {'id': 'constant', 'name': 'CONSTANT', 'icon': Icons.repeat},
      {'id': 'no_pattern', 'name': 'NO PATTERN', 'icon': Icons.grid_off},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How would you describe your cycles?',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D1B1A),
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: cycleTypes.length,
            itemBuilder: (context, index) {
              final type = cycleTypes[index];
              final isSelected = _cycleType == type['id'];
              return GestureDetector(
                onTap: () => setState(() => _cycleType = type['id'] as String),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF4D453F) : const Color(0xFFFFFBFA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(type['icon'] as IconData, color: isSelected ? Colors.white : const Color(0xFF9B8B7E), size: 24),
                      const SizedBox(height: 8),
                      Text(
                        type['name'] as String,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF1D1B1A),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialistSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Do you see a specialist?',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D1B1A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildToggleButton('Yes', _seesSpecialist == true, () => setState(() => _seesSpecialist = true), isPurple: true)),
              const SizedBox(width: 12),
              Expanded(child: _buildToggleButton('No', _seesSpecialist == false, () => setState(() => _seesSpecialist = false))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConceiveSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3EF).withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you trying to conceive?',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D1B1A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildToggleButton('Yes', _tryingToConceive == true, () => setState(() => _tryingToConceive = true), isGreen: true)),
              const SizedBox(width: 12),
              Expanded(child: _buildToggleButton('No', _tryingToConceive == false, () => setState(() => _tryingToConceive = false), isGreen: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String title, bool isSelected, VoidCallback onTap, {bool isPurple = false, bool isGreen = false}) {
    Color activeColor = isPurple ? const Color(0xFFE8E0F0) : (isGreen ? const Color(0xFF2E7D32) : const Color(0xFFF2EDEA));
    Color textColor = isSelected && isGreen ? Colors.white : const Color(0xFF1D1B1A);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : (isGreen ? Colors.white : const Color(0xFFF2EDEA).withOpacity(0.5)),
          borderRadius: BorderRadius.circular(100),
          border: isGreen ? Border.all(color: const Color(0xFF2E7D32).withOpacity(isSelected ? 1.0 : 0.2)) : null,
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHRTSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF2EDEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you currently on Hormone Replacement Therapy (HRT)?',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D1B1A),
            ),
          ),
          const SizedBox(height: 20),
          ProfileRadioCard(
            title: "Yes - I'm on HRT",
            isSelected: _hrtStatus == 'yes',
            onTap: () => setState(() => _hrtStatus = 'yes'),
          ),
          ProfileRadioCard(
            title: "No - I'm not taking hormones",
            isSelected: _hrtStatus == 'no',
            onTap: () => setState(() => _hrtStatus = 'no'),
          ),
          ProfileRadioCard(
            title: "I'm starting HRT soon",
            isSelected: _hrtStatus == 'soon',
            onTap: () => setState(() => _hrtStatus = 'soon'),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection() {
    final interests = [
      'Dietary management for PCOS',
      'Understanding hormone labs',
      'Exercise for insulin resistance'
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Information interests?',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D1B1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"Would you like information about your condition?"',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          ...interests.map((interest) => _buildInterestItem(interest)),
        ],
      ),
    );
  }

  Widget _buildInterestItem(String title) {
    final bool isSelected = _interests.contains(title);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _interests.remove(title);
          } else {
            _interests.add(title);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF1D1B1A).withOpacity(0.7),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primary : const Color(0xFFD0C4BC),
                ),
              ),
              child: isSelected ? const Center(child: Icon(Icons.check, size: 16, color: AppTheme.primary)) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyFooter(BuildContext context) {
    final bool isReady = _conditions.isNotEmpty &&
        _cycleType != null &&
        _seesSpecialist != null &&
        _tryingToConceive != null &&
        _hrtStatus != null;
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
                  onPressed: isReady ? () => context.push('/medications') : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF67594E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
