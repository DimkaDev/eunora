import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/onboarding/presentation/widgets/onboarding_header.dart';
import 'package:eunora/features/onboarding/presentation/widgets/profile_radio_card.dart';

class SurgicalMenopauseProfilePage extends StatefulWidget {
  const SurgicalMenopauseProfilePage({super.key});

  @override
  State<SurgicalMenopauseProfilePage> createState() => _SurgicalMenopauseProfilePageState();
}

class _SurgicalMenopauseProfilePageState extends State<SurgicalMenopauseProfilePage> {
  DateTime? _procedureDate;
  String? _procedureType;
  String? _hrtStatus;
  String? _hrtTiming;
  final Set<String> _selectedSymptoms = {};
  double _overallFeeling = 7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const OnboardingHeader(
              currentStep: 1,
              title: 'Health Profile',
              subtitle: 'SURGICAL MENOPAUSE',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleSection(),
                    const SizedBox(height: 32),
                    _buildProcedureDateSection(),
                    const SizedBox(height: 24),
                    _buildProcedureTypeSection(),
                    const SizedBox(height: 24),
                    _buildHRTSection(),
                    const SizedBox(height: 24),
                    _buildSymptomsSection(),
                    const SizedBox(height: 24),
                    _buildFeelingSection(),
                    const SizedBox(height: 24),
                    _buildNoteBox(),
                    const SizedBox(height: 40),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flash_on, size: 12, color: Color(0xFFBA1A1A)),
                  const SizedBox(width: 4),
                  Text(
                    'Rapid Onset',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFBA1A1A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Your Surgical Menopause Profile',
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D1B1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Surgical menopause has a different timeline and intensity. We\'re here to support that.',
          style: GoogleFonts.manrope(
            fontSize: 16,
            color: const Color(0xFF1D1B1A).withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildProcedureDateSection() {
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
            'WHEN DID YOU HAVE YOUR PROCEDURE?',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: const Color(0xFF1D1B1A),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _procedureDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF7F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _procedureDate == null ? 'MM/DD/YYYY' : '${_procedureDate!.month}/${_procedureDate!.day}/${_procedureDate!.year}',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: _procedureDate == null ? Colors.grey : const Color(0xFF1D1B1A),
                    ),
                  ),
                  const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us track symptom timelines',
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcedureTypeSection() {
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
            'WHAT TYPE OF PROCEDURE?',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: const Color(0xFF1D1B1A),
            ),
          ),
          const SizedBox(height: 20),
          ProfileRadioCard(
            title: 'Hysterectomy',
            isSelected: _procedureType == 'hysterectomy',
            onTap: () => setState(() => _procedureType = 'hysterectomy'),
          ),
          ProfileRadioCard(
            title: 'Bilateral oophorectomy',
            isSelected: _procedureType == 'oophorectomy',
            onTap: () => setState(() => _procedureType = 'oophorectomy'),
          ),
          ProfileRadioCard(
            title: 'Both',
            isSelected: _procedureType == 'both',
            onTap: () => setState(() => _procedureType = 'both'),
          ),
          ProfileRadioCard(
            title: 'Other',
            isSelected: _procedureType == 'other',
            onTap: () => setState(() => _procedureType = 'other'),
          ),
          ProfileRadioCard(
            title: 'Prefer not to say',
            isSelected: _procedureType == 'prefer_not',
            onTap: () => setState(() => _procedureType = 'prefer_not'),
          ),
        ],
      ),
    );
  }

  Widget _buildHRTSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E0F0).withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WERE YOU PRESCRIBED HRT AFTER YOUR SURGERY?',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: const Color(0xFF1D1B1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Selective hormonal replacement after surgical menopause is common.',
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: const Color(0xFF1D1B1A).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          _buildHrtOption('Yes - immediately', 'immediately'),
          _buildHrtOption('Yes - but delayed', 'delayed'),
          _buildHrtOption('No', 'no'),
          _buildHrtOption('Not yet', 'not_yet'),
          
          if (_hrtStatus != null && _hrtStatus!.startsWith('yes')) ...[
            const SizedBox(height: 16),
            Text(
              'When did you start HRT?',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1D1B1A),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _hrtTiming,
              items: ['Right after surgery', '1 month after', '3 months after', '6+ months after']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _hrtTiming = val),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHrtOption(String title, String value) {
    final bool isSelected = _hrtStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _hrtStatus = value),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primary : const Color(0xFFD0C4BC),
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF1D1B1A),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomsSection() {
    final symptoms = [
      {'name': 'Hot Flashes', 'icon': Icons.thermostat},
      {'name': 'Night Sweats', 'icon': Icons.nights_stay},
      {'name': 'Mood Swings', 'icon': Icons.mood_bad},
      {'name': 'Sleep issues', 'icon': Icons.bedtime},
      {'name': 'Brain Fog', 'icon': Icons.psychology},
      {'name': 'Joint Pain', 'icon': Icons.accessibility},
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
            'WHICH SYMPTOMS HIT HARDEST RIGHT NOW?',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: const Color(0xFF1D1B1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Surgical menopause often causes rapid-onset symptoms. Select all that apply.',
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: Colors.grey,
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
            itemCount: symptoms.length,
            itemBuilder: (context, index) {
              final s = symptoms[index];
              final String name = s['name'] as String;
              final isSelected = _selectedSymptoms.contains(name);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedSymptoms.remove(name);
                    } else {
                      _selectedSymptoms.add(name);
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFBF7F4) : const Color(0xFFFFFBFA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(s['icon'] as IconData, color: const Color(0xFF9B8B7E), size: 24),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: const Color(0xFF1D1B1A),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              hintText: 'Other symptoms...',
              hintStyle: GoogleFonts.manrope(fontSize: 14, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFF2EDEA).withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeelingSection() {
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
            'HOW ARE YOU FEELING OVERALL SINCE SURGERY?',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: const Color(0xFF1D1B1A),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              _overallFeeling.round().toString(),
              style: GoogleFonts.notoSerif(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1D1B1A),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.sentiment_very_dissatisfied, color: Colors.amber, size: 32),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    thumbColor: const Color(0xFF4D453F),
                    overlayColor: const Color(0xFF4D453F).withOpacity(0.1),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [Colors.red, Colors.yellow, Colors.green],
                      ),
                    ),
                    child: Slider(
                      value: _overallFeeling,
                      min: 1,
                      max: 10,
                      onChanged: (val) => setState(() => _overallFeeling = val),
                    ),
                  ),
                ),
              ),
              const Icon(Icons.sentiment_very_satisfied, color: Colors.amber, size: 32),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3EF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite, color: Color(0xFF2E7D32), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Surgical menopause is a significant transition. Eunora is here to help you understand and manage your symptoms during this time.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: const Color(0xFF2E7D32),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => context.go('/medications'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF67594E),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            elevation: 0,
          ),
          child: Text(
            'CONTINUE',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {},
          child: Text(
            'Get Support Resources',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D1B1A).withOpacity(0.5),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
