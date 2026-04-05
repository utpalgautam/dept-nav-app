import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation_provider.dart';
import 'indoor_navigation_screen.dart';
import 'dart:convert';
import 'dart:typed_data';

class EntryPointConfirmationScreen extends StatefulWidget {
  final String buildingId;
  final String buildingName;
  final String entryPointId;
  final String? entryPointImageUrl;
  final String? destinationLocationId;

  const EntryPointConfirmationScreen({
    super.key,
    required this.buildingId,
    required this.buildingName,
    required this.entryPointId,
    this.entryPointImageUrl,
    this.destinationLocationId,
  });

  @override
  State<EntryPointConfirmationScreen> createState() => _EntryPointConfirmationScreenState();
}

class _EntryPointConfirmationScreenState extends State<EntryPointConfirmationScreen> {
  Uint8List? _decodedImage;

  @override
  void initState() {
    super.initState();
    _decodeImage();
    
    // Voice Instruction on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navProvider = Provider.of<NavigationProvider>(context, listen: false);
      navProvider.speak("Confirm the entry point");
    });
  }

  void _decodeImage() {
    if (widget.entryPointImageUrl != null && widget.entryPointImageUrl!.isNotEmpty) {
      if (!widget.entryPointImageUrl!.startsWith('http')) {
        try {
          final raw = widget.entryPointImageUrl!.contains(',') 
              ? widget.entryPointImageUrl!.split(',').last 
              : widget.entryPointImageUrl!;
          setState(() {
            _decodedImage = base64Decode(raw);
          });
        } catch (e) {
          debugPrint("Error decoding base64 image: $e");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E), // Dark premium background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              // ── Header Card ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Black Arrow Icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_upward_rounded, 
                        color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    // Text
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Confirm the",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            "entry point",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Voice Indicator (Microphone Icon)
                    _VoiceCircleIndicator(),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // ── Entry Point Image ───────────────────────────────────────
              Expanded(
                flex: 8,
                child: Center(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.white, width: 3.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36.5), // Slightly less than 40 to account for border
                      child: _buildEntryPointImage(),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // ── Confirm Button ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 72,
                child: ElevatedButton(
                  onPressed: () => _startIndoorNavigation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "I am at the Given Entry point",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntryPointImage() {
    if (_decodedImage != null) {
      return Image.memory(_decodedImage!, fit: BoxFit.cover);
    } else if (widget.entryPointImageUrl != null && widget.entryPointImageUrl!.startsWith('http')) {
      return Image.network(
        widget.entryPointImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(Icons.image_not_supported_rounded, 
          color: Colors.white24, size: 48),
      ),
    );
  }

  void _startIndoorNavigation(BuildContext context) {
    if (widget.buildingId.isEmpty || widget.entryPointId.isEmpty) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => IndoorNavigationScreen(
          buildingId: widget.buildingId,
          buildingName: widget.buildingName,
          floor: 0,
          entryPointId: widget.entryPointId,
          destinationLocationId: widget.destinationLocationId,
        ),
      ),
    );
  }
}

class _VoiceCircleIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.mic_rounded, color: Colors.black, size: 22),
    );
  }
}
