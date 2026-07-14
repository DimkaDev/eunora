/// HRT Drug Library — UK + US brands, combined-product support.
///
/// Sources:
/// - NHSBSA HRT Prescribing Statistics England 2024/25
/// - NHS.uk brand listings + BMS Prescribing Guidance 2026
/// - GoodRx prescribing/popularity data 2025/26
/// - Market-supply reporting (Sandoz/Viatris/Amneal post-Climara discontinuation)
library hrt_drug_library;

enum HrtDrugCategory {
  systemicEstrogen, // patch, gel, spray, oral tablet — oestrogen only
  combined, // single product containing oestrogen + progestogen
  progestogenOnly, // taken alongside a separate oestrogen product
  vaginalLocal, // low-dose local oestrogen, not systemic
}

enum HrtMarket { uk, us, both }

class HrtDrugDefinition {
  final String name;
  final HrtDrugCategory category;

  /// Must map to existing MedicationType values: patch, pill, gel, cream, other.
  /// The spec lists: patch, tablet, gel, spray, pessary, implant, ring.
  /// This app maps: tablet→pill, spray/pessary/ring/implant→other.
  final List<String> commonForms;
  final bool isCombinedProduct;
  final HrtMarket market;

  /// Still shown in autocomplete for existing users mid-treatment;
  /// excluded from cold-start Quick-Add ranking.
  final bool isDiscontinued;

  const HrtDrugDefinition({
    required this.name,
    required this.category,
    required this.commonForms,
    required this.market,
    this.isCombinedProduct = false,
    this.isDiscontinued = false,
  });
}

/// Ordered by real-world prescribing frequency.
/// This ordering drives cold-start Quick-Add ranking before per-user
/// personalization takes over.
const List<HrtDrugDefinition> kHrtDrugLibrary = [
  // ===== SYSTEMIC ESTROGEN — UK =====
  HrtDrugDefinition(
    name: 'Estradiol',
    category: HrtDrugCategory.systemicEstrogen,
    commonForms: ['gel', 'patch', 'spray'],
    market: HrtMarket.both,
  ),
  HrtDrugDefinition(
    name: 'Oestrogel',
    category: HrtDrugCategory.systemicEstrogen,
    commonForms: ['gel'],
    market: HrtMarket.uk,
  ),
  HrtDrugDefinition(
    name: 'Evorel',
    category: HrtDrugCategory.systemicEstrogen,
    commonForms: ['patch'],
    market: HrtMarket.uk,
  ),
  HrtDrugDefinition(
    name: 'Estradot',
    category: HrtDrugCategory.systemicEstrogen,
    commonForms: ['patch'],
    market: HrtMarket.uk,
  ),
  HrtDrugDefinition(
    name: 'Sandrena',
    category: HrtDrugCategory.systemicEstrogen,
    commonForms: ['gel'],
    market: HrtMarket.uk,
  ),
  HrtDrugDefinition(
    name: 'Lenzetto',
    category: HrtDrugCategory.systemicEstrogen,
    commonForms: ['spray'],
    market: HrtMarket.uk,
  ),
  HrtDrugDefinition(
    name: 'Progynova',
    category: HrtDrugCategory.systemicEstrogen,
    commonForms: ['tablet'],
    market: HrtMarket.uk,
  ),
  HrtDrugDefinition(
    name: 'FemSeven',
    category: HrtDrugCategory.systemicEstrogen,
    commonForms: ['patch'],
    market: HrtMarket.uk,
  ),

  // ===== SYSTEMIC ESTROGEN — US =====
  HrtDrugDefinition(
    name: 'Vivelle-Dot',
    category: HrtDrugCategory.systemicEstrogen,
    commonForms: ['patch'],
    market: HrtMarket.us,
  ),
  HrtDrugDefinition(
    name: 'Minivelle',
    category: HrtDrugCategory.systemicEstrogen,
    commonForms: ['patch'],
    market: HrtMarket.us,
  ),
  // Bayer discontinued brand late 2023; generics still widely prescribed.
  // Kept in autocomplete for existing users, excluded from Quick-Add ranking.
  HrtDrugDefinition(
    name: 'Climara',
    category: HrtDrugCategory.systemicEstrogen,
    commonForms: ['patch'],
    market: HrtMarket.us,
    isDiscontinued: true,
  ),
  HrtDrugDefinition(
    name: 'EstroGel',
    category: HrtDrugCategory.systemicEstrogen,
    commonForms: ['gel'],
    market: HrtMarket.us,
  ),
  HrtDrugDefinition(
    name: 'Divigel',
    category: HrtDrugCategory.systemicEstrogen,
    commonForms: ['gel'],
    market: HrtMarket.us,
  ),
  HrtDrugDefinition(
    name: 'Elestrin',
    category: HrtDrugCategory.systemicEstrogen,
    commonForms: ['gel'],
    market: HrtMarket.us,
  ),
  HrtDrugDefinition(
    name: 'Evamist',
    category: HrtDrugCategory.systemicEstrogen,
    commonForms: ['spray'],
    market: HrtMarket.us,
  ),
  // Oral form only; Estrace vaginal cream is listed under vaginalLocal.
  HrtDrugDefinition(
    name: 'Estrace',
    category: HrtDrugCategory.systemicEstrogen,
    commonForms: ['tablet'],
    market: HrtMarket.us,
  ),
  // Conjugated equine estrogens, oral.
  HrtDrugDefinition(
    name: 'Premarin',
    category: HrtDrugCategory.systemicEstrogen,
    commonForms: ['tablet'],
    market: HrtMarket.both,
  ),
  HrtDrugDefinition(
    name: 'Menostar',
    category: HrtDrugCategory.systemicEstrogen,
    commonForms: ['patch'],
    market: HrtMarket.us,
  ),

  // ===== PROGESTOGEN-ONLY (paired manually with a separate systemic entry) =====
  HrtDrugDefinition(
    name: 'Utrogestan',
    category: HrtDrugCategory.progestogenOnly,
    commonForms: ['tablet', 'pessary'],
    market: HrtMarket.uk,
  ),
  // Oral micronized progesterone, US equivalent of Utrogestan.
  HrtDrugDefinition(
    name: 'Prometrium',
    category: HrtDrugCategory.progestogenOnly,
    commonForms: ['tablet'],
    market: HrtMarket.us,
  ),
  // IUS; mapped to 'other' form value (ring not in MedicationType).
  HrtDrugDefinition(
    name: 'Mirena',
    category: HrtDrugCategory.progestogenOnly,
    commonForms: ['ring'],
    market: HrtMarket.both,
  ),

  // ===== COMBINED PRODUCTS — UK (single entry = both hormones) =====
  HrtDrugDefinition(
    name: 'Evorel Conti',
    category: HrtDrugCategory.combined,
    commonForms: ['patch'],
    market: HrtMarket.uk,
    isCombinedProduct: true,
  ),
  HrtDrugDefinition(
    name: 'Femoston',
    category: HrtDrugCategory.combined,
    commonForms: ['tablet'],
    market: HrtMarket.uk,
    isCombinedProduct: true,
  ),
  HrtDrugDefinition(
    name: 'Femoston Conti',
    category: HrtDrugCategory.combined,
    commonForms: ['tablet'],
    market: HrtMarket.uk,
    isCombinedProduct: true,
  ),
  HrtDrugDefinition(
    name: 'FemSeven Conti',
    category: HrtDrugCategory.combined,
    commonForms: ['patch'],
    market: HrtMarket.uk,
    isCombinedProduct: true,
  ),
  HrtDrugDefinition(
    name: 'FemSeven Sequi',
    category: HrtDrugCategory.combined,
    commonForms: ['patch'],
    market: HrtMarket.uk,
    isCombinedProduct: true,
  ),
  HrtDrugDefinition(
    name: 'Kliovance',
    category: HrtDrugCategory.combined,
    commonForms: ['tablet'],
    market: HrtMarket.uk,
    isCombinedProduct: true,
  ),
  HrtDrugDefinition(
    name: 'Kliofem',
    category: HrtDrugCategory.combined,
    commonForms: ['tablet'],
    market: HrtMarket.uk,
    isCombinedProduct: true,
  ),
  HrtDrugDefinition(
    name: 'Elleste Duet',
    category: HrtDrugCategory.combined,
    commonForms: ['tablet'],
    market: HrtMarket.uk,
    isCombinedProduct: true,
  ),
  HrtDrugDefinition(
    name: 'Evorel Sequi',
    category: HrtDrugCategory.combined,
    commonForms: ['patch'],
    market: HrtMarket.uk,
    isCombinedProduct: true,
  ),
  HrtDrugDefinition(
    name: 'Novofem',
    category: HrtDrugCategory.combined,
    commonForms: ['tablet'],
    market: HrtMarket.uk,
    isCombinedProduct: true,
  ),

  // ===== COMBINED PRODUCTS — US =====
  // Conjugated estrogens + medroxyprogesterone.
  HrtDrugDefinition(
    name: 'Prempro',
    category: HrtDrugCategory.combined,
    commonForms: ['tablet'],
    market: HrtMarket.us,
    isCombinedProduct: true,
  ),
  // Estradiol + norethindrone, twice-weekly patch.
  HrtDrugDefinition(
    name: 'Combipatch',
    category: HrtDrugCategory.combined,
    commonForms: ['patch'],
    market: HrtMarket.us,
    isCombinedProduct: true,
  ),
  HrtDrugDefinition(
    name: 'Climara Pro',
    category: HrtDrugCategory.combined,
    commonForms: ['patch'],
    market: HrtMarket.us,
    isCombinedProduct: true,
  ),
  // Estradiol + micronized progesterone, oral.
  HrtDrugDefinition(
    name: 'Bijuve',
    category: HrtDrugCategory.combined,
    commonForms: ['tablet'],
    market: HrtMarket.both,
    isCombinedProduct: true,
  ),

  // ===== VAGINAL / LOCAL-ONLY (excluded from systemic trend correlation) =====
  HrtDrugDefinition(
    name: 'Ovestin',
    category: HrtDrugCategory.vaginalLocal,
    commonForms: ['pessary'],
    market: HrtMarket.uk,
  ),
  // Also marketed as Yuvafem in the US.
  HrtDrugDefinition(
    name: 'Vagifem',
    category: HrtDrugCategory.vaginalLocal,
    commonForms: ['pessary'],
    market: HrtMarket.both,
  ),
  HrtDrugDefinition(
    name: 'Gina',
    category: HrtDrugCategory.vaginalLocal,
    commonForms: ['pessary'],
    market: HrtMarket.uk,
  ),
  HrtDrugDefinition(
    name: 'Estring',
    category: HrtDrugCategory.vaginalLocal,
    commonForms: ['ring'],
    market: HrtMarket.both,
  ),
  HrtDrugDefinition(
    name: 'Estrace Vaginal Cream',
    category: HrtDrugCategory.vaginalLocal,
    commonForms: ['other'],
    market: HrtMarket.us,
  ),
  HrtDrugDefinition(
    name: 'Premarin Vaginal Cream',
    category: HrtDrugCategory.vaginalLocal,
    commonForms: ['other'],
    market: HrtMarket.us,
  ),
  HrtDrugDefinition(
    name: 'Imvexxy',
    category: HrtDrugCategory.vaginalLocal,
    commonForms: ['other'],
    market: HrtMarket.us,
  ),
  // Note: Femring delivers systemic-level dosing despite vaginal route, but
  // classified as vaginalLocal for correlation-exclusion per its primary labeling.
  HrtDrugDefinition(
    name: 'Femring',
    category: HrtDrugCategory.vaginalLocal,
    commonForms: ['other'],
    market: HrtMarket.us,
  ),
];
