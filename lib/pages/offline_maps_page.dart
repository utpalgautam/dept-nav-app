import 'package:flutter/material.dart';
import 'dart:async';
import 'coming_soon_page.dart';

enum MapStatus { downloaded, downloading, notDownloaded }

class OfflineMap {
  final String title;
  final String subtitle;
  final String size;
  final IconData icon;
  final Color iconColor;
  MapStatus status;
  double progress;

  OfflineMap({
    required this.title,
    required this.subtitle,
    required this.size,
    required this.icon,
    required this.iconColor,
    this.status = MapStatus.notDownloaded,
    this.progress = 0.0,
  });
}

class OfflineMapsPage extends StatefulWidget {
  const OfflineMapsPage({super.key});

  @override
  State<OfflineMapsPage> createState() => _OfflineMapsPageState();
}

class _OfflineMapsPageState extends State<OfflineMapsPage> {
  bool _isOfflineMode = true;
  Timer? _downloadTimer;

  // Initial data
  final List<OfflineMap> _maps = [
    OfflineMap(
      title: "Main Building",
      subtitle: "84.2 MB • Updated 2 days ago",
      size: "84.2 MB",
      icon: Icons.map,
      iconColor: const Color(0xFFCCFF5F),
      status: MapStatus.downloaded,
      progress: 1.0,
    ),
    OfflineMap(
      title: "Old Library Complex",
      subtitle: "12.4 MB • Floors 1–5",
      size: "12.4 MB",
      icon: Icons.local_library,
      iconColor: Colors.grey[300]!,
      status: MapStatus.notDownloaded,
    ),
    OfflineMap(
      title: "Faculty Building",
      subtitle: "8.1 MB • 2 Floors",
      size: "8.1 MB",
      icon: Icons.school,
      iconColor: Colors.grey[300]!,
      status: MapStatus.notDownloaded,
    ),
    OfflineMap(
      title: "IT LAB COMPLEX",
      subtitle: "45.0 MB • 3 Floors",
      size: "45.0 MB",
      icon: Icons.computer,
      iconColor: Colors.grey[200]!,
      status: MapStatus.notDownloaded,
    ),
  ];

  @override
  void dispose() {
    _downloadTimer?.cancel();
    super.dispose();
  }

  void _startDownload(int index) {
    setState(() {
      _maps[index].status = MapStatus.downloading;
      _maps[index].progress = 0.0;
    });

    // Cancel any existing simulation
    _downloadTimer?.cancel();

    // Simulate download
    _downloadTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;

      setState(() {
        if (_maps[index].progress < 1.0) {
          _maps[index].progress += 0.05;
        } else {
          _maps[index].status = MapStatus.downloaded;
          _maps[index].progress = 1.0;
          timer.cancel();
        }
      });
    });
  }

  void _stopDownload(int index) {
    _downloadTimer?.cancel();
    setState(() {
      _maps[index].status = MapStatus.notDownloaded;
      _maps[index].progress = 0.0;
    });
  }

  void _deleteMap(int index) {
    setState(() {
      _maps[index].status = MapStatus.notDownloaded;
      _maps[index].progress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final downloadingMaps = _maps
        .where((m) => m.status == MapStatus.downloading)
        .toList();
    final downloadedMaps = _maps
        .where((m) => m.status == MapStatus.downloaded)
        .toList();
    final availableMaps = _maps
        .where((m) => m.status == MapStatus.notDownloaded)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Light grey background
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF5F5F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Cached Offline Maps",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOfflineModeToggle(),
            const SizedBox(height: 20),
            _buildStorageStatus(),
            const SizedBox(height: 24),

            if (downloadingMaps.isNotEmpty) ...[
              _buildSectionTitle("DOWNLOADING"),
              const SizedBox(height: 12),
              ...downloadingMaps.map(
                (map) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildDownloadingItem(map),
                ),
              ),
              const SizedBox(height: 24),
            ],

            _buildSectionTitle("SAVED & AVAILABLE"),
            const SizedBox(height: 12),
            ...downloadedMaps.map(
              (map) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSavedItem(
                  map: map,
                  isDownloaded: true,
                  onDelete: () => _deleteMap(_maps.indexOf(map)),
                ),
              ),
            ),
            ...availableMaps.map(
              (map) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSavedItem(
                  map: map,
                  isDownloaded: false,
                  onDownload: () => _startDownload(_maps.indexOf(map)),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineModeToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Offline Mode",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Force use of cached data only",
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
          Switch(
            value: _isOfflineMode,
            onChanged: (value) {
              setState(() {
                _isOfflineMode = value;
              });
            },
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFFCCFF5F),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageStatus() {
    // Calculate storage used based on downloaded maps (simulated)
    // Assuming base usage of 1.2 GB plus downloaded maps
    double baseUsage = 1.2; // GB
    // Just a placeholder calculation

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "STORAGE STATUS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                "${baseUsage.toStringAsFixed(1)} GB / 5 GB used",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: baseUsage / 5.0,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFCCFF5F),
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildDownloadingItem(OfflineMap map) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(map.icon, color: Colors.grey, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      map.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${(map.progress * 100).toInt()}% of ${map.size}",
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _stopDownload(_maps.indexOf(map)),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: map.progress,
              backgroundColor: Colors.grey[100],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFCCFF5F),
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedItem({
    required OfflineMap map,
    required bool isDownloaded,
    VoidCallback? onDownload,
    VoidCallback? onDelete,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: isDownloaded
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComingSoonPage(title: map.title),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: map.iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(map.icon, color: Colors.black54, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          map.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        if (isDownloaded) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF9CCC65),
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      map.subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              if (isDownloaded)
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline, color: Colors.grey),
                ),
              if (!isDownloaded)
                GestureDetector(
                  onTap: onDownload,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFCCFF5F),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.download,
                      size: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
