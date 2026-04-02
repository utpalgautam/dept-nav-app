import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart' show kHasSeenOnboarding;
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
  // Separate notifier to safely drive AnimatedBuilder without framework assertions
  final ValueNotifier<double> _pageNotifier = ValueNotifier<double>(0.0);

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      imagePath: 'assets/images/onboarding/amphi.png',
      titleLine1: 'Move ',
      boldWord1: 'smarter,',
      titleLine2: 'Move ',
      boldWord2: 'faster',
      subtitle:
          'Navigate your campus with ease and confidence, every step of the way.',
    ),
    _OnboardingPage(
      imagePath: 'assets/images/onboarding/amphi2.png',
      titleLine1: 'Find your ',
      boldWord1: 'way,',
      titleLine2: 'every ',
      boldWord2: 'day',
      subtitle:
          'Real-time directions to every block, department, and facility on campus.',
    ),
    _OnboardingPage(
      imagePath: 'assets/images/onboarding/amphi.png',
      titleLine1: 'Explore ',
      boldWord1: 'places,',
      titleLine2: 'find ',
      boldWord2: 'spaces',
      subtitle:
          'Discover hidden spots, study zones, and all amenities around you.',
    ),
    _OnboardingPage(
      imagePath: 'assets/images/onboarding/amphi2.png',
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



  @override
  void initState() {
    super.initState();
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _entranceCtrl.forward().then((_) {
      _textCtrl.forward(); // start text after panel appears
    });
    _pageController.addListener(() {
      if (!_pageController.hasClients || !_pageController.position.haveDimensions) return;
      final page = _pageController.page ?? 0.0;
      _pageNotifier.value = page;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceCtrl.dispose();
    _textCtrl.dispose();
    _pageNotifier.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kHasSeenOnboarding, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, anim, __) => const LoginScreen(),
      transitionsBuilder: (_, anim, __, child) {
        final tween = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(
          position: anim.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 600),
    ));
  }

  void _onPageChanged(int idx) {
    setState(() => _currentPage = idx);
    _textCtrl
      ..reset()
      ..forward();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        // ── Panoramic Background ───────────────────
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _entranceCtrl,
            builder: (context, child) => Opacity(
              opacity: _imageFade.value,
              child: Transform.scale(
                scale: _imageScale.value,
                child: child,
              ),
            ),
            child: AnimatedBuilder(
              animation: _pageNotifier,
              builder: (context, child) {
                final page = _pageNotifier.value;

                // Panorama logic for pages 0, 1, 2
                // Alignment moves from -1.0 to 1.0 slowly.
                double panProgress = (page / 2.0).clamp(0.0, 1.0);
                double alignmentX = -1.0 + (panProgress * 2.0);

                // Slide 4 opacity (fade inside as we move from page 2 to 3)
                double slide4Opacity = (page - 2.0).clamp(0.0, 1.0);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/onboarding/amphi.png',
                      fit: BoxFit.cover,
                      alignment: Alignment(alignmentX, 0.0),
                    ),
                    if (slide4Opacity > 0.0)
                      Opacity(
                        opacity: slide4Opacity,
                        child: Image.asset(
                          'assets/images/onboarding/amphi2.png',
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),

        // ── Invisible PageView to drive _pageController ───────────────────
        Positioned.fill(
          child: IgnorePointer(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: _onPageChanged,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (ctx, i) => const SizedBox.shrink(),
            ),
          ),
        ),

        // ── Full-screen swipe gesture (continuous, drives page live) ────────
        Positioned.fill(
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              if (!_pageController.hasClients ||
                  !_pageController.position.haveDimensions) return;
              // Convert finger delta to page offset
              final screenWidth = MediaQuery.of(context).size.width;
              final pageDelta = -details.delta.dx / screenWidth;
              final newPage =
                  (_pageController.page! + pageDelta).clamp(0.0, (_pages.length - 1).toDouble());
              _pageController.jumpTo(newPage * screenWidth);
            },
            onHorizontalDragEnd: (details) {
              if (!_pageController.hasClients ||
                  !_pageController.position.haveDimensions) return;
              final currentPage = _pageController.page!;
              int targetPage;
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -300) {
                targetPage = (currentPage + 1).floor().clamp(0, _pages.length - 1);
              } else if (velocity > 300) {
                targetPage = (currentPage - 1).ceil().clamp(0, _pages.length - 1);
              } else {
                targetPage = currentPage.round().clamp(0, _pages.length - 1);
              }
              _pageController.animateToPage(
                targetPage,
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
              );
            },
            behavior: HitTestBehavior.translucent,
          ),
        ),

        // ── Bottom dark gradient for text readability ─────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.45,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
        ),

        // ── Text panel & slider (bottom) ────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _entranceCtrl,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _panelSlide.value),
              child: Opacity(
                opacity: _panelFade.value.clamp(0.0, 1.0),
                child: child!,
              ),
            ),
            child: SafeArea(
              child: _buildTextPanel(_pages[_currentPage]),
            ),
          ),
        ),
      ]),
    );
  }


  // ─────────────────────────────────────────────────────────────────────────
  // Bottom text panel — glassmorphic card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTextPanel(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
            child: Container(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                page.subtitle,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.038, // Dynamic font size
                  color: Colors.white.withValues(alpha: 0.85),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  letterSpacing: 0.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          // ── Bottom navigation bar ───────────────────────────────────────
          _buildBottomBar(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRichLine(String normal, String bold) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: MediaQuery.of(context).size.width * 0.09, // Dynamic font size
          color: Colors.white,
          fontFamily: 'Poppins',
          height: 1.15,
          letterSpacing: -0.5,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
    final bool isLastPage = _currentPage == _pages.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // ── Dot indicators ──
          Row(
            children: List.generate(_pages.length, (i) {
              final bool isActive = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.3),
                ),
              );
            }),
          ),
          const Spacer(),
          // ── Continue / Get Started button ──
          GestureDetector(
            onTap: _nextPage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              height: 44,
              padding: EdgeInsets.symmetric(
                horizontal: isLastPage ? 22 : 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.1, 0),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Text(
                      isLastPage ? 'Get Started' : 'Continue',
                      key: ValueKey<bool>(isLastPage),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isLastPage ? Icons.arrow_forward_rounded : Icons.arrow_forward_rounded,
                    color: Colors.black,
                    size: 17,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Staggered animation widget — each text line slides up + fades in
// ─────────────────────────────────────────────────────────────────────────────
class _StaggeredLine extends StatefulWidget {
  final AnimationController controller;
  final Interval interval;
  final Widget child;

  const _StaggeredLine({
    required this.controller,
    required this.interval,
    required this.child,
  });

  @override
  State<_StaggeredLine> createState() => _StaggeredLineState();
}

class _StaggeredLineState extends State<_StaggeredLine> {
  late final CurvedAnimation _fade;
  late final CurvedAnimation _slideCurve;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _fade = CurvedAnimation(parent: widget.controller, curve: widget.interval);
    _slideCurve = CurvedAnimation(parent: widget.controller, curve: widget.interval);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(_slideCurve);
  }

  @override
  void dispose() {
    _fade.dispose();
    _slideCurve.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (_, __) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      ),
    );
  }
}

