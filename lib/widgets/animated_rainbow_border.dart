import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedRainbowBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final Color backgroundColor;

  const AnimatedRainbowBorder({
    super.key,
    required this.child,
    this.borderRadius = 30.0,
    this.borderWidth = 2.0,
    this.backgroundColor = const Color(0xFF0F0F13), // Default deep dark inner background
  });

  @override
  State<AnimatedRainbowBorder> createState() => _AnimatedRainbowBorderState();
}

class _AnimatedRainbowBorderState extends State<AnimatedRainbowBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(widget.borderWidth),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: SweepGradient(
              transform: GradientRotation(_controller.value * 2 * math.pi),
              colors: const [
                Color(0xFFFF0080), // Pink
                Color(0xFF7928CA), // Purple
                Color(0xFF0070F3), // Blue
                Color(0xFF00DFD8), // Cyan
                Color(0xFF7928CA), // Purple
                Color(0xFFFF0080), // Pink
              ],
              stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(
                  widget.borderRadius - widget.borderWidth),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}
