import 'package:flutter/material.dart';
import '../services/google_auth_service.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool showWelcomeDialog;
  const HomeScreen({super.key, this.showWelcomeDialog = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GoogleAuthService authService = GoogleAuthService();

  @override
  void initState() {
    super.initState();
    if (widget.showWelcomeDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showRegistrationSuccess();
      });
    }
  }

  void _showRegistrationSuccess() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Registered!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'You have been successfully registered.\nWelcome aboard! 🎉',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                const Text('Continue', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Home',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // User Avatar
              if (user?.photoURL != null)
                ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.grey,
                    BlendMode.saturation,
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(user!.photoURL!),
                  ),
                )
              else
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  child: const Icon(Icons.person, size: 50, color: Colors.grey),
                ),

              const SizedBox(height: 24),

              // Welcome Message
              Text(
                'Welcome ${user?.displayName?.split(' ').first ?? 'back'}!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              // User Email and optional Name fallback
              if (user?.email != null)
                Text(
                  user!.email!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),

              const SizedBox(height: 40),

              // Success Message
              if (user != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.black87),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'We are glad you came to our navigation system!',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
