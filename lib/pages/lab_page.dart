import 'package:flutter/material.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import 'coming_soon_page.dart';

class Lab {
  final String name;
  final String location;
  final String incharge;
  final String capacity;
  final Color imageColor;
  final String imageUrl;

  const Lab({
    required this.name,
    required this.location,
    required this.incharge,
    required this.capacity,
    required this.imageColor,
    required this.imageUrl,
  });
}

class LabPage extends StatefulWidget {
  const LabPage({super.key});

  @override
  State<LabPage> createState() => _LabPageState();
}

class _LabPageState extends State<LabPage> {
  static const List<Lab> _allLabs = [
    Lab(
      name: "System Security Lab",
      location: "iT LAB COMPLEX, 2nd Floor",
      incharge: "Dr. Hiran V Nath",
      capacity: "70",
      imageColor: Color(0xFFFFF59D),
      imageUrl:
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQrHhh-RwEMB3SQTp4EyKu4Wue3o_7LIb42Sw&s",
    ),
    Lab(
      name: "Networks Security Lab",
      location: "IT LAB COMPLEX, 2nd Floor",
      incharge: "Dr. Sumesh T A",
      capacity: "60",
      imageColor: Color(0xFFA5D6A7),
      imageUrl:
          "https://lh7-rt.googleusercontent.com/docsz/AD_4nXeHUB0d6XEC73tXagU-kj1vxhYYXFITtFcCTiYhF6nkyEoB7oEHyZdR_K2_IleofBUG_BQS0OjxfgfsyGF5bVfSeex8rpaX-30NjkVt2laL3e08BgXO_xfrlveOr2iXU5avio2-OTRRNtcS7mUF9FHHjnAh?key=z7AVppCIK5RDvRK9u53QuA",
    ),
    Lab(
      name: "IP Lab",
      location: "Main Building, 2nd Floor",
      incharge: "NA",
      capacity: "50",
      imageColor: Color(0xFF90CAF9),
      imageUrl:
          "https://lh7-rt.googleusercontent.com/docsz/AD_4nXduUjmoTh1ac3DhSHdN-r25oK15AD0X_j_DEnnDWVnFLOUI9tDjdeVJGnmxEy3ra1LcNdTWsesJE-a-XUTk8z73RGojxEoevrQyVFdjPYi9ReBDH30f9ZFhxdv46zSTDUgP1soqYQxP-kStA6s1OUd3nsuX?key=z7AVppCIK5RDvRK9u53QuA",
    ),
  ];

  String _searchQuery = "";

  void _showDetailsDialog(BuildContext context, Lab lab) {
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
                  color: lab.imageColor.withOpacity(0.2),
                  image: DecorationImage(
                    image: NetworkImage(lab.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  lab.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              _buildDetailRow("Location", lab.location),
              _buildDetailRow("Lab Incharge", lab.incharge),
              _buildDetailRow("Capacity", lab.capacity),
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
    final filteredLabs = _allLabs.where((l) {
      final query = _searchQuery.toLowerCase();
      return l.name.toLowerCase().contains(query) ||
          l.location.toLowerCase().contains(query) ||
          l.incharge.toLowerCase().contains(query);
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
        ...filteredLabs.map(
          (lab) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: LabCard(
              name: lab.name,
              imageColor: lab.imageColor,
              imageUrl: lab.imageUrl,
              onTap: () => _showDetailsDialog(context, lab),
              onNavigate: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComingSoonPage(title: lab.name),
                  ),
                );
              },
            ),
          ),
        ),
        if (filteredLabs.isEmpty)
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
