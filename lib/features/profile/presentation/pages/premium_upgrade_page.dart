import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';

class PremiumUpgradePage extends StatefulWidget {
  const PremiumUpgradePage({super.key});

  @override
  State<PremiumUpgradePage> createState() => _PremiumUpgradePageState();
}

class _PremiumUpgradePageState extends State<PremiumUpgradePage> {
  // Billing cycle selection: 'annual' or 'monthly'
  String _billingCycle = 'annual';

  // FAQ expanded states
  bool _faqCancelExpanded = false;
  bool _faqLikeExpanded = true; // default expanded
  bool _faqSecureExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isAnnual = _billingCycle == 'annual';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5F0).withOpacity(0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF444444)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Upgrade to Premium',
          style: GoogleFonts.notoSerif(
            color: const Color(0xFF1C1917),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Title
            Text(
              'Unlock Premium',
              style: GoogleFonts.notoSerif(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1C1917),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Choose the analytical path with full data transparency and advanced health insights.',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  height: 1.5,
                  color: const Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),

            // Billing Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: const Color(0xFFE7E5E4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _billingCycle = 'monthly'),
                      borderRadius: BorderRadius.circular(9999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !isAnnual ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(9999),
                          boxShadow: !isAnnual
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Monthly',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: !isAnnual ? AppTheme.primary : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _billingCycle = 'annual'),
                      borderRadius: BorderRadius.circular(9999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isAnnual ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(9999),
                          boxShadow: isAnnual
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Annually',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isAnnual ? Colors.white : const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isAnnual ? const Color(0xFFE8F5E9) : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                'Save 33%',
                                style: GoogleFonts.manrope(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1B5E20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Subscription Action
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                elevation: 4,
                shadowColor: AppTheme.primary.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Starting Free Trial Checkout...')),
                );
              },
              child: Text(
                'Start 7-Day Free Trial',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isAnnual ? 'Then \$79.99/year. Cancel anytime.' : 'Then \$7.99/month. Cancel anytime.',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),

            // Feature Comparison Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE7E5E4)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.2),
                  1: FixedColumnWidth(64),
                  2: FixedColumnWidth(80),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE7E5E4))),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Text(
                          'Feature',
                          style: GoogleFonts.notoSerif(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1C1917),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'FREE',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: const Color(0xFF78716C),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        color: AppTheme.primary.withOpacity(0.04),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'PREMIUM',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppTheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  _buildComparisonRow('Symptom Tracking', '5 / day', 'Unlimited'),
                  _buildComparisonRowWithIcons('Core Visualizations', true, true),
                  _buildComparisonRowWithIcons('AI Trigger Correlations', false, true),
                  _buildComparisonRowWithIcons('Personalized Insights', false, true),
                  _buildComparisonRowWithIcons('PDF Doctor Reports', false, true),
                  _buildComparisonRowWithIcons('Apple Health Integration', false, true),
                  _buildComparisonRowWithIcons('Raw Data Export (CSV)', false, true),
                  _buildComparisonRowWithIcons('Priority Support', false, true),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // FAQs
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1C1917),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Collapsible FAQs
            _buildFaqItem(
              'Can I cancel anytime?',
              'Yes! You can manage or cancel your subscription easily through your App Store or Google Play Account settings at least 24 hours before your billing date.',
              _faqCancelExpanded,
              (val) => setState(() => _faqCancelExpanded = val),
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              "What if I don't like Premium?",
              "We offer a full 7-day trial for you to explore all features. If you decide it's not for you, just cancel before the trial ends and you won't be charged a cent.",
              _faqLikeExpanded,
              (val) => setState(() => _faqLikeExpanded = val),
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              'Is my payment secure?',
              'Absolutely. We process payments securely via Apple App Store and Google Play subscriptions, using enterprise-grade security.',
              _faqSecureExpanded,
              (val) => setState(() => _faqSecureExpanded = val),
            ),
            const SizedBox(height: 36),

            // Security Badges Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSecurityBadge(Icons.lock_outline, 'Secure\nPayment'),
                Container(width: 1, height: 40, color: const Color(0xFFE7E5E4)),
                _buildSecurityBadge(Icons.shield_outlined, 'Data\nPrivacy'),
                Container(width: 1, height: 40, color: const Color(0xFFE7E5E4)),
                _buildSecurityBadge(Icons.verified_user_outlined, 'Trial\nGuarantee'),
              ],
            ),
            const SizedBox(height: 48),

            // Legal Footers
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Privacy Policy',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                Text(
                  '•',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Terms of Service',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                Text(
                  '•',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Purchase restored successfully.')),
                    );
                  },
                  child: Text(
                    'Restore Purchase',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  TableRow _buildComparisonRow(String featureName, String freeVal, String premiumVal) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(
            featureName,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            freeVal,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: const Color(0xFF9CA3AF),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Container(
          color: AppTheme.primary.withOpacity(0.04),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            premiumVal,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  TableRow _buildComparisonRowWithIcons(String featureName, bool hasFree, bool hasPremium) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(
            featureName,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: hasFree
              ? const Icon(Icons.check, color: Color(0xFF9CA3AF), size: 18)
              : const Icon(Icons.remove, color: Color(0xFFD1D5DB), size: 18),
        ),
        Container(
          color: AppTheme.primary.withOpacity(0.04),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: hasPremium
              ? const Icon(Icons.check_circle, color: AppTheme.primary, size: 18)
              : const Icon(Icons.remove, color: Color(0xFFD1D5DB), size: 18),
        ),
      ],
    );
  }

  Widget _buildFaqItem(String question, String answer, bool isExpanded, ValueChanged<bool> onToggle) {
    return Container(
      decoration: BoxDecoration(
        color: isExpanded ? Colors.white : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? AppTheme.primary : const Color(0xFFE7E5E4),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => onToggle(!isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isExpanded ? AppTheme.primary : const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: isExpanded ? AppTheme.primary : const Color(0xFF9CA3AF),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  height: 1.5,
                  color: const Color(0xFF4B5563),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSecurityBadge(IconData icon, String text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF9CA3AF), size: 24),
        const SizedBox(height: 6),
        Text(
          text,
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF6B7280),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
