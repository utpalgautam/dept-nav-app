import 'package:flutter/material.dart';

/// Google Maps–style dark navigation bottom controls.
class CustomNavigationControls extends StatefulWidget {
  final bool isNavigating;
  final bool isLoading;
  final String distance;
  final String time;
  final String? arrivalTime;
  final String instruction;
  final VoidCallback onStartNavigation;
  final VoidCallback onStopNavigation;
  final VoidCallback onConfirmArrival;

  const CustomNavigationControls({
    super.key,
    required this.isNavigating,
    this.isLoading = false,
    required this.distance,
    required this.time,
    this.arrivalTime,
    required this.instruction,
    required this.onStartNavigation,
    required this.onStopNavigation,
    required this.onConfirmArrival,
  });

  @override
  State<CustomNavigationControls> createState() =>
      _CustomNavigationControlsState();
}

class _CustomNavigationControlsState extends State<CustomNavigationControls> {
  double _sliderValue = 0.0;
  bool _isSliding = false;

  @override
  void didUpdateWidget(CustomNavigationControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isNavigating && oldWidget.isNavigating != widget.isNavigating) {
      _sliderValue = 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.isNavigating
        ? _buildTrackingControls()
        : _buildPreviewControls();
  }

  // ── Preview (before navigation starts) ─────────────────────────────────
  Widget _buildPreviewControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF151A2D),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            widget.instruction,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'NIT Calicut, Kerala',
            style: TextStyle(fontSize: 13, color: Colors.white54),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _InfoChip(label: widget.time, icon: Icons.access_time_rounded),
              const SizedBox(width: 10),
              _InfoChip(label: widget.distance, icon: Icons.straighten_rounded),
            ],
          ),
          const SizedBox(height: 24),
          widget.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF1A73E8),
                    strokeWidth: 2.5,
                  ),
                )
              : _buildSwipeSlider(),
        ],
      ),
    );
  }

  Widget _buildSwipeSlider() {
    return GestureDetector(
      onHorizontalDragStart: (_) => setState(() => _isSliding = true),
      onHorizontalDragUpdate: (d) {
        if (!_isSliding) return;
        setState(() {
          _sliderValue = (_sliderValue + d.primaryDelta! / 240).clamp(0.0, 1.0);
        });
      },
      onHorizontalDragEnd: (_) {
        if (_sliderValue > 0.75) {
          setState(() {
            _sliderValue = 1.0;
            _isSliding = false;
          });
          widget.onStartNavigation();
        } else {
          setState(() {
            _sliderValue = 0.0;
            _isSliding = false;
          });
        }
      },
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: const Color(0xFF1A73E8),
          borderRadius: BorderRadius.circular(31),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A73E8).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Swipe to Navigate',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    '${widget.time} • ${widget.distance}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              right: 22,
              top: 0,
              bottom: 0,
              child: Icon(Icons.chevron_right, color: Colors.white70, size: 18),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                margin: EdgeInsets.only(
                  left: 6 + _sliderValue * 190,
                ),
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  color: Color(0xFF1A73E8),
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Active Navigation (Google Style Redesign) ──────────────────────────
  Widget _buildTrackingControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      decoration: const BoxDecoration(
        color: Colors.black, // Exact Google style
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 32,
            height: 3,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Exit Button (X)
              _CircularIconButton(
                icon: Icons.close,
                onTap: widget.onStopNavigation,
              ),

              // 2. Center Info
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          widget.time,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.directions_walk_rounded, 
                          color: Colors.white54, size: 20),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.distance} • ${widget.arrivalTime ?? "..."}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Navigation Arrow Button
              _CircularIconButton(
                icon: Icons.directions_rounded,
                onTap: widget.onConfirmArrival, // Or a separate route overview action
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircularIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24, width: 1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1A73E8)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
