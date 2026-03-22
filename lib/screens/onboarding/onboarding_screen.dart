import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // ── Illustration ambient: subtle image parallax on page scroll ─────────────
  late final AnimationController _swayCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _entranceCtrl.forward().then((_) {
      _textCtrl.forward(); // start text after panel appears
    });
    _swayCtrl.repeat(reverse: true);
    _pageController.addListener(() {
      if (!_pageController.hasClients || !_pageController.position.haveDimensions) return;
      final page = _pageController.page ?? 0.0;
      if (page >= _pages.length - 1 && !_navigating) {
        _navigating = true;
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && (_pageController.page ?? 0.0) >= _pages.length - 1) {
            _completeOnboarding();
          } else {
            _navigating = false;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceCtrl.dispose();
    _textCtrl.dispose();
    _swayCtrl.dispose();
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
              animation: _pageController,
              builder: (context, child) {
                double page = 0.0;
                if (_pageController.hasClients &&
                    _pageController.position.haveDimensions) {
                  page = _pageController.page ?? 0.0;
                }

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
              if (targetPage == _pages.length - 1 &&
                  currentPage >= (_pages.length - 1) - 0.01 &&
                  velocity < -300) {
                _completeOnboarding();
              } else {
                _pageController.animateToPage(
                  targetPage,
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                );
              }
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
                  fontSize: 15,
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
          fontSize: 36,
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
    const double barHeight = 68.0;
    const double iconSize = 52.0;
    const double edgePad = 8.0;

    return Container(
      height: barHeight,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          // Track runs from left icon start to right edge of slider
          const double trackLeft = edgePad + iconSize / 2;
          final double trackRight = totalWidth - edgePad - iconSize / 2;
          final double trackSpan = trackRight - trackLeft;
          final double maxPage = (_pages.length - 1).toDouble();

          return Stack(
            children: [
              // ── Sliding white walking circle (draggable) ─────────────────
              AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double page = _currentPage.toDouble();
                  if (_pageController.hasClients &&
                      _pageController.position.haveDimensions) {
                    page = _pageController.page ?? page;
                  }

                  double fraction = page % 1.0;
                  bool isMoving = fraction > 0.01 && fraction < 0.99;

                  // Map page (0..maxPage) → x center position across the track
                  double t = (page / maxPage).clamp(0.0, 1.0);
                  double xCenter = trackLeft + t * trackSpan;
                  double topOffset = (barHeight - iconSize) / 2;
                  
                  bool isDone = t > 0.99;

                  return Positioned(
                    left: xCenter - (iconSize + 10) / 2,
                    top: topOffset - 5,
                    width: iconSize + 10,
                    height: iconSize + 10,
                    // GestureDetector wraps only the icon for drag control
                    child: GestureDetector(
                      onHorizontalDragStart: (_) {
                        // Stop any in-progress animation when user grabs the icon
                        _pageController.jumpTo(_pageController.offset);
                      },
                      onHorizontalDragUpdate: (details) {
                        if (!_pageController.hasClients ||
                            !_pageController.position.haveDimensions) return;
                        // dx in pixels → page units via trackSpan
                        final pageDelta = details.delta.dx / trackSpan * maxPage;
                        final newPage = (_pageController.page! + pageDelta)
                            .clamp(0.0, maxPage);
                        final screenWidth = MediaQuery.of(context).size.width;
                        _pageController.jumpTo(newPage * screenWidth);
                      },
                      onHorizontalDragEnd: (details) {
                        if (!_pageController.hasClients ||
                            !_pageController.position.haveDimensions) return;
                        final currentPage = _pageController.page!;
                        final velocity = details.primaryVelocity ?? 0;
                        int targetPage;
                        // For the slider icon, dragging RIGHT is positive velocity, which increases the page
                        if (velocity > 300) {
                          targetPage = (currentPage + 1).floor().clamp(0, _pages.length - 1);
                        } else if (velocity < -300) {
                          targetPage = (currentPage - 1).ceil().clamp(0, _pages.length - 1);
                        } else {
                          targetPage = currentPage.round().clamp(0, _pages.length - 1);
                        }
                        
                        HapticFeedback.selectionClick();
                        _pageController.animateToPage(
                          targetPage,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          width: isDone ? iconSize + 8 : iconSize,
                          height: isDone ? iconSize + 8 : iconSize,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              if (isMoving || isDone)
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: isDone ? 0.5 : 0.25),
                                  blurRadius: isDone ? 18 : 12,
                                  spreadRadius: isDone ? 4 : 2,
                                )
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child)),
                            child: Icon(
                              isDone ? Icons.check_rounded : Icons.directions_walk_rounded,
                              key: ValueKey<bool>(isDone),
                              color: Colors.black,
                              size: isDone ? 30 : 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
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

