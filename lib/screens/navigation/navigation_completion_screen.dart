import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart' show AuthWrapper;
import '../../core/utils/navigation_utils.dart';

/// Full-screen arrival confirmation screen, pixel-matched to the design image.
/// Shown after completing outdoor-only navigation (50 XP) or indoor-only (25 XP).
class NavigationCompletionScreen extends StatefulWidget {
  final String destinationName;
  final String? roomNumber;
  final String? floor;
  final String? buildingName;
  final int timeTakenMinutes;
  final double distanceMeters;
  final String distanceMetric;

  /// true → indoor-only completion (25 XP), false → full outdoor+indoor or outdoor-only (50 XP)
  final bool isIndoorOnly;

  const NavigationCompletionScreen({
    super.key,
    required this.destinationName,
    this.roomNumber,
    this.floor,
    this.buildingName,
    required this.timeTakenMinutes,
    required this.distanceMeters,
    this.distanceMetric = 'Kilometers',
    this.isIndoorOnly = false,
  });

  @override
  State<NavigationCompletionScreen> createState() =>
      _NavigationCompletionScreenState();
}

class _NavigationCompletionScreenState
    extends State<NavigationCompletionScreen> with TickerProviderStateMixin {
  late final AnimationController _checkController;
  late final Animation<double> _checkScale;
  late final AnimationController _cardController;
  late final Animation<double> _cardSlide;
  late final Animation<double> _cardFade;

  int get _xp => widget.isIndoorOnly ? 25 : 50;
  int get _steps => (widget.distanceMeters * 1.312).round();

  String get _arrivalSubtitle {
    final parts = <String>[widget.destinationName];
    if (widget.roomNumber != null && widget.roomNumber!.isNotEmpty) {
      parts.add(widget.roomNumber!);
    }
    if (widget.floor != null && widget.floor!.isNotEmpty) {
      parts.add(widget.floor!);
    }
    if (widget.buildingName != null && widget.buildingName!.isNotEmpty) {
      parts.add('${widget.buildingName} Building');
    }
    return 'You have arrived at ${parts.join(', ')}';
  }

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cardSlide = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );
    _cardFade = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeIn,
    );

    _checkController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardController.forward();
    });

    _awardXp();
  }

  Future<void> _awardXp() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'points': FieldValue.increment(_xp)});
      }
    } catch (e) {
      debugPrint('NavigationCompletionScreen: Failed to award XP: $e');
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.2,
            colors: [Color(0xFF3A3A3C), Color(0xFF1C1C1E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Animated Checkmark Circle ──────────────────────────────
              ScaleTransition(
                scale: _checkScale,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, size: 62, color: Colors.black),
                ),
              ),

              const SizedBox(height: 28),

              // ── Title ─────────────────────────────────────────────────
              const Text(
                'Destination Reached!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 10),

              // ── Subtitle ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Text(
                  _arrivalSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // ── Trip Summary Card (with backdrop blur) ─────────────────
              AnimatedBuilder(
                animation: _cardController,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _cardSlide.value),
                  child: Opacity(opacity: _cardFade.value, child: child),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 40,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Row 1
                            SizedBox(
                              height: 110,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: _SummaryTile(label: 'Time taken', value: widget.timeTakenMinutes.toString(), unit: 'MINS')),
                                  const SizedBox(width: 10),
                                  Expanded(child: _SummaryTile(label: 'Distance', value: NavigationUtils.formatDistance(widget.distanceMeters, widget.distanceMetric).split(' ')[0], unit: NavigationUtils.formatDistance(widget.distanceMeters, widget.distanceMetric).split(' ').sublist(1).join(' ').toUpperCase())),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Row 2
                            SizedBox(
                              height: 110,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: _SummaryTile(label: 'Steps', value: _steps.toString(), unit: '')),
                                  const SizedBox(width: 10),
                                  Expanded(child: _SummaryTile(label: 'Points', value: '+$_xp', unit: 'XP')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // ── Back to Home Page Button ───────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                  elevation: 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(36),
                    onTap: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) =>
                              const AuthWrapper(hasSeenOnboarding: true),
                        ),
                        (route) => false,
                      );
                    },
                    child: const SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Center(
                        child: Text(
                          'Back to Home Page',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary Tile — equal dimensions via IntrinsicHeight + crossAxisAlignment.stretch
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEF0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
          if (unit.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              unit,
              style: const TextStyle(
                color: Color(0xFF999999),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
