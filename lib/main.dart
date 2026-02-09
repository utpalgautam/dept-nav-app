import 'package:flutter/material.dart';
import 'pages/faculty_page.dart';
import 'pages/hall_page.dart';
import 'pages/lab_page.dart';
import 'pages/offline_maps_page.dart';
import 'widgets/common.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Directory',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(
          0xFFF5F5F7,
        ), // Light grey background
        primaryColor: const Color(0xFFCCFF5F), // Lime green
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFCCFF5F),
          secondary: Color(0xFFCCFF5F),
          surface: Colors.white,
          background: Color(0xFFF5F5F7),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Default to Home
  int _selectedDirectoryTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildPlaceholderPage("Home", Icons.home);
      case 1:
        return _buildDirectoryPage();
      case 2:
        return _buildPlaceholderPage("Search", Icons.search);
      case 3:
        return const OfflineMapsPage();
      case 4:
        return _buildPlaceholderPage("Profile", Icons.person);
      default:
        return _buildPlaceholderPage("Home", Icons.home);
    }
  }

  Widget _buildPlaceholderPage(String title, IconData icon) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Animation
          const EngineeringGears(size: 300, opacity: 0.3),
          // Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text("Coming Soon", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryPage() {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(),
          _buildTabBar(),
          Expanded(child: _buildDirectoryContent()),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Dark charcoal
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, "Home", 0),
          _buildNavItem(Icons.folder_shared, "Directory", 1),
          _buildNavItem(Icons.search, "Search", 2),
          _buildNavItem(Icons.map, "Maps", 3),
          _buildNavItem(Icons.person, "Profile", 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    Color color = isSelected ? const Color(0xFFCCFF5F) : Colors.grey[400]!;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () {},
          ),
          const Text(
            "Campus Directory",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFFCCFF5F)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem("Faculty", 0),
          _buildTabItem("Halls", 1),
          _buildTabItem("Labs", 2),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    bool isSelected = _selectedDirectoryTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedDirectoryTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFCCFF5F) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey[400],
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDirectoryContent() {
    switch (_selectedDirectoryTab) {
      case 0:
        return const FacultyPage();
      case 1:
        return const HallPage();
      case 2:
        return const LabPage();
      default:
        return const FacultyPage();
    }
  }
}
