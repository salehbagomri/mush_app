import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mush_app/core/constants/app_colors.dart';
import 'package:mush_app/core/constants/app_strings.dart';
import 'package:mush_app/core/router/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _totalPages = 4;

  final List<_FeatureOnboardingData> _featurePages = const [
    _FeatureOnboardingData(
      title: 'دليل خدمي وسياحي متكامل',
      description:
          'استكشف مئات الخدمات الحكومية والخاصة والمعالم السياحية في مدينتي الشحر والمكلا بكل سهولة وموثوقية.',
      icon: Icons.explore_outlined,
      gradient: LinearGradient(
        colors: [Color(0xFF00897B), Color(0xFF4EBAAA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    _FeatureOnboardingData(
      title: 'معلومات تفصيلية وشاملة',
      description:
          'تعرف على متطلبات المعاملات، الرسوم المقررة، أوقات العمل الرسمية، وأرقام التواصل المباشرة بدقة.',
      icon: Icons.info_outline_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    _FeatureOnboardingData(
      title: 'تواصل وزيارة بنقرة واحدة',
      description:
          'اتصل مباشرة، تواصل عبر الواتساب، وتوجه للموقع الجغرافي عبر خرائط جوجل بلمسة زر واحدة.',
      icon: Icons.phone_in_talk_outlined,
      gradient: LinearGradient(
        colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isFirstPage = _currentPage == 0;

    return Scaffold(
      backgroundColor: isFirstPage ? const Color(0xFFE9ECF2) : null,
      body: Stack(
        children: [
          // Pages
          PageView.builder(
            controller: _pageController,
            itemCount: _totalPages,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) {
              if (i == 0) {
                return _buildGraduationProjectPage();
              }
              return _buildFeaturePage(_featurePages[i - 1]);
            },
          ),

          // Skip Button
          SafeArea(
            child: Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    foregroundColor:
                        isFirstPage ? const Color(0xFF1B2433) : Colors.white70,
                    textStyle: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  child: const Text(AppStrings.skip),
                ),
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    isFirstPage
                        ? Colors.black.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.35),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _totalPages,
                    effect: WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: isFirstPage
                          ? const Color(0xFF1B2433)
                          : Colors.white,
                      dotColor: isFirstPage ? Colors.black26 : Colors.white38,
                    ),
                  ),

                  // Next / Get Started Button
                  AnimatedContainer(
                    duration: 300.ms,
                    child: _currentPage < _totalPages - 1
                        ? FloatingActionButton(
                            heroTag: 'onboarding_next',
                            onPressed: _nextPage,
                            backgroundColor: isFirstPage
                                ? const Color(0xFF1B2433)
                                : Colors.white,
                            foregroundColor: isFirstPage
                                ? Colors.white
                                : AppColors.primary,
                            elevation: 4,
                            child: const Icon(Icons.arrow_forward_ios),
                          )
                        : ElevatedButton(
                            onPressed: _finish,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 14),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              AppStrings.getStarted,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// الشاشة الأولى: مشروع التخرج (مطابقة لصورة n1.jpg)
  Widget _buildGraduationProjectPage() {
    return Container(
      color: const Color(0xFFE9ECF2),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // الشعار
              Container(
                width: 135,
                height: 135,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2433),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 98,
                    height: 98,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7A747),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.navigation_rounded,
                        size: 50,
                        color: Color(0xFF1B2433),
                      ),
                    ),
                  ),
                ),
              )
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.easeOutBack)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 22),

              // العنوان الرئيسي
              const Text(
                'دليل الشحر المكلا',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B2433),
                  letterSpacing: -0.4,
                ),
              )
                  .animate()
                  .slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOut)
                  .fadeIn(duration: 400.ms, delay: 100.ms),

              const SizedBox(height: 18),

              // الفقرة التعريفية
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: const Text(
                  'يعتبر البرنامج فريدا من نوعة ويقدم خدمة جبارة للمجتمع وزوار المجتمع كدليل خدمي سياحي تم تطوير وتصميم وتحليل وبرمجة البرنامج من قبل قروب اعضاء مشروع التخرج',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.5,
                    height: 1.65,
                    color: Color(0xFF2B374A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
                  .animate()
                  .slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOut)
                  .fadeIn(duration: 400.ms, delay: 200.ms),

              const SizedBox(height: 22),

              // المشرف على المشروع
              const Text(
                'دكتور.مهندس/ إبراهيم إسكندر فاضل',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B2433),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 280.ms),

              const SizedBox(height: 8),

              // أسماء أعضاء الفريق
              ...[
                'م.صالح أحمد باقمري',
                'م.سالم علي الموزعي',
                'م.أحمد سالم شيخان',
                'م.عبدالعزيز محمد بن محمود',
                'م.محمد عبدالله العطاس',
              ].map(
                (name) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF242F42),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // العبارة الختامية
              const Text(
                '" إذهب للمجتمع ولاتدع المجتمع ياتي إليك "',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B2433),
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 350.ms),
            ],
          ),
        ),
      ),
    );
  }

  /// الشاشات التعريفية بمميزات التطبيق
  Widget _buildFeaturePage(_FeatureOnboardingData data) {
    return Container(
      decoration: BoxDecoration(gradient: data.gradient),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(data.icon, size: 76, color: Colors.white),
            )
                .animate()
                .scale(duration: 500.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 44),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                data.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            )
                .animate()
                .slideY(begin: 0.25, duration: 400.ms, curve: Curves.easeOut)
                .fadeIn(duration: 400.ms, delay: 150.ms),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Text(
                data.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15.5,
                  color: Colors.white70,
                  height: 1.65,
                ),
              ),
            )
                .animate()
                .slideY(begin: 0.25, duration: 400.ms, curve: Curves.easeOut)
                .fadeIn(duration: 400.ms, delay: 250.ms),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _FeatureOnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final LinearGradient gradient;

  const _FeatureOnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}
