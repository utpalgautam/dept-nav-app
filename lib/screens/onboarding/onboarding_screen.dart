import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────
class _OnboardingPage {
  final String imagePath;
  final String titleLine1;
  final String boldWord1;
  final String titleLine2;
  final String boldWord2;
  final String subtitle;

  const _OnboardingPage({
    required this.imagePath,
    required this.titleLine1,
    required this.boldWord1,
    required this.titleLine2,
    required this.boldWord2,
    required this.subtitle,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // ── Page state ─────────────────────────────────────────────────────────────
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      imagePath: 'assets/images/onboarding/onboarding_1.png',
      titleLine1: 'Move ',
      boldWord1: 'smarter,',
      titleLine2: 'Move ',
      boldWord2: 'faster',
      subtitle:
          'Navigate your campus with ease and confidence, every step of the way.',
    ),
    _OnboardingPage(
      imagePath: 'assets/images/onboarding/onboarding_2.png',
      titleLine1: 'Find your ',
      boldWord1: 'way,',
      titleLine2: 'every ',
      boldWord2: 'day',
      subtitle:
          'Real-time directions to every block, department, and facility on campus.',
    ),
    _OnboardingPage(
      imagePath: 'assets/images/onboarding/onboarding_3.png',
      titleLine1: 'Explore ',
      boldWord1: 'places,',
      titleLine2: 'find ',
      boldWord2: 'spaces',
      subtitle:
          'Discover hidden spots, study zones, and all amenities around you.',
    ),
    _OnboardingPage(
      imagePath: 'assets/images/onboarding/onboarding_4.png',
      titleLine1: 'Stay ',
      boldWord1: 'connected,',
      titleLine2: 'Stay ',
      boldWord2: 'informed',
      subtitle:
          'Get updates, announcements, and directions — all in one place.',
    ),
  ];

  // ── Entrance animation (runs once on launch) ───────────────────────────────
  late final AnimationController _entranceCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );
  late final Animation<double> _imageScale = Tween<double>(begin: 1.07, end: 1.0)
      .animate(CurvedAnimation(
          parent: _entranceCtrl,
          curve: const Interval(0.0, 0.7, curve: Curves.easeOut)));
  late final Animation<double> _imageFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
  late final Animation<double> _panelSlide =
      Tween<double>(begin: 60.0, end: 0.0).animate(CurvedAnimation(
          parent: _entranceCtrl,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack)));
  late final Animation<double> _panelFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.4, 0.85, curve: Curves.easeOut));

  // ── Per-page staggered text animations ────────────────────────────────────
  late AnimationController _textCtrl;

  // 3 items: line1, line2, subtitle
  final List<Interval> _textIntervals = const [
    Interval(0.0, 0.5, curve: Curves.easeOut),  // line 1
    Interval(0.15, 0.65, curve: Curves.easeOut), // line 2
    Interval(0.35, 0.85, curve: Curves.easeOut), // subtitle
  ];

  // ── Illustration ambient: subtle image parallax on page scroll ─────────────
  late final AnimationController _swayCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  // ── Button press scale ─────────────────────────────────────────────────────
  late final AnimationController _btnCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
  );
  late final Animation<double> _btnScale =
      Tween<double>(begin: 1.0, end: 0.88).animate(
          CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _entranceCtrl.forward().then((_) {
      _textCtrl.forward(); // start text after panel appears
    });
    _swayCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceCtrl.dispose();
    _textCtrl.dispose();
    _swayCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, anim, __) => const LoginScreen(),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  Future<void> _nextPage() async {
    HapticFeedback.lightImpact();
    await _btnCtrl.forward();
    await _btnCtrl.reverse();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic);
    } else {
      await _completeOnboarding();
    }
  }

  void _onPageChanged(int idx) {
    setState(() => _currentPage = idx);
    _textCtrl
      ..reset()
      ..forward();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Illustration takes top 58%, panel sits below that
    final illustrationHeight = size.height * 0.58;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(fit: StackFit.expand, children: [
        // ── Background illustration PageView (top 58%) ───────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: illustrationHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: _onPageChanged,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (_, i) => _buildIllustration(_pages[i]),
          ),
        ),

        // ── Swipe gesture detector (covers full screen) ──────────────────
        Positioned.fill(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! < -300) {
                _nextPage();
              } else if (details.primaryVelocity != null &&
                  details.primaryVelocity! > 300 &&
                  _currentPage > 0) {
                _pageController.previousPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic);
              }
            },
            behavior: HitTestBehavior.translucent,
          ),
        ),

        // ── Soft gradient bridge between image and panel ─────────────────
        AnimatedBuilder(
          animation: _panelFade,
          builder: (_, __) => Positioned(
            top: illustrationHeight - 48,
            left: 0,
            right: 0,
            height: 64,
            child: Opacity(
              opacity: _panelFade.value,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.white],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Frosted glass text panel (bottom 42%) ────────────────────────
        AnimatedBuilder(
          animation: _entranceCtrl,
          builder: (_, child) => Positioned(
            top: illustrationHeight + 16 + _panelSlide.value,
            left: 0,
            right: 0,
            bottom: 0,
            child: Opacity(
              opacity: _panelFade.value.clamp(0.0, 1.0),
              child: child!,
            ),
          ),
          child: _buildTextPanel(_pages[_currentPage]),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Illustration area
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildIllustration(_OnboardingPage page) {
    return AnimatedBuilder(
      animation: _entranceCtrl,
      builder: (_, child) => Opacity(
        opacity: _imageFade.value,
        child: Transform.scale(
          scale: _imageScale.value,
          alignment: Alignment.center,
          child: child,
        ),
      ),
      child: Container(
        color: const Color(0xFFF5F5F5),
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
        child: Image.asset(
          page.imagePath,
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom text panel — glassmorphic card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTextPanel(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Glass card ─────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(28, 26, 28, 28),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Line 1 — staggered entrance
                    _StaggeredLine(
                      controller: _textCtrl,
                      interval: _textIntervals[0],
                      child: _buildRichLine(page.titleLine1, page.boldWord1),
                    ),
                    const SizedBox(height: 2),
                    // Line 2 — slightly delayed
                    _StaggeredLine(
                      controller: _textCtrl,
                      interval: _textIntervals[1],
                      child: _buildRichLine(page.titleLine2, page.boldWord2),
                    ),
                    const SizedBox(height: 14),
                    // Subtitle — last to appear
                    _StaggeredLine(
                      controller: _textCtrl,
                      interval: _textIntervals[2],
                      child: Text(
                        page.subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withValues(alpha: 0.52),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                          height: 1.6,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // ── Bottom navigation bar ───────────────────────────────────────
          _buildBottomBar(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRichLine(String normal, String bold) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 33,
          color: Colors.black,
          fontFamily: 'Poppins',
          height: 1.2,
          letterSpacing: -0.6,
        ),
        children: [
          TextSpan(text: normal),
          TextSpan(
            text: bold,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom navigation bar
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final isLast = _currentPage == _pages.length - 1;
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(children: [
        const SizedBox(width: 8),

        // Walking icon
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle),
          child: const Icon(Icons.directions_walk_rounded,
              color: Colors.black, size: 26),
        ),

        // Expanding pill dot indicators
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) {
              final active = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 26 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.28),
                ),
              );
            }),
          ),
        ),

        // Next / Done button
        ScaleTransition(
          scale: _btnScale,
          child: GestureDetector(
            onTap: _nextPage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOut,
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isLast ? Colors.white : const Color(0xFF383838),
                borderRadius: BorderRadius.circular(26),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isLast
                      ? Icons.check_rounded
                      : Icons.arrow_forward_ios_rounded,
                  key: ValueKey<bool>(isLast),
                  color: isLast ? Colors.black : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Staggered animation widget — each text line slides up + fades in
// ─────────────────────────────────────────────────────────────────────────────
class _StaggeredLine extends StatelessWidget {
  final AnimationController controller;
  final Interval interval;
  final Widget child;

  const _StaggeredLine({
    required this.controller,
    required this.interval,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: controller, curve: interval);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: interval));

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      ),
    );
  }
}
