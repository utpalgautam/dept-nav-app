import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:my_app/screens/saved_spots_screen.dart';
import 'package:my_app/screens/search.dart';
import 'package:my_app/screens/edit_account_screen.dart';
import 'package:my_app/screens/change_password_screen.dart';
import 'package:my_app/screens/notifications_screen.dart';
import 'package:my_app/services/user_service.dart';
import 'package:my_app/theme/app_theme.dart';
import 'package:my_app/widgets/pressed_effect.dart';
import 'package:my_app/widgets/custom_button.dart';
import 'package:my_app/widgets/app_header.dart';
import 'package:my_app/widgets/app_bottom_nav.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // State for toggles
  bool _isAppLockEnabled = false;
  bool _isAccessibleRoutesEnabled = false;
  bool _isAppLocked = false;
  String _userName = "Alex Rivera";
  String _userDepartment = "Computer Science Department";
  String _userYear = "3rd year";
  String _userProgram = "B.Tech";
  String _distanceUnit = "Meters";
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadSettings(isStartup: true);
  }

  Future<void> _loadSettings({bool isStartup = false}) async {
    final userData = await UserService.loadUserData();
    
    setState(() {
      _isAppLockEnabled = userData[UserService.keyAppLock];
      _userName = userData[UserService.keyUserName];
      _userDepartment = userData[UserService.keyUserDept];
      _userYear = userData[UserService.keyUserYear];
      _userProgram = userData[UserService.keyUserProgram];
      _distanceUnit = userData[UserService.keyDistanceUnit];
      _isAccessibleRoutesEnabled = userData[UserService.keyAccessibleRoutes];
      
      final String? imagePath = userData[UserService.keyProfileImage];
      if (imagePath != null) {
        _imageFile = File(imagePath);
      }
      
      if (isStartup && _isAppLockEnabled) {
        _isAppLocked = true;
      }
    });

    if (isStartup && _isAppLockEnabled) {
      _authenticate(isStartup: true);
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    if (value is bool) {
      await UserService.saveBool(key, value);
    } else if (value is String) {
      await UserService.saveString(key, value);
    }
  }

  Future<void> _authenticate({bool isStartup = false}) async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        if (mounted && !isStartup) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Security authentication is not available on this device.')),
          );
        }
        if (isStartup) {
          setState(() => _isAppLocked = false);
        }
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows PIN/Password fallback
        ),
      );

      if (mounted) {
        setState(() {
          if (isStartup) {
            _isAppLocked = !didAuthenticate;
          } else {
            _isAppLockEnabled = didAuthenticate;
            _saveSetting('app_lock_enabled', didAuthenticate);
          }
        });
        
        if (didAuthenticate && !isStartup) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('App Lock enabled successfully!')),
          );
        }
      }
    } on PlatformException catch (e) {
      debugPrint('Error during biometric authentication: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication error: ${e.message}')),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        _saveSetting('profile_image_path', pickedFile.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showDistanceUnitPicker(BuildContext context, Color primary, Color dark, Color iosDivider) {
    final List<String> units = ['Meters', 'Kilometers', 'Feet', 'Miles'];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Text(
              'Select Distance Unit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...units.map((unit) => ListTile(
              title: Text(unit, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: _distanceUnit == unit ? Icon(Icons.check_circle, color: primary) : null,
              onTap: () {
                setState(() => _distanceUnit = unit);
                _saveSetting(UserService.keyDistanceUnit, unit);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showFeedbackSheet(BuildContext context, Color primary, Color dark) {
    final TextEditingController feedbackController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Text(
                'Send Feedback',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us what you love or what we could improve!',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: feedbackController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Your thoughts...',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Send Feedback',
                backgroundColor: primary,
                textColor: dark,
                onPressed: () {
                  if (feedbackController.text.isNotEmpty) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feedback sent! Thank you for your input.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                'Change Profile Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Color(0xFF1A1C1E)),
                title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF1A1C1E)),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primaryColor = Color(0xFFC8E953);
    const Color listBg = Color(0xFFF9FAFB);
    const Color iosGray = Color(0xFF8E8E93);
    const Color brandDark = Color(0xFF1A1C1E);
    const Color iosDivider = Color(0xFFE5E5EA);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: _isAppLocked 
        ? _buildLockedScreen(primaryColor, brandDark)
        : Stack(
            children: [
          CustomScrollView(
            slivers: [
              AppHeader(
                title: 'My Profile',
                showDivider: false,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: PressedEffect(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.notifications_none, color: isDark ? Colors.white : AppColors.brandDark),
                      ),
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      _buildProfileSection(context, primaryColor, brandDark, iosGray, iosDivider),
                      const SizedBox(height: 32),
                      CustomButton(
                        label: 'Edit Account',
                        backgroundColor: primaryColor,
                        textColor: brandDark,
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EditAccountScreen()),
                          );
                          // Reload settings when returning to sync name/image
                          // Pass isStartup: false to prevent re-authentication
                          _loadSettings(isStartup: false);
                        },
                      ),
                      const SizedBox(height: 32),
                      _buildSettingsSection(
                        context,
                        title: 'Activity',
                        iosGray: iosGray,
                        listBg: listBg,
                        iosDivider: iosDivider,
                        brandDark: brandDark,
                        primaryColor: primaryColor,
                        items: [
                          _SettingsItemData(
                            icon: Icons.bookmark,
                            label: 'Saved Locations',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SavedSpotsScreen()),
                            ),
                          ),
                          _SettingsItemData(
                            icon: Icons.history,
                            label: 'Recent Searches',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SearchHistoryScreen()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildSettingsSection(
                        context,
                        title: 'Security',
                        iosGray: iosGray,
                        listBg: listBg,
                        iosDivider: iosDivider,
                        brandDark: brandDark,
                        primaryColor: primaryColor,
                        items: [
                          _SettingsItemData(
                            icon: Icons.lock,
                            label: 'Change Password',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                            ),
                          ),
                          _SettingsItemData(
                            icon: Icons.lock_outline,
                            label: 'App Lock (PIN/Biometric)',
                            hasSwitch: true,
                            switchValue: _isAppLockEnabled,
                            onSwitchChanged: (v) {
                              if (v) {
                                _authenticate();
                              } else {
                                setState(() => _isAppLockEnabled = false);
                                _saveSetting('app_lock_enabled', false);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildSettingsSection(
                        context,
                        title: 'App Preferences',
                        iosGray: iosGray,
                        listBg: listBg,
                        iosDivider: iosDivider,
                        brandDark: brandDark,
                        primaryColor: primaryColor,
                        items: [
                          _SettingsItemData(
                            icon: Icons.accessible,
                            label: 'Accessible Routes',
                            subtitle: 'Prioritize elevators & ramps',
                            hasSwitch: true,
                            switchValue: _isAccessibleRoutesEnabled,
                            onSwitchChanged: (v) {
                               setState(() => _isAccessibleRoutesEnabled = v);
                               _saveSetting('accessible_routes', v);
                             },
                           ),
                          _SettingsItemData(
                            icon: Icons.straighten,
                            label: 'Distance Units',
                            trailingText: _distanceUnit,
                            onTap: () => _showDistanceUnitPicker(context, primaryColor, brandDark, iosDivider),
                          ),
                          _SettingsItemData(
                            icon: Icons.feedback_outlined,
                            label: 'Send Feedback',
                            onTap: () => _showFeedbackSheet(context, primaryColor, brandDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildSignOutButton(brandDark, context),
                      const SizedBox(height: 24),
                      _buildVersionInfo(iosGray),
                      const SizedBox(height: 120), // Spacing for bottom nav
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AppBottomNav(activeIndex: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedScreen(Color primaryColor, Color brandDark) {
    return Container(
      width: double.infinity,
      color: brandDark,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_person, size: 80, color: primaryColor),
          const SizedBox(height: 24),
          const Text(
            'App Locked',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Authentication required to proceed',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: 200,
            child: CustomButton(
              label: 'Unlock Now',
              backgroundColor: primaryColor,
              textColor: brandDark,
              onPressed: () => _authenticate(isStartup: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, Color primary, Color dark, Color gray, Color divider) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primary, primary.withValues(alpha: 0.3)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              backgroundImage: _imageFile != null
                  ? FileImage(_imageFile!) as ImageProvider
                  : const NetworkImage(
                      "https://images.unsplash.com/photo-1633332755192-727a05c4013d?q=80&w=2080&auto=format&fit=crop",
                    ),
            ),
            ),
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Text(
                  'STUDENT',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: PressedEffect(
                onPressed: () => _showImageSourceActionSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: dark,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.photo_camera, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          _userName,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: dark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _userDepartment,
          style: TextStyle(color: gray, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: divider),
          ),
          child: Text(
            'ID: 20248831 • $_userProgram • $_userYear',
            style: TextStyle(
              color: dark.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<_SettingsItemData> items,
    required Color iosGray,
    required Color listBg,
    required Color iosDivider,
    required Color brandDark,
    required Color primaryColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: iosGray,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: listBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: iosDivider),
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isLast = index == items.length - 1;
              return Column(
                children: [
                  PressedEffect(
                    onPressed: item.onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(item.icon, color: brandDark, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: brandDark,
                                  ),
                                ),
                                if (item.subtitle != null)
                                  Text(
                                    item.subtitle!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: iosGray,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (item.hasSwitch)
                            Switch(
                              value: item.switchValue ?? false,
                              onChanged: item.onSwitchChanged,
                              activeTrackColor: primaryColor,
                              inactiveTrackColor: iosDivider,
                              thumbColor: WidgetStateProperty.all(Colors.white),
                            )
                          else if (item.trailingText != null)
                            Row(
                              children: [
                                Text(
                                  item.trailingText!,
                                  style: TextStyle(
                                    color: iosGray,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.chevron_right, color: iosGray, size: 18),
                              ],
                            )
                          else
                            Icon(Icons.chevron_right, color: iosGray, size: 18),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.only(left: 72),
                      child: Container(color: iosDivider, height: 1),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutButton(Color dark, BuildContext context) {
    return PressedEffect(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signing out...')),
        );
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFEE2E2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text(
              'Sign Out',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionInfo(Color gray) {
    return Column(
      children: [
        Text(
          'Version 2.4.0 (Build 128)',
          style: TextStyle(
            color: gray,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Made with ♥ by Team eXploree',
          style: TextStyle(
            color: gray.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SettingsItemData {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? trailingText;
  final bool hasSwitch;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final VoidCallback? onTap;

  _SettingsItemData({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailingText,
    this.hasSwitch = false,
    this.switchValue,
    this.onSwitchChanged,
    this.onTap,
  });
}
