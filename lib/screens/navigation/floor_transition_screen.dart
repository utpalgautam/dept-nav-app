import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../../providers/navigation_provider.dart';

class FloorTransitionScreen extends StatefulWidget {
  final int currentFloor;
  final int targetFloor;
  final String subInstruction;
  final VoidCallback onConfirm;

  const FloorTransitionScreen({
    super.key,
    required this.currentFloor,
    required this.targetFloor,
    this.subInstruction = "Straight 50m",
    required this.onConfirm,
  });

  @override
  State<FloorTransitionScreen> createState() => _FloorTransitionScreenState();
}

class _FloorTransitionScreenState extends State<FloorTransitionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _hasSpoken = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Voice feedback on entry
    Future.microtask(() {
      final navProv = Provider.of<NavigationProvider>(context, listen: false);
      if (!_hasSpoken) {
        navProv.speak("Please change floor. Go from Floor ${widget.currentFloor} to Floor ${widget.targetFloor}.");
        _hasSpoken = true;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202022),
      body: Consumer<NavigationProvider>(
        builder: (context, navProv, child) {
          return SafeArea(
            child: Column(
              children: [
                // Premium Header matching Outdoor Nav
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildHeader(navProv),
                ),
                
                const Spacer(flex: 2),
                
                // Animation Area
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Custom Stair Painter with Glow
                    CustomPaint(
                      size: const Size(200, 200),
                      painter: _StairPainter(
                        isUp: widget.targetFloor > widget.currentFloor,
                      ),
                    ),
                    // Animated Hopping Person
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          final isUp = widget.targetFloor > widget.currentFloor;
                          double t = _animation.value;
                          
                          const int segments = 5;
                          double segmentT = (t * segments) % 1.0;
                          int segmentIndex = (t * segments).floor();
                          if (segmentIndex >= segments) segmentIndex = segments - 1;

                          double stepWidth = 40.0;
                          double stepHeight = 40.0;

                          double startX = segmentIndex * stepWidth - 80;
                          double startY = isUp 
                              ? 80 - segmentIndex * stepHeight 
                              : -80 + segmentIndex * stepHeight;

                          double x, y;
                          if (segmentT < 0.6) {
                            double subT = segmentT / 0.6;
                            x = startX + subT * (stepWidth * 0.5);
                            y = startY;
                          } else {
                            double subT = (segmentT - 0.6) / 0.4;
                            x = startX + (stepWidth * 0.5) + subT * (stepWidth * 0.5);
                            double jumpHeight = 15.0;
                            y = startY + (isUp ? -stepHeight : stepHeight) * subT - (math.sin(subT * math.pi) * jumpHeight);
                          }

                          return Transform.translate(
                            offset: Offset(x, y - 24),
                            child: Opacity(
                              opacity: math.sin(t * math.pi),
                              child: const Icon(
                                Icons.directions_walk_rounded,
                                color: Colors.blue,
                                size: 48,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                
                const Spacer(flex: 3),
                
                // Bottom Action
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onConfirm();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(35),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "I am on the new Floor",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(NavigationProvider navProv) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Change Floor",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                Text(
                  "Floor ${widget.currentFloor} → Floor ${widget.targetFloor}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                if (widget.subInstruction.isNotEmpty)
                  Text(
                    widget.subInstruction,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              shape: BoxShape.circle,
              boxShadow: navProv.isSpeaking
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ]
                  : [],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => navProv.toggleVoice(),
              icon: Icon(
                Icons.mic_rounded,
                color: navProv.isSpeaking ? Colors.blue : Colors.black,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StairPainter extends CustomPainter {
  final bool isUp;
  _StairPainter({required this.isUp});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path();
    double stepWidth = 40.0;
    double stepHeight = 40.0;
    double startX = size.width / 2 - 100;
    double startY = isUp ? size.height / 2 + 80 : size.height / 2 - 80;

    path.moveTo(startX, startY);
    for (int i = 0; i < 5; i++) {
       path.relativeLineTo(stepWidth, 0);
       path.relativeLineTo(0, isUp ? -stepHeight : stepHeight);
    }

    canvas.drawPath(path, paint);

    final glowPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    
    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
