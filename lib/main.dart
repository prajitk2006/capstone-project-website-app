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
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1115),
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF1A1D24),
          primary: Color(0xFF4B5563),
        ),
        fontFamily: 'Roboto',
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Timer _clockTimer;
  String _currentTime = '';
  String _currentDate = '';

  int _cameraCounter = 0;
  final List<CameraData> _cameras = [];
  final List<AlertData> _activeAlerts = [];
  final Random _random = Random();

  // Alert types for simulation
  final List<AlertType> _alertTypes = [
    AlertType(name: "MOTION DETECTED", severity: AlertSeverity.high, color: Colors.red),
    AlertType(name: "UNAUTHORIZED ACCESS", severity: AlertSeverity.critical, color: Colors.redAccent),
    AlertType(name: "SIGNAL LOSS", severity: AlertSeverity.medium, color: Colors.amber),
    AlertType(name: "DOOR FORCED", severity: AlertSeverity.high, color: Colors.deepOrange),
  ];

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateClock();
    });

    // Add initial cameras
    for(int i = 0; i < 6; i++){
      _addCamera();
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _updateClock() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(now);
      _currentDate = DateFormat('yyyy-MM-dd').format(now);
    });
  }

  void _addCamera() {
    setState(() {
      _cameraCounter++;
      _cameras.add(CameraData(id: _cameraCounter, name: 'CAMERA $_cameraCounter'));
    });
  }

  void _simulateAlert() {
    if (_cameras.isEmpty) return;

    final int randomCamIndex = _random.nextInt(_cameras.length);
    final CameraData targetCam = _cameras[randomCamIndex];
    final AlertType randomEvent = _alertTypes[_random.nextInt(_alertTypes.length)];

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

      // Check if camera still has other active alerts
      final bool stillHasAlerts = _activeAlerts.any((alert) => alert.cameraId == cameraId);
      if (!stillHasAlerts) {
        final int camIndex = _cameras.indexWhere((c) => c.id == cameraId);
        if (camIndex != -1) {
          _cameras[camIndex].hasAlert = false;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildCameraGrid(),
                ),
                _buildAlertSidebar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Colors.grey[900]!, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'CCTV',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white),
              ),
              const Text(
                ' // MONITORING',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300, letterSpacing: 1.5, color: Colors.grey),
              ),
            ],
          ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _addCamera,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('ADD CAMERA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[850],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currentTime,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 16, color: Colors.white70),
                  ),
                  Text(
                    _currentDate,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraGrid() {
    return _cameras.isEmpty
        ? const Center(child: Text("No cameras added.", style: TextStyle(color: Colors.grey)))
        : GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 16 / 9,
            ),
            itemCount: _cameras.length,
            itemBuilder: (context, index) {
              return CameraWidget(camera: _cameras[index]);
            },
          );
  }

  Widget _buildAlertSidebar() {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(left: BorderSide(color: Colors.grey[900]!, width: 1)),
      ),
      child: Column(
        children: [
          // Sidebar Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[900]!, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SYSTEM ALERTS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white70)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _activeAlerts.isNotEmpty ? Colors.red : Colors.grey[850],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_activeAlerts.length} ACTIVE',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Alerts List
          Expanded(
            child: _activeAlerts.isEmpty
                ? const Center(
                    child: Text(
                      'No active alerts.\nSystem normal.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _activeAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = _activeAlerts[index];
                      return AlertWidget(
                        alert: alert,
                        onAcknowledge: () => _acknowledgeAlert(alert.id, alert.cameraId),
                      );
                    },
                  ),
          ),

          // Sidebar Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[900]!, width: 1)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _simulateAlert,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey[700]!),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('SIMULATE EVENT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Data Models
class CameraData {
  final int id;
  final String name;
  bool hasAlert;

  CameraData({required this.id, required this.name, this.hasAlert = false});
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

// Widgets
class CameraWidget extends StatelessWidget {
  final CameraData camera;

  const CameraWidget({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: camera.hasAlert ? Colors.red : Colors.grey[850]!,
          width: 1,
        ),
        boxShadow: camera.hasAlert
            ? [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 15, spreadRadius: 1)]
            : [],
      ),
      child: Column(
        children: [
          // Camera Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[850]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CAM ${camera.id.toString().padLeft(2, '0')} // ${camera.name}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: camera.hasAlert ? Colors.red : Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),

          // Camera Feed (Simulated)
          Expanded(
            child: Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Pattern background
                  CustomPaint(painter: GridPatternPainter()),
                  // No signal text
                  const Center(
                    child: Text(
                      'NO SIGNAL',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF222630)
      ..strokeWidth = 1.0;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFF1A1D24));

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 20) {
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alert.type.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: alert.type.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  alert.type.name,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: alert.type.color, letterSpacing: 1.1),
                ),
              ),
              Text(
                DateFormat('HH:mm:ss').format(alert.timestamp),
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            alert.cameraName,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onAcknowledge,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.grey[700]!),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                minimumSize: const Size(0, 32),
              ),
              child: const Text('ACKNOWLEDGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ),
          ),
        ],
      ),
    );
  }
}
