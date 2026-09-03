import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import 'first_vehicle_setup_screen.dart';

class OnboardingSlide {
  final String svgPath;
  final String title;
  final String description;

  const OnboardingSlide({
    required this.svgPath,
    required this.title,
    required this.description,
  });
}

/// Onboarding Screen with 3 Calm Technology & Offline First slides (DSS Section 10.1)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static const List<OnboardingSlide> _slides = [
    OnboardingSlide(
      svgPath: 'assets/illustrations/onboarding_maintenance.svg',
      title: 'Privat & 100% Offline',
      description:
          'Data kendaraan dan riwayat perjalanan tersimpan aman di perangkat. Tanpa akun, tanpa cloud, dan tanpa iklan.',
    ),
    OnboardingSlide(
      svgPath: 'assets/illustrations/onboarding_health.svg',
      title: 'Pantau Kondisi Kendaraan',
      description:
          'Pantau sisa usia oli, rem, aki, dan ban dengan kalkulasi kilometer dan waktu yang akurat.',
    ),
    OnboardingSlide(
      svgPath: 'assets/illustrations/onboarding_tracking.svg',
      title: 'Catat Rute & Perjalanan',
      description:
          'Rekam rute perjalanan GPS secara mandiri dan bagikan ringkasan pencapaian dengan mudah.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FirstVehicleSetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space24),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.space24),
              // App Identity Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/app_logo.svg',
                    width: 36,
                    height: 36,
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Text(
                    'RideCare',
                    style: AppTypography.heading1.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space16),

              // Slide content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (idx) => setState(() => _currentIndex = idx),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 200,
                          child: SvgPicture.asset(
                            slide.svgPath,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space32),
                        Text(
                          slide.title,
                          style: AppTypography.heading1,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.space16),
                        Text(
                          slide.description,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Page Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final isActive = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primaryBlue : AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.space32),

              // Bottom Action Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.buttonBorderRadius,
                  ),
                ),
                onPressed: _next,
                child: Text(
                  _currentIndex == _slides.length - 1 ? 'Mulai Pengaturan' : 'Lanjut',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space24),
            ],
          ),
        ),
      ),
    );
  }
}
