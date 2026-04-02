import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';

class ReportIssueScreen extends StatefulWidget {
  final String? routeId;

  const ReportIssueScreen({super.key, this.routeId});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _reportService = ReportService();
  
  String _selectedType = 'Navigation Issue';
  bool _isSubmitting = false;
  bool _includeLocation = true;
  Position? _currentPosition;

  final List<String> _issueTypes = [
    'Navigation Issue',
    'Incorrect Route',
    'Indoor Map Issue',
    'Location Not Found',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    final report = ReportModel(
      id: '',
      userId: user?.uid ?? 'guest',
      userName: user?.name ?? 'Guest User',
      type: _selectedType,
      description: _descriptionController.text.trim(),
      status: 'open',
      priority: 'Medium',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      location: (_includeLocation && _currentPosition != null)
          ? {
              'lat': _currentPosition!.latitude,
              'lng': _currentPosition!.longitude,
            }
          : null,
      relatedNodeId: widget.routeId,
    );

    try {
      await _reportService.submitReport(report);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Report an Issue',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Help us improve the mapping experience by reporting any issues you encounter.',
                style: TextStyle(color: Color(0xFF888888), fontSize: 14),
              ),
              const SizedBox(height: 32),
              
              _buildLabel('ISSUE TYPE'),
              const SizedBox(height: 8),
              _buildDropdown(),
              const SizedBox(height: 24),
              
              _buildLabel('DESCRIPTION'),
              const SizedBox(height: 8),
              _buildTextField(),
              const SizedBox(height: 24),

              _buildLocationCheckbox(),
              const SizedBox(height: 48),
              
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF9CA3AF),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          isExpanded: true,
          items: _issueTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
          onChanged: (val) => setState(() => _selectedType = val!),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: 'Describe the issue in detail...',
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      validator: (val) => (val == null || val.isEmpty) ? 'Please enter a description' : null,
    );
  }

  Widget _buildLocationCheckbox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: CheckboxListTile(
        title: const Text(
          'Include Current Location',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: _currentPosition != null 
          ? Text('Coords: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}')
          : const Text('Fetching location...'),
        value: _includeLocation,
        activeColor: Colors.black,
        onChanged: (val) => setState(() => _includeLocation = val!),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
