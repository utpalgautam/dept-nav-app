import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/theme/app_theme.dart';
import 'package:my_app/widgets/pressed_effect.dart';
import 'package:my_app/widgets/custom_button.dart';
import 'package:my_app/widgets/app_header.dart';
import 'package:my_app/widgets/app_bottom_nav.dart';
import 'package:my_app/services/user_service.dart';

class EditAccountScreen extends StatefulWidget {
  const EditAccountScreen({super.key});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final TextEditingController _nameController = TextEditingController(text: "Alex Rivera");
  String _department = "Computer Science Department";
  String _yearOfStudy = "3rd year";
  String _program = "B.Tech";
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final userData = await UserService.loadUserData();
    
    setState(() {
      final String? imagePath = userData[UserService.keyProfileImage];
      if (imagePath != null) {
        _imageFile = File(imagePath);
      }
      _nameController.text = userData[UserService.keyUserName];
      _department = userData[UserService.keyUserDept];
      _yearOfStudy = userData[UserService.keyUserYear];
      _program = userData[UserService.keyUserProgram];
    });
  }

  Future<void> _saveProfileData() async {
    await UserService.saveString(UserService.keyUserName, _nameController.text);
    await UserService.saveString(UserService.keyUserDept, _department);
    await UserService.saveString(UserService.keyUserYear, _yearOfStudy);
    await UserService.saveString(UserService.keyUserProgram, _program);
    
    if (_imageFile != null) {
      await UserService.saveProfileImage(_imageFile!.path);
    }
    
    // NOTE: This is where you would call your API/Database to save profile data.
    // Example: await database.saveProfile(prefs.getString('user_id'), name, dept, year);
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
        _saveProfileData();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
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
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  final List<String> _departments = [
    "Computer Science Department",
    "Information Technology",
    "Mechanical Engineering",
    "Architecture",
    "Business Management",
  ];

  final List<String> _years = [
    "1st year",
    "2nd year",
    "3rd year",
    "4th year",
    "Postgraduate",
  ];

  final List<String> _programs = [
    "B.Tech",
    "M.Tech",
    "PhD",
    "MCA",
    "M.Sc",
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color currentCardBg = isDark ? const Color(0xFF2A2D1E) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? AppColors.brandDark : AppColors.backgroundLight,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              AppHeader(
                title: 'Edit Account Details',
                onBack: () => Navigator.pop(context),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      _buildProfilePictureSection(context, isDark),
                      const SizedBox(height: 40),
                      _buildInputFields(context, isDark, currentCardBg),
                      const SizedBox(height: 40),
                      CustomButton(
                        label: 'Update Profile',
                        onPressed: () async {
                          await _saveProfileData();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile updated successfully!')),
                          );
                          Navigator.pop(context);
                        },
                        backgroundColor: AppColors.primary,
                        height: 56,
                        fontSize: 18,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Last updated: Today',
                        style: TextStyle(color: AppColors.iosGray, fontSize: 14),
                      ),
                      const SizedBox(height: 100), // Space for bottom nav
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
            child: AppBottomNav(activeIndex: 4, isRoot: false),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePictureSection(BuildContext context, bool isDark) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? const Color(0xFF2A2D1E) : Colors.white, width: 4),
                boxShadow: AppDecorations.softShadow,
                image: DecorationImage(
                  image: _imageFile != null
                      ? FileImage(_imageFile!) as ImageProvider
                      : const NetworkImage(
                          "https://images.unsplash.com/photo-1633332755192-727a05c4013d?q=80&w=2080&auto=format&fit=crop",
                        ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: isDark ? const Color(0xFF2A2D1E) : Colors.white),
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
              bottom: 0,
              right: 0,
              child: PressedEffect(
              onPressed: () => _showImageSourceActionSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? const Color(0xFF2A2D1E) : Colors.white, width: 2),
                    boxShadow: AppDecorations.softShadow,
                  ),
                  child: const Icon(Icons.photo_camera, color: Colors.black, size: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _nameController.text,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        PressedEffect(
          onPressed: () => _showImageSourceActionSheet(context),
          child: const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Text(
              'Change Photo',
              style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputFields(BuildContext context, bool isDark, Color cardBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Email Address (Read-only)', AppColors.iosGray),
        Container(
          width: double.infinity,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.mail, color: AppColors.iosGray, size: 18),
              const SizedBox(width: 12),
              const Text(
                'alex.johnson@university.edu',
                style: TextStyle(color: AppColors.iosGray, fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildLabel('Full Name', isDark ? Colors.grey[400]! : const Color(0xFF171811)),
        _buildTextField(Icons.person, _nameController, isDark, cardBg),
        const SizedBox(height: 20),
        _buildLabel('Branch/Department', isDark ? Colors.grey[400]! : const Color(0xFF171811)),
        _buildDropdown(Icons.school, _department, _departments, (v) => setState(() => _department = v!), isDark, cardBg),
        const SizedBox(height: 20),
        _buildLabel('Year of Study', isDark ? Colors.grey[400]! : const Color(0xFF171811)),
        _buildDropdown(Icons.calendar_month, _yearOfStudy, _years, (v) => setState(() => _yearOfStudy = v!), isDark, cardBg),
        const SizedBox(height: 20),
        _buildLabel('Academic Program', isDark ? Colors.grey[400]! : const Color(0xFF171811)),
        _buildDropdown(Icons.assignment_ind, _program, _programs, (v) => setState(() => _program = v!), isDark, cardBg),
      ],
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField(IconData icon, TextEditingController controller, bool isDark, Color cardBg) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF3A3D2E) : const Color(0xFFDFE2D5)),
        boxShadow: AppDecorations.softShadow,
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.iosGray, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown(IconData icon, String value, List<String> items, ValueChanged<String?> onChanged, bool isDark, Color cardBg) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF3A3D2E) : const Color(0xFFDFE2D5)),
        boxShadow: AppDecorations.softShadow,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.expand_more, color: AppColors.iosGray),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  Icon(icon, color: AppColors.iosGray, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
          isExpanded: true,
          dropdownColor: cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
