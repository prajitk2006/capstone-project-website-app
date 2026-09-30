import 'dart:async';
import 'dart:math';
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
        scaffoldBackgroundColor: const Color(0xFF0A0A0C),
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF141518),
          primary: Color(0xFF4B5563),
          secondary: Colors.blueAccent,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF141518),
          elevation: 0,
        ),
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
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Add Device'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.grey),
                title: const Text('CCTV Camera'),
                onTap: () {
                  _addCamera(CameraSource.cctv);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.smartphone, color: Colors.grey),
                title: const Text('Mobile Device Camera'),
                onTap: () {
                  _addCamera(CameraSource.mobile);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final alertCount = _activeAlerts.length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            const Text('MONITORING', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(_currentTime, style: const TextStyle(fontFamily: 'monospace', color: Colors.grey)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Device',
            onPressed: _showAddCameraDialog,
          ),
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded),
            tooltip: 'Simulate Event',
            onPressed: _simulateAlert,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            const Tab(text: 'CAMERAS', icon: Icon(Icons.grid_view_rounded, size: 20)),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none_rounded, size: 20),
                  const SizedBox(width: 8),
                  const Text('ALERTS'),
                  if (alertCount > 0)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$alertCount',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCamerasTab(),
          _buildAlertsTab(),
        ],
      ),
    );
  }

  Widget _buildCamerasTab() {
    if (_cameras.isEmpty) {
      return const Center(child: Text("No devices connected.", style: TextStyle(color: Colors.grey)));
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
          padding: const EdgeInsets.all(16),
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
      return const Center(child: Text('System normal. No active alerts.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: camera.hasAlert ? Colors.red.withOpacity(0.8) : Colors.transparent,
          width: 2,
        ),
        boxShadow: camera.hasAlert
            ? [BoxShadow(color: Colors.red.withOpacity(0.2), blurRadius: 20)]
            : [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            // Feed background
            Positioned.fill(
              child: CustomPaint(painter: GridPatternPainter()),
            ),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: camera.hasAlert
                  ? const Icon(Icons.warning_rounded, color: Colors.red, size: 48, key: ValueKey('alert'))
                  : const Text('NO SIGNAL', style: TextStyle(color: Colors.white24, letterSpacing: 2), key: ValueKey('normal')),
              ),
            ),
            // Header bar
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  )
                ),
                child: Row(
                  children: [
                    Icon(
                      camera.source == CameraSource.cctv ? Icons.videocam : Icons.smartphone,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        camera.name.toUpperCase(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: onDelete,
                      child: const Icon(Icons.close, size: 16, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1E2126)..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFF141518));
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alert.type.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: alert.type.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: alert.type.color.withOpacity(0.1),
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
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm:ss').format(alert.timestamp),
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onAcknowledge,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.grey.shade800),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('RESOLVE'),
          ),
        ],
      ),
    );
  }
}