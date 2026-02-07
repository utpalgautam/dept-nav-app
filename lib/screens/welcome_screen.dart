import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:lottie/lottie.dart';
import '../widgets/floating_background.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import '../services/google_auth_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _rotationController;
  late AnimationController _starController;
  late AnimationController _windController;
  late Animation<double> _scaleAnimation;
  double _touchScale = 1.0;
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  bool _isGoogleSignInLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleSignInLoading = true);
    try {
      final userCredential = await _googleAuthService.signInWithGoogle();
      if (userCredential != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleSignInLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _windController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _rotationController.dispose();
    _starController.dispose();
    _windController.dispose();
    super.dispose();
  }

  // Helper to build a twinkling star
  Widget _buildStar(double top, double left, double size, {double delay = 0}) {
    return Positioned(
      top: top,
      left: left,
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _starController,
          curve: Interval(delay, 1.0, curve: Curves.easeInOut),
        ),
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: _starController,
            curve: Interval(delay, 1.0, curve: Curves.easeInOut),
          ),
          child: Icon(Icons.star, color: const Color(0xFFEFFC90), size: size),
        ),
      ),
    );
  }

  // Helper to build an animated wind line
  Widget _buildWindLine(
      double top, double startX, double length, bool isBlack) {
    return AnimatedBuilder(
      animation: _windController,
      builder: (context, child) {
        final width = MediaQuery.of(context).size.width;
        // Move from left to right, looping
        double x =
            (startX + (_windController.value * width)) % (width + length) -
                length;

        return Positioned(
          top: top,
          left: x,
          child: Opacity(
            opacity: 0.4,
            child: Container(
              width: length,
              height: 1.5,
              decoration: BoxDecoration(
                color: isBlack ? Colors.black : const Color(0xFFEFFC90),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper to build cardinal directions for the icon
  Widget _buildDirection(String label, double angle) {
    return Transform.rotate(
      angle: angle,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(
              top: 4), // Move slightly inwards from absolute edge
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B5E20), // Deep Forest Green
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    // Ensure the system status bar is dark (for light background)
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: FloatingBackground(
          child: Stack(
            children: [
              // Background Animation (Lottie kept behind the shapes)
              Positioned.fill(
                child: Lottie.asset(
                  'assets/animations/welcome_bg.json',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),

              // Main Content
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Animated Compass Icon Container
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: GestureDetector(
                                  onTapDown: (_) =>
                                      setState(() => _touchScale = 0.92),
                                  onTapUp: (_) =>
                                      setState(() => _touchScale = 1.0),
                                  onTapCancel: () =>
                                      setState(() => _touchScale = 1.0),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    curve: Curves.easeInOut,
                                    transform: Matrix4.identity()
                                      ..scale(_touchScale),
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                          0xFFEFFC90), // Light lime background
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Counter-rotating Navigation Ring (Outer Text & Inner Border)
                                        RotationTransition(
                                          turns: Tween<double>(
                                                  begin: 1.0, end: 0.0)
                                              .animate(_rotationController),
                                          child: SizedBox(
                                            width: 80,
                                            height: 80,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                // Outer Cardinal Directions
                                                _buildDirection('N', 0),
                                                _buildDirection(
                                                    'E', math.pi / 2),
                                                _buildDirection('S', math.pi),
                                                _buildDirection(
                                                    'W', 3 * math.pi / 2),

                                                // Inner Ring Border
                                                Container(
                                                  width: 54,
                                                  height: 54,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: const Color(
                                                              0xFF689F38)
                                                          .withOpacity(0.35),
                                                      width: 1,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Compass needle
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black,
                                          ),
                                          child: RotationTransition(
                                            turns: _rotationController,
                                            child: const Icon(
                                              Icons.explore,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // NIT Calicut Label
                              Text(
                                'NIT CALICUT',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black.withOpacity(0.5),
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 4),

                              const Text(
                                'eXploree',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Your ultimate companion for navigating\nNIT Calicut campus halls & offices.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Image Section with Stars
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Twinkling Stars around the image
                                  _buildStar(-15, -10, 12, delay: 0.1),
                                  _buildStar(10, -20, 8, delay: 0.4),
                                  _buildStar(-20, 150, 10, delay: 0.7),
                                  _buildStar(screenHeight * 0.3 * 0.7, -10, 10,
                                      delay: 0.2),
                                  _buildStar(screenHeight * 0.3 - 20, 260, 12,
                                      delay: 0.5),
                                  _buildStar(screenHeight * 0.3 * 0.3, 280, 8,
                                      delay: 0.8),

                                  // Animated Wind Lines covering full image height
                                  _buildWindLine(
                                      screenHeight * 0.3 * 0.15, 0, 60, true),
                                  _buildWindLine(screenHeight * 0.3 * 0.30, 100,
                                      80, false),
                                  _buildWindLine(
                                      screenHeight * 0.3 * 0.45, 200, 50, true),
                                  _buildWindLine(screenHeight * 0.3 * 0.60, 50,
                                      100, false),
                                  _buildWindLine(
                                      screenHeight * 0.3 * 0.75, 150, 70, true),
                                  _buildWindLine(
                                      screenHeight * 0.3 * 0.85, 80, 90, false),
                                  _buildWindLine(
                                      screenHeight * 0.3 * 0.95, 180, 60, true),

                                  // Main Campus Image
                                  FadeTransition(
                                    opacity: _controller,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.05),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(
                                        parent: _controller,
                                        curve: const Interval(0.4, 1.0,
                                            curve: Curves.easeOut),
                                      )),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.asset(
                                          'assets/images/campus_building.png',
                                          height: screenHeight * 0.3,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            height: 160,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Center(
                                                child: Icon(Icons.image,
                                                    color: Colors.grey)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // New User? Label
                              Text(
                                'New User?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Sign Up Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SignupScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward, size: 18),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // or sign in with divider
                              Row(
                                children: [
                                  Expanded(
                                      child:
                                          Divider(color: Colors.grey.shade300)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      "or sign up with",
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                      child:
                                          Divider(color: Colors.grey.shade300)),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Google Sign-up Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: _isGoogleSignInLoading
                                      ? null
                                      : _handleGoogleSignIn,
                                  style: OutlinedButton.styleFrom(
                                    side:
                                        BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isGoogleSignInLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.black),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/images/google.png',
                                              height: 20,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  const Icon(Icons.g_mobiledata,
                                                      size: 20),
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              "Sign up with Google",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              const SizedBox(height: 4),

                              // Guest Button
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 36),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const HomeScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Continue as Guest",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 4),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Already have an account? ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Log in',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Color(
                                            0xFF1B5E20), // Dark green for visibility
                                        fontWeight: FontWeight.w900,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
