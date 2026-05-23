import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // FAQ data model
  final List<Map<String, String>> _allFaqs = [
    {
      'question': 'How do I track my symptoms daily?',
      'answer': 'Simply tap the \'+\' icon on your home dashboard. You can select symptoms, intensity levels, and add personal notes to your journal.'
    },
    {
      'question': 'Is my health data private and secure?',
      'answer': 'Yes, MenoSync encrypts your health data. Only you have access to it, and you can download or delete your records at any time from Settings.'
    },
    {
      'question': 'Can I export my data for my doctor?',
      'answer': 'Absolutely! Go to Profile > Download Your Data to export your records as a CSV, or use the Passport tab to generate a clinical PDF report.'
    },
    {
      'question': 'How does MenoSync predict cycles?',
      'answer': 'MenoSync uses advanced algorithms to track your historical symptom patterns and predict cycle phases, even during perimenopause.'
    },
    {
      'question': 'What are "Insights" and how do they help?',
      'answer': 'Insights are daily trends and medical updates generated based on your symptoms, helping you understand triggers and cycle changes.'
    },
    {
      'question': 'How do I sync with Apple Health?',
      'answer': 'Go to Profile > Integrations and toggle the Apple Health switch. Allow MenoSync access when prompted on your device.'
    },
    {
      'question': 'Can I change my notification settings?',
      'answer': 'Yes, tap Notifications in Settings to configure your reminder times for HRT doses and daily symptom journals.'
    },
    {
      'question': 'Is MenoSync suitable for perimenopause?',
      'answer': 'Yes! MenoSync is designed specifically for all stages, including perimenopause, menopause transition, and postmenopause.'
    },
  ];

  // Map to track expanded FAQs
  final Map<int, bool> _expandedFaqs = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter FAQs based on query
    final filteredFaqs = _allFaqs.where((faq) {
      final q = faq['question']!.toLowerCase();
      final a = faq['answer']!.toLowerCase();
      return q.contains(_searchQuery) || a.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface.withOpacity(0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help & Support',
              style: GoogleFonts.notoSerif(
                color: AppTheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Find answers and get help when you need it',
              style: GoogleFonts.manrope(
                color: AppTheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.primary),
            onPressed: () {
              // Focus search bar
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section 1: Search Bar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.onSurface.withOpacity(0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppTheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.manrope(color: AppTheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Search FAQs...',
                          hintStyle: GoogleFonts.manrope(
                            color: AppTheme.outline.withOpacity(0.6),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 16, color: AppTheme.outline),
                        onPressed: () => _searchController.clear(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Section 2: FAQ Accordions
            Text(
              'FREQUENTLY ASKED QUESTIONS',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            filteredFaqs.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No matching FAQs found.',
                      style: GoogleFonts.manrope(
                        color: AppTheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredFaqs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final faq = filteredFaqs[index];
                      // Find original index to maintain state mapping
                      final originalIndex = _allFaqs.indexOf(faq);
                      final isExpanded = _expandedFaqs[originalIndex] ?? false;

                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _expandedFaqs[originalIndex] = !isExpanded;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        faq['question']!,
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: AppTheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    AnimatedRotation(
                                      turns: isExpanded ? 0.5 : 0.0,
                                      duration: const Duration(milliseconds: 200),
                                      child: const Icon(
                                        Icons.expand_more,
                                        color: AppTheme.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isExpanded) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFDF9F7),
                                  border: Border(
                                    top: BorderSide(
                                      color: Color(0xFFF2EDEA),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Text(
                                    faq['answer']!,
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 32),

            // Section 3: Helpful Resources
            Text(
              'HELPFUL RESOURCES',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildResourceTile(
                    Icons.menu_book,
                    'Understanding Menopause Stages',
                    () {},
                  ),
                  const Divider(height: 1, color: AppTheme.surfaceContainerLow, indent: 20, endIndent: 20),
                  _buildResourceTile(
                    Icons.local_library,
                    'Nutrition & Hormonal Balance Guide',
                    () {},
                  ),
                  const Divider(height: 1, color: AppTheme.surfaceContainerLow, indent: 20, endIndent: 20),
                  _buildResourceTile(
                    Icons.play_circle,
                    'Video Tutorials: Getting Started',
                    () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Section 4: Contact Support Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.onSurface.withOpacity(0.02),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Still need help?',
                    style: GoogleFonts.notoSerif(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Our support team is here for you 24/7.',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final useHorizontalLayout = constraints.maxWidth > 400;
                      return useHorizontalLayout
                          ? Row(
                              children: [
                                Expanded(child: _buildChatButton()),
                                const SizedBox(width: 12),
                                Expanded(child: _buildEmailButton()),
                              ],
                            )
                          : Column(
                              children: [
                                _buildChatButton(),
                                const SizedBox(height: 12),
                                _buildEmailButton(),
                              ],
                            );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Section 5: Additional Links
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildLegalTile('Privacy Policy'),
                  const Divider(height: 1, color: AppTheme.surfaceContainerLow, indent: 16, endIndent: 16),
                  _buildLegalTile('Terms of Service'),
                  const Divider(height: 1, color: AppTheme.surfaceContainerLow, indent: 16, endIndent: 16),
                  _buildLegalTile('Read our Blog'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'MENOSYNC V2.4.0 • MADE WITH CARE',
              style: GoogleFonts.manrope(
                fontSize: 10,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
                color: AppTheme.outline.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceTile(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurface,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.outlineVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildChatButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
        ),
      ),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Starting Live Chat...')),
        );
      },
      icon: const Icon(Icons.chat, size: 18),
      label: Text(
        'Chat with Support',
        style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildEmailButton() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primary,
        side: const BorderSide(color: AppTheme.primary, width: 2),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
        ),
      ),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening Email Composer...')),
        );
      },
      icon: const Icon(Icons.mail, size: 18),
      label: Text(
        'Email Support',
        style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildLegalTile(String title) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title tapped')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const Icon(Icons.open_in_new, size: 16, color: AppTheme.outlineVariant),
          ],
        ),
      ),
    );
  }
}
