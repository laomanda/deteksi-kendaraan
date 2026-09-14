import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';
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

/// Simple, elegant, and responsive Onboarding screen
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
      title: 'Pantau Jadwal Servis & Oli',
      description:
          'Ketahui waktu tepat untuk mengganti oli dan merawat komponen sebelum motor mengalami kendala.',
    ),
    OnboardingSlide(
      svgPath: 'assets/illustrations/onboarding_health.svg',
      title: 'Kesehatan Mesin & Komponen',
      description:
          'Pantau kondisi oli, rem, ban, dan aki secara real-time berdasarkan jarak kilometer spidometer Anda.',
    ),
    OnboardingSlide(
      svgPath: 'assets/illustrations/onboarding_tracking.svg',
      title: 'Catat Perjalanan & Odometer',
      description:
          'Rekam rute berkendara dengan GPS. Jarak perjalanan otomatis memperbarui angka spidometer kendaraan Anda.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToSetup() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FirstVehicleSetupScreen()),
    );
  }

  void _next() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
      );
    } else {
      _goToSetup();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastSlide = _currentIndex == _slides.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Minimal Header Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // App Mark
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/app_logo.svg',
                            width: 28,
                            height: 28,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'RideCare',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),

                      // Skip Button
                      if (!isLastSlide)
                        TextButton(
                          onPressed: _goToSetup,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Lewati',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),

                  // Carousel Slides
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _slides.length,
                      onPageChanged: (idx) => setState(() => _currentIndex = idx),
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Clean Illustration Container
                              SizedBox(
                                height: 210,
                                child: SvgPicture.asset(
                                  slide.svgPath,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 36),

                              // Title
                              Text(
                                slide.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),

                              // Description
                              Text(
                                slide.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.45,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Smooth Page Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final isActive = i == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 22 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primaryBlue : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),

                  // Bottom Action Button
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _next,
                    child: Text(
                      isLastSlide ? 'Mulai Daftarkan Kendaraan' : 'Lanjut',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
