import 'package:flutter/material.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import 'coming_soon_page.dart';

class FacultyMember {
  final String name;
  final String designation;
  final String department;
  final String cabin;
  final String email;
  final String phone;
  final Color imageColor;
  final String avatarUrl;
  final String category;

  const FacultyMember({
    required this.name,
    required this.designation,
    required this.department,
    required this.cabin,
    required this.email,
    required this.phone,
    required this.imageColor,
    required this.avatarUrl,
    required this.category,
  });
}

class FacultyPage extends StatefulWidget {
  const FacultyPage({super.key});

  @override
  State<FacultyPage> createState() => _FacultyPageState();
}

class _FacultyPageState extends State<FacultyPage> {
  static const List<FacultyMember> _allFacultyMembers = [
    FacultyMember(
      name: "Dr. Abdul Nazeer K. A.",
      designation: "Professor",
      department: "Computer Science and Engineering",
      cabin: "CSE 203-C",
      email: "nazeer@nitc.ac.in",
      phone: "+91-495-2286818",
      imageColor: Color(0xFFBCAAA4),
      avatarUrl:
          "https://admin.minerva.nitc.ac.in/uploads/nazeer_24e3044022.png",
      category: "Professor",
    ),
    FacultyMember(
      name: "Dr. Murali Krishnan K",
      designation: "Professor",
      department: "Computer Science and Engineering",
      cabin: "CSE 201-C",
      email: "kmurali@nitc.ac.in",
      phone: "+91 (495) 2286805",
      imageColor: Color(0xFF90A4AE),
      avatarUrl: " ",
      category: "Professor",
    ),
    FacultyMember(
      name: "Dr. Subasini R",
      designation: "Head of Department",
      department: "Computer Science and Engineering",
      cabin: "CSE 101-A",
      email: "suba@nitc.ac.in",
      phone: "+914952286800",
      imageColor: Color(0xFF81D4FA),
      avatarUrl:
          "https://admin.minerva.nitc.ac.in/uploads/Subashini_R_d85f3e4e27.png",
      category: "Associate Professor",
    ),
    FacultyMember(
      name: "Dr. Shweta",
      designation: "Asst. Professor",
      department: "Computer Science and Engineering",
      cabin: "CSE 201-A",
      email: "shweta@nitc.ac.in",
      phone: "+914952286800",
      imageColor: Color(0xFFFFCC80),
      avatarUrl:
          "https://admin.minerva.nitc.ac.in/uploads/Shweta_3f47db4401.png",
      category: "Assistant Professor",
    ),
    FacultyMember(
      name: "Dr. Sourav Biswas",
      designation: "Asst. Professor",
      department: "Computer Science and Engineering",
      cabin: "MB 104",
      email: "souravbiswas@nitc.ac.in",
      phone: "+91-495-2286818",
      imageColor: Color(0xFFE0E0E0),
      avatarUrl:
          "https://admin.minerva.nitc.ac.in/uploads/Sourav_Biswas_8abf4d003d.png",
      category: "Assistant Professor",
    ),
    FacultyMember(
      name: "Dr. B. Umamaheshwar Sharma",
      designation: "Asst. Professor",
      department: "Computer Science and Engineering",
      cabin: "MB 209",
      email: "busharma@nitc.ac.in",
      phone: "+91 (495) 228 1310",
      imageColor: Color(0xFFE0E0E0),
      avatarUrl:
          "https://admin.minerva.nitc.ac.in/uploads/B_Umamaheswara_Sharma_1d138fc22d.png",
      category: "Assistant Professor",
    ),
  ];

  String _searchQuery = "";

  void _showDetailsDialog(BuildContext context, FacultyMember member) {
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
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(member.avatarUrl),
                  backgroundColor: member.imageColor.withOpacity(0.2),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              _buildDetailRow("Designation", member.designation),
              _buildDetailRow("Department", member.department),
              _buildDetailRow("Cabin", member.cabin),
              _buildDetailRow("Email", member.email),
              _buildDetailRow("Phone", member.phone),
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
    final filteredMembers = _allFacultyMembers.where((m) {
      final query = _searchQuery.toLowerCase();
      return m.name.toLowerCase().contains(query) ||
          m.designation.toLowerCase().contains(query) ||
          m.department.toLowerCase().contains(query);
    }).toList();

    final professors = filteredMembers
        .where((m) => m.category == "Professor")
        .toList();
    final associateProfessors = filteredMembers
        .where((m) => m.category == "Associate Professor")
        .toList();
    final assistantProfessors = filteredMembers
        .where((m) => m.category == "Assistant Professor")
        .toList();

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
        if (professors.isNotEmpty)
          ..._buildGroup(context, "PROFESSORS", professors),
        if (associateProfessors.isNotEmpty)
          ..._buildGroup(context, "ASSOCIATE PROFESSORS", associateProfessors),
        if (assistantProfessors.isNotEmpty)
          ..._buildGroup(context, "ASSISTANT PROFESSORS", assistantProfessors),
        if (filteredMembers.isEmpty)
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

  List<Widget> _buildGroup(
    BuildContext context,
    String title,
    List<FacultyMember> members,
  ) {
    return [
      SectionHeader(title: title),
      const SizedBox(height: 12),
      ...members.map(
        (member) => Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: PersonCard(
            name: member.name,
            imageColor: member.imageColor,
            avatarUrl: member.avatarUrl,
            onTap: () => _showDetailsDialog(context, member),
            onNavigate: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ComingSoonPage(title: member.name),
                ),
              );
            },
          ),
        ),
      ),
      const SizedBox(height: 8),
    ];
  }
}
