import 'package:flutter/material.dart';

/// Google Maps–style turn-by-turn navigation header (dark theme).
class TurnByTurnWidget extends StatelessWidget {
  final String instruction;
  final String distance;
  final int sign; // GraphHopper sign for the current instruction
  final VoidCallback onClose;
  final String? nextInstruction; // "Then turn right" pill
  final int? nextSign; // GraphHopper sign for the next instruction

  const TurnByTurnWidget({
    super.key,
    required this.instruction,
    required this.distance,
    required this.sign,
    required this.onClose,
    this.nextInstruction,
    this.nextSign,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Main Turn Banner ───────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          decoration: BoxDecoration(
            color: const Color(0xFF1C6B45), // Google Maps nav green
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
            child: Row(
              children: [
                // Direction Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getDirectionIcon(sign),
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                // Instruction + Distance
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instruction,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        distance,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Microphone Icon (placeholder/decorative like in image)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: Color(0xFF1C6B45),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── "Then" Pill ───────────────────────────────────────────────────
        if (nextInstruction != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2340),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getDirectionIcon(nextSign ?? 0),
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Then $nextInstruction',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  IconData _getDirectionIcon(int sign) {
    switch (sign) {
      case -3:
        return Icons.turn_sharp_left;
      case -2:
        return Icons.turn_left;
      case -1:
        return Icons.turn_slight_left;
      case 1:
        return Icons.turn_slight_right;
      case 2:
        return Icons.turn_right;
      case 3:
        return Icons.turn_sharp_right;
      case 4:
        return Icons.flag_rounded;
      case 5:
        return Icons.sync_rounded; // Rerouting
      case 6:
        return Icons.keyboard_double_arrow_right; // Waypoint
      default:
        return Icons.straight_rounded;
    }
  }
}
