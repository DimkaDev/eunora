import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/features/onboarding/presentation/providers/menopause_stage_provider.dart';
import 'package:eunora/features/onboarding/presentation/pages/menopause_stage_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/perimenopause_profile_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/menopause_stage_profile_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/postmenopause_profile_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/surgical_menopause_profile_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/pcos_profile_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/your_medications_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/frequent_symptoms_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/other_medications_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/health_conditions_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/contraception_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/weight_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/lifestyle_habits_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/active_setup_page.dart';

import 'package:eunora/features/onboarding/presentation/providers/onboarding_profile_provider.dart';

class OnboardingFlowPage extends ConsumerStatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  ConsumerState<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends ConsumerState<OnboardingFlowPage> {
  late final PageController _pageController;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentStep);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingProfileProvider.notifier).loadOrCreate();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < 9) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stageState = ref.watch(menopauseStageProvider);
    final selectedStage = stageState.selectedStage;

    Widget buildStep1() {
      switch (selectedStage) {
        case MenopauseStage.irregular:
          return PerimenopauseProfilePage(onNext: _nextPage, onBack: _prevPage);
        case MenopauseStage.noPeriod12Months:
          return MenopauseStageProfilePage(onNext: _nextPage, onBack: _prevPage);
        case MenopauseStage.postmenopause:
          return PostmenopauseProfilePage(onNext: _nextPage, onBack: _prevPage);
        case MenopauseStage.surgical:
          return SurgicalMenopauseProfilePage(onNext: _nextPage, onBack: _prevPage);
        case MenopauseStage.pcos:
          return PCOSProfilePage(onNext: _nextPage, onBack: _prevPage);
        default:
          return const SizedBox();
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F6),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (page) {
          setState(() {
            _currentStep = page;
          });
        },
        children: [
          MenopauseStagePage(onNext: _nextPage, onBack: _prevPage),
          buildStep1(),
          YourMedicationsPage(onNext: _nextPage, onBack: _prevPage),
          FrequentSymptomsPage(onNext: _nextPage, onBack: _prevPage),
          OtherMedicationsPage(onNext: _nextPage, onBack: _prevPage),
          HealthConditionsPage(onNext: _nextPage, onBack: _prevPage),
          ContraceptionPage(onNext: _nextPage, onBack: _prevPage),
          WeightPage(onNext: _nextPage, onBack: _prevPage),
          LifestyleHabitsPage(onNext: _nextPage, onBack: _prevPage),
          ActiveSetupPage(onBack: _prevPage),
        ],
      ),
    );
  }
}
