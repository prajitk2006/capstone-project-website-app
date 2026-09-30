import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const CCTVDashboardApp());
}

class CCTVDashboardApp extends StatelessWidget {
  const CCTVDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minimal CCTV Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: const ColorScheme.dark(
          surface: Colors.black26,
          primary: Colors.white,
          secondary: Colors.white70,
        ),
        fontFamily: 'Roboto',
      ),
      home: const DashboardScreen(),
    );
  }
}

enum CameraSource { cctv, mobile }

class CameraData {
  final int id;
  final String name;
  final CameraSource source;
  bool hasAlert;

  CameraData({
    required this.id,
    required this.name,
    required this.source,
    this.hasAlert = false,
  });
}

enum AlertSeverity { medium, high, critical }

class AlertType {
  final String name;
  final AlertSeverity severity;
  final Color color;

  AlertType({required this.name, required this.severity, required this.color});
}

class AlertData {
  final String id;
  final int cameraId;
  final String cameraName;
  final AlertType type;
  final DateTime timestamp;

  AlertData({
    required this.id,
    required this.cameraId,
    required this.cameraName,
    required this.type,
    required this.timestamp,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Timer _clockTimer;
  String _currentTime = '';

  int _cameraCounter = 0;
  final List<CameraData> _cameras = [];
  final List<AlertData> _activeAlerts = [];
  final Random _random = Random();

  final List<AlertType> _alertTypes = [
    AlertType(name: "MOTION DETECTED", severity: AlertSeverity.high, color: Colors.redAccent),
    AlertType(name: "UNAUTHORIZED ACCESS", severity: AlertSeverity.critical, color: Colors.red),
    AlertType(name: "SIGNAL LOSS", severity: AlertSeverity.medium, color: Colors.amber),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });

    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateClock();
    });

    // Initial cameras
    _addCamera(CameraSource.cctv);
    _addCamera(CameraSource.cctv);
    _addCamera(CameraSource.mobile);
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _updateClock() {
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
    });
  }

  void _addCamera(CameraSource source) {
    setState(() {
      _cameraCounter++;
      _cameras.add(CameraData(
        id: _cameraCounter,
        name: 'Camera $_cameraCounter',
        source: source,
      ));
    });
  }

  void _deleteCamera(int id) {
    setState(() {
      _cameras.removeWhere((cam) => cam.id == id);
      // Optional: remove related alerts
      _activeAlerts.removeWhere((alert) => alert.cameraId == id);
    });
  }

  void _simulateAlert() {
    if (_cameras.isEmpty) return;

    final targetCam = _cameras[_random.nextInt(_cameras.length)];
    final randomEvent = _alertTypes[_random.nextInt(_alertTypes.length)];

    final newAlert = AlertData(
      id: DateTime.now().millisecondsSinceEpoch.toString() + _random.nextInt(1000).toString(),
      cameraId: targetCam.id,
      cameraName: targetCam.name,
      type: randomEvent,
      timestamp: DateTime.now(),
    );

    setState(() {
      _activeAlerts.insert(0, newAlert);
      targetCam.hasAlert = true;
    });
  }

  void _acknowledgeAlert(String alertId, int cameraId) {
    setState(() {
      _activeAlerts.removeWhere((alert) => alert.id == alertId);
      if (!_activeAlerts.any((alert) => alert.cameraId == cameraId)) {
        final camIndex = _cameras.indexWhere((c) => c.id == cameraId);
        if (camIndex != -1) _cameras[camIndex].hasAlert = false;
      }
    });
  }

  void _showAddCameraDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38), // 0.15 * 255 = 38
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withAlpha(77), width: 1.5), // 0.3 * 255 = 77
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Add Device',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.videocam, color: Colors.white),
                      title: const Text('CCTV Camera', style: TextStyle(color: Colors.white)),
                      onTap: () {
                        _addCamera(CameraSource.cctv);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.smartphone, color: Colors.white),
                      title: const Text('Mobile Device Camera', style: TextStyle(color: Colors.white)),
                      onTap: () {
                        _addCamera(CameraSource.mobile);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final alertCount = _activeAlerts.length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF9A826), // Warm Yellow-Orange
              Color(0xFFFF4B2B), // Warm Red
              Color(0xFF9D50BB), // Warm Purple
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              _buildSidebar(alertCount),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCamerasTab(),
                    _buildAlertsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(int alertCount) {
    return Container(
      width: 250,
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(38), // 0.15
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withAlpha(77), width: 1.5), // 0.3
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26), // 0.1
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('MONITORING', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white))),
                  ],
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    _currentTime,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                ),
                const SizedBox(height: 32),
                _buildSidebarItem(
                  icon: Icons.grid_view_rounded,
                  title: 'CAMERAS',
                  index: 0,
                ),
                const SizedBox(height: 16),
                _buildSidebarItem(
                  icon: Icons.notifications_none_rounded,
                  title: 'ALERTS',
                  index: 1,
                  badgeCount: alertCount,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddCameraDialog,
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                  label: const Text('Add Device', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withAlpha(51), // 0.2
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _simulateAlert,
                  icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
                  label: const Text('Simulate Event', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withAlpha(51), // 0.2
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem({required IconData icon, required String title, required int index, int badgeCount = 0}) {
    final isSelected = _tabController.index == index;
    return InkWell(
      onTap: () {
        _tabController.animateTo(index);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withAlpha(64) : Colors.transparent, // 0.25
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: Colors.white.withAlpha(128)) : Border.all(color: Colors.transparent), // 0.5
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white))),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$badgeCount', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCamerasTab() {
    if (_cameras.isEmpty) {
      return const Center(child: Text("No devices connected.", style: TextStyle(color: Colors.white70)));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 800) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          padding: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 16 / 10,
          ),
          itemCount: _cameras.length,
          itemBuilder: (context, index) {
            final cam = _cameras[index];
            return CameraWidget(
              key: ValueKey(cam.id),
              camera: cam,
              onDelete: () => _deleteCamera(cam.id),
            );
          },
        );
      },
    );
  }

  Widget _buildAlertsTab() {
    if (_activeAlerts.isEmpty) {
      return const Center(child: Text('System normal. No active alerts.', style: TextStyle(color: Colors.white70)));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
      itemCount: _activeAlerts.length,
      itemBuilder: (context, index) {
        final alert = _activeAlerts[index];
        return AlertWidget(
          key: ValueKey(alert.id),
          alert: alert,
          onAcknowledge: () => _acknowledgeAlert(alert.id, alert.cameraId),
        );
      },
    );
  }
}

class CameraWidget extends StatelessWidget {
  final CameraData camera;
  final VoidCallback onDelete;

  const CameraWidget({super.key, required this.camera, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(38), // 0.15
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: camera.hasAlert ? Colors.red.withAlpha(204) : Colors.white.withAlpha(77), // 0.8 / 0.3
              width: camera.hasAlert ? 2 : 1.5,
            ),
            boxShadow: camera.hasAlert
                ? [BoxShadow(color: Colors.red.withAlpha(102), blurRadius: 20)] // 0.4
                : [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10)], // 0.05
          ),
          child: Stack(
            children: [
              // Feed background
              Positioned.fill(
                child: CustomPaint(painter: GridPatternPainter(Colors.white.withAlpha(26))), // 0.1
              ),
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: camera.hasAlert
                    ? const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 48, key: ValueKey('alert'))
                    : const Text('NO SIGNAL', style: TextStyle(color: Colors.white70, letterSpacing: 2), key: ValueKey('normal')),
                ),
              ),
              // Header bar
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(64), // 0.25
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        camera.source == CameraSource.cctv ? Icons.videocam : Icons.smartphone,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          camera.name.toUpperCase(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: onDelete,
                        child: const Icon(Icons.close, size: 16, color: Colors.white70),
                      ),
                    ],
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

class GridPatternPainter extends CustomPainter {
  final Color lineColor;
  GridPatternPainter(this.lineColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = lineColor..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AlertWidget extends StatelessWidget {
  final AlertData alert;
  final VoidCallback onAcknowledge;

  const AlertWidget({super.key, required this.alert, required this.onAcknowledge});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(38), // 0.15
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: alert.type.color.withAlpha(179), width: 1.5), // 0.7
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: alert.type.color.withAlpha(51), // 0.2
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_amber_rounded, color: alert.type.color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.type.name,
                        style: TextStyle(fontWeight: FontWeight.bold, color: alert.type.color, letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.cameraName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('HH:mm:ss').format(alert.timestamp),
                        style: const TextStyle(fontSize: 12, color: Colors.white70, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: onAcknowledge,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withAlpha(128)), // 0.5
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('RESOLVE'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
