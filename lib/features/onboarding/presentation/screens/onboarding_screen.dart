import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import 'first_vehicle_setup_screen.dart';

class OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;

  const OnboardingSlide({
    required this.icon,
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
      icon: Icons.offline_pin_outlined,
      title: 'Kedaulatan Data 100% Offline',
      description:
          'Seluruh data kendaraan dan riwayat perjalanan tersimpan privat di perangkat Anda. Tanpa login akun, tanpa cloud, dan tanpa iklan.',
    ),
    OnboardingSlide(
      icon: Icons.health_and_safety_outlined,
      title: 'Kesehatan Kendaraan Presisi',
      description:
          'Kalkulasi degradasi suku cadang mekanis berdasarkan kilometer dan waktu. Pantau sisa umur oli, rem, aki, dan ban dalam sekilas pandang.',
    ),
    OnboardingSlide(
      icon: Icons.route_outlined,
      title: 'Pelacakan Rute & Berbagi',
      description:
          'Rekam rute GPS mandiri dengan peta OpenStreetMap. Bagikan pencapaian perjalanan Anda dengan kartu infografis elegan.',
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
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.space8),
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
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                          ),
                          child: Icon(
                            slide.icon,
                            size: 56,
                            color: AppColors.primaryBlue,
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
