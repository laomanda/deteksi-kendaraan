import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/backup_service.dart';
import '../../../navigation/main_navigation_screen.dart';
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
  bool _isImporting = false;

  static const List<OnboardingSlide> _slides = [
    OnboardingSlide(
      svgPath: 'assets/onboarding/onboarding_service_hero.svg',
      title: 'Pantau Jadwal Servis & Oli',
      description:
          'Ketahui waktu tepat untuk mengganti oli dan merawat komponen sebelum motor mengalami kendala.',
    ),
    OnboardingSlide(
      svgPath: 'assets/onboarding/onboarding_telemetry_hero.svg',
      title: 'Kesehatan Mesin & Komponen',
      description:
          'Pantau kondisi oli, rem, ban, dan aki secara real-time berdasarkan jarak kilometer spidometer Anda.',
    ),
    OnboardingSlide(
      svgPath: 'assets/onboarding/onboarding_tracking_hero.svg',
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

  Future<void> _importBackup() async {
    setState(() => _isImporting = true);
    try {
      final result = await BackupService.pickAndImportDatabase();
      if (!mounted) return;

      if (result == null) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.healthOptimal,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.healthCritical,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memulihkan data: $e'),
          backgroundColor: AppColors.healthCritical,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
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
                            'assets/branding/app_logo_emblem.svg',
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
                              Flexible(
                                flex: 3,
                                child: SvgPicture.asset(
                                  slide.svgPath,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 20),

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
                              const SizedBox(height: 8),

                              // Description
                              Text(
                                slide.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
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
                  const SizedBox(height: 18),

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
                  const SizedBox(height: 10),

                  // Alternative: Restore Backup
                  TextButton.icon(
                    onPressed: _isImporting ? null : _importBackup,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    icon: _isImporting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                          )
                        : const Icon(Icons.restore_page_outlined, size: 18),
                    label: Text(
                      _isImporting ? 'Memulihkan Data...' : 'Punya cadangan data? Impor di sini',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
