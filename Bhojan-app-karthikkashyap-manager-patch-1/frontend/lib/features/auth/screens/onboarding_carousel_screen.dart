import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class OnboardingCarouselScreen extends StatefulWidget {
  const OnboardingCarouselScreen({Key? key}) : super(key: key);

  @override
  _OnboardingCarouselScreenState createState() => _OnboardingCarouselScreenState();
}

class _OnboardingCarouselScreenState extends State<OnboardingCarouselScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Great Food Finds You Now.",
      "subtitle": "Stop making trips to the cafeteria. Let your meal come to you while you keep doing your thing.",
      "image": "assets/images/onboard_1.png"
    },
    {
      "title": "Food Worth Every Bite.",
      "subtitle": "Every counter on Bhojan is picked for quality, hygiene and taste. Nothing random, nothing sketchy.",
      "image": "assets/images/onboard_2.png"
    },
    {
      "title": "Know When It's Ready.",
      "subtitle": "Live updates from kitchen to counter. No more hovering around — we'll tell you exactly when to show up.",
      "image": "assets/images/onboard_3.png"
    },
    {
      "title": "Pay The Way You Want.",
      "subtitle": "UPI, debit, credit or wallet — pick what works for you and you're done in a single tap.",
      "image": "assets/images/onboard_4.png"
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: onboardingData.length * 100);
    
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // Dark purple top background
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Tenant Dropdown Display
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.business, color: Colors.deepOrange, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Capgemini',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (value) {
                          setState(() {
                            _currentPage = value % onboardingData.length;
                          });
                        },
                        itemBuilder: (context, index) {
                          final dataIndex = index % onboardingData.length;
                          return OnboardingContent(
                            title: onboardingData[dataIndex]["title"]!,
                            subtitle: onboardingData[dataIndex]["subtitle"]!,
                            image: onboardingData[dataIndex]["image"]!,
                          );
                        },
                      ),
                    ),
                    
                    // Left-aligned Dots
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: List.generate(
                          onboardingData.length,
                          (index) => buildDot(index: index),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Bottom Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () => context.push('/sign-up-type'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text('New User? Sign Up!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: () => context.push('/login-otp'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary.withOpacity(0.08),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Login with OTP', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: () => context.push('/login-password'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary.withOpacity(0.08),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Login', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Terms of Use', style: AppTextStyles.labelMedium.copyWith(color: Colors.grey.shade600)),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.0),
                                child: Text('|', style: TextStyle(color: Colors.grey)),
                              ),
                              Text('Privacy Policy', style: AppTextStyles.labelMedium.copyWith(color: Colors.grey.shade600)),
                            ],
                          ),
                          const SizedBox(height: 32), // Bottom padding for SafeArea
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 6),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? AppColors.primary : AppColors.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  const OnboardingContent({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.image,
  }) : super(key: key);

  final String title, subtitle, image;

  @override
  Widget build(BuildContext context) {
    // Split the title to highlight the last word
    List<String> words = title.split(' ');
    String lastWord = "";
    String firstPart = title;
    
    if (words.length > 1) {
      lastWord = words.removeLast();
      firstPart = words.join(' ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SizedBox(
            width: double.infinity,
            child: Image.asset(
              image,
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: AppTextStyles.headlineLarge.copyWith(
                    fontWeight: FontWeight.w800, 
                    color: AppColors.textPrimary,
                    height: 1.2,
                    fontSize: 32,
                  ),
                  children: [
                    TextSpan(text: firstPart + ' '),
                    TextSpan(
                      text: lastWord, 
                      style: const TextStyle(color: AppColors.primary)
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                subtitle,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.grey.shade600, 
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
