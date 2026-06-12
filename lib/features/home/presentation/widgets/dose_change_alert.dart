import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

class DoseChangeAlert extends StatefulWidget {
  final Map<String, dynamic> change;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const DoseChangeAlert({
    super.key,
    required this.change,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<DoseChangeAlert> createState() => _DoseChangeAlertState();
}

class _DoseChangeAlertState extends State<DoseChangeAlert> {
  bool _showExplanation = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.change['name'] ?? '';
    final oldDose = widget.change['oldDose'] ?? '';
    final newDose = widget.change['newDose'] ?? '';

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            maxWidth: 400,
            minHeight: 520,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D1B1A).withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Icon
                  const Icon(
                    Icons.help_outline_rounded,
                    color: Color(0xFF9B8B7E),
                    size: 38,
                  ),
                  const SizedBox(height: 16),
                  // Alert Title
                  Text(
                    'We Noticed a Dose Change',
                    style: GoogleFonts.notoSerif(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      color: const Color(0xFF1D1B1A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  // Alert Description
                  Text.rich(
                    TextSpan(
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        height: 1.5,
                        color: const Color(0xFF4D453F),
                      ),
                      children: [
                        const TextSpan(text: 'Your last entry for '),
                        TextSpan(
                          text: name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' showed $oldDose. Your new entry shows $newDose. Did your doctor change your dose?'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  // Visual Comparison
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F2F0).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFD0C4BC).withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Before
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'BEFORE',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: const Color(0xFF7F756E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                oldDose,
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF7F756E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Arrow
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF9B8B7E),
                          size: 22,
                        ),
                        // After
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'AFTER',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: const Color(0xFF9B8B7E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                newDose,
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF9B8B7E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Explanation Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDDDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: const Border(
                        left: BorderSide(
                          color: Color(0x33655A6E),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Tracking dose changes helps us show you the impact on your symptoms. We\'ll track the next 14 days and compare.',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                        color: const Color(0xFF6C6074),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Button Section
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: widget.onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9B8B7E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Yes, My Dose Changed',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFD0C4BC),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'No, That Was a Mistake',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1D1B1A),
                        ),
                      ),
                    ),
                  ),
                  // Optional Link / Info Expansion
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showExplanation = !_showExplanation;
                      });
                    },
                    child: Text(
                      'How does before/after comparison work?',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9B8B7E),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  if (_showExplanation) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE7E5).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'We\'ll track your symptoms for 14 days after your dose change. Then we\'ll show you patterns like "hot flashes decreased by 30%". This helps you and your doctor see if the new dose is working.',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          height: 1.4,
                          color: const Color(0xFF4D453F),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
