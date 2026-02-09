import 'package:flutter/material.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import 'coming_soon_page.dart';

class Hall {
  final String name;
  final String location;
  final String capacity;
  final String type;
  final Color imageColor;
  final String imageUrl;

  const Hall({
    required this.name,
    required this.location,
    required this.capacity,
    required this.type,
    required this.imageColor,
    required this.imageUrl,
  });
}

class HallPage extends StatefulWidget {
  const HallPage({super.key});

  @override
  State<HallPage> createState() => _HallPageState();
}

class _HallPageState extends State<HallPage> {
  static const List<Hall> _allHalls = [
    Hall(
      name: "A P J Abdul Kalam Hall",
      location: "CSED Building, 2nd Floor",
      capacity: "30",
      type: "Conference Hall",
      imageColor: Color(0xFF9FA8DA),
      imageUrl:
          "https://nitc.ac.in/imgserver/uploads/attachments/Ed__7d2e36dc-38c7-4c0b-8187-5e33b103e720_.jpg",
    ),
    Hall(
      name: "CSED Seminar Hall",
      location: "Main Building, 1st Floor",
      capacity: "50",
      type: "Seminar Room",
      imageColor: Color(0xFF80CBC4),
      imageUrl:
          "https://nitc.ac.in/imgserver/uploads/attachments/Ed__fc03a7cd-d42d-423c-b306-184174bf6c12_.jpeg",
    ),
  ];

  String _searchQuery = "";

  void _showDetailsDialog(BuildContext context, Hall hall) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: hall.imageColor.withOpacity(0.2),
                  image: DecorationImage(
                    image: NetworkImage(hall.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  hall.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              _buildDetailRow("Type", hall.type),
              _buildDetailRow("Location", hall.location),
              _buildDetailRow("Capacity", hall.capacity),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredHalls = _allHalls.where((h) {
      final query = _searchQuery.toLowerCase();
      return h.name.toLowerCase().contains(query) ||
          h.location.toLowerCase().contains(query) ||
          h.type.toLowerCase().contains(query);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        DirectorySearchBar(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        const SizedBox(height: 24),
        ...filteredHalls.map(
          (hall) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: HallCard(
              name: hall.name,
              imageColor: hall.imageColor,
              imageUrl: hall.imageUrl,
              onTap: () => _showDetailsDialog(context, hall),
              onNavigate: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComingSoonPage(title: hall.name),
                  ),
                );
              },
            ),
          ),
        ),
        if (filteredHalls.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text(
                "No results found",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        const SizedBox(height: 80),
      ],
    );
  }
}
