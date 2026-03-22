import 'dart:ui';

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
    required this.boldWord1,
    required this.titleLine1,
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
  late final Animation<double> _imageScale =
      Tween<double>(begin: 1.07, end: 1.0).animate(CurvedAnimation(
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
  final List<Interval> _textIntervals = const [
    Interval(0.0, 0.5, curve: Curves.easeOut),
    Interval(0.15, 0.65, curve: Curves.easeOut),
    Interval(0.35, 0.85, curve: Curves.easeOut),
  ];

  @override
  void initState() {
    super.initState();
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _entranceCtrl.forward().then((_) {
      _textCtrl.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kHasSeenOnboarding, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, anim, __) => const LoginScreen(),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  Future<void> _nextPage() async {
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
    final illustrationHeight = size.height * 0.58;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(fit: StackFit.expand, children: [
        // ── Background illustration PageView ─────────────────────────────
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

        // ── Full-screen swipe gesture ─────────────────────────────────────
        Positioned.fill(
          child: GestureDetector(
            onHorizontalDragEnd: (d) {
              if (d.primaryVelocity != null && d.primaryVelocity! < -300) {
                _nextPage();
              } else if (d.primaryVelocity != null &&
                  d.primaryVelocity! > 300 &&
                  _currentPage > 0) {
                _pageController.previousPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic);
              }
            },
            behavior: HitTestBehavior.translucent,
          ),
        ),

        // ── Gradient bridge (image → panel) ─────────────────────────────
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

        // ── Frosted glass text panel ──────────────────────────────────────
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
  // Bottom text panel
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTextPanel(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Glass card
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
                    _StaggeredLine(
                      controller: _textCtrl,
                      interval: _textIntervals[0],
                      child: _buildRichLine(page.titleLine1, page.boldWord1),
                    ),
                    const SizedBox(height: 2),
                    _StaggeredLine(
                      controller: _textCtrl,
                      interval: _textIntervals[1],
                      child: _buildRichLine(page.titleLine2, page.boldWord2),
                    ),
                    const SizedBox(height: 14),
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

          // ── Swipe slider bar ──────────────────────────────────────────
          _SwipeSlider(
            page: _currentPage,
            total: _pages.length,
            isLast: _currentPage == _pages.length - 1,
            onNext: _nextPage,
          ),
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
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Draggable Swipe Slider — the main bottom control
// ─────────────────────────────────────────────────────────────────────────────
class _SwipeSlider extends StatefulWidget {
  final int page;
  final int total;
  final bool isLast;
  final VoidCallback onNext;

  const _SwipeSlider({
    required this.page,
    required this.total,
    required this.isLast,
    required this.onNext,
  });

  @override
  State<_SwipeSlider> createState() => _SwipeSliderState();
}

class _SwipeSliderState extends State<_SwipeSlider>
    with SingleTickerProviderStateMixin {
  // ── Internal state ─────────────────────────────────────────────────────────
  // _progress in [0.0, 1.0]: 0 = handle at left, 1 = handle at right
  double _progress = 0.0;
  bool _busy = false; // true while animation is running

  // ── Animation controller for snap-back & auto-complete ────────────────────
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late Animation<double> _tweenAnim;

  static const double _handleSize = 52.0;
  static const double _barPadding = 8.0;
  static const double _completeThreshold = 0.80;

  @override
  void initState() {
    super.initState();
    // Single listener on controller — reads _tweenAnim.value
    _anim.addListener(() {
      if (mounted) setState(() => _progress = _tweenAnim.value);
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ── Drag ───────────────────────────────────────────────────────────────────
  void _onDragUpdate(double dx, double maxDrag) {
    if (_busy) return;
    _anim.stop();
    setState(() {
      _progress = (_progress + dx / maxDrag).clamp(0.0, 1.0);
    });
  }

  // ── Release ────────────────────────────────────────────────────────────────
  void _onDragEnd() {
    if (_busy) return;
    if (_progress >= _completeThreshold) {
      _complete();
    } else {
      _snapBack(curve: Curves.elasticOut);
    }
  }

  // ── Auto-complete when threshold reached ───────────────────────────────────
  Future<void> _complete() async {
    _busy = true;
    // Animate handle to end
    await _animateTo(1.0, curve: Curves.easeOut,
        duration: const Duration(milliseconds: 280));
    // Haptic + callback
    HapticFeedback.mediumImpact();
    widget.onNext();
    // Small pause so the check icon shows briefly
    await Future.delayed(const Duration(milliseconds: 180));
    // Snap back
    await _animateTo(0.0, curve: Curves.easeOut,
        duration: const Duration(milliseconds: 360));
    _busy = false;
  }

  // ── Snap back ──────────────────────────────────────────────────────────────
  void _snapBack({Curve curve = Curves.elasticOut}) {
    _animateTo(0.0, curve: curve,
        duration: const Duration(milliseconds: 480));
  }

  Future<void> _animateTo(
    double target, {
    required Curve curve,
    required Duration duration,
  }) async {
    _anim.duration = duration;
    _tweenAnim = Tween<double>(begin: _progress, end: target)
        .animate(CurvedAnimation(parent: _anim, curve: curve));
    _anim.forward(from: 0.0);
    await _anim.forward(from: 0.0);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final barWidth = constraints.maxWidth;
      final maxDrag = barWidth - _handleSize - _barPadding * 2;
      final handleLeft = _barPadding + _progress * maxDrag;

      // Handle scale: 1.0 → 1.10 as progress increases
      final handleScale = 1.0 + _progress * 0.10;

      // Glow radius on handle grows with progress
      final glowBlur = _progress * 18.0;
      final glowSpread = _progress * 3.0;
      final glowAlpha = _progress * 0.45;

      // Icon flips to check when near completion
      final showCheck = _progress > 0.85;

      // Track fill — progress bar behind handle
      final fillWidth = _barPadding + _progress * maxDrag + _handleSize / 2;

      return GestureDetector(
        onHorizontalDragUpdate: (d) => _onDragUpdate(d.delta.dx, maxDrag),
        onHorizontalDragEnd: (_) => _onDragEnd(),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Stack(clipBehavior: Clip.none, children: [
              // ── Subtle progress fill behind handle ──────────────────────
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: fillWidth.clamp(0.0, barWidth),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.08 * _progress),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Dot indicators (centered, fades as handle moves over) ──
              Center(
                child: Opacity(
                  // Fade dots when handle is in the middle zone
                  opacity: (1.0 - (_progress * 1.6)).clamp(0.0, 1.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(widget.total, (i) {
                      final active = i == widget.page;
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
              ),

              // ── Slide hint label — fades in when handle is at start ────
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Opacity(
                  opacity: (1.0 - _progress * 4).clamp(0.0, 0.38),
                  child: Center(
                    child: Text(
                      widget.isLast ? 'start' : 'next',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Draggable handle ────────────────────────────────────────
              Positioned(
                left: handleLeft,
                top: (_barPadding * 1.3),
                child: Transform.scale(
                  scale: handleScale,
                  child: Container(
                    width: _handleSize,
                    height: _handleSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        // Base shadow
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                        // Glow that intensifies as handle moves right
                        if (_progress > 0.05)
                          BoxShadow(
                            color: Colors.white.withValues(alpha: glowAlpha),
                            blurRadius: glowBlur,
                            spreadRadius: glowSpread,
                          ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        showCheck
                            ? Icons.check_rounded
                            : Icons.arrow_forward_ios_rounded,
                        key: ValueKey<bool>(showCheck),
                        color: Colors.black,
                        size: showCheck ? 26 : 20,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Left edge fade overlay ─────────────────────────────────
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 20,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1A1A1A).withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Right edge fade overlay ────────────────────────────────
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 20,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFF1A1A1A).withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Staggered text line animation
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
