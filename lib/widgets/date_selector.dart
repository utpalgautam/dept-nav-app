import 'package:flutter/material.dart';

class DateSelector extends StatelessWidget {
  final String label;
  final ValueChanged<DateTime> onSelected;

  const DateSelector({
    super.key,
    required this.label,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        Row(
          children: [
            _dropdown("Day", 1, 31),
            const SizedBox(width: 8),
            _dropdown("Month", 1, 12),
            const SizedBox(width: 8),
            _dropdown("Year", 1980, DateTime.now().year),
          ],
        ),
      ],
    );
  }

  Widget _dropdown(String hint, int start, int end) {
    return Expanded(
      child: DropdownButtonFormField<int>(
        hint: Text(hint),
        items: List.generate(
          end - start + 1,
          (i) => DropdownMenuItem(
            value: start + i,
            child: Text("${start + i}"),
          ),
        ),
        onChanged: (_) {},
      ),
    );
  }
}
