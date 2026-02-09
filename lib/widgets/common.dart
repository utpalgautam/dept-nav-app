import 'package:flutter/material.dart';
import 'dart:math' as math;

class DirectorySearchBar extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  const DirectorySearchBar({super.key, this.onChanged});

  @override
  State<DirectorySearchBar> createState() => _DirectorySearchBarState();
}

class _DirectorySearchBarState extends State<DirectorySearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        focusNode: _focusNode,
        cursorColor: Colors.black,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: Colors.grey),
          hintText: _isFocused ? "" : "Search",
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}

class MainCampusView extends StatelessWidget {
  const MainCampusView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage(
            "https://upload.wikimedia.org/wikipedia/commons/thumb/c/cd/University_of_Oregon_campus_map_1919.jpg/800px-University_of_Oregon_campus_map_1919.jpg",
          ), // Placeholder map
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 16,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Main Campus View",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Tap to view full outdoor map",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: const Icon(Icons.map, color: Color(0xFFCCFF5F)),
          ),
        ],
      ),
    );
  }
}

class EngineeringGears extends StatefulWidget {
  final double size;
  final double opacity;

  const EngineeringGears({super.key, this.size = 180, this.opacity = 1.0});

  @override
  State<EngineeringGears> createState() => _EngineeringGearsState();
}

class _EngineeringGearsState extends State<EngineeringGears>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.opacity,
      child: SizedBox(
        height: widget.size,
        width: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Larger background gear
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: Icon(
                    Icons.settings,
                    size: widget.size * (120 / 180),
                    color: Colors.grey[300],
                  ),
                );
              },
            ),
            // Medium gear
            Positioned(
              top: widget.size * (20 / 180),
              right: widget.size * (20 / 180),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: -_controller.value * 4 * math.pi,
                    child: Icon(
                      Icons.settings,
                      size: widget.size * (60 / 180),
                      color: const Color(0xFFCCFF5F),
                    ),
                  );
                },
              ),
            ),
            // Small gear
            Positioned(
              bottom: widget.size * (30 / 180),
              left: widget.size * (40 / 180),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: -_controller.value * 6 * math.pi,
                    child: Icon(
                      Icons.settings,
                      size: widget.size * (40 / 180),
                      color: Colors.grey[400],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
