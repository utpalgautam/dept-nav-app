// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../widgets/floating_background.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/validators.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController(); // Student Name
  final _facultyNameController = TextEditingController(); // Faculty Name
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Faculty specific controllers
  final _officeAddressController = TextEditingController();
  final _joiningYearController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _facultyEmailController = TextEditingController();
  final _facultyPasswordController = TextEditingController();
  final _facultyConfirmPasswordController = TextEditingController();

  bool _passwordsMatch = true;
  bool _facultyPasswordsMatch = true;

  // Password Visibility
  bool _isStudentPassVisible = false;
  bool _isStudentConfirmVisible = false;
  bool _isFacultyPassVisible = false;
  bool _isFacultyConfirmVisible = false;

  @override
  void initState() {
    super.initState();
    _confirmPasswordController.addListener(_checkPasswordMatch);
    _passwordController.addListener(_checkPasswordMatch);

    _facultyConfirmPasswordController.addListener(_checkFacultyPasswordMatch);
    _facultyPasswordController.addListener(_checkFacultyPasswordMatch);
  }

  void _checkPasswordMatch() {
    setState(() {
      _passwordsMatch =
          _passwordController.text == _confirmPasswordController.text;
    });
  }

  void _checkFacultyPasswordMatch() {
    setState(() {
      _facultyPasswordsMatch = _facultyPasswordController.text ==
          _facultyConfirmPasswordController.text;
    });
  }

  // Dropdown values
  String? _selectedBranch;
  String? _selectedProgramme;
  String? _selectedYear;

  // Role selection
  bool _isStudent = true; // true = Student, false = Staff

  final List<String> _branches = [
    'Computer Science',
    'Electronics',
    'Electrical',
    'Mechanical',
    'Civil',
    'Chemical',
    'Architecture'
  ];

  final List<String> _programmes = ['B.Tech', 'M.Tech', 'Others'];

  List<String> get _currentYearOptions {
    if (_selectedProgramme == 'B.Tech') {
      return ['1st Year', '2nd Year', '3rd Year', '4th Year'];
    } else if (_selectedProgramme == 'M.Tech') {
      return ['1st Year', '2nd Year'];
    } else if (_selectedProgramme == 'Others') {
      return ['Other'];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Create Account",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FloatingBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Join your campus community to start\nnavigating buildings and departments.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                // Role Selection
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isStudent = true),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: _isStudent
                                ? AppColors.primary
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isStudent
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'STUDENT',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _isStudent
                                  ? Colors.black
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isStudent = false),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: !_isStudent
                                ? AppColors.primary
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: !_isStudent
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'FACULTY',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: !_isStudent
                                  ? Colors.black
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                if (_isStudent) ...[
                  // Student Name
                  const Text(
                    'FULL NAME',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    label: 'e.g:Rahul Chauhan',
                    controller: _nameController,
                    prefix: const Icon(Icons.person, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Branch / Department
                  const Text(
                    'BRANCH / DEPARTMENT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedBranch,
                    decoration: InputDecoration(
                      hintText: 'Select your department',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.domain, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: _branches.map((branch) {
                      return DropdownMenuItem(
                        value: branch,
                        child: Text(branch),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBranch = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  const SizedBox(height: 24),

                  // Programme
                  const Text(
                    'PROGRAMME',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedProgramme,
                    decoration: InputDecoration(
                      hintText: 'Select Programme',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.school, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: _programmes.map((prog) {
                      return DropdownMenuItem(
                        value: prog,
                        child: Text(prog),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProgramme = value;
                        _selectedYear = null; // Reset year on programme change
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Year
                  const Text(
                    'YEAR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedYear,
                    decoration: InputDecoration(
                      hintText: 'Select Year',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.calendar_today,
                          size: 20, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    items: _currentYearOptions.map((year) {
                      return DropdownMenuItem(
                        value: year,
                        child: Text(
                          year,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Student Email
                  const Text(
                    'EMAIL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    label: 'name_rollno.@nitc.ac.in or name@gmail.com',
                    controller: _emailController,
                    prefix: const Icon(Icons.mail, color: Colors.grey),
                    suffix: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _emailController,
                      builder: (context, value, child) {
                        if (value.text.isEmpty) return const SizedBox.shrink();
                        final isValid = Validators.isValidEmail(value.text);
                        return Icon(
                          isValid ? Icons.check_circle : Icons.cancel,
                          color: isValid ? Colors.green : Colors.red,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Student Password
                  const Text(
                    'PASSWORD',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    label: '••••••••',
                    obscure: !_isStudentPassVisible,
                    controller: _passwordController,
                    prefix: const Icon(Icons.lock, color: Colors.grey),
                    suffix: IconButton(
                      icon: Icon(
                        _isStudentPassVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isStudentPassVisible = !_isStudentPassVisible;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Student Confirm Password
                  const Text(
                    'CONFIRM PASSWORD',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    label: '••••••••',
                    obscure: !_isStudentConfirmVisible,
                    controller: _confirmPasswordController,
                    prefix: const Icon(Icons.lock, color: Colors.grey),
                    suffix: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isStudentConfirmVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isStudentConfirmVisible =
                                  !_isStudentConfirmVisible;
                            });
                          },
                        ),
                        if (_confirmPasswordController.text.isNotEmpty)
                          Icon(
                            _passwordsMatch ? Icons.check_circle : Icons.cancel,
                            color: _passwordsMatch ? Colors.green : Colors.red,
                          ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Faculty Fields

                  // Faculty Name
                  const Text(
                    'FULL NAME',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    label: 'eg: Dr Sourav Biswas',
                    controller: _facultyNameController,
                    prefix: const Icon(Icons.person, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Office Address
                  const Text(
                    'OFFICE ADDRESS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    label: 'MB 104',
                    controller: _officeAddressController,
                    prefix: const Icon(Icons.location_on_outlined,
                        color: Colors.grey),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'JOINING YEAR',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6B7280),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            CustomTextField(
                              label: 'e.g : 2015',
                              controller: _joiningYearController,
                              prefix: const Icon(Icons.calendar_today,
                                  color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CONTACT NO.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6B7280),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            CustomTextField(
                              label: '+91 98765...',
                              controller: _contactNumberController,
                              prefix:
                                  const Icon(Icons.phone, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Faculty Email
                  const Text(
                    'EMAIL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    label: 'abc@Nitc.ac.in or xyz@google.com',
                    controller: _facultyEmailController,
                    prefix: const Icon(Icons.mail, color: Colors.grey),
                    suffix: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _facultyEmailController,
                      builder: (context, value, child) {
                        if (value.text.isEmpty) return const SizedBox.shrink();
                        final isValid = Validators.isValidEmail(value.text);
                        return Icon(
                          isValid ? Icons.check_circle : Icons.cancel,
                          color: isValid ? Colors.green : Colors.red,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Faculty Password
                  const Text(
                    'PASSWORD',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    label: '••••••••',
                    obscure: !_isFacultyPassVisible,
                    controller: _facultyPasswordController,
                    prefix: const Icon(Icons.lock, color: Colors.grey),
                    suffix: IconButton(
                      icon: Icon(
                        _isFacultyPassVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isFacultyPassVisible = !_isFacultyPassVisible;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Faculty Confirm Password
                  const Text(
                    'CONFIRM PASSWORD',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    label: '••••••••',
                    obscure: !_isFacultyConfirmVisible,
                    controller: _facultyConfirmPasswordController,
                    prefix: const Icon(Icons.lock, color: Colors.grey),
                    suffix: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isFacultyConfirmVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isFacultyConfirmVisible =
                                  !_isFacultyConfirmVisible;
                            });
                          },
                        ),
                        if (_facultyConfirmPasswordController.text.isNotEmpty)
                          Icon(
                            _facultyPasswordsMatch
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: _facultyPasswordsMatch
                                ? Colors.green
                                : Colors.red,
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                const SizedBox(height: 8),
                Text(
                  'Must be at least 8 characters with one number.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),

                const SizedBox(height: 32),

                PrimaryButton(
                  text: 'Register',
                  onPressed: () {
                    // Validation logic based on role
                    if (_isStudent) {
                      final email = _emailController.text;
                      final password = _passwordController.text;
                      final confirmPassword = _confirmPasswordController.text;

                      if (_selectedBranch == null ||
                          _selectedProgramme == null ||
                          _selectedYear == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please select Branch, Programme, and Year.')),
                        );
                        return;
                      }

                      if (!Validators.isValidEmail(email)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please use a valid @nitc.ac.in or @gmail.com email.')),
                        );
                        return;
                      }

                      if (password.length < 8) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Password must be at least 8 characters.')),
                        );
                        return;
                      }

                      if (password != confirmPassword) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Passwords do not match.')),
                        );
                        return;
                      }
                    } else {
                      // Faculty validation
                      final email = _facultyEmailController.text;
                      final password = _facultyPasswordController.text;
                      final confirmPassword =
                          _facultyConfirmPasswordController.text;

                      if (_officeAddressController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please enter Office Address.')),
                        );
                        return;
                      }
                      if (_joiningYearController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please enter Year of Joining.')),
                        );
                        return;
                      }
                      if (_contactNumberController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please enter Contact Number.')),
                        );
                        return;
                      }

                      if (!Validators.isValidEmail(email)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please use a valid @nitc.ac.in or @gmail.com email.')),
                        );
                        return;
                      }

                      if (password.length < 8) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Password must be at least 8 characters.')),
                        );
                        return;
                      }

                      if (password != confirmPassword) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Passwords do not match.')),
                        );
                        return;
                      }
                    }

                    // Handle registration
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Registration Successful as ${_isStudent ? "Student" : "Faculty"}!')),
                    );
                  },
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Log in',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _officeAddressController.dispose();
    _joiningYearController.dispose();
    _contactNumberController.dispose();
    _facultyEmailController.dispose();
    _facultyPasswordController.dispose();
    _facultyConfirmPasswordController.dispose();

    super.dispose();
  }
}
