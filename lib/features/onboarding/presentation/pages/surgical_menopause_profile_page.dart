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
                Text(
                  'Surgical Menopause Info',
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
              'Surgical menopause occurs after surgical removal of the ovaries. Because it triggers an immediate hormonal decline compared to natural transition, tracking procedure details and postoperative HRT helps Eunora customize symptom progression paths.',
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
                  subtitle: 'SURGICAL MENOPAUSE',
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
                        _buildProcedureDateSection(),
                        const SizedBox(height: 24),
                        _buildProcedureTypeSection(),
                        const SizedBox(height: 24),
                        _buildHRTSection(),
                        const SizedBox(height: 24),
                        _buildFeelingSection(),
                        const SizedBox(height: 24),
                        _buildNoteBox(),
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
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Gradient Background Track
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: const LinearGradient(
                            colors: [Colors.red, Colors.yellow, Colors.green],
                          ),
                        ),
                      ),
                      // Slider
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: Colors.transparent,
                          thumbColor: const Color(0xFF4D453F),
                          overlayColor: const Color(0xFF4D453F).withOpacity(0.1),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 18),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
                        ),
                        child: Slider(
                          value: _overallFeeling,
                          min: 1,
                          max: 10,
                          onChanged: (val) => setState(() => _overallFeeling = val),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
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

  Widget _buildStickyFooter(BuildContext context) {
    final bool isReady = _procedureDate != null && _procedureType != null && _hrtStatus != null;
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
