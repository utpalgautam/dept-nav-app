import 'package:flutter/material.dart';
import 'dart:math' as math;

class FloatingBackground extends StatefulWidget {
  final Widget child;

  const FloatingBackground({super.key, required this.child});

  @override
  State<FloatingBackground> createState() => _FloatingBackgroundState();
}

class _FloatingBackgroundState extends State<FloatingBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  Widget _buildBackgroundShape(double startX, Color color,
      {required double size,
      double opacity = 0.12,
      double speed = 1.0,
      double delay = 0.0}) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        final screenHeight = MediaQuery.of(context).size.height;

        // Loop from top to bottom
        double progress = (_bgController.value + delay) % 1.0;
        double top = (progress * (screenHeight + size)) - size;

        // Subtle horizontal sway using sine
        double sway = math.sin(progress * math.pi * 4) * 20 * speed;
        double x = startX + sway;

        return Positioned(
          top: top,
          left: x,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        // Ensure the Stack fills the entire screen
        const SizedBox.expand(),

        // Animated Background Shapes - Floating Circles
        _buildBackgroundShape(-20, const Color(0xFFC0CA33),
            size: 100, speed: 1.2, delay: 0.1, opacity: 0.15), // Darker Parrot
        _buildBackgroundShape(screenWidth * 0.7, const Color(0xFF9E9D24),
            size: 140,
            speed: 0.8,
            delay: 0.4,
            opacity: 0.18), // Darker Light Green
        _buildBackgroundShape(screenWidth * 0.2, const Color(0xFF2E7D32),
            size: 180,
            speed: 0.5,
            delay: 0.7,
            opacity: 0.15), // Dark Leaf Green
        _buildBackgroundShape(screenWidth * 0.5, const Color(0xFF1B5E20),
            size: 160,
            speed: 0.6,
            delay: 0.3,
            opacity: 0.14), // Very Dark Green
        _buildBackgroundShape(screenWidth * 0.8, const Color(0xFF9E9D24),
            size: 80, speed: 1.5, delay: 0.2, opacity: 0.2),
        _buildBackgroundShape(screenWidth * 0.1, const Color(0xFF0D5302),
            size: 110,
            speed: 0.9,
            delay: 0.8,
            opacity: 0.16), // Deep Forest Green
        _buildBackgroundShape(screenWidth * 0.4, const Color(0xFF827717),
            size: 120, speed: 1.0, delay: 0.5, opacity: 0.18),

        // The content of the screen
        widget.child,
      ],
    );
  }
}
